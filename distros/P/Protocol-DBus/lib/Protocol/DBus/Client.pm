package Protocol::DBus::Client;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Protocol::DBus::Client

=head1 SYNOPSIS

    my $dbus = Protocol::DBus::Client::system();

    $dbus->initialize();

=head1 DESCRIPTION

This is the end class for use in DBus client applications. It subclasses
L<Protocol::DBus::Peer>.

B<NOTE:> This module will automatically send a “Hello” message after
authentication completes. That message’s response will be processed
automatically. Because this is part of the protocol’s handshake
logic rather than something useful for callers, it is abstracted away from
the caller. It is neither necessary nor productive for callers to send a
“Hello” message.

=cut

use parent 'Protocol::DBus::Peer';

use Protocol::DBus::Authn;
use Protocol::DBus::Connect;
use Protocol::DBus::Path;

=head1 STATIC FUNCTIONS

=head2 system()

Creates an instance of this class that includes a connection to the
system’s message bus.

This does not do authentication; you’ll need to do that via the class’s
methods.

=cut

sub system {
    my @addrs = Protocol::DBus::Path::system_message_bus();

    return _create_local(@addrs);
}

=head2 login_session()

Like C<system()> but for the login session’s message bus.

=cut

sub login_session {
    my @addrs = Protocol::DBus::Path::login_session_message_bus();

    if (!@addrs) {
        die "Failed to identify login system message bus!";
    }

    return _create_local(@addrs);
}

sub _create_local {
    my ($addr) = @_;
    my ($socket, $bin_addr) = Protocol::DBus::Connect::create_socket($addr);

    return __PACKAGE__->new(
        socket => $socket,
        address => $bin_addr,
        human_address => $addr->to_string(),
        authn_mechanism => 'EXTERNAL',
    );
}

#----------------------------------------------------------------------

=head1 METHODS

=head2 $done_yn = I<OBJ>->initialize()

This returns truthy once the connection is ready to use and falsy until then.
In blocking I/O contexts the call will block.

Note that this automatically handles D-Bus’s initial C<Hello> message and
its response.

Previously this function was called C<do_authn()> and did not wait for
the C<Hello> message’s response. The older name is retained
as an alias for backward compatibility.

=cut

sub initialize {
    my ($self) = @_;

    if ($self->_connect() && $self->{'_authn'}->go()) {
        $self->{'_sent_hello'} ||= do {
            my $connection_name_sr = \$self->{'_connection_name'};

            $self->send_call(
                path => '/org/freedesktop/DBus',
                interface => 'org.freedesktop.DBus',
                destination => 'org.freedesktop.DBus',
                member => 'Hello',
            )->then( sub { $$connection_name_sr = $_[0]->get_body()->[0]; } );
        };

        if (!$self->{'_connection_name'}) {
          GET_MESSAGE: {
                if (my $msg = $self->SUPER::get_message()) {
                    return 1 if $self->{'_connection_name'};

                    push @{ $self->{'_pending_received_messages'} }, $msg;

                    redo GET_MESSAGE;
                }
            }
        }
    }

    return $self->{'_connection_name'} ? 1 : 0;
}

sub _connect {
    my ($self) = @_;

    local $!;

    if (!$self->{'_connected'}) {
        $self->{'_sent_connect'} ||= do {
            if ( connect $self->{'_socket'}, $self->{'_address'} ) {
                $self->{'_connected'} = 1;
            }
            elsif (!$!{'EINPROGRESS'}) {
                die "connect($self->{'_human_address'}): $!";
            }
        };
    }

    if (!$self->{'_connected'}) {

        # This non-blocking connect logic will ordinarily be unneeded
        # since even in non-blocking mode a UNIX socket connect() doesn’t
        # normally block. Where such a connect() *will* have to wait is
        # when the server has no more space for a new connection.

        my $mask = q<>;
        vec( $mask, fileno $self->{'_socket'}, 1 ) = 1;

        my $got = select undef, $mask, undef, 0;

        if ($got > 0) {
            my $errno = getsockopt( $self->{'_socket'}, Socket::SOL_SOCKET(), Socket::SO_ERROR() );
            if (!defined $errno) {
                die "getsockopt(SOL_SOCKET, SO_ERROR): $!";
            }

            local $! = unpack 'I', $errno;

            if (0 + $!) {
                die "connect($self->{'_human_address'}): $!";
            }
            else {
                $self->{'_connected'} = 1;
            }
        }
    }

    return $self->{'_connected'};
}

*do_authn = *initialize;

#----------------------------------------------------------------------

=head2 $yn = I<OBJ>->init_pending_send()

This indicates whether there is data queued up to send for the initialization.
Only useful with non-blocking I/O.

This function was previously called C<authn_pending_send()>; the former
name is retained for backward compatibility.

=cut

sub init_pending_send {
    my ($self) = @_;

    if ($self->{'_connection_name'}) {
        die "Don’t call this after initialize() is done!";
    }

    return 1 if $self->{'_sent_connect'} && !$self->{'_connected'};

    if ($self->{'_sent_hello'}) {
        return $self->pending_send();
    }

    return $self->{'_authn'}->pending_send();
}

*authn_pending_send = \*init_pending_send;

#----------------------------------------------------------------------

=head2 $yn = I<OBJ>->supports_unix_fd()

Boolean that indicates whether this client supports UNIX FD passing.

(See the main L<Protocol::DBus> documentation for details about
support for UNIX FD passing.)

=cut

sub supports_unix_fd {
    my ($self) = @_;

    return $self->{'_authn'}->negotiated_unix_fd();
}

#----------------------------------------------------------------------

=head2 $msg = I<OBJ>->get_message()

Same as in the base class, but for clients the initial “Hello” message and
its response are abstracted

=cut

sub get_message {
    my ($self) = @_;

    die "initialize() is not finished!" if !$self->{'_connection_name'};

    if ($self->{'_pending_received_messages'} && @{ $self->{'_pending_received_messages'} }) {
        return shift @{ $self->{'_pending_received_messages'} };
    }

    no warnings 'redefine';
    *get_message = Protocol::DBus::Peer->can('get_message');

    return $_[0]->get_message();
}

=head2 $name = I<OBJ>->get_unique_bus_name()

Returns the connection’s unique bus name.

C<get_connection_name()> is a historical alias for this method.

=cut

sub get_unique_bus_name {
    return $_[0]->{'_connection_name'} || die 'No connection name known yet!';
}

BEGIN {
    *get_connection_name = *get_unique_bus_name;
}

# undocumented for now
sub new {
    my ($class, %opts) = @_;

    my $authn = Protocol::DBus::Authn->new(
        socket => $opts{'socket'},
        mechanism => $opts{'authn_mechanism'},
    );

    my $self = $class->SUPER::new( $opts{'socket'} );

    $self->{'_authn'} = $authn;

    if (my $address = $opts{'address'}) {
        $self->{'_address'} = $address;
        $self->{'_human_address'} = $opts{'human_address'};
    }
    else {
        $self->{'_connected'} = 1;
    }

    return $self;
}

#sub DESTROY {
#    print "DESTROYED: [$_[0]]\n";
#}

1;
