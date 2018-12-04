package Protocol::DBus::Client;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Protocol::DBus::Client

=head1 SYNOPSIS

    my $dbus = Protocol::DBus::Client::system();

    $dbus->do_authn();

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
    my $addr = Protocol::DBus::Path::system_message_bus();

    return _create_local($addr);
}

=head2 login_session()

Like C<system()> but for the login session’s message bus.

=cut

sub login_session {
    my $addr = Protocol::DBus::Path::login_session_message_bus() or do {
        die "Failed to identify login system message bus!";
    };

    return _create_local($addr);
}

sub _create_local {
    my ($addr) = @_;
    my $socket = Protocol::DBus::Connect::create_socket($addr);

    return __PACKAGE__->new(
        socket => $socket,
        authn_mechanism => 'EXTERNAL',
    );
}

#----------------------------------------------------------------------

=head1 METHODS

=head2 $done_yn = I<OBJ>->do_authn()

This returns truthy once the authn is complete and falsy until then.
In blocking I/O contexts the call will block until authn is complete.

=cut

sub do_authn {
    my ($self) = @_;

    if ($self->{'_authn'}->go()) {
        $self->{'_sent_hello'} ||= do {
            $self->send_call(
                path => '/org/freedesktop/DBus',
                interface => 'org.freedesktop.DBus',
                destination => 'org.freedesktop.DBus',
                member => 'Hello',
                on_return => sub {
                    $self->{'_connection_name'} = $_[0]->get_body()->[0];
                },
            );
        };

        return 1;
    }

    return 0;
}

#----------------------------------------------------------------------

=head2 $yn = I<OBJ>->authn_pending_send()

This indicates whether there is data queued up to send for the authn.
Only useful with non-blocking I/O.

=cut

sub authn_pending_send {
    my ($self) = @_;

    return $self->{'_authn'}->pending_send();
}

#----------------------------------------------------------------------

=head2 $yn = I<OBJ>->supports_unix_fd()

Boolean that indicates whether this client supports UNIX FD passing.

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
    if ( my $msg = $_[0]->SUPER::get_message() ) {

        no warnings 'redefine';
        *get_message = Protocol::DBus::Peer->can('get_message');

        return $_[0]->get_message();
    }

    return undef;
}

=head2 $name = I<OBJ>->get_connection_name()

Returns the name of the connection. This must only be called after at least
one message is received; if it is called before then, an exception is thrown.

=cut

sub get_connection_name {
    return $_[0]->{'_connection_name'} || die 'No connection name known yet!';
}

# undocumented
sub new {
    my ($class, %opts) = @_;

    my $authn = Protocol::DBus::Authn->new(
        socket => $opts{'socket'},
        mechanism => $opts{'authn_mechanism'},
    );

    my $self = bless { _socket => $opts{'socket'}, _authn => $authn }, $class;

    $self->_set_up_peer_io( $opts{'socket'} );

    return $self;
}

1;
