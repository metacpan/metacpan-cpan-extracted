package POE::Component::IRC::Plugin::Proxy;
BEGIN {
  $POE::Component::IRC::Plugin::Proxy::AUTHORITY = 'cpan:HINRIK';
}
$POE::Component::IRC::Plugin::Proxy::VERSION = '6.88';
use strict;
use warnings FATAL => 'all';
use Carp;
use Socket qw(inet_ntoa);
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::IRCD
           Filter::Line Filter::Stackable);
use POE::Component::IRC::Plugin qw(PCI_EAT_NONE);

sub new {
    my ($package) = shift;
    croak "$package requires an even number of arguments" if @_ & 1;
    my %args = @_;
    $args{ lc $_ } = delete $args{ $_ } for keys %args;
    return bless \%args, $package;
}

sub PCI_register {
    my ($self, $irc) = splice @_, 0, 2;

    if (!$irc->isa('POE::Component::IRC::State')) {
        die __PACKAGE__ . ' requires PoCo::IRC::State or a subclass thereof';
    }

    $irc->raw_events(1);
    $self->{irc} = $irc;
    $irc->plugin_register(
        $self,
        'SERVER',
        qw(
            connected
            disconnected
            001
            error
            socketerr
            raw
        )
    );

    POE::Session->create(
        object_states => [
            $self => [qw(
                _client_error
                _client_flush
                _client_input
                _listener_accept
                _listener_failed
                _start
                _shutdown
                _spawn_listener
            )],
        ],
    );

    return 1;
}

sub PCI_unregister {
    my ($self, $irc) = splice @_, 0, 2;
    $poe_kernel->post($self->{SESSION_ID} => _shutdown => delete $self->{irc});
    $poe_kernel->refcount_decrement($self->{SESSION_ID}, __PACKAGE__);
    return 1;
}

sub S_connected {
    my ($self, $irc) = splice @_, 0, 2;
    $self->{stashed} = 0;
    $self->{stash} = [ ];
    return PCI_EAT_NONE;
}

sub S_001 {
    my ($self, $irc) = splice @_, 0, 2;
    $poe_kernel->post($self->{SESSION_ID} => '_shutdown');
    $poe_kernel->post($self->{SESSION_ID} => '_spawn_listener');
    return PCI_EAT_NONE;
}

sub S_disconnected {
    my ($self, $irc) = splice @_, 0, 2;
    $poe_kernel->post($self->{SESSION_ID} => '_shutdown');
    return PCI_EAT_NONE;
}

sub S_socketerr {
    my ($self, $irc) = splice @_, 0, 2;
    $poe_kernel->post($self->{SESSION_ID} => '_shutdown');
    return PCI_EAT_NONE;
}

sub S_error {
    my ($self, $irc) = splice @_, 0, 2;
    $poe_kernel->post($self->{SESSION_ID} => '_shutdown');
    return PCI_EAT_NONE;
}

sub S_raw {
    my ($self, $irc) = splice @_, 0, 2;
    my $line  = ${ $_[0] };
    my $input = $self->{irc_filter}->get( [$line] )->[0];

    return PCI_EAT_NONE if $input->{command} eq 'PING';

    for my $wheel_id (keys %{ $self->{wheels} }) {
        $self->_send_to_client($wheel_id, $line);
    }

    return PCI_EAT_NONE if $self->{stashed};

    if ($input->{command} =~ /^(?:NOTICE|\d{3})$/) {
        push @{ $self->{stash} }, $line;
    }

    $self->{stashed} = 1 if $input->{command} =~ /^(?:376|422)$/;
    return PCI_EAT_NONE;
}

sub _send_to_client {
    my ($self, $wheel_id, $line) = splice @_, 0, 3;
    return if !defined $self->{wheels}->{ $wheel_id }->{wheel};
    return if !$self->{wheels}->{ $wheel_id }->{reg};

    $self->{wheels}->{ $wheel_id }->{wheel}->put($line);
    return;
}

sub _close_wheel {
    my ($self, $wheel_id) = splice @_, 0, 2;
    return if !defined $self->{wheels}->{ $wheel_id };

    delete $self->{wheels}->{ $wheel_id };
    $self->{irc}->send_event(irc_proxy_close => $wheel_id);
    return;
}

sub _start {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    $self->{SESSION_ID} = $_[SESSION]->ID();
    $kernel->refcount_increment($self->{SESSION_ID}, __PACKAGE__);

    $self->{irc_filter} = POE::Filter::IRCD->new();
    $self->{ircd_filter} = POE::Filter::Stackable->new(
        Filters => [
            POE::Filter::Line->new(),
            $self->{irc_filter},
        ],
    );

    if ($self->{irc}->connected()) {
        $kernel->yield('_spawn_listener');
    }
    return;
}

sub _spawn_listener {
    my $self = $_[OBJECT];

    $self->{listener} = POE::Wheel::SocketFactory->new(
        BindAddress  => $self->{bindaddress} || 'localhost',
        BindPort     => $self->{bindport} || 0,
        SuccessEvent => '_listener_accept',
        FailureEvent => '_listener_failed',
        Reuse        => 'yes',
    );

    if (!$self->{listener}) {
        my $irc = $self->{irc};
        $irc->plugin_del($self);
        return;
    }

    $self->{irc}->send_event(irc_proxy_up => $self->{listener}->getsockname());
    return;
}

sub _listener_accept {
    my ($self, $socket, $peeradr, $peerport) = @_[OBJECT, ARG0 .. ARG2];

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle       => $socket,
        InputFilter  => $self->{ircd_filter},
        OutputFilter => POE::Filter::Line->new(),
        InputEvent   => '_client_input',
        ErrorEvent   => '_client_error',
        FlushedEvent => '_client_flush',
    );

    if ($wheel) {
        my $wheel_id = $wheel->ID();
        $self->{wheels}->{ $wheel_id }->{wheel} = $wheel;
        $self->{wheels}->{ $wheel_id }->{port} = $peerport;
        $self->{wheels}->{ $wheel_id }->{peer} = inet_ntoa( $peeradr );
        $self->{wheels}->{ $wheel_id }->{start} = time;
        $self->{wheels}->{ $wheel_id }->{reg} = 0;
        $self->{wheels}->{ $wheel_id }->{register} = 0;
        $self->{irc}->send_event(irc_proxy_connect => $wheel_id);
    }
    else {
        $self->{irc}->send_event(irc_proxy_rw_fail => inet_ntoa( $peeradr ) => $peerport);
    }

    return;
}

sub _listener_failed {
    delete ( $_[OBJECT]->{listener} );
    return;
}

sub _client_flush {
    my ($self, $wheel_id) = @_[OBJECT, ARG0];

    return if !defined $self->{wheels}->{ $wheel_id } || !$self->{wheels}->{ $wheel_id }->{quiting};
    $self->_close_wheel($wheel_id);
    return;
}

# this code needs refactoring
## no critic (Subroutines::ProhibitExcessComplexity)
sub _client_input {
    my ($self, $input, $wheel_id) = @_[OBJECT, ARG0, ARG1];
    my ($irc, $wheels) = ($self->{irc}, $self->{wheels});

    return if $wheels->{$wheel_id}{quiting};

    if ($input->{command} eq 'QUIT') {
        $self->_close_wheel($wheel_id);
        return;
    }

    if ($input->{command} eq 'PASS' && $wheels->{$wheel_id}{reg} < 2) {
        $wheels->{$wheel_id}{pass} = $input->{params}[0];
    }

    if ($input->{command} eq 'NICK' && $wheels->{$wheel_id}{reg} < 2) {
        $wheels->{$wheel_id}{nick} = $input->{params}[0];
        $wheels->{$wheel_id}{register}++;
    }

    if ($input->{command} eq 'USER' && $wheels->{$wheel_id}{reg} < 2) {
        $wheels->{$wheel_id}{user} = $input->{params}[0];
        $wheels->{$wheel_id}{register}++;
    }

    if (!$wheels->{$wheel_id}{reg} && $wheels->{$wheel_id}{register} >= 2) {
        my $password = delete $wheels->{$wheel_id}{pass};
        $wheels->{$wheel_id}{reg} = 1;

        if (!$password || $password ne $self->{password}) {
            $self->_send_to_client($wheel_id,
                'ERROR :Closing Link: * ['
                . ($wheels->{$wheel_id}{user} || 'unknown')
                . '@' . $wheels->{$wheel_id}{peer}
                . '] (Unauthorised connection)'
            );
            $wheels->{$wheel_id}{quiting}++;
            return;
        }

        my $nickname = $irc->nick_name();
        my $fullnick = $irc->nick_long_form($nickname);
        if ($nickname ne $wheels->{$wheel_id}{nick}) {
            $self->_send_to_client($wheel_id, "$wheels->{$wheel_id}{nick} NICK :$nickname");
        }

        for my $line (@{ $self->{stash} }) {
            $self->_send_to_client($wheel_id, $line);
        }

        for my $channel ($irc->nick_channels($nickname)) {
            $self->_send_to_client($wheel_id, ":$fullnick JOIN $channel");
            $irc->yield(names => $channel);
            $irc->yield(topic => $channel);
        }

        $irc->send_event(irc_proxy_authed => $wheel_id);
        return;
    }

    return if !$wheels->{$wheel_id}{reg};

    if ($input->{command} =~ /^(?:NICK|USER|PASS)$/) {
        return;
    }

    if ($input->{command} eq 'PING') {
        $self->_send_to_client($wheel_id, "PONG $input->{params}[0]");
        return;
    }

    if ($input->{command} eq 'PONG' and $input->{params}[0] =~ /^[0-9]+$/) {
        $wheels->{$wheel_id}{lag} = time() - $input->{params}[0];
        return;
    }

    $irc->yield(quote => $input->{raw_line});
    return;
}

sub _client_error {
    my ($self, $wheel_id) = @_[OBJECT, ARG3];

    $self->_close_wheel($wheel_id);
    return;
}

sub _shutdown {
    my $self = $_[OBJECT];
    my $irc = $self->{irc} || $_[ARG0];

    my $mysockaddr = $self->getsockname();
    delete $self->{listener};

    for my $wheel_id ( $self->list_wheels() ) {
        $self->_close_wheel( $wheel_id );
    }
    delete $self->{wheels};
    $irc->send_event(irc_proxy_down => $mysockaddr);

    return;
}

sub getsockname {
    my ($self) = @_;
    return if !$self->{listener};
    return $self->{listener}->getsockname();
}

sub list_wheels {
    my ($self) = @_;
    return keys %{ $self->{wheels} };
}

sub wheel_info {
    my ($self, $wheel_id) = @_;
    return if !defined $self->{wheels}->{ $wheel_id };
    return $self->{wheels}->{ $wheel_id }->{start} if !wantarray;
    return map { $self->{wheels}->{ $wheel_id }->{$_} } qw(peer port start lag);
}

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::Proxy - A PoCo-IRC plugin that provides a
lightweight IRC proxy/bouncer

=head1 SYNOPSIS

 use strict;
 use warnings;
 use POE qw(Component::IRC::State Component::IRC::Plugin::Proxy Component::IRC::Plugin::Connector);

 my $irc = POE::Component::IRC::State->spawn();

 POE::Session->create(
     package_states => [
         main => [ qw(_start) ],
     ],
     heap => { irc => $irc },
 );

 $poe_kernel->run();

 sub _start {
     my ($kernel, $heap) = @_[KERNEL, HEAP];
     $heap->{irc}->yield( register => 'all' );
     $heap->{proxy} = POE::Component::IRC::Plugin::Proxy->new( bindport => 6969, password => "m00m00" );
     $heap->{irc}->plugin_add( 'Connector' => POE::Component::IRC::Plugin::Connector->new() );
     $heap->{irc}->plugin_add( 'Proxy' => $heap->{proxy} );
     $heap->{irc}->yield ( connect => { Nick => 'testbot', Server => 'someserver.com' } );
     return;
 }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::Proxy is a L<POE::Component::IRC>
plugin that provides lightweight IRC proxy/bouncer server to your
L<POE::Component::IRC> bots. It enables multiple IRC
clients to be hidden behind a single IRC client-server connection.

Spawn a L<POE::Component::IRC::State> session and add in a
POE::Component::IRC::Plugin::Proxy plugin object, specifying a bindport and a
password the connecting IRC clients have to use. When the component is
connected to an IRC network a listening port is opened by the plugin for
multiple IRC clients to connect.

Neat, huh? >;o)

This plugin will activate L<POE::Component::IRC>'s raw
events (L<C<irc_raw>|POE::Component::IRC/irc_raw>) by calling
C<< $irc->raw_events(1) >>.

This plugin requires the IRC component to be
L<POE::Component::IRC::State> or a subclass thereof.

=head1 METHODS

=head2 C<new>

Takes a number of arguments:

B<'password'>, the password to require from connecting clients;

B<'bindaddress'>, a local address to bind the listener to, default is 'localhost';

B<'bindport'>, what port to bind to, default is 0, ie. randomly allocated by OS;

Returns an object suitable for passing to
L<POE::Component::IRC>'s C<plugin_add> method.

=head2 C<getsockname>

Takes no arguments. Accesses the listeners C<getsockname> method. See
L<POE::Wheel::SocketFactory> for details of the
return value;

=head2 C<list_wheels>

Takes no arguments. Returns a list of wheel ids of the current connected clients.

=head2 C<wheel_info>

Takes one parameter, a wheel ID to query. Returns undef if an invalid wheel id
is passed. In a scalar context returns the time that the client connected in
unix time. In a list context returns a list consisting of the peer address,
port, tthe connect time and the lag in seconds for that connection.

=head1 OUTPUT EVENTS

The plugin emits the following L<POE::Component::IRC>
events:

=head2 C<irc_proxy_up>

Emitted when the listener is successfully started. C<ARG0> is the result of the
listener C<getsockname>.

=head2 C<irc_proxy_connect>

Emitted when a client connects to the listener. C<ARG0> is the wheel ID of the
client.

=head2 C<irc_proxy_rw_fail>

Emitted when the L<POE::Wheel::ReadWrite> fails on a
connection. C<ARG0> is the wheel ID of the client.

=head2 C<irc_proxy_authed>

Emitted when a connecting client successfully negotiates an IRC session with
the plugin. C<ARG0> is the wheel ID of the client.

=head2 C<irc_proxy_close>

Emitted when a connected client disconnects. C<ARG0> is the wheel ID of the
client.

=head2 C<irc_proxy_down>

Emitted when the listener is successfully shutdown. C<ARG0> is the result of the
listener C<getsockname>.

=head1 QUIRKS

Connecting IRC clients will not be able to change nickname. This is a feature.

=head1 AUTHOR

Chris 'BinGOs' Williams

=head1 SEE ALSO

L<POE::Component::IRC>

L<POE::Component::IRC::State>

=cut
