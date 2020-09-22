package Plasp::Session;

use Moo;
use Types::Standard qw(HashRef);
use namespace::clean;

with 'Plasp::State::Session';

=head1 NAME

Plasp::Session - Default class for $Session objects

=head1 SYNOPSIS

  package MyApp;

  use Moo;

  sub BUILD {
    my ( $self, @args ) = @_;

    $self->Session( bless $env->{'psgix.session'}, 'Plasp::Session' );
  };

=head1 DESCRIPTION

The C<$Session> object keeps track of user and web client state, in a persistent
manner, making it relatively easy to develop web applications.

A Plasp::Session composes the L<Plasp::State::Session> role, which implements
the API a C<$Session> object. Please refer to L<Plasp::State::Session> for the
C<$Session> API.

Plasp::Session uses the C<< $env->{'psgix.session'} >> hash provided by Plack.
Therefore, further configuration is handled as middleware, in the C<app.psgi>
file.

There are thus two options to implementing your own Plasp Session class. You
can use this default class, which would rely on L<Plack::Middleware::Session>
interface to State and Store. You can then write State and Store classes to
define the methods required or you can use a third-party session middleware.

Alternatively, you may write a class replacing Plasp::Session and compose of
the L<Plasp::State::Session> role to implement the API for $Session.
Overload the methods as necessary. Then configure the application with your
custom Session class.

  MyApp->config(
    SessionClass  => 'MyApp::Session',
    SessionConfig => {
      myapp_session_config_1 => 'foo',
      myapp_session_config_2 => 'bar',
    },
  );

Since Plasp is designed to be a Plack app and utilizes the PSGI 1.1
specification, the former method is recommended. However, you can do both and
use a custom class that better fits your needs or is more integrated with
Plack::Middleware::Session.

=cut

sub BUILD {
    my $self = shift;
    my $env  = $self->asp->req->env;

    # Copy all the keys from the fetched session object
    my $session = $env->{'psgix.session'};
    $self->{$_} = $session->{$_} for ( keys %$session );

    # If SessionID key not found then this is a new session
    unless ( keys %$session ) {
        $self->SessionID( $env->{'psgix.session.options'}{id} || '' );
        $self->_set_is_new;
    }

    # Overwrite Plack session with self
    $env->{'psgix.session'} = $self;

    return;
}

around 'Abandon' => sub {
    my ( $orig, $class, @args ) = @_;

    # Tell Plack::Session to delete the session object
    $class->asp->req->env->{'psgix.session.options'}{expire} = 1;

    return $class->$orig( @args );
};

# Unfortunately, this class cannot fetch a desired session by session key
# because the store is abstracted out by PSGI. However, if the request
# session key is the same as the current session, then we can return it.
sub _fetch_session {
    my ( $self, $session_id ) = @_;
    my $env = $self->asp->req->env;

    if ( $session_id eq $env->{'psgix.session.options'}{id} ) {
        my %session = %{ $env->{'psgix.session'} };

        # Remove internal values (that shouldn't get stored)
        delete $session{asp};
        delete $session{_is_new};

        return \%session;
    }
}

1;

=head1 SEE ALSO

=over

=item * L<Plasp::State>

=item * L<Plasp::State::Session>

=item * L<Plasp::State::Application>

=item * L<Plasp::Application>

=back
