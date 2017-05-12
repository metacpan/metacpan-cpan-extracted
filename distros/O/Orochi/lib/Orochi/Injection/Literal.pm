package Orochi::Injection::Literal;
use Moose;
use namespace::clean -except => qw(meta);

with 'Orochi::Injection';

has value => (
    is => 'ro',
);

sub BUILDARGS {
    my $class = shift;
    return @_ == 1 ? { value => $_[0] } : { @_ };
}

sub expand { return $_[0]->value }

__PACKAGE__->meta->make_immutable;

1;
