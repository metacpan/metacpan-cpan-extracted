use strict;
use warnings;


package Neo4j_Test::Rel;
sub isa { $_[1] eq 'Neo4j::Types::Relationship' }

sub id { shift->[0] }
sub start_id { shift->[1] }
sub end_id { shift->[2] }
sub type { shift->[3] }
sub properties { shift->[4] }
sub get { shift->properties->{+pop} }

sub new {
	my ($class, $params) = @_;
	bless [
		$params->{id},
		$params->{start_id},
		$params->{end_id},
		$params->{type},
		$params->{properties} // {},
	], $class;
}


1;
