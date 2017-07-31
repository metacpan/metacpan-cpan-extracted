package MooseX::DIC::InjectionPointMetada;

use Moose;
use namespace::autoclean;

use MooseX::DIC::Types;

has scope => ( is => 'ro', isa => 'InjectionScope', default => 'object' );
has qualifiers =>
    ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] } );

sub from_attribute {
    my $attribute = shift;

    return MooseX::DIC::InjectionPointMetada->new(
        scope      => $attribute->scope;
        qualifiers => $attribute->qualifiers
    );
}

__PACKAGE__->meta->make_immutable;

1;
