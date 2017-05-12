package Mojolicious::Sessions::ThreeS::Storage::Memory;
$Mojolicious::Sessions::ThreeS::Storage::Memory::VERSION = '0.004';
use Mojo::Base qw/Mojolicious::Sessions::ThreeS::Storage/;

=head1 NAME

Mojolicious::Sessions::ThreeS::Storage::Memory - A simple in Memory storage for sessions. Nice for tests.

=cut

my $_SESSION_STORE = {};

=head2 list_sessions

Returns the ArrayRef of sessions for introspection.

=cut

sub list_sessions{
    my ($self) = @_;
    return [ values %$_SESSION_STORE ];
}

=head2 get_session

See L<Mojolicious::Sessions::ThreeS::Storage>

=cut

sub get_session{
    my ($self, $session_id) = @_;
    return $_SESSION_STORE->{$session_id};
}

=head2 store_session

See L<Mojolicious::Sessions::ThreeS::Storage>

=cut

sub store_session{
    my ($self, $session_id, $session) = @_;
    $_SESSION_STORE->{$session_id} = $session;
}

=head2 remove_session_id

See L<Mojolicious::Sessions::ThreeS::Storage>

=cut

sub remove_session_id{
    my ($self, $session_id) = @_;
    delete $_SESSION_STORE->{$session_id};
}

1;
