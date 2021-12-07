package MojoX::HTTP::Async;

=encoding utf-8

=head1 NAME

MojoX::HTTP::Async - The simple package to execute multiple parallel requests to the same host

=head1 SYNOPSIS

    use MojoX::HTTP::Async ();
    use Mojo::Message::Request ();

    # creates new instance for async requests
    # restricts max amount of simultaneously executed requests
    my $ua = MojoX::HTTP::Async->new('host' => 'my-site.com', 'slots' => 2);

    # let's fill slots
    $ua->add( '/page1.html?lang=en');
    $ua->add( 'http://my-site.com/page2.html');
    $ua->add( Mojo::Message::Request->new() );

    # non-blocking requests processing
    while ( $ua->not_empty() ) {
        if (my $tx = $ua->next_response) { # returns an instance of Mojo::Transaction::HTTP class
            print $tx->res->headers->to_string;
        } else {
            # do something else
        }
    }

    # blocking requests processing
    while (my $tx = $ua->wait_for_next_response($timeout)) {
        # do something here
    }

    # how to process connect timeouts
    if (my $error = $tx->req()->error()) {
        say $error->{code};
        say $error->{message};
    }

    # how to process request timeouts and other errors sucn as broken pipes, etc
    if (my $error = $tx->res()->error()) {
        say $error->{code};
        say $error->{message};
    }

    # makes reconnection if either slot was timeouted or was inactive too long
    $ua->refresh_connections();

    # close everything
    $ua->close_all();

=head1 DESCRIPTION

This library allows to make multiple HTTP/HTTPS request to the particular host in non-blocking mode.

In comparison with C<HTTP::Async>, this library doesn't make a new connection on each request.

And in comparison with C<Mojo::AsyncAwait>, it's it's more intuitive how to use it, and there is no any Singleton restrictions.

The instance of this class can work only with one domain and scheme: either HTTP or HTTPS.

=head1 LICENSE

This module is distributed under terms of Artistic Perl 5 license.

=cut

use 5.020;
use warnings;
use bytes ();
use Socket qw/ inet_aton pack_sockaddr_in AF_INET SOCK_STREAM SOL_SOCKET SO_KEEPALIVE SO_OOBINLINE IPPROTO_TCP TCP_KEEPIDLE TCP_KEEPINTVL TCP_KEEPCNT /;
#use IO::Socket::IP ();
use IO::Socket::SSL ();
use Fcntl qw/ F_SETFL O_NONBLOCK FD_CLOEXEC O_NOINHERIT /;
use experimental qw/ signatures /;
use Carp qw/ croak /;
use List::Util qw/ first /;
use Time::HiRes qw/ time /;
use Mojo::Message::Request ();
use Mojo::Message::Response ();
use Mojo::Transaction::HTTP ();
use URI ();
use Scalar::Util qw/ blessed /;
use Errno qw / :POSIX /;

our $VERSION = 0.10;

use constant {
    IS_WIN     => ($^O eq 'MSWin32') ? 1 : 0,
    IS_NOT_WIN => ($^O ne 'MSWin32') ? 1 : 0,
};

=head2 new($class, %opts)

The class constructor.

=over

=item host

It's the obligatory option.
Sets the name/adress of remote host to be requested.

=item port

By default it's equal to 80.
Sets the port number of remote point.

=item slots

By default it's equal to 5.
Sets the maximum amount of slots.
These slot will be filled one by one if required.

=item ssl

By default it's equal to 0 (means HTTP).
Sets the scheme of requests: HTTP or HTTPS.

=item ssl_opts

It's a HashRef with options to control SSL Layer.
See C<IO::Socket::SSL> constructor arguments for details.

=item connect_timeout

By default it's equal to 1.
Sets connection timeout in seconds.

If it's equal to 0, then there will be no timeout restrictions.

=item request_timeout

By default it's equal to 1
Sets the time in seconds with granular accuracy as micro seconds.
The awaiting time of response will be limited with this value.

In case of 0 value there will be no time restrictions.

=item sol_socket

It's a HashRef with socket options.
THe possible keys are:

=item B<so_keepalive>

Enables TCP KeepAlive on socket.
The default value is 1 (means that option is enabled).

=item B<sol_tcp>

WARNING: These options can be unsupported on some OS platforms.

It's a HashRef with socket TCP-options.

If some key is absent in HashRef then system settings will be used.

The supported key are shown below:

B<tcp_keepidle> - the time (in seconds) the connection needs to remain idle before TCP starts sending keepalive probes

B<tcp_keepintvl> - the time (in seconds) between individual keepalive probes

B<tcp_keepcnt> - the maximum number of keepalive probes TCP should send before dropping the connection.

=item inactivity_conn_ts

If last response was received C<inactivity_conn_ts> seconds or more ago,
then such slots will be destroyed in C<clear> method.

By default the value is 0 (disabled).

=item debug

Enables debug mode. The dbug messages will be printed in STDERR.
By default the value is 0 (disabled).

=back

=cut

sub new ($class, %opts) {
    croak("host is mandatory") if (! $opts{'host'});
    my $self = bless({
        'slots' => 5,
        'ssl' => 0,
        'ssl_opts' => undef,
        'port' => $opts{'ssl'} ? 443 : 80,
        'request_timeout' => 1, # 1 sec
        'connect_timeout' => 1, # 1 sec
        'sol_socket' => {
            'so_keepalive' => 1,
        },
        'sol_tcp' => {},
        'inactivity_conn_ts' => 0,
        %opts,
        '_conns' => [],
    }, $class);
    return $self;
}

sub _connect ($self, $slot, $proto, $peer_addr) {

    warn("Connecting\n") if $self->{'debug'};

    socket(my $socket, AF_INET, SOCK_STREAM, $proto) || croak("socket error: $!");
    connect($socket, $peer_addr)                     || croak("connect error: $!"); # in case of O_NONBLOCK it will return with EINPROGRESS

    # When a constant is used in an expression, Perl replaces it with its value at compile time,
    # and may then optimize the expression further. In particular, any code in an if (CONSTANT)
    # block will be optimized away if the constant is false.
    if (&IS_NOT_WIN) {
        fcntl($socket, F_SETFL, O_NONBLOCK | FD_CLOEXEC) || croak("fcntl error has occurred: $!");
    }

    if (&IS_WIN) {
        #$socket = IO::Socket::IP->new_from_fd(fileno($socket), '+<');
        defined($socket->blocking(0)) or croak("can't set non-blocking state on socket: $!");
        #$socket->sockopt(O_NOINHERIT, 1) or croak("fcntl error has occurred: $!"); # the same as SOCK_CLOEXEC
    }

    my $sol_socket_opts = $self->{'sol_socket'} // {};

    if (exists($sol_socket_opts->{'so_keepalive'})) {
        setsockopt($socket, SOL_SOCKET, SO_KEEPALIVE, 1) || croak("setsockopt error has occurred while setting SO_KEEPALIVE: $!");

        if ($sol_socket_opts->{'so_keepalive'}) {
            my $sol_tcp_opts = $self->{'sol_tcp'} // {};
            state $SOL_TCP = &IPPROTO_TCP();

            if (exists($sol_tcp_opts->{'tcp_keepidle'})) {
                setsockopt($socket, $SOL_TCP, TCP_KEEPIDLE, $sol_tcp_opts->{'tcp_keepidle'}) || croak("setsockopt error has occurred while setting TCP_KEEPIDLE: $!");
            }

            if (exists($sol_tcp_opts->{'tcp_keepintvl'})) {
                setsockopt($socket, $SOL_TCP, TCP_KEEPINTVL, $sol_tcp_opts->{'tcp_keepintvl'}) || croak("setsockopt error has occurred while setting TCP_KEEPINTVL: $!");
            }

            if (exists($sol_tcp_opts->{'tcp_keepcnt'})) {
                setsockopt($socket, $SOL_TCP, TCP_KEEPCNT, $sol_tcp_opts->{'tcp_keepcnt'}) || croak("setsockopt error has occurred while setting TCP_KEEPCNT: $!");
            }
        }
    }

    $slot->{'connected_ts'} = time();
    $slot->{'reader'} = $slot->{'writer'} = $slot->{'socket'} = $socket;
    $slot->{'sock_no'} = fileno($socket);
    if ($self->{'ssl'}) {
        my $ssl_socket = IO::Socket::SSL->new_from_fd($socket, ($self->{'ssl_opts'} // {})->%*);
        croak("error=$!, ssl_error=" . $IO::Socket::SSL::SSL_ERROR) if (!$ssl_socket);
        $ssl_socket->blocking(0); # just to be sure
        $slot->{'reader'} = $slot->{'writer'} = $ssl_socket;
    }
}

sub _connect_slot ($self, $slot) {
    my $timeout = $self->{'connect_timeout'};

    if ($timeout > 0) {
        eval {
            local $SIG{'ALRM'} = sub { die "alarm\n" };
            alarm($timeout);
            $self->_connect($slot, @{$self}{qw/ proto peer_addr /});
            alarm(0);
        };

        my $error = $@;

        alarm(0);

        if ($error) {
            croak($error) if ($error ne "alarm\n");
            $self->_mark_request_as_timeouted($slot, 'Connect timeout');
        }
    } else {
        $self->_connect($slot, @{$self}{qw/ proto peer_addr /});
    }
}

sub _make_connections ($self, $amount) {

    my $host_addr = inet_aton($self->{'host'});
    croak("can't call inet_aton") if (! $host_addr);

    $self->{'peer_addr'} //= pack_sockaddr_in($self->{'port'}, $host_addr);
    $self->{'proto'} //= getprotobyname("tcp");

    for (1 .. $amount) {
        my $slot = $self->_make_slot();
        $self->_connect_slot($slot);
        $self->_add_slot($slot);
    }
}

sub _add_slot ($self, $slot) {
    push($self->{'_conns'}->@*, $slot) if ($slot);
}

sub _make_slot ($self) {
    return {
        'reader' => undef,
        'writer' => undef,
        'socket' => undef,
        'sock_no' => 0,
        'is_busy' => 0,
        'request' => undef,
        'tx' => undef,
        'exp_ts' => 0,
        'tmp_response' => undef,
        'reconnect_is_required' => 0,
        'last_response_ts' => 0,
        'connected_ts' => 0,
    };
}

sub _check_for_errors ($self, $socks2slots = {}, $error_handles = '', $reason = '') {

    my $message = $reason;

    if (!$message) {
        $message = ($!{'EPIPE'} || $!{'ECONNRESET'} || $!{'ECONNREFUSED'} || $!{'ECONNABORTED'}) ? 'Premature connection close' : 'Unknown error';
    }

    for my $slot_no (keys %$socks2slots) {
        if ( vec($error_handles, $slot_no, 1) != 0 ) {
            my $slot = $socks2slots->{ $slot_no };
            $self->_mark_response_as_broken($slot, 520, $message);
        }
    }
}

sub _get_free_slot ($self) {

    my $slot;
    my %socks2slots = map { $_->{'sock_no'} => $_ }
                      grep { !$_->{'is_busy'} && $_->{'socket'} && !$_->{'reconnect_is_required'} }
                      $self->{'_conns'}->@*;

    if (%socks2slots) {

        local $!;
        my $write_handles = '';

        vec($write_handles, $_, 1) = 1 for keys %socks2slots;

        my $error_handles = $write_handles;
        my ($nfound, $timeleft) = select(undef, $write_handles, $error_handles, 0);

        $self->_check_for_errors(\%socks2slots, $error_handles, $!);

        if ($nfound) {
            my $slot_no = first { vec($write_handles, $_, 1) == 1 } keys %socks2slots;
            $slot = $socks2slots{ $slot_no };
        }
    }

    return $slot;
}

=head2 add ($self, $request_or_uri, $timeout = undef)

Adds HTTP request into empty slot.

If the request was successfully added, then it will return 1.
Otherwise it will return 0.

The request can be not added into slot only in case, if there are no empty slots and new slot wasn't created due to
the limit of slot's amount had been reached (see C<new> and C<slots>.

It's recommendable always to check result code of this method.

Example:

    my $ua = MojoX::HTTP::Async->new('host' => 'my-host.com', 'slots' => 1);

    # let's occupy the only slot
    $ua->add('/page1.html');

    # let's wait until it's become free again
    while ( ! $ua->add('/page2.html') ) {
        while (my $tx = $ua->wait_for_next_response() ) {
            # do something here
        }
    }

=over

=item $request_or_uri

It can be either an instance of C<Mojo::Message::Request> class, or an instance of C<Mojo::URL>.
It also can be a simple URI srtring.

If the resourse contains the host, then it must be the same as in the constructor C<new>.

Using of string with URI or an instance of C<Mojo::URL> class assumes that GET HTTP method will be used.

=item $timeout

Time in seconds. Can be fractional with microseconds tolerance.

The C<request_timeout> from conmtrucor will be used by default.

=back

=cut

sub add ($self, $request_or_uri, $timeout = undef) {
    my $status = 0;
    my $slot = $self->_get_free_slot();

    if ( ! $slot && $self->{'slots'} > scalar($self->{'_conns'}->@*) ) {
        $self->_make_connections(1);
        $slot = $self->_get_free_slot();
    }

    if ($slot) {
        my $request = $request_or_uri;
        if ( !ref($request_or_uri) || ( blessed($request_or_uri) && $request_or_uri->isa('Mojo::URL') ) ) {
            $request = Mojo::Message::Request->new();
            $request->url()->parse($request_or_uri);
        }
        if ($request) {
            $self->_send_request($slot, $request, $timeout);
            $status = 1;
        }
    }

    return $status;
}

sub _clear_slot ($self, $slot, $force = 0) {
    $slot->{'is_busy'} = 0;
    $slot->{'exp_ts'} = 0;
    $slot->{'tx'} = undef;
    $slot->{'request'} = undef;
    $slot->{'tmp_response'} = undef;
    if ($force) {
        close($slot->{'socket'}) if $slot->{'socket'};
        $slot->{'socket'} = undef;
        $slot->{'reader'} = undef;
        $slot->{'writer'} = undef;
        $slot->{'sock_no'} = 0;
        $slot->{'reconnect_is_required'} = 0;
        $slot->{'last_response_ts'} = 0;
        $slot->{'connected_ts'} = 0;
    }
}

sub _mark_slot_as_broken($self, $slot) {
    $slot->{'reconnect_is_required'} = 1;
    $slot->{'is_busy'} = 1;
    $slot->{'request'} //= Mojo::Message::Request->new();
    $slot->{'tx'} //= Mojo::Transaction::HTTP->new(
        'req' => $slot->{'request'},
        'res' => Mojo::Message::Response->new()
    );
}

sub _mark_request_as_broken ($self, $slot, $code = 520, $msg = 'Unknown Error') {
    $self->_mark_slot_as_broken($slot);li
    $slot->{'request'}->error({'message' => $msg, 'code' => $code});
}

sub _mark_response_as_broken ($self, $slot, $code = 520, $msg = 'Unknown Error') {
    $self->_mark_slot_as_broken($slot);

    my $res = $slot->{'tx'}->res();
    $res->error({'message' => $msg, 'code' => $code});
    $res->headers()->content_length(0);
    $res->code($code);
    $res->message($msg);
}

sub _mark_request_as_timeouted ($self, $slot, $message = 'Request timeout') {
    $self->_mark_request_as_broken($slot, 524, $message);
}

sub _mark_response_as_timeouted ($self, $slot, $message = 'Request timeout') {
    $self->_mark_response_as_broken($slot, 524, $message);
}

sub _send_request ($self, $slot, $request, $timeout = undef) {

    croak("slot is busy") if ($slot->{'is_busy'});
    croak("request object is obligatory") if (!$request);
    croak('request must be a descendant of Mojo::Message::Request package') if (!$request->isa('Mojo::Message::Request'));

    my $required_scheme = $self->{'ssl'} ? 'https' : 'http';
    my $url = $request->url();
    my $uri = URI->new( $url );
    my $scheme = $url->scheme();

    if ($scheme && $required_scheme ne $scheme) {
        croak(sprintf("Wrong scheme in URI '%s'. It must correspond to the 'ssl' option", $uri->as_string()));
    }

    if (! $uri->scheme()) {
        # URI::_generic doesn't have C<host> method, that's why we set the scheme by ourseleves to change C<$uri> type
        $uri->scheme($required_scheme);
    }

    if (my $host = $uri->host()) {
        if ($host ne $self->{'host'}) {
            croak(sprintf("Wrong host in URI '%s'. It must be the same as it was specified in constructor: %s", $uri->as_string(), $self->{'host'}));
        }
    }

    $timeout //= $self->{'request_timeout'};

    my $response = '';
    state $default_ua_hdr = 'perl/' . __PACKAGE__;

    my $h = $request->headers();
    $h->host($self->{'host'}) if (! $h->host() );
    $h->user_agent($default_ua_hdr) if (! $h->user_agent() );

    $slot->{'request'} = $request;
    $slot->{'is_busy'} = 1;
    $slot->{'exp_ts'} = ($timeout > 0) ? ( time() + $timeout ) : 0;

    my $plain_request = $request->to_string();

    if ($self->{'ssl'}) {
        $slot->{'writer'}->print($plain_request);
    } else {
        my $socket = $slot->{'socket'};
        my $msg_len = bytes::length($plain_request);
        my $sent_bytes = 0;
        my $attempts = 10;

        local $!;

        while ($sent_bytes < $msg_len && $attempts--) {
            my $bytes = syswrite($socket, $plain_request, $msg_len, $sent_bytes);

            if ($! || ! defined($bytes)) {
                my $error = $! // 'Unknown error';
                $self->_mark_request_as_broken($slot, 520, $error);
                return;
            }

            $sent_bytes += $bytes;
            $plain_request = substr($plain_request, $bytes) if $sent_bytes < $msg_len;
        }

        if ($sent_bytes < $msg_len) {
            my $error = $! // 'sent message is shorter than original';
            $self->_mark_request_as_broken($slot, 520, $error);
            return;
        }
    }

    if ($slot->{'exp_ts'} && time() > $slot->{'exp_ts'}) {
        $self->_mark_request_as_timeouted($slot);
    }

    return;
}

sub _try_to_read ($self, $slot) {

    return if $slot->{'tx'} || ! $slot->{'is_busy'};

    my $reader = $slot->{'reader'};
    my $response = $slot->{'tmp_response'} // Mojo::Message::Response->new();

    $response->parse($_) while (<$reader>);

    if ($! && !$!{'EAGAIN'} && !$!{'EWOULDBLOCK'}) { # not a "Resourse temporary unavailable" (no data)
        $self->_mark_response_as_broken($slot, 520, $!);
    } elsif ($response && $response->code()) {

        my $content = $response->content();

        if ($content->is_finished()) { # this is required to support  "Transfer-Encoding: chunked"
            $slot->{'tx'} = Mojo::Transaction::HTTP->new(
                'req' => $slot->{'request'},
                'res' => $response
            );
            $slot->{'tmp_response'} = undef;
            $slot->{'last_response_ts'} = time();
        } else {
            $slot->{'tmp_response'} = $response;
        }

        $slot->{'reconnect_is_required'} = 1 if ($content->relaxed()); # responses that are terminated with a connection close
    }

    if (! $slot->{'tx'} && ($slot->{'exp_ts'} && time() > $slot->{'exp_ts'})) {
        $self->_mark_response_as_timeouted($slot);
    }
}

=head2 not_empty($self)

Returns 1 if there even one slot is busy or slot contains a not processed response.
Otherwise the method returns 0.

=cut

sub not_empty ($self) {

    my $not_empty = scalar $self->{'_conns'}->@*;

    for my $slot ($self->{'_conns'}->@*) {
        $not_empty-- if !$slot->{'is_busy'} && !$slot->{'tx'};
    }

    return $not_empty ? 1 : 0;
}


=head2 wait_for_next_response($self, $timeout = 0)

Waits for first received response or time-outed request in any slot.
Returns the C<Mojo::Transaction::HTTP> instance with result.

=over

=item $timeout

Period of time in seconds. Can be fractial with microsecond tollerance.
The response will be marked as time-outed after this time is out.

The default value is 0, which means that request will have been blocked until the response is received.

If all slots are empty, then C<undef> will be returned.

=back

=cut

sub wait_for_next_response ($self, $timeout = 0) {

    my $response;
    my $exp_ts = $timeout ? (time() + $timeout) : 0;

    while (1) {
        last if ($exp_ts && time() >= $exp_ts); # awaiting process is time-outed
        last if (($response = $self->next_response()) || !$self->not_empty());
        select(undef, undef, undef, 1E-6) if (!$response); # sleep 1 microsecond
    }

    return $response;
}

=head2 next_response ($self)

Returns an instance of C<Mojo::Transaction::HTTP> class.
If there is no response, it will return C<undef>.

=cut

sub next_response ($self) {
    return $self->_get_response_from_ready_slot() // $self->_get_response_from_slot();
}

sub _get_response_from_slot ($self) {

    my $tx;
    my $slot = first { $_->{'tx'} } $self->{'_conns'}->@*;

    if ($slot) {
        $tx = $slot->{'tx'};
        $self->_clear_slot($slot, $slot->{'reconnect_is_required'});
    }

    return $tx;
}

sub _get_response_from_ready_slot ($self) {

    my $tx;
    my %socks2slots = map { $_->{'sock_no'} => $_ }
                      grep { ! $_->{'tx'} && ! $_->{'reconnect_is_required'} && $_->{'is_busy'} }
                      $self->{'_conns'}->@*;

    if (%socks2slots) {

        local $!;
        my $read_handles = '';

        vec($read_handles, $_, 1) = 1 for keys %socks2slots;

        my $error_handles = $read_handles;
        my ($nfound, $timeleft) = select($read_handles, undef, $error_handles, 0);

        $self->_check_for_errors(\%socks2slots, $error_handles, $!);

        for my $sock_no (keys %socks2slots) {
            my $slot = $socks2slots{ $sock_no };
            if ( $nfound && vec($read_handles, $sock_no, 1) == 1 ) {
                $self->_try_to_read($slot);
                next if ! $slot->{'tx'};
                next if ! $slot->{'is_busy'};
                $tx = $slot->{'tx'};
            } else {
                if (!$slot->{'tx'} && ($slot->{'exp_ts'} && time() > $slot->{'exp_ts'})) {
                    $self->_mark_response_as_timeouted($slot);
                    $tx = $slot->{'tx'};
                }
            }

            if ($tx) {
                $self->_clear_slot($slot, 0);
                last;
            }
        }
    }

    return $tx;
}

=head2 refresh_connections ($self)

Closes connections in slots in the following cases:

    1. The slot was marked as timeouted
    2. The "inactivity_conn_ts" was set and the connection was expired
    3. There are some errors in socket (for example: Connection reset by peer, Broken pipe, etc)

=cut

sub refresh_connections ($self) {

    my $n = 0;
    my $now = time();
    my $keep_ts = $self->{'inactivity_conn_ts'} // 0;

    if (scalar $self->{'_conns'}->@*) {

        local $!;
        my $error_handles = '';
        my %socks2slots = map { $_->{'sock_no'} => $_ } $self->{'_conns'}->@*;

        vec($error_handles, $_, 1) = 1 for keys %socks2slots;
        select(undef, undef, $error_handles, 0);

        $self->_check_for_errors(\%socks2slots, $error_handles, $!); # broken connections will be marked as required to reconnect
    }

    for my $i (reverse( 0 .. $#{ $self->{'_conns'} })) {
        my $slot = $self->{'_conns'}->[$i];
        my $slot_exp_ts = ($slot->{'last_response_ts'} || $slot->{'connected_ts'}) + $keep_ts;
        my $is_outdated = $keep_ts && $slot_exp_ts <= $now;

        warn("Outdated\n") if $self->{'debug'} && $is_outdated;

        if ($slot->{'reconnect_is_required'} || $is_outdated) {
            warn("Going to reconnect\n") if $self->{'debug'};
            $self->_clear_slot($slot, 1);
            $self->_connect_slot($slot);
            $n++;
        }
    }

    return $n;
}

=head2 close_all ($self)

Closes all opened connections and resets all slots with requests.

=cut

sub close_all ($self) {
    $self->_clear_slot($_, 1) for $self->{'_conns'}->@*;
    $self->{'_conns'} = [];
    return;
}

=head2 DESTROY($class)

The class destructor.

Closes all opened sockets.

=cut

sub DESTROY ($self) {
    my $in_use = 0;
    while ( my $slot = shift($self->{'_conns'}->@*) ) {
        $in_use++ if ($slot->{'is_busy'});
        $slot->{'socket'}->close() if ($slot->{'socket'});
    }
    warn ref($self) ." object destroyed but still in use" if $in_use;
}

1;
__END__
