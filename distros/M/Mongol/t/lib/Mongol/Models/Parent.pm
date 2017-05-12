package Mongol::Models::Parent;

use Moose;

extends 'Mongol::Model';

with 'Mongol::Roles::Core';
with 'Mongol::Roles::Relations';
with 'Mongol::Roles::UUID';

has 'name' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

__PACKAGE__->has_many( 'Mongol::Models::Child' => 'parent_id' );

__PACKAGE__->meta()->make_immutable();

1;

__END__
