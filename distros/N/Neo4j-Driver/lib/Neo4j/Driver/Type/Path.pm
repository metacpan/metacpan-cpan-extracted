use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Path;
# ABSTRACT: Directed sequence of relationships between two nodes
$Neo4j::Driver::Type::Path::VERSION = '0.52';

# For documentation, see Neo4j::Driver::Types.


use parent 'Neo4j::Types::Path';
use overload '@{}' => \&_array, fallback => 1;

use Carp qw(croak);


sub nodes {
	my ($self) = @_;
	
	my $i = 0;
	return grep { ++$i & 1 } @{$self->{path}};
}


sub relationships {
	my ($self) = @_;
	
	my $i = 0;
	return grep { $i++ & 1 } @{$self->{path}};
}


sub elements {
	my ($self) = @_;
	
	return @{$self->{path}};
}


sub path {
	# uncoverable pod (see Deprecations.pod)
	my ($self) = @_;
	
	warnings::warnif deprecated => __PACKAGE__ . "->path() is deprecated; use elements()";
	return [ @{$self->{path}} ];
}


sub _array {
	my ($self) = @_;
	
	warnings::warnif deprecated => "Direct array access is deprecated; use " . __PACKAGE__ . "->elements()";
	return $self->{path};
}


# for experimental Cypher type system customisation only
sub _private {
	my ($self) = @_;
	
	$self->{private} //= {};
	return $self->{private};
}


1;
