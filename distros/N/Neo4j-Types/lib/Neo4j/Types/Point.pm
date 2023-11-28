use v5.10.1;
use strict;
use warnings;

package Neo4j::Types::Point;
# ABSTRACT: Represents a Neo4j spatial point value
$Neo4j::Types::Point::VERSION = '2.00';

sub new {
	# uncoverable pod
	warnings::warnif deprecated => "Deprecated: Use Neo4j::Types::Generic::Point->new() instead";
	
	require Neo4j::Types::Generic::Point;
	&Neo4j::Types::Generic::Point::new;
}


1;
