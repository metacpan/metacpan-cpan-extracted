package Net::ZooTool::User;

use Moose;
with 'Net::ZooTool::Utils';

use Carp;

use namespace::autoclean;

our $VERSION = '0.003';

has auth => (
    isa => 'Net::ZooTool::Auth',
    is  => 'ro',
);

sub BUILD {
    my $self = shift;
}

before [ 'items', 'info', 'validate', 'friends', 'followers', 'profiles' ] => sub {
    my ( $self, $args ) = @_;

    croak
        "You are trying to use a feature that requires authentication without providing username and password"
        if $args->{login} and ( !$self->auth->user or !$self->auth->password );

    # Appends apikey to all registered methods
    $args->{apikey} = $self->auth->apikey;
};

=head2
    Get the latest items...
=cut
sub items {
    my ( $self, $args ) = @_;

    my $data = _fetch('/users/items/' . _hash_to_query_string($args), $self->auth );
    return $data;
}

=head2
    Get info about a certain user
=cut
sub info {
    my ( $self, $args ) = @_;
    my $data = _fetch('/users/info/' . _hash_to_query_string($args), $self->auth );
    return $data;
}

=head2
    Validate user credentials. Useful for logins.
=cut
sub validate {
    my ( $self, $args ) = @_;
    my $data = _fetch('/users/validate/' . _hash_to_query_string($args), $self->auth );
    return $data;
}

=head2
    Get a list of friends from the user
=cut
sub friends {
    my ( $self, $args ) = @_;
    my $data = _fetch('/users/friends/' . _hash_to_query_string($args), $self->auth);
    return $data;
}

=head2
    Get a list of followers from the user
=cut
sub followers {
    my ( $self, $args ) = @_;
    my $data = _fetch('/users/followers/' . _hash_to_query_string($args), $self->auth);
    return $data;
}

=head2
    Get a list of external profiles for a user
=cut
sub profiles {
    my ( $self, $args ) = @_;
    my $data = _fetch('/users/profiles/' . _hash_to_query_string($args), $self->auth);
    return $data;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
