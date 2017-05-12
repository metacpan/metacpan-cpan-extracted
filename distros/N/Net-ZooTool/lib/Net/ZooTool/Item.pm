package Net::ZooTool::Item;

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

before [ 'info', 'popular' ] => sub {
    # Appends apikey to all registered methods
    my ( $self, $args ) = @_;

    croak
        "You are trying to use a feature that requires authentication without providing username and password"
        if $args->{login} and ( !$self->auth->user or !$self->auth->password );

    $args->{apikey} = $self->auth->apikey;
};

=head2
    Get the info for an item by uid
=cut
sub info {
    my ( $self, $args ) = @_;
    my $data = _fetch('/items/info/' . _hash_to_query_string($args));
    return $data;
}

=head2
    Get the most popular items
=cut
sub popular {
    my ( $self, $args ) = @_;
    my $data = _fetch('/items/popular/' . _hash_to_query_string($args));
    return $data;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
