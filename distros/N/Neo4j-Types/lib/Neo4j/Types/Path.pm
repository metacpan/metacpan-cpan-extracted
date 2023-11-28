use v5.10.1;
use strict;
use warnings;

package Neo4j::Types::Path;
# ABSTRACT: Represents a Neo4j path of nodes and relationships
$Neo4j::Types::Path::VERSION = '2.00';


sub elements {
	my ($self) = @_;
	
	return @$self;
}


sub nodes {
	my ($self) = @_;
	
	my $i = 0;
	return grep { ++$i & 1 } @$self;
}


sub relationships {
	my ($self) = @_;
	
	my $i = 0;
	return grep { $i++ & 1 } @$self;
}


1;
