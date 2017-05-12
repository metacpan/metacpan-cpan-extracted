package Storm::Role::Query::HasAttributeMap;
{
  $Storm::Role::Query::HasAttributeMap::VERSION = '0.240';
}

use Moose::Role;
with 'Storm::Role::Query::HasAttributeOrder';

has '_attribute_map' => (
    is => 'ro'     ,
    lazy_build => 1,
);

sub _build__attribute_map {
    my $self = shift;
    my $class = $self->class;
    my %map = map { $_->name => $_ } $self->attribute_order;
    return \%map;
}

no Moose::Role;
1;
