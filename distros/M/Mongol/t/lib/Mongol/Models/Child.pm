package Mongol::Models::Child;

use Moose;

extends 'Mongol::Model';

with 'Mongol::Roles::Core';
with 'Mongol::Roles::Relations';

has 'parent_id' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has 'name' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

sub setup {
	my $class = shift();

	$class->collection()
		->indexes()
		->create_one( [ parent_id => 1 ] );
}

__PACKAGE__->has_one( 'Mongol::Models::Parent' => 'parent_id' );

__PACKAGE__->meta()->make_immutable();

1;

__END__
