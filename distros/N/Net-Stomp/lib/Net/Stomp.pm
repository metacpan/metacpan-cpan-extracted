package Net::Stomp;
use strict;
use warnings;
use IO::Select;
use Net::Stomp::Frame;
use Carp qw(longmess);
use base 'Class::Accessor::Fast';
use Log::Any;
our $VERSION = '0.60';

__PACKAGE__->mk_accessors( qw(
    current_host failover hostname hosts port select serial session_id socket ssl
    ssl_options socket_options subscriptions _connect_headers bufsize
    reconnect_on_fork logger connect_delay
    reconnect_attempts initial_reconnect_attempts timeout receipt_timeout
) );

sub _logconfess {
    my ($self,@etc) = @_;
    my $m = longmess(@etc);
    $self->logger->fatal($m);
    die $m;
}
sub _logdie {
    my ($self,@etc) = @_;
    $self->logger->fatal(@etc);
    die "@etc";
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->bufsize(8192) unless $self->bufsize;
    $self->connect_delay(5) unless defined $self->connect_delay;
    $self->reconnect_on_fork(1) unless defined $self->reconnect_on_fork;
    $self->reconnect_attempts(0) unless defined $self->reconnect_attempts;
    $self->initial_reconnect_attempts(1) unless defined $self->initial_reconnect_attempts;
    $self->socket_options({}) unless defined $self->socket_options;

    $self->logger(Log::Any->get_logger) unless $self->logger;

    $self->{_framebuf} = "";

    # We are not subscribed to anything at the start
    $self->subscriptions( {} );

    $self->select( IO::Select->new );
    my @hosts = ();

    # failover://tcp://primary:61616
    # failover:(tcp://primary:61616,tcp://secondary:61616)?randomize=false

    if ($self->failover) {
        my ($uris, $opts) = $self->failover =~ m{^failover:(?://)? \(? (.*?) \)? (?: \? (.*?) ) ?$}ix;

        $self->_logconfess("Unable to parse failover uri: " . $self->failover)
            unless $uris;

        foreach my $host (split(/,/,$uris)) {
            $host =~ m{^\w+://([a-zA-Z0-9\-./]+):([0-9]+)$} || $self->_logconfess("Unable to parse failover component: '$host'");
            my ($hostname, $port) = ($1, $2);

            push(@hosts, {hostname => $hostname, port => $port});
        }
    } elsif ($self->hosts) {
        ## @hosts is used inside the while loop later to decide whether we have
        ## cycled through all setup hosts.
        @hosts = @{$self->hosts};
    }
    $self->hosts(\@hosts) if @hosts;

    $self->_get_connection_retrying(1);

    return $self;
}

sub _get_connection_retrying {
    my ($self,$initial) = @_;

    my $tries=0;
    while(not eval { $self->_get_connection; 1 }) {
        my $err = $@;$err =~ s{\n\z}{}sm;
        ++$tries;
        if($self->_should_stop_trying($initial,$tries)) {
            # We've cycled enough. Die now.
            $self->_logdie("Failed to connect: $err; giving up");
        }
        $self->logger->warn("Failed to connect: $err; retrying");
        sleep($self->connect_delay);
    }
}

sub _should_stop_trying {
    my ($self,$initial,$tries) = @_;

    my $max_tries = $initial
        ? $self->initial_reconnect_attempts
        : $self->reconnect_attempts;

    return unless $max_tries > 0; # 0 means forever

    if (defined $self->hosts) {
        $max_tries *= @{$self->hosts}; # try at least once per host
    }
    return $tries >= $max_tries;
}

my $socket_class;
sub _get_connection {
    my $self = shift;
    if (my $hosts = $self->hosts) {
        if (defined $self->current_host && ($self->current_host < $#{$hosts} ) ) {
            $self->current_host($self->current_host+1);
        } else {
            $self->current_host(0);
        }
        my $h = $hosts->[$self->current_host];
        $self->hostname($h->{hostname});
        $self->port($h->{port});
        $self->ssl($h->{ssl});
        $self->ssl_options($h->{ssl_options} || {});
    }
    my $socket = $self->_get_socket;
    $self->_logdie("Error connecting to " . $self->hostname . ':' . $self->port . ": $!")
        unless $socket;

    $self->select->remove($self->socket);

    $self->select->add($socket);
    $self->socket($socket);
    $self->{_pid} = $$;
}

sub _get_socket {
    my ($self) = @_;
    my $socket;

    my $timeout = $self->timeout;
    $timeout = 5 unless defined $timeout;

    my %sockopts = (
        Timeout  => $timeout,
        %{ $self->socket_options },
        PeerAddr => $self->hostname,
        PeerPort => $self->port,
        Proto    => 'tcp',
    );
    my $keep_alive = delete $sockopts{keep_alive};

    if ( $self->ssl ) {
        eval { require IO::Socket::SSL };
        $self->_logdie(
            "You should install the IO::Socket::SSL module for SSL support in Net::Stomp"
        ) if $@;
        %sockopts = ( %sockopts, %{ $self->ssl_options || {} } );
        $self->logger->trace('opening IO::Socket::SSL',\%sockopts);
        $socket = IO::Socket::SSL->new(%sockopts);
    } else {
        $socket_class ||= eval { require IO::Socket::IP; IO::Socket::IP->VERSION('0.20'); "IO::Socket::IP" }
            || do { require IO::Socket::INET; "IO::Socket::INET" };
        $self->logger->trace("opening $socket_class",\%sockopts);
        $socket = $socket_class->new(%sockopts);
        binmode($socket) if $socket;
    }
    if ($keep_alive) {
        require Socket;
        if (Socket->can('SO_KEEPALIVE')) {
            $socket->setsockopt(Socket::SOL_SOCKET(),Socket::SO_KEEPALIVE(),1);
        }
        else {
            $self->logger->warn(q{TCP keep-alive was requested, but the Socket module does not export the SO_KEEPALIVE constant, so we couldn't enable it});
        }
    }

    return $socket;
}

sub connect {
    my ( $self, $conf ) = @_;

    $self->logger->trace('connecting');
    my $frame = Net::Stomp::Frame->new(
        { command => 'CONNECT', headers => $conf } );
    $self->send_frame($frame);
    $frame = $self->receive_frame;

    if ($frame && $frame->command eq 'CONNECTED') {
        $self->logger->trace('connected');
        # Setting initial values for session id, as given from
        # the stomp server
        $self->session_id( $frame->headers->{session} );
        $self->_connect_headers( $conf );
    }
    else {
        $self->logger->warn('failed to connect',{ %{$frame} });
    }

    return $frame;
}

sub _close_socket {
    my ($self) = @_;
    return unless $self->socket;
    $self->logger->trace('closing socket');
    $self->socket->close;
    $self->select->remove($self->socket);
}

sub disconnect {
    my $self = shift;
    $self->logger->trace('disconnecting');
    my $frame = Net::Stomp::Frame->new( { command => 'DISCONNECT' } );
    $self->send_frame($frame);
    $self->_close_socket;
    return 1;
}

sub _reconnect {
    my $self = shift;
    $self->_close_socket;

    $self->logger->warn("reconnecting");
    $self->_get_connection_retrying(0);
    # Both ->connect and ->subscribe can call _reconnect. It *should*
    # work out fine in the end, worst scenario we send a few subscribe
    # frame more than once
    $self->connect( $self->_connect_headers );
    for my $sub(keys %{$self->subscriptions}) {
        $self->subscribe($self->subscriptions->{$sub});
    }
}

sub can_read {
    my ( $self, $conf ) = @_;

    # If there is any data left in the framebuffer that we haven't read, return
    # 'true'. But we don't want to spin endlessly, so only return true the
    # first time. (Anything touching the _framebuf should update this flag when
    # it does something.
    if ( $self->{_framebuf_changed} && length $self->{_framebuf} ) {
        $self->{_framebuf_changed} = 0;
        return 1;
    }

    $conf ||= {};
    my $timeout = exists $conf->{timeout} ? $conf->{timeout} : $self->timeout;
    return $self->select->can_read($timeout) || 0;
}

sub send {
    my ( $self, $conf ) = @_;
    $conf = { %$conf };
    $self->logger->trace('sending',$conf);
    my $body = $conf->{body};
    delete $conf->{body};
    my $frame = Net::Stomp::Frame->new(
        { command => 'SEND', headers => $conf, body => $body } );
    $self->send_frame($frame);
    return 1;
}

sub send_with_receipt {
    my ( $self, $conf ) = @_;
    $conf = { %$conf };

    # send the message
    my $receipt_id = $self->_get_next_transaction;
    $self->logger->debug('sending with receipt',{ receipt => $receipt_id });
    $conf->{receipt} = $receipt_id;
    my $receipt_timeout = exists $conf->{timeout} ? delete $conf->{timeout} : $self->receipt_timeout;
    $self->send($conf);

    $self->logger->trace('waiting for receipt',$conf);
    # check the receipt
    my $receipt_frame = $self->receive_frame({
        ( defined $receipt_timeout ?
              ( timeout => $receipt_timeout )
              : () ),
    });

    if (@_ > 2) {
        $_[2] = $receipt_frame;
    }

    if (   $receipt_frame
        && $receipt_frame->command eq 'RECEIPT'
        && $receipt_frame->headers->{'receipt-id'} eq $receipt_id )
    {
        $self->logger->debug('got good receipt',{ %{$receipt_frame} });
        return 1;
    } else {
        $self->logger->debug('got bad receipt',{ %{$receipt_frame || {} } });
        return 0;
    }
}

sub send_transactional {
    my ( $self, $conf ) = @_;

    $conf = { %$conf };
    # begin the transaction
    my $transaction_id = $self->_get_next_transaction;
    $self->logger->debug('starting transaction',{ transaction => $transaction_id });
    my $begin_frame
        = Net::Stomp::Frame->new(
        { command => 'BEGIN', headers => { transaction => $transaction_id } }
        );
    $self->send_frame($begin_frame);

    $conf->{transaction} = $transaction_id;
    my $receipt_frame;
    my $ret = $self->send_with_receipt($conf,$receipt_frame);

    if (@_ > 2) {
        $_[2] = $receipt_frame;
    }

    if ( $ret ) {
        # success, commit the transaction
        $self->logger->debug('committing transaction',{ transaction => $transaction_id });
        my $frame_commit = Net::Stomp::Frame->new(
            {   command => 'COMMIT',
                headers => { transaction => $transaction_id }
            }
        );
        $self->send_frame($frame_commit);
    } else {
        $self->logger->debug('rolling back transaction',{ transaction => $transaction_id });
        # some failure, abort transaction
        my $frame_abort = Net::Stomp::Frame->new(
            {   command => 'ABORT',
                headers => { transaction => $transaction_id }
            }
        );
        $self->send_frame($frame_abort);
    }
    return $ret;
}

sub _sub_key {
    my ($conf) = @_;

    if ($conf->{id}) { return "id-".$conf->{id} }
    return "dest-".$conf->{destination}
}

sub subscribe {
    my ( $self, $conf ) = @_;
    $self->logger->trace('subscribing',$conf);
    my $frame = Net::Stomp::Frame->new(
        { command => 'SUBSCRIBE', headers => $conf } );
    $self->send_frame($frame);
    my $subs = $self->subscriptions;
    $subs->{_sub_key($conf)} = $conf;
    return 1;
}

sub unsubscribe {
    my ( $self, $conf ) = @_;
    $self->logger->trace('unsubscribing',$conf);
    my $frame = Net::Stomp::Frame->new(
        { command => 'UNSUBSCRIBE', headers => $conf } );
    $self->send_frame($frame);
    my $subs = $self->subscriptions;
    delete $subs->{_sub_key($conf)};
    return 1;
}

sub ack {
    my ( $self, $conf ) = @_;
    $conf = { %$conf };
    my $id    = $conf->{frame}->headers->{'message-id'};
    delete $conf->{frame};
    $self->logger->trace('acking',{ 'message-id' => $id, %$conf });
    my $frame = Net::Stomp::Frame->new(
        { command => 'ACK', headers => { 'message-id' => $id, %$conf } } );
    $self->send_frame($frame);
    return 1;
}

sub nack {
    my ( $self, $conf ) = @_;
    $conf = { %$conf };
    my $id    = $conf->{frame}->headers->{'message-id'};
    $self->logger->trace('nacking',{ 'message-id' => $id, %$conf });
    delete $conf->{frame};
    my $frame = Net::Stomp::Frame->new(
        { command => 'NACK', headers => { 'message-id' => $id, %$conf } } );
    $self->send_frame($frame);
    return 1;
}

sub send_frame {
    my ( $self, $frame ) = @_;
    # see if we're connected before we try to syswrite()
    if (not $self->_connected) {
        $self->_reconnect;
        if (not $self->_connected) {
            $self->_logdie(q{wasn't connected; couldn't _reconnect()});
        }
    }
    # keep writing until we finish, or get an error
    my $to_write = my $frame_string = $frame->as_string;
    my $written;
    while (length($to_write)) {
        local $SIG{PIPE}='IGNORE'; # just in case writing to a closed
                                   # socket kills us
        $written = $self->socket->syswrite($to_write);
        last unless defined $written;
        substr($to_write,0,$written,'');
    }
    if (not defined $written) {
        $self->logger->warn("error writing frame <<$frame_string>>: $!");
    }
    unless (defined $written && $self->_connected) {
        $self->_reconnect;
        $self->send_frame($frame);
    }
    return;
}

sub _read_data {
    my ($self, $timeout) = @_;

    return unless $self->select->can_read($timeout);
    my $len = $self->socket->sysread($self->{_framebuf},
                                     $self->bufsize,
                                     length($self->{_framebuf} || ''));

    if (defined $len && $len>0) {
        $self->{_framebuf_changed} = 1;
    }
    else {
        if (!defined $len) {
            $self->logger->warn("error reading frame: $!");
        }
        # EOF or error detected - connection is gone. We have to reset
        # the framebuf in case we had a partial frame in there that
        # will never arrive.
        $self->_close_socket;
        $self->{_framebuf} = "";
        delete $self->{_command};
        delete $self->{_headers};
    }
    return $len;
}

sub _read_headers {
    my ($self) = @_;

    return 1 if $self->{_headers};
    if ($self->{_framebuf} =~ s/^\n*([^\n].*?)\n\n//s) {
        $self->{_framebuf_changed} = 1;
        my $raw_headers = $1;
        if ($raw_headers =~ s/^(.+)\n//) {
            $self->{_command} = $1;
        }
        foreach my $line (split(/\n/, $raw_headers)) {
            my ($key, $value) = split(/\s*:\s*/, $line, 2);
            $self->{_headers}{$key} = $value
                unless defined $self->{_headers}{$key};
        }
        return 1;
    }
    return 0;
}

sub _read_body {
    my ($self) = @_;

    my $h = $self->{_headers};
    if ($h->{'content-length'}) {
        if (length($self->{_framebuf}) > $h->{'content-length'}) {
            $self->{_framebuf_changed} = 1;
            my $body = substr($self->{_framebuf},
                              0,
                              $h->{'content-length'},
                              '' );

            # Trim the trailer off the frame.
            $self->{_framebuf} =~ s/^.*?\000\n*//s;
            return Net::Stomp::Frame->new({
                command => delete $self->{_command},
                headers => delete $self->{_headers},
                body => $body
            });
        }
    } elsif ($self->{_framebuf} =~ s/^(.*?)\000\n*//s) {
        # No content-length header.

        my $body = $1;
        $self->{_framebuf_changed} = 1;
        return Net::Stomp::Frame->new({
              command => delete $self->{_command},
              headers => delete $self->{_headers},
              body => $body });
    }

    return 0;
}

# this method is to stop the pointless warnings being thrown when trying to
# call peername() on a closed socket, i.e.
#   getpeername() on closed socket GEN125 at
#   /opt/xt/xt-perl/lib/5.12.3/x86_64-linux/IO/Socket.pm line 258.
#
# solution taken from:
# http://objectmix.com/perl/80545-warning-getpeername.html
sub _connected {
    my $self = shift;

    return if $self->{_pid} != $$ and $self->reconnect_on_fork;

    my $connected;
    {
        local $^W = 0;
        $connected = $self->socket->connected;
    }
    return $connected;
}

sub receive_frame {
    my ($self, $conf) = @_;

    $self->logger->trace('waiting to receive frame',$conf);
    my $timeout = exists $conf->{timeout} ? $conf->{timeout} :  $self->timeout;

    unless ($self->_connected) {
        $self->_reconnect;
    }

    my $done = 0;
    while ( not $done = $self->_read_headers ) {
        return undef unless $self->_read_data($timeout);
    }
    while ( not $done = $self->_read_body ) {
        return undef unless $self->_read_data($timeout);
    }

    return $done;
}

sub _get_next_transaction {
    my $self = shift;
    my $serial = $self->serial || 0;
    $serial++;
    $self->serial($serial);

    return ($self->session_id||'nosession') . '-' . $serial;
}

1;

__END__

=head1 NAME

Net::Stomp - A Streaming Text Orientated Messaging Protocol Client

=head1 SYNOPSIS

  # send a message to the queue 'foo'
  use Net::Stomp;
  my $stomp = Net::Stomp->new( { hostname => 'localhost', port => '61613' } );
  $stomp->connect( { login => 'hello', passcode => 'there' } );
  $stomp->send(
      { destination => '/queue/foo', body => 'test message' } );
  $stomp->disconnect;

  # subscribe to messages from the queue 'foo'
  use Net::Stomp;
  my $stomp = Net::Stomp->new( { hostname => 'localhost', port => '61613' } );
  $stomp->connect( { login => 'hello', passcode => 'there' } );
  $stomp->subscribe(
      {   destination             => '/queue/foo',
          'ack'                   => 'client',
          'activemq.prefetchSize' => 1
      }
  );
  while (1) {
    my $frame = $stomp->receive_frame;
    if (!defined $frame) {
      # maybe log connection problems
      next; # will reconnect automatically
    }
    warn $frame->body; # do something here
    $stomp->ack( { frame => $frame } );
  }
  $stomp->disconnect;

  # write your own frame
  my $frame = Net::Stomp::Frame->new(
       { command => $command, headers => $conf, body => $body } );
  $self->send_frame($frame);

  # connect with failover supporting similar URI to ActiveMQ
  $stomp = Net::Stomp->new({ failover => "failover://tcp://primary:61616" })
  # "?randomize=..." and other parameters are ignored currently
  $stomp = Net::Stomp->new({ failover => "failover:(tcp://primary:61616,tcp://secondary:61616)?randomize=false" })

  # Or in a more natural perl way
  $stomp = Net::Stomp->new({ hosts => [
    { hostname => 'primary', port => 61616 },
    { hostname => 'secondary', port => 61616 },
  ] });

=head1 DESCRIPTION

This module allows you to write a Stomp client. Stomp is the Streaming
Text Orientated Messaging Protocol (or the Protocol Briefly Known as
TTMP and Represented by the symbol :ttmp). It's a simple and easy to
implement protocol for working with Message Orientated Middleware from
any language. L<Net::Stomp> is useful for talking to Apache ActiveMQ,
an open source (Apache 2.0 licensed) Java Message Service 1.1 (JMS)
message broker packed with many enterprise features.

A Stomp frame consists of a command, a series of headers and a body -
see L<Net::Stomp::Frame> for more details.

For details on the protocol see L<https://stomp.github.io/>.

In long-lived processes, you can use a new C<Net::Stomp> object to
send each message, but it's more polite to the broker to keep a single
object around and re-use it for multiple messages; this reduce the
number of TCP connections that have to be established. C<Net::Stomp>
tries very hard to re-connect whenever something goes wrong.

=head2 ActiveMQ-specific suggestions

To enable the ActiveMQ Broker for Stomp add the following to the
activemq.xml configuration inside the <transportConnectors> section:

  <transportConnector name="stomp" uri="stomp://localhost:61613"/>

To enable the ActiveMQ Broker for Stomp and SSL add the following
inside the <transportConnectors> section:

  <transportConnector name="stomp+ssl" uri="stomp+ssl://localhost:61612"/>

For details on Stomp in ActiveMQ See L<http://activemq.apache.org/stomp.html>.

=head1 CONSTRUCTOR

=head2 C<new>

The constructor creates a new object. You must pass in a hostname and
a port or set a failover configuration:

  my $stomp = Net::Stomp->new( { hostname => 'localhost', port => '61613' } );

If you want to use SSL, make sure you have L<IO::Socket::SSL> and
pass in the SSL flag:

  my $stomp = Net::Stomp->new( {
    hostname => 'localhost',
    port     => '61612',
    ssl      => 1,
  } );

If you want to pass in L<IO::Socket::SSL> options:

  my $stomp = Net::Stomp->new( {
    hostname    => 'localhost',
    port        => '61612',
    ssl         => 1,
    ssl_options => { SSL_cipher_list => 'ALL:!EXPORT' },
  } );

=head3 Failover

There is some failover support in C<Net::Stomp>. You can specify
L<< /C<failover> >> in a similar manner to ActiveMQ
(L<http://activemq.apache.org/failover-transport-reference.html>) for
similarity with Java configs or using a more natural method to Perl of
passing in an array-of-hashrefs in the C<hosts> parameter.

When C<Net::Stomp> connects the first time, upon construction, it will
simply try each host in the list, stopping at the first one that
accepts the connection, dying if no connection attempt is
successful. You can set L<< /C<initial_reconnect_attempts> >> to 0 to
mean "keep looping forever", or to an integer value to mean "only go
through the list of hosts this many times" (the default value is
therefore 1).

When C<Net::Stomp> notices that the connection has been lost (inside
L<< /C<send_frame> >> or L<< /C<receive_frame> >>), it will try to
re-connect. In this case, the number of connection attempts will be
limited by L<< /C<reconnect_attempts> >>, which defaults to 0, meaning
"keep trying forever".

=head3 Reconnect on C<fork>

By default Net::Stomp will reconnect, using a different socket, if the
process C<fork>s. This avoids problems when parent & child write to
the socket at the same time. If, for whatever reason, you don't want
this to happen, set L<< /C<reconnect_on_fork> >> to C<0> (either as a
constructor parameter, or by calling the method).

=head1 ATTRIBUTES

These can be passed as constructor parameters, or used as read/write
accessors.

=head2 C<hostname>

If you want to connect to a single broker, you can specify its
hostname here. If you modify this value during the lifetime of the
object, the new value will be used for the subsequent reconnect
attempts.

=head2 C<port>

If you want to connect to a single broker, you can specify its
port here. If you modify this value during the lifetime of the
object, the new value will be used for the subsequent reconnect
attempts.

=head2 C<socket_options>

Optional hashref, it will be passed to the L<IO::Socket::IP>,
L<IO::Socket::SSL>, or L<IO::Socket::INET> constructor every time we
need to get a socket.

In addition to the various options supported by those classes, you can
set C<keep_alive> to a true value, which will enable TCP-level
keep-alive on the socket (see L<the TCP Keepalive
HOWTO|http://www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/> for
some information on that feature).

=head2 C<ssl>

Boolean, defaults to false, whether we should use SSL to talk to the
single broker. If you modify this value during the lifetime of the
object, the new value will be used for the subsequent reconnect
attempts.

=head2 C<ssl_options>

Options to pass to L<IO::Socket::SSL> when connecting via SSL to the
single broker. If you modify this value during the lifetime of the
object, the new value will be used for the subsequent reconnect
attempts.

=head2 C<failover>

Modifying this attribute after the object has been constructed has no
effect. Pass this as a constructor parameter only. Its value must be a
URL (as a string) in the form:

   failover://(tcp://$hostname1:$port1,tcp://$hostname2:$port,...)

This is equivalent to setting L<< /C<hosts> >> to:

  [ { hostname => $hostname1, port => $port1 },
    { hostname => $hostname2, port => $port2 } ]

=head2 C<hosts>

Arrayref of hashrefs, each having a C<hostname> key and a C<port> key,
and optionall C<ssl> and C<ssl_options>. Connections will be attempted
in order, looping around if necessary, depending on the values of L<<
/C<initial_reconnect_attempts> >> and L<< /C<reconnect_attempts> >>.

=head2 C<current_host>

If using multiple hosts, this is the index (inside the L<< /C<hosts>
>> array) of the one we're currently connected to.

=head2 C<logger>

Optional logger object, the default one is a L<Log::Any> logger. You
can pass in any object with the same API, or configure
L<Log::Any::Adapter> to route the messages to whatever logging system
you need.

=head2 C<reconnect_on_fork>

Boolean, defaults to true. Reconnect if a method is being invoked from
a different process than the one that created the object. Don't change
this unless you really know what you're doing.

=head2 C<initial_reconnect_attempts>

Integer, how many times to loop through the L<< /C<hosts> >> trying to
connect, before giving up and throwing an exception, during the
construction of the object. Defaults to 1. 0 means "keep trying
forever". Between each connection attempt there will be a sleep of L<<
/C<connect_delay> >> seconds.

=head2 C<reconnect_attempts>

Integer, how many times to loop through the L<< /C<hosts> >> trying to
connect, before giving up and throwing an exception, during L<<
/C<send_frame> >> or L<< /C<receive_frame> >>. Defaults to 0, meaning
"keep trying forever". Between each connection attempt there will be a
sleep of L<< /C<connect_delay> >> seconds.

=head2 C<connect_delay>

Integer, defaults to 5. How many seconds to sleep between connection
attempts to brokers.

=head2 C<timeout>

Integer, in seconds, defaults to C<undef>. The default timeout for
read operations. C<undef> means "wait forever".

=head2 C<receipt_timeout>

Integer, in seconds, defaults to C<undef>. The default timeout while
waiting for a receipt (in L<< /C<send_with_receipt> >> and L<<
/C<send_transactional> >>). If C<undef>, the global L<< /C<timeout> >>
is used.

=head1 METHODS

=head2 C<connect>

This starts the Stomp session with the Stomp server. You may pass in a
C<login> and C<passcode> options, plus whatever other headers you may
need (e.g. C<client-id>, C<host>).

  $stomp->connect( { login => 'hello', passcode => 'there' } );

Returns the frame that the server responded with (or C<undef> if the
connection was lost). If that frame's command is not C<CONNECTED>,
something went wrong.

=head2 C<send>

This sends a message to a queue or topic. You must pass in a
destination and a body (which must be a string of bytes). You can also
pass whatever other headers you may need (e.g. C<transaction>).

  $stomp->send( { destination => '/queue/foo', body => 'test message' } );

It's probably a good idea to pass a C<content-length> corresponding to
the byte length of the C<body>; this is necessary if the C<body>
contains a byte 0.

Always returns a true value. It automatically reconnects if writing to
the socket fails.

=head2 C<send_with_receipt>

This sends a message asking for a receipt, and returns false if the
receipt of the message is not acknowledged by the server:

  $stomp->send_with_receipt(
      { destination => '/queue/foo', body => 'test message' }
  ) or die "Couldn't send the message!";

If using ActiveMQ, you might also want to make the message persistent:

  $stomp->send_transactional(
      { destination => '/queue/foo', body => 'test message', persistent => 'true' }
  ) or die "Couldn't send the message!";

The actual frame sequence for a successful sending is:

  -> SEND
  <- RECEIPT

The actual frame sequence for a failed sending is:

  -> SEND
  <- anything but RECEIPT

If you are using this connection only to send (i.e. you've never
called L<< /C<subscribe> >>), the only thing that could be received
instead of a C<RECEIPT> is an C<ERROR> frame, but if you subscribed,
the broker may well send a C<MESSAGE> before sending the
C<RECEIPT>. B<DO NOT> use this method on a connection used for
receiving.

If you want to see the C<RECEIPT> or C<ERROR> frame, pass a scalar as
a second parameter to the method, and it will be set to the received
frame:

  my $success = $stomp->send_transactional(
      { destination => '/queue/foo', body => 'test message' },
      $received_frame,
  );
  if (not $success) { warn $received_frame->as_string }

You can specify a C<timeout> in the parametrs, just like for L<<
/C<received_frame> >>. This function will wait for that timeout, or
for L<< /C<receipt_timeout> >>, or for L<< /C<timeout> >>, whichever
is defined, or forever, if none is defined.

=head2 C<send_transactional>

This sends a message in transactional mode and returns false if the
receipt of the message is not acknowledged by the server:

  $stomp->send_transactional(
      { destination => '/queue/foo', body => 'test message' }
  ) or die "Couldn't send the message!";

If using ActiveMQ, you might also want to make the message persistent:

  $stomp->send_transactional(
      { destination => '/queue/foo', body => 'test message', persistent => 'true' }
  ) or die "Couldn't send the message!";

C<send_transactional> just wraps C<send_with_receipt> in a STOMP
transaction.

The actual frame sequence for a successful sending is:

  -> BEGIN
  -> SEND
  <- RECEIPT
  -> COMMIT

The actual frame sequence for a failed sending is:

  -> BEGIN
  -> SEND
  <- anything but RECEIPT
  -> ABORT

If you are using this connection only to send (i.e. you've never
called L<< /C<subscribe> >>), the only thing that could be received
instead of a C<RECEIPT> is an C<ERROR> frame, but if you subscribed,
the broker may well send a C<MESSAGE> before sending the
C<RECEIPT>. B<DO NOT> use this method on a connection used for
receiving.

If you want to see the C<RECEIPT> or C<ERROR> frame, pass a scalar as
a second parameter to the method, and it will be set to the received
frame:

  my $success = $stomp->send_transactional(
      { destination => '/queue/foo', body => 'test message' },
      $received_frame,
  );
  if (not $success) { warn $received_frame->as_string }

You can specify a C<timeout> in the parametrs, just like for L<<
/C<received_frame> >>. This function will wait for that timeout, or
for L<< /C<receipt_timeout> >>, or for L<< /C<timeout> >>, whichever
is defined, or forever, if none is defined.

=head2 C<disconnect>

This disconnects from the Stomp server:

  $stomp->disconnect;

If you call any other method after this, a new connection will be
established automatically (to the next failover host, if there's more
than one).

Always returns a true value.

=head2 C<subscribe>

This subscribes you to a queue or topic. You must pass in a
C<destination>.

Always returns a true value.

The acknowledge mode (header C<ack>) defaults to C<auto>, which means
that frames will be considered delivered after they have been sent to
a client. The other option is C<client>, which means that messages
will only be considered delivered after the client specifically
acknowledges them with an ACK frame (see L<< /C<ack> >>).

When C<Net::Stomp> reconnects after a failure, all subscriptions will
be re-instated, each with its own options.

Other options:

=over 4

=item C<selector>

Specifies a JMS Selector using SQL 92 syntax as specified in the JMS
1.1 specification. This allows a filter to be applied to each message
as part of the subscription.

=item C<id>

A unique identifier for this subscription. Very useful if you
subscribe to the same destination more than once (e.g. with different
selectors), so that messages arriving will have a C<subscription>
header with this value if they arrived because of this subscription.

=item C<activemq.dispatchAsync>

Should messages be dispatched synchronously or asynchronously from the
producer thread for non-durable topics in the broker. For fast
consumers set this to false. For slow consumers set it to true so that
dispatching will not block fast consumers.

=item C<activemq.exclusive>

Would I like to be an Exclusive Consumer on a queue.

=item C<activemq.maximumPendingMessageLimit>

For Slow Consumer Handling on non-durable topics by dropping old
messages - we can set a maximum pending limit which once a slow
consumer backs up to this high water mark we begin to discard old
messages.

=item C<activemq.noLocal>

Specifies whether or not locally sent messages should be ignored for
subscriptions. Set to true to filter out locally sent messages.

=item C<activemq.prefetchSize>

Specifies the maximum number of pending messages that will be
dispatched to the client. Once this maximum is reached no more
messages are dispatched until the client acknowledges a message. Set
to 1 for very fair distribution of messages across consumers where
processing messages can be slow.

=item C<activemq.priority>

Sets the priority of the consumer so that dispatching can be weighted
in priority order.

=item C<activemq.retroactive>

For non-durable topics do you wish this subscription to the
retroactive.

=item C<activemq.subscriptionName>

For durable topic subscriptions you must specify the same L<<
/C<client-id> >> on the connection and L<< /C<subscriptionName> >> on
the subscribe.

=back

  $stomp->subscribe(
      {   destination             => '/queue/foo',
          'ack'                   => 'client',
          'activemq.prefetchSize' => 1
      }
  );

=head2 C<unsubscribe>

This unsubscribes you to a queue or topic. You must pass in a
C<destination> or an C<id>:

  $stomp->unsubcribe({ destination => '/queue/foo' });

Always returns a true value.

=head2 C<receive_frame>

This blocks and returns you the next Stomp frame, or C<undef> if there
was a connection problem.

  my $frame = $stomp->receive_frame;
  warn $frame->body; # do something here

By default this method will block until a frame can be returned, or
for however long the L</timeout> attribue says. If you wish to wait
for a specified time pass a C<timeout> argument:

  # Wait half a second for a frame, else return undef
  $stomp->receive_frame({ timeout => 0.5 })

=head2 C<can_read>

This returns whether there is new data waiting to be read from the
STOMP server. Optionally takes a timeout in seconds:

  my $can_read = $stomp->can_read;
  my $can_read = $stomp->can_read({ timeout => '0.1' });

C<undef> says block until something can be read, C<0> says to poll and
return immediately. This method ignores the value of the L</timeout>
attribute.

=head2 C<ack>

This acknowledges that you have received and processed a frame I<and
all frames before it> (if you are using client acknowledgements):

  $stomp->ack( { frame => $frame } );

Always returns a true value.

=head2 C<nack>

This informs the remote end that you have been unable to process a
received frame (if you are using client acknowledgements)
(See individual stomp server documentation for information about
additional fields that can be passed to alter NACK behavior):

  $stomp->nack( { frame => $frame } );

Always returns a true value.

=head2 C<send_frame>

If this module does not provide enough help for sending frames, you
may construct your own frame and send it:

  # write your own frame
  my $frame = Net::Stomp::Frame->new(
       { command => $command, headers => $conf, body => $body } );
  $self->send_frame($frame);

This is the method used by all the other methods that send frames. It
will keep trying to send the frame as hard as it can, reconnecting if
the connection breaks (limited by L<< /C<reconnect_attempts> >>). If
no connection can be established, and L<< /C<reconnect_attempts> >> is
not 0, this method will C<die>.

Always returns an empty list.

=head1 SEE ALSO

L<Net::Stomp::Frame>.

=head1 SOURCE REPOSITORY

https://github.com/dakkar/Net-Stomp

=head1 AUTHORS

Leon Brocard <acme@astray.com>,
Thom May <thom.may@betfair.com>,
Michael S. Fischer <michael@dynamine.net>,
Ash Berlin <ash_github@firemirror.com>

=head1 CONTRIBUTORS

Paul Driver <frodwith@cpan.org>,
Andreas Faafeng <aff@cpan.org>,
Vigith Maurice <vigith@yahoo-inc.com>,
Stephen Fralich <sjf4@uw.edu>,
Squeeks <squeek@cpan.org>,
Chisel Wright <chisel@chizography.net>,
Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT

Copyright (C) 2006-9, Leon Brocard
Copyright (C) 2009, Thom May, Betfair.com
Copyright (C) 2010, Ash Berlin, Net-a-Porter.com
Copyright (C) 2010, Michael S. Fischer

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

