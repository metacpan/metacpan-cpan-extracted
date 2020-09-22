package Plasp::State::Application;

use Moo::Role;
use Types::Standard qw(InstanceOf);

has 'asp' => (
    is       => 'ro',
    isa      => InstanceOf ['Plasp'],
    required => 1,
    weak_ref => 1,
);

=head1 NAME

Plasp::State::Application - Role for $Application objects

=head1 SYNOPSIS

  package MyApp::Application;

  with 'Plasp::State::Application';

=head1 DESCRIPTION

Like the C<$Session> object, you may use the C<$Application> object to store
data across the entire life of the application. Every page in the ASP
application always has access to this object. So if you wanted to keep track of
how many visitors there where to the application during its lifetime, you might
have a line like this:

  $Application->{num_users}++

The Lock and Unlock methods are used to prevent simultaneous access to the
C<$Application> object.

=head1 METHODS

=over

=item $Application->Lock()

Not implemented. This is a no-op. This is unnecessary given the implementation

=cut

# TODO: will not implement
sub Lock {
    my ( $self ) = @_;
    $self->asp->log->warn( "\$Application->Lock has not been implemented!" );
    return;
}

=item $Application->UnLock()

Not implemented. This is a no-op. This is unnecessary given the implementation

=cut

# TODO: will not implement
sub UnLock {
    my ( $self ) = @_;
    $self->asp->log->warn( "\$Application->UnLock has not been implemented!" );
    return;
}

=item $Application->GetSession($sess_id)

This NON-PORTABLE API extension returns a user C<$Session> given a session id.
This allows one to easily write a session manager if session ids are stored in
C<$Application> during C<Session_OnStart>, with full access to these sessions
for administrative purposes.

Be careful not to expose full session ids over the net, as they could be used
by a hacker to impersonate another user. So when creating a session manager, for
example, you could create some other id to reference the SessionID internally,
which would allow you to control the sessions. This kind of application would
best be served under a secure web server.

=cut

sub GetSession {
    my ( $self, $sess_id ) = @_;

    # This _fetch_session method might not be implemented or possible
    return $self->asp->Session->_fetch_session( $sess_id );
}

=item $Application->SessionCount()

This NON-PORTABLE method returns the current number of active sessions in the
application, and is enabled by the C<SessionCount> configuration setting. This
method is not implemented as part of the original ASP object model, but is
implemented here because it is useful. In particular, when accessing databases
with license requirements, one can monitor usage effectively through accessing
this value.

=cut

# TODO: will not implement
sub SessionCount {
    my ( $self ) = @_;
    $self->asp->log->warn( "\$Application->SessionCount has not been implemented!" );
    return;
}

sub DEMOLISH {
    my ( $self ) = @_;

    # It's okay if it fails...
    eval { $self->asp->GlobalASA->Application_OnEnd };
}

1;

=back

=head1 SEE ALSO

=over

=item * L<Plasp::Session>

=item * L<Plasp::Request>

=item * L<Plasp::Response>

=item * L<Plasp::Server>

=back
