use strict;
use warnings;


package Neo4j_Test::Node;
sub isa { $_[1] eq 'Neo4j::Types::Node' }

sub id { shift->[0] }
sub labels { @{shift->[1]} }
sub properties { shift->[2] }
sub get { shift->properties->{+pop} }

sub new {
	my ($class, $params) = @_;
	bless [
		$params->{id},
		$params->{labels} // [],
		$params->{properties} // {},
	], $class;
}


1;
