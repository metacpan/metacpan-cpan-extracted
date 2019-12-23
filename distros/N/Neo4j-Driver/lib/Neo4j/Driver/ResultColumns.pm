use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::ResultColumns;
# ABSTRACT: Structure definition of Cypher result values
$Neo4j::Driver::ResultColumns::VERSION = '0.14';

use Carp qw(croak);


sub new {
	my ($class, $result) = @_;
	
	croak 'Result missing columns' unless $result && $result->{columns};
	my $columns = $result->{columns};
	my $column_keys = {};
	for (my $f = scalar(@$columns) - 1; $f >= 0; $f--) {
		$column_keys->{$columns->[$f]} = $f;
		$column_keys->{$f} = $f;
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
	
	# reconstruct the ordered list of keys
	my @keys = ();
	foreach my $key ( keys %$self ) {
		my $i = $self->{$key};
		next if defined $keys[$i] && $keys[$i] ne "$i" && $key eq "$i";
		$keys[$i] = $key;
	}
	return @keys;
}


sub add {
	my ($self, $column) = @_;
	
	my $index = $self->count;
	$self->{$column} = $self->{$index} = $index;
	return $index;
}


sub count {
	my ($self) = @_;
	
	my $column_count = (scalar keys %$self) >> 1;  # each column has two hash entries (numeric and by name)
	return $column_count;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::ResultColumns - Structure definition of Cypher result values

=head1 VERSION

version 0.14

=head1 DESCRIPTION

The L<Neo4j::Driver::ResultColumns> package is not part of the
public L<Neo4j::Driver> API.

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2019 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
