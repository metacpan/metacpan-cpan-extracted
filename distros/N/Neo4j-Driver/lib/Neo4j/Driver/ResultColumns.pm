use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::ResultColumns;
# ABSTRACT: Structure definition of Cypher result values
$Neo4j::Driver::ResultColumns::VERSION = '0.18';

use Carp qw(croak);


sub new {
	my ($class, $result) = @_;
	
	croak 'Result missing columns' unless $result && $result->{columns};
	my $columns = $result->{columns};
	my $column_keys = {};
	for (my $f = scalar(@$columns) - 1; $f >= 0; $f--) {
		$column_keys->{$columns->[$f]} = $f;
	}
	
	return bless $column_keys, $class;
}


sub key {
	my ($self, $key) = @_;
	
	# returns the index [!] of the field specified by the given key
	return $self->{$key};
}


sub list {
	my ($self) = @_;
	warnings::warnif deprecated => "Neo4j::Driver::Record->{column_keys} is deprecated";
	
	# returns the unordered list of keys
	# (prior to version 0.1701, the list was returned in the original order)
	return keys %$self;
}


sub add {
	my ($self, $column) = @_;
	
	my $index = $self->count;
	$self->{$column} = $index;
	return $index;
}


sub count {
	my ($self) = @_;
	
	return scalar $self->list;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::ResultColumns - Structure definition of Cypher result values

=head1 VERSION

version 0.18

=head1 DESCRIPTION

The L<Neo4j::Driver::ResultColumns> package is not part of the
public L<Neo4j::Driver> API.

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2020 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
