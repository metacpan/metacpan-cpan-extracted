package Starlight::Server;

use strict;
use warnings;

our $VERSION = '0.0400';

use Config;

use English '-no_match_vars';
use Errno ();
use File::Spec;
use Plack;
use Plack::HTTPParser qw( parse_http_request );
use IO::Socket::INET;
use HTTP::Date;
use HTTP::Status;
use List::Util qw(max sum);
use Plack::Util;
use Plack::TempBuffer;
use Socket qw(IPPROTO_TCP TCP_NODELAY);

use Try::Tiny;

BEGIN { try { require Time::HiRes; Time::HiRes->import(qw(time)) } }

use constant DEBUG            => $ENV{PERL_STARLIGHT_DEBUG};
use constant CHUNKSIZE        => 64 * 1024;
use constant MAX_REQUEST_SIZE => 131072;

use constant HAS_INET6        => eval { AF_INET6 && socket my $ipv6_socket, AF_INET6, SOCK_DGRAM, 0 };

use constant EINTR            => exists &Errno::EINTR ? &Errno::EINTR : -1;
use constant EAGAIN           => exists &Errno::EAGAIN ? &Errno::EAGAIN : -1;
use constant EWOULDBLOCK      => exists &Errno::EWOULDBLOCK ? &Errno::EWOULDBLOCK : -1;


my $null_io = do { open my $io, "<", \""; $io }; #"

sub new {
    my($class, %args) = @_;

    my $self = bless {
        host                 => $args{host},
        port                 => $args{port},
        socket               => $args{socket},
        listen               => $args{listen},
        listen_sock          => $args{listen_sock},
        timeout              => $args{timeout} || 300,
        keepalive_timeout    => $args{keepalive_timeout} || 2,
        max_keepalive_reqs   => $args{max_keepalive_reqs} || 1,
        server_software      => $args{server_software} || "Starlight/$VERSION ($^O)",
        server_ready         => $args{server_ready} || sub {},
        ssl                  => $args{ssl},
        ipv6                 => $args{ipv6},
        ssl_key_file         => $args{ssl_key_file},
        ssl_cert_file        => $args{ssl_cert_file},
        ssl_ca_file          => $args{ssl_ca_file},
        ssl_verify_mode      => $args{ssl_verify_mode},
        user                 => $args{user},
        group                => $args{group},
        umask                => $args{umask},
        daemonize            => $args{daemonize},
        pid                  => $args{pid},
        error_log            => $args{error_log},
        quiet                => $args{quiet} || $args{q} || $ENV{PLACK_QUIET},
        min_reqs_per_child   => (
            defined $args{min_reqs_per_child}
                ? $args{min_reqs_per_child} : undef,
        ),
        max_reqs_per_child   => (
            $args{max_reqs_per_child} || $args{max_requests} || 1000,
        ),
        spawn_interval       => $args{spawn_interval} || 0,
        err_respawn_interval => (
            defined $args{err_respawn_interval}
                ? $args{err_respawn_interval} : undef,
        ),
        main_process_delay   => $args{main_process_delay} || 0.1,
        is_multithread       => Plack::Util::FALSE,
        is_multiprocess      => Plack::Util::FALSE,
        _using_defer_accept  => undef,
        _unlink              => [],
        _sigint              => 'INT',
    }, $class;

    # Windows 7 and previous have bad SIGINT handling
    if ($^O eq 'MSWin32') {
        require Win32;
        my @v = Win32::GetOSVersion();
        if ($v[1]*1000 + $v[2] < 6_002) {
            $self->{_sigint} = 'TERM';
        }
    };

    if ($args{max_workers} && $args{max_workers} > 1) {
        die(
            "Forking in $class is deprecated. Falling back to the single process mode. ",
            "If you need more workers, use Starlight instead and run like `plackup -s Starlight`\n",
        );
    }

    $self;
}

sub run {
    my($self, $app) = @_;
    $self->setup_listener();
    $self->accept_loop($app);
}

sub prepare_socket_class {
    my($self, $args) = @_;

    if ($self->{socket} and ($self->{port} or $self->{ipv6})) {
        die "UNIX socket and ether IPv4 or IPv6 are not supported at the same time.\n";
    }

    if ($self->{ssl} and ($self->{socket} or $self->{ipv6})) {
        die "SSL and either UNIX socket or IPv6 are not supported at the same time.\n";
    }

    if ($self->{socket}) {
        try { require IO::Socket::UNIX; 1 }
            or die "UNIX socket suport requires IO::Socket::UNIX\n";
        $args->{Local} =~ s/^@/\0/; # abstract socket address
        return "IO::Socket::UNIX";
    } elsif ($self->{ssl}) {
        try { require IO::Socket::SSL; 1 }
            or die "SSL suport requires IO::Socket::SSL\n";
        $args->{SSL_key_file}       = $self->{ssl_key_file};
        $args->{SSL_cert_file}      = $self->{ssl_cert_file};
        $args->{SSL_ca_file}        = $self->{ssl_ca_file};
        $args->{SSL_client_ca_file} = $self->{ssl_ca_file};
        $args->{SSL_verify_mode}    = $self->{ssl_verify_mode};
        return "IO::Socket::SSL";
    } elsif ($self->{ipv6}) {
        try { require IO::Socket::IP; 1 }
            or die "IPv6 support requires IO::Socket::IP\n";
        $self->{host}      ||= '::';
        $args->{LocalAddr} ||= '::';
        return "IO::Socket::IP";
    }

    return "IO::Socket::INET";
}

sub setup_listener {
    my ($self) = @_;

    my %args = $self->{socket} ? (
        Listen    => Socket::SOMAXCONN,
        Local     => $self->{socket},
    ) : (
        Listen    => Socket::SOMAXCONN,
        LocalPort => $self->{port} || 5000,
        LocalAddr => $self->{host} || 0,
        Proto     => 'tcp',
        ReuseAddr => 1,
    );

    my $proto = $self->{ssl} ? 'https' : 'http';
    my $listening = $self->{socket} ? "socket $self->{socket}" : "port $self->{port}";

    my $class = $self->prepare_socket_class(\%args);
    $self->{listen_sock} ||= $class->new(%args)
        or die "failed to listen to $listening: $!\n";

    print STDERR "Starting $self->{server_software} $proto server listening at $listening\n"
        unless $self->{quiet};

    my $family = Socket::sockaddr_family(getsockname($self->{listen_sock}));
    $self->{_listen_sock_is_unix} = $family == AF_UNIX;
    $self->{_listen_sock_is_tcp}  = $family != AF_UNIX;

    # set defer accept
    if ($^O eq 'linux' && $self->{_listen_sock_is_tcp}) {
        setsockopt($self->{listen_sock}, IPPROTO_TCP, 9, 1)
            and $self->{_using_defer_accept} = 1;
    }

    if ($self->{_listen_sock_is_unix} && not $args{Local} =~ /^\0/) {
        $self->_add_to_unlink(File::Spec->rel2abs($args{Local}));
    }

    $self->{server_ready}->({ %$self, proto => $proto });
}

sub accept_loop {
    # TODO handle $max_reqs_per_child
    my($self, $app, $max_reqs_per_child) = @_;
    my $proc_req_count = 0;

    $self->{can_exit} = 1;
    my $is_keepalive = 0;
    my $sigint = $self->{_sigint};
    local $SIG{$sigint} = local $SIG{TERM} = sub {
        my ($sig) = @_;
        warn "*** SIG$sig received in process $$" if DEBUG;
        exit 0 if $self->{can_exit};
        $self->{term_received}++;
        exit 0
            if ($is_keepalive && $self->{can_exit}) || $self->{term_received} > 1;
        # warn "server termination delayed while handling current HTTP request";
    };

    local $SIG{PIPE} = 'IGNORE';

    while (! defined $max_reqs_per_child || $proc_req_count < $max_reqs_per_child) {
        if (my ($conn,$peer) = $self->{listen_sock}->accept) {
            $self->{_is_deferred_accept} = $self->{_using_defer_accept};
            $conn->blocking(0)
                or die "failed to set socket to nonblocking mode:$!\n";
            my ($peerport, $peerhost, $peeraddr) = (0, undef, undef);
            if ($self->{_listen_sock_is_tcp}) {
                if (try { TCP_NODELAY }) {
                    $conn->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1)
                        or die "setsockopt(TCP_NODELAY) failed:$!\n";
                }
                local $@;
                if (HAS_INET6 && Socket::sockaddr_family(getsockname($conn)) == AF_INET6) {
                    ($peerport, $peerhost) = Socket::unpack_sockaddr_in6($peer);
                    $peeraddr = Socket::inet_ntop(AF_INET6, $peerhost);
                } else {
                    ($peerport, $peerhost) = Socket::unpack_sockaddr_in($peer);
                    $peeraddr = Socket::inet_ntoa($peerhost);
                }
            }
            my $req_count = 0;
            my $pipelined_buf = '';
            while (1) {
                ++$req_count;
                ++$proc_req_count;
                my $env = {
                    SERVER_PORT => $self->{port} || 0,
                    SERVER_NAME => $self->{host} || '*',
                    SCRIPT_NAME => '',
                    REMOTE_ADDR => $peeraddr,
                    REMOTE_PORT => $peerport,
                    'psgi.version' => [ 1, 1 ],
                    'psgi.errors'  => *STDERR,
                    'psgi.url_scheme'   => $self->{ssl} ? 'https' : 'http',
                    'psgi.run_once'     => Plack::Util::FALSE,
                    'psgi.multithread'  => $self->{is_multithread},
                    'psgi.multiprocess' => $self->{is_multiprocess},
                    'psgi.streaming'    => Plack::Util::TRUE,
                    'psgi.nonblocking'  => Plack::Util::FALSE,
                    'psgix.input.buffered' => Plack::Util::TRUE,
                    'psgix.io'          => $conn,
                    'psgix.harakiri'    => Plack::Util::TRUE,
                };

                my $may_keepalive = $req_count < $self->{max_keepalive_reqs};
                if ($may_keepalive && $max_reqs_per_child && $proc_req_count >= $max_reqs_per_child) {
                    $may_keepalive = undef;
                }
                $may_keepalive = 1 if length $pipelined_buf;
                my $keepalive;
                ($keepalive, $pipelined_buf) = $self->handle_connection($env, $conn, $app,
                                                                        $may_keepalive, $req_count != 1, $pipelined_buf);

                if ($env->{'psgix.harakiri.commit'}) {
                    $conn->close;
                    return;
                }
                last unless $keepalive;
                # TODO add special cases for clients with broken keep-alive support, as well as disabling keep-alive for HTTP/1.0 proxies
            }
            $conn->close;
        }
    }
}

my $bad_response = [ 400, [ 'Content-Type' => 'text/plain', 'Connection' => 'close' ], [ 'Bad Request' ] ];
sub handle_connection {
    my($self, $env, $conn, $app, $use_keepalive, $is_keepalive, $prebuf) = @_;

    my $buf = '';
    my $pipelined_buf='';
    my $res = $bad_response;

    local $self->{can_exit} = (defined $prebuf) ? 0 : 1;
    while (1) {
        my $rlen;
        if ( $rlen = length $prebuf ) {
            $buf = $prebuf;
            undef $prebuf;
        }
        else {
            $rlen = $self->read_timeout(
                $conn, \$buf, MAX_REQUEST_SIZE - length($buf), length($buf),
                $is_keepalive ? $self->{keepalive_timeout} : $self->{timeout},
            ) or return;
        }
        $self->{can_exit} = 0;
        my $reqlen = parse_http_request($buf, $env);
        if ($reqlen >= 0) {
            # handle request
            my $protocol = $env->{SERVER_PROTOCOL};
            if ($use_keepalive) {
                if ( $protocol eq 'HTTP/1.1' ) {
                    if (my $c = $env->{HTTP_CONNECTION}) {
                        $use_keepalive = undef
                            if $c =~ /^\s*close\s*/i;
                    }
                }
                else {
                    if (my $c = $env->{HTTP_CONNECTION}) {
                        $use_keepalive = undef
                            unless $c =~ /^\s*keep-alive\s*/i;
                    } else {
                        $use_keepalive = undef;
                    }
                }
            }
            $buf = substr $buf, $reqlen;
            my $chunked = do { no warnings; lc delete $env->{HTTP_TRANSFER_ENCODING} eq 'chunked' };
            if (my $cl = $env->{CONTENT_LENGTH}) {
                my $buffer = Plack::TempBuffer->new($cl);
                while ($cl > 0) {
                    my $chunk;
                    if (length $buf) {
                        $chunk = $buf;
                        $buf = '';
                    } else {
                        $self->read_timeout(
                            $conn, \$chunk, $cl, 0, $self->{timeout})
                            or return;
                    }
                    $buffer->print($chunk);
                    $cl -= length $chunk;
                }
                $env->{'psgi.input'} = $buffer->rewind;
            }
            elsif ($chunked) {
                my $buffer = Plack::TempBuffer->new;
                my $chunk_buffer = '';
                my $length;
                DECHUNK: while(1) {
                    my $chunk;
                    if ( length $buf ) {
                        $chunk = $buf;
                        $buf = '';
                    }
                    else {
                        $self->read_timeout($conn, \$chunk, CHUNKSIZE, 0, $self->{timeout})
                            or return;
                    }

                    $chunk_buffer .= $chunk;
                    while ( $chunk_buffer =~ s/^(([0-9a-fA-F]+).*\015\012)// ) {
                        my $trailer   = $1;
                        my $chunk_len = hex $2;
                        if ($chunk_len == 0) {
                            last DECHUNK;
                        } elsif (length $chunk_buffer < $chunk_len + 2) {
                            $chunk_buffer = $trailer . $chunk_buffer;
                            last;
                        }
                        $buffer->print(substr $chunk_buffer, 0, $chunk_len, '');
                        $chunk_buffer =~ s/^\015\012//;
                        $length += $chunk_len;
                    }
                }
                $env->{CONTENT_LENGTH} = $length;
                $env->{'psgi.input'} = $buffer->rewind;
            } else {
                if ( $buf =~ m!^(?:GET|HEAD)! ) { #pipeline
                    $pipelined_buf = $buf;
                    $use_keepalive = 1; #force keepalive
                } # else clear buffer
                $env->{'psgi.input'} = $null_io;
            }

            if ( $env->{HTTP_EXPECT} ) {
                if ( $env->{HTTP_EXPECT} eq '100-continue' ) {
                    $self->write_all($conn, "HTTP/1.1 100 Continue\015\012\015\012")
                        or return;
                } else {
                    $res = [417,[ 'Content-Type' => 'text/plain', 'Connection' => 'close' ], [ 'Expectation Failed' ] ];
                    last;
                }
            }

            $res = Plack::Util::run_app $app, $env;
            last;
        }
        if ($reqlen == -2) {
            # request is incomplete, do nothing
        } elsif ($reqlen == -1) {
            # error, close conn
            last;
        }
    }

    if (ref $res eq 'ARRAY') {
        $self->_handle_response($env->{SERVER_PROTOCOL}, $res, $conn, \$use_keepalive);
    } elsif (ref $res eq 'CODE') {
        $res->(sub {
            $self->_handle_response($env->{SERVER_PROTOCOL}, $_[0], $conn, \$use_keepalive);
        });
    } else {
        die "Bad response $res\n";
    }
    if ($self->{term_received}) {
        exit 0;
    }

    return ($use_keepalive, $pipelined_buf);
}

sub _handle_response {
    my($self, $protocol, $res, $conn, $use_keepalive_r) = @_;
    my $status_code = $res->[0];
    my $headers = $res->[1];
    my $body = $res->[2];

    my @lines;
    my %send_headers;
    for (my $i = 0; $i < @$headers; $i += 2) {
        my $k = $headers->[$i];
        my $v = $headers->[$i + 1];
        $v = '' if not defined $v;
        my $lck = lc $k;
        if ($lck eq 'connection') {
            $$use_keepalive_r = undef
                if $$use_keepalive_r && lc $v ne 'keep-alive';
        } else {
            push @lines, "$k: $v\015\012";
            $send_headers{$lck} = $v;
        }
    }
    if (! exists $send_headers{server}) {
        unshift @lines, "Server: $self->{server_software}\015\012";
    }
    if (! exists $send_headers{date}) {
        unshift @lines, "Date: @{[HTTP::Date::time2str()]}\015\012";
    }

    # try to set content-length when keepalive can be used, or disable it
    my $use_chunked;
    if (defined $protocol and $protocol eq 'HTTP/1.1') {
        if (defined $send_headers{'content-length'}
                || defined $send_headers{'transfer-encoding'}) {
            # ok
        } elsif (!Plack::Util::status_with_no_entity_body($status_code)) {
            push @lines, "Transfer-Encoding: chunked\015\012";
            $use_chunked = 1;
        }
        push @lines, "Connection: close\015\012" unless $$use_keepalive_r;
    } else {
        # HTTP/1.0
        if ($$use_keepalive_r) {
            if (defined $send_headers{'content-length'}
                || defined $send_headers{'transfer-encoding'}) {
                # ok
            } elsif (! Plack::Util::status_with_no_entity_body($status_code)
                     && defined(my $cl = Plack::Util::content_length($body))) {
                push @lines, "Content-Length: $cl\015\012";
            } else {
                $$use_keepalive_r = undef
            }
        }
        push @lines, "Connection: keep-alive\015\012" if $$use_keepalive_r;
        push @lines, "Connection: close\015\012" if !$$use_keepalive_r; #fmm..
    }

    unshift @lines, "HTTP/1.1 $status_code @{[ HTTP::Status::status_message($status_code) || 'Unknown' ]}\015\012";
    push @lines, "\015\012";

    if (defined $body && ref $body eq 'ARRAY' && @$body == 1
            && defined $body->[0] && length $body->[0] < 8192) {
        # combine response header and small request body
        my $buf = $body->[0];
        if ($use_chunked ) {
            my $len = length $buf;
            $buf = sprintf("%x",$len) . "\015\012" . $buf . "\015\012" . '0' . "\015\012\015\012";
        }
        $self->write_all(
            $conn, join('', @lines, $buf), $self->{timeout},
        );
        return;
    }
    $self->write_all($conn, join('', @lines), $self->{timeout})
        or return;

    if (defined $body) {
        my $failed;
        my $completed;
        my $body_count = (ref $body eq 'ARRAY') ? $#{$body} + 1 : -1;
        Plack::Util::foreach(
            $body,
            sub {
                unless ($failed) {
                    my $buf = $_[0];
                    --$body_count;
                    if ( $use_chunked ) {
                        my $len = length $buf;
                        return unless $len;
                        $buf = sprintf("%x",$len) . "\015\012" . $buf . "\015\012";
                        if ( $body_count == 0 ) {
                            $buf .= '0' . "\015\012\015\012";
                            $completed = 1;
                        }
                    }
                    $self->write_all($conn, $buf, $self->{timeout})
                        or $failed = 1;
                }
            },
        );
        $self->write_all($conn, '0' . "\015\012\015\012", $self->{timeout}) if $use_chunked && !$completed;
    } else {
        return Plack::Util::inline_object
            write => sub {
                my $buf = $_[0];
                if ( $use_chunked ) {
                    my $len = length $buf;
                    return unless $len;
                    $buf = sprintf("%x",$len) . "\015\012" . $buf . "\015\012"
                }
                $self->write_all($conn, $buf, $self->{timeout})
            },
            close => sub {
                $self->write_all($conn, '0' . "\015\012\015\012", $self->{timeout}) if $use_chunked;
            };
    }
}

# returns value returned by $cb, or undef on timeout or network error
sub do_io {
    my ($self, $is_write, $sock, $buf, $len, $off, $timeout) = @_;
    my $ret;
    unless ($is_write || delete $self->{_is_deferred_accept}) {
        goto DO_SELECT;
    }
 DO_READWRITE:
    # try to do the IO
    if ($is_write) {
        $ret = syswrite $sock, $buf, $len, $off
            and return $ret;
    } else {
        $ret = sysread $sock, $$buf, $len, $off
            and return $ret;
    }
    unless ((! defined($ret)
                 && ($! == EINTR || $! == EAGAIN || $! == EWOULDBLOCK))) {
        return;
    }
    # wait for data
 DO_SELECT:
    while (1) {
        my ($rfd, $wfd);
        my $efd = '';
        vec($efd, fileno($sock), 1) = 1;
        if ($is_write) {
            ($rfd, $wfd) = ('', $efd);
        } else {
            ($rfd, $wfd) = ($efd, '');
        }
        my $start_at = time;
        my $nfound = select($rfd, $wfd, $efd, $timeout);
        $timeout -= (time - $start_at);
        last if $nfound;
        return if $timeout <= 0;
    }
    goto DO_READWRITE;
}

# returns (positive) number of bytes read, or undef if the socket is to be closed
sub read_timeout {
    my ($self, $sock, $buf, $len, $off, $timeout) = @_;
    $self->do_io(undef, $sock, $buf, $len, $off, $timeout);
}

# returns (positive) number of bytes written, or undef if the socket is to be closed
sub write_timeout {
    my ($self, $sock, $buf, $len, $off, $timeout) = @_;
    $self->do_io(1, $sock, $buf, $len, $off, $timeout);
}

# writes all data in buf and returns number of bytes written or undef if failed
sub write_all {
    my ($self, $sock, $buf, $timeout) = @_;
    my $off = 0;
    while (my $len = length($buf) - $off) {
        my $ret = $self->write_timeout($sock, $buf, $len, $off, $timeout)
            or return;
        $off += $ret;
    }
    return length $buf;
}

sub _add_to_unlink {
    my ($self, $filename) = @_;
    push @{$self->{_unlink}}, File::Spec->rel2abs($filename);
}

sub _daemonize {
    my $self = shift;

    if ($^O eq 'MSWin32') {
        foreach my $arg (qw(daemonize pid)) {
            die "$arg parameter is not supported on this platform ($^O)\n" if $self->{$arg};
        }
    }

    my ($pidfh, $pidfile);
    if ($self->{pid}) {
        $pidfile = File::Spec->rel2abs($self->{pid});
        if (defined *Fcntl::O_EXCL{CODE}) {
            sysopen $pidfh, $pidfile, Fcntl::O_WRONLY|Fcntl::O_CREAT|Fcntl::O_EXCL
                                               or die "Cannot open pid file: $self->{pid}: $!\n";
        } else {
            open $pidfh, '>', $pidfile         or die "Cannot open pid file: $self->{pid}: $!\n";
        }
    }

    if (defined $self->{error_log}) {
        open STDERR, '>>', $self->{error_log}  or die "Cannot open error log file: $self->{error_log}: $!\n";
    }

    if ($self->{daemonize}) {

        chdir File::Spec->rootdir              or die "Cannot chdir to root directory: $!\n";

        open my $devnull,  '+>', File::Spec->devnull or die "Cannot open null device: $!\n";

        open STDIN, '>&', $devnull             or die "Cannot dup null device: $!\n";
        open STDOUT, '>&', $devnull            or die "Cannot dup null device: $!\n";

        defined(my $pid = fork)                or die "Cannot fork: $!\n";
        if ($pid) {
            if ($self->{pid} and $pid) {
                print $pidfh "$pid\n"          or die "Cannot write pidfile $self->{pid}: $!\n";
                close $pidfh;
                open STDERR, '>&', $devnull    or die "Cannot dup null device: $!\n";
            }
            exit;
        }

        close $pidfh if $pidfh;

        if ($Config::Config{d_setsid}) {
            POSIX::setsid()                    or die "Cannot setsid: $!\n";
        }

        if (not defined $self->{error_log}) {
            open STDERR, '>&', $devnull        or die "Cannot dup null device: $!\n";
        }
    }

    if ($pidfile) {
        $self->_add_to_unlink($pidfile);
    }

    return;
}

sub _setup_privileges {
    my ($self) = @_;

    if (defined $self->{group}) {
        if (not $Config::Config{d_setegid}) {
            die "group parameter is not supported on this platform ($^O)\n";
        }
        if ($self->_get_gid($self->{group}) ne $EGID) {
            warn "*** setting group to \"$self->{group}\"" if DEBUG;
            $self->_set_gid($self->{group});
        }
    }

    if (defined $self->{user}) {
        if (not $Config::Config{d_seteuid}) {
            die "user parameter is not supported on this platform ($^O)\n";
        }
        if ($self->_get_uid($self->{user}) ne $EUID) {
            warn "*** setting user to \"$self->{user}\"" if DEBUG;
            $self->_set_uid($self->{user});
        }
    }

    if (defined $self->{umask}) {
        if (not $Config::Config{d_umask}) {
            die "umask parameter is not supported on this platform ($^O)\n";
        }
        warn "*** setting umask to \"$self->{umask}\"" if DEBUG;
        umask(oct($self->{umask}));
    }

    return;
}

# Taken from Net::Server::Daemonize
sub _get_uid {
    my ($self, $user) = @_;
    my $uid  = ($user =~ /^(\d+)$/) ? $1 : getpwnam($user);
    die "No such user \"$user\"\n" unless defined $uid;
    return $uid;
}

# Taken from Net::Server::Daemonize
sub _get_gid {
    my ($self, @groups) = @_;
    my @gid;

    foreach my $group ( split( /[, ]+/, join(" ",@groups) ) ){
        if( $group =~ /^\d+$/ ){
            push @gid, $group;
        }else{
            my $id = getgrnam($group);
            die "No such group \"$group\"\n" unless defined $id;
            push @gid, $id;
        }
    }

    die "No group found in arguments.\n" unless @gid;
    return join(" ",$gid[0],@gid);
}

# Taken from Net::Server::Daemonize
sub _set_uid {
    my ($self, $user) = @_;
    my $uid = $self->_get_uid($user);

    eval { POSIX::setuid($uid) };
    if ($UID != $uid || $EUID != $uid) { # check $> also (rt #21262)
        $UID = $EUID = $uid; # try again - needed by some 5.8.0 linux systems (rt #13450)
        if ($UID != $uid) {
            die "Couldn't become uid \"$uid\": $!\n";
        }
    }

    return 1;
}

# Taken from Net::Server::Daemonize
sub _set_gid {
    my ($self, @groups) = @_;
    my $gids = $self->_get_gid(@groups);
    my $gid  = (split /\s+/, $gids)[0];
    eval { $) = $gids }; # store all the gids - this is really sort of optional

    eval { POSIX::setgid($gid) };
    if (! grep {$gid == $_} split /\s+/, $GID) { # look for any valid id in the list
        die "Couldn't become gid \"$gid\": $!\n";
    }

    return 1;
}

sub _sleep {
    my ($self, $t) = @_;
    select undef, undef, undef, $t if $t;
}

sub _create_process {
    my ($self, $app) = @_;
    my $pid = fork;
    return warn "cannot fork: $!" unless defined $pid;

    if ($pid == 0) {
        warn "*** process $$ starting" if DEBUG;
        eval {
            $SIG{CHLD} = 'DEFAULT';
            $self->accept_loop($app, $self->_calc_reqs_per_child());
        };
        warn $@ if $@;
        warn "*** process $$ ending" if DEBUG;
        exit 0;
    } else {
        $self->{processes}->{$pid} = 1;
    }
}

sub _calc_reqs_per_child {
    my $self = shift;
    my $max = $self->{max_reqs_per_child};
    if (my $min = $self->{min_reqs_per_child}) {
        srand((rand() * 2 ** 30) ^ $$ ^ time);
        return $max - int(($max - $min + 1) * rand);
    } else {
        return $max;
    }
}

sub DESTROY {
    my ($self) = @_;
    while (my $f = shift @{$self->{_unlink}}) {
        unlink $f;
    }
}

1;
