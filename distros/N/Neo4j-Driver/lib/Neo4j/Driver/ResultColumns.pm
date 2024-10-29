use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::ResultColumns;
# ABSTRACT: Structure definition of Cypher result values
$Neo4j::Driver::ResultColumns::VERSION = '0.50';

# This package is not part of the public Neo4j::Driver API.


# ResultColumns (column_keys) is a hash ref with entries for all field names
# (column keys) and all field indices in a Neo4j result. Their value is always
# the column index in the result record array.
# For example, for `RETURN 1 AS foo`, it would look like this:
#   $column_keys = { 'foo' => 0, '0' => 0 };

# Exceptionally, index/key collisions can occur (see record-ambiguous.t).
# The ResultColumns lookup hash is limited to cases where no ambiguity exists.
# Any column key which would also be a valid index is moved to a sub-hash
# stored in the entry '' (empty string). Neo4j doesn't allow zero-length
# field names, so '' itself is never ambiguous.


use Carp qw(croak);


sub new {
	my ($class, $result) = @_;
	
	croak 'Result missing columns' unless $result && $result->{columns};
	my $columns = $result->{columns};
	my $column_keys = {};
	for my $index (0 .. $#$columns) {
		my $key = $columns->[$index];
		
		# Create lookup cache for both index and key to the index.
		# Ambiguous index/key pairs are moved to the '' sub-hash.
		
		if ( exists $column_keys->{$key} ) {
			delete $column_keys->{$key};
			$column_keys->{''}->{$key} = $index;
		}
		else {
			$column_keys->{$key} = $index;
		}
		
		if ( exists $column_keys->{$index} ) {
			$column_keys->{''}->{$index} = delete $column_keys->{$index};
		}
		else {
			$column_keys->{$index} = $index;
		}
	}
	
	return bless $column_keys, $class;
}


sub key {
	my ($self, $key) = @_;
	
	# returns the index [!] of the field specified by the given key
	return $self->{$key} if length $key && exists $self->{$key};
	return $self->{''}->{$key} if exists $self->{''};
	return undef;
}


sub list {
	my ($self) = @_;
	warnings::warnif deprecated => "Neo4j::Driver::Record->{column_keys} is deprecated";
	
	# returns the unordered list of keys
	# (prior to version 0.1701, the list was returned in the original order)
	my @list = grep { length && $_ ne $self->{$_} } keys %$self;
	push @list, keys %{$self->{''}} if exists $self->{''};
	return @list;
}


sub add {
	my ($self, $column) = @_;
	
	my $index = $self->count;
	
	if ( exists $self->{$column} ) {
		delete $self->{$column};
		$self->{''}->{$column} = $index;
	}
	else {
		$self->{$column} = $index;
	}
	
	if ( exists $self->{$index} ) {
		$self->{''}->{$index} = delete $self->{$index};
	}
	else {
		$self->{$index} = $index;
	}
	
	return $index;
}


sub count {
	my ($self) = @_;
	
	return scalar $self->list;
}


1;
