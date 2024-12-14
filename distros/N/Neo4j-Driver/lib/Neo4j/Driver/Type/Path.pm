use v5.12;
use warnings;

package Neo4j::Driver::Type::Path 1.02;
# ABSTRACT: Directed sequence of relationships between two nodes


# For documentation, see Neo4j::Driver::Types.


use parent 'Neo4j::Types::Path';


sub nodes {
	my ($self) = @_;
	
	my $i = 0;
	return grep { ++$i & 1 } @{$self->{'..'}};
}


sub relationships {
	my ($self) = @_;
	
	my $i = 0;
	return grep { $i++ & 1 } @{$self->{'..'}};
}


sub elements {
	my ($self) = @_;
	
	return @{$self->{'..'}};
}


1;
