use v5.12;
use warnings;

package Neo4j::Driver::Record 1.02;
# ABSTRACT: Container for Cypher result values


use Carp qw(croak);
use List::Util qw(first);

use Neo4j::Driver::ResultSummary;


# Check if the given value was created as a number. Older Perls lack stable
# tracking of numbers vs. strings, but a quirk of bitwise string operators
# can be used to determine whether the scalar contains a number (see perlop).
# That isn't quite the same, but it should be good enough for us.
# (original idea from https://github.com/makamaka/JSON-PP/commit/87bd6a4)
sub _SvNIOKp {
	no warnings 'numeric';
	return length( (my $string = '') & shift );
}
*created_as_number = $^V ge v5.36 ? \&builtin::created_as_number : \&_SvNIOKp;


sub get {
	my ($self, $field) = @_;
	
	if ( ! defined $field ) {
		warnings::warnif ambiguous =>
			sprintf "Ambiguous get() on %s with multiple fields", __PACKAGE__
			if @{$self->{row}} > 1;
		return $self->{row}->[0];
	}
	
	my $index = $self->{field_names_cache}->{$field};
	return $self->{row}->[$index] if defined $index && length $field;
	
	# At this point, it looks like the given $field is both a valid name and
	# a valid index, which should be pretty rare.
	# Callers usually specify the field as a literal in the method call, so we
	# can DWIM and disambiguate by using Perl's created_as_number() built-in.
	
	no if $^V ge v5.36, 'warnings', 'experimental::builtin';
	if ( created_as_number($field) ) {
		croak sprintf "Field %s not present in query result", $field
			unless $field == int $field && $field >= 0 && $field < @{$self->{row}};
		return $self->{row}->[$field];
	}
	
	my $field_names = $self->{field_names_cache}->{''};
	$index = first { $field eq $field_names->[$_] } 0 .. $#$field_names;
	croak sprintf "Field '%s' not present in query result", $field
		unless defined $index;
	return $self->{row}->[$index];
}


sub data {
	my ($self) = @_;
	
	return $self->{hash} if exists $self->{hash};
	
	my $field_names = $self->{field_names_cache}->{''};
	my %data;
	$data{ $field_names->[$_] } = $self->{row}->[$_] for 0 .. $#$field_names;
	return $self->{hash} = \%data;
}


# Parse the field names (result column keys) provided by the server and
# return them as a hash ref for fast index lookups
sub _field_names_cache {
	my ($result) = @_;
	
	my $field_names = $result->{columns};
	my $cache = { '' => $field_names };
	for my $index (0 .. $#$field_names) {
		my $name = $field_names->[$index];
		
		# Create lookup cache for both index and field name to the index.
		# Skip ambiguous index/name pairs.
		
		if ( exists $cache->{$name} ) {
			delete $cache->{$name};
		}
		else {
			$cache->{$name} = $index;
		}
		
		if ( exists $cache->{$index} ) {
			delete $cache->{$index};
		}
		else {
			$cache->{$index} = $index;
		}
	}
	
	return $cache;
}

# The field names (column keys / ex ResultColumns) are stored in a hash ref.
# For each field, there are entries with keys for the name and the column index
# in the result record array. The value is always the column index.
# For example, for `RETURN 1 AS foo`, it would look like this:
#   $cache = { 'foo' => 0, '0' => 0 };

# Exceptionally, index/name collisions can occur (see record-ambiguous.t).
# The field names lookup cache is limited to cases where no ambiguity exists.
# A reference to the original list of field names is kept in
# the entry '' (empty string). Neo4j doesn't allow zero-length
# field names, so '' itself is never ambiguous.


sub summary {
	# uncoverable pod (see consume)
	my ($self) = @_;
	warnings::warnif deprecated => "summary() in Neo4j::Driver::Record is deprecated; use consume() in Neo4j::Driver::Result instead";
	
	croak 'Summary unavailable for Record retrieved with fetch() or list(); use consume() in Neo4j::Driver::Result' unless $self->{_summary};
	return $self->{_summary};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Record - Container for Cypher result values

=head1 VERSION

version 1.02

=head1 SYNOPSIS

 $record = $session->execute_write( sub ($transaction) {
   return $transaction->run( ... )->fetch;
 });
 
 $value = $record->get('name');  # field key
 $value = $record->get(0);       # field index
 
 # Shortcut for records with just a single key
 $value = $record->get;

=head1 DESCRIPTION

Container for Cypher result values. Records are returned from Cypher
query execution, contained within a Result. A record is
a form of ordered map and, as such, contained values can be accessed
by either positional index or textual key.

To obtain a record, call L<Neo4j::Driver::Result/"fetch">.

=head1 METHODS

L<Neo4j::Driver::Record> implements the following methods.

=head2 get

 $value1 = $record->get('field_key');
 $value2 = $record->get(2);

Get a value from this record, either by field key or by zero-based
index.

When called without parameters, C<get()> will return the first
field. If there is more than a single field, a warning in the
category C<ambiguous> will be issued.

 $value = $session->run('RETURN "It works!"')->single->get;
 $value = $session->run('RETURN "warning", "ambiguous"')->single->get;

Values are returned from Neo4j as L<Neo4j::Types> objects and
as simple Perl references / scalars. For details and for known
issues with type mapping see L<Neo4j::Driver::Types>.

=head2 data

 $hashref = $record->data;
 $value = $hashref->{field_key};

Return the keys and values of this record as a hash reference.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Driver::B<Result>>

=item * L<Neo4j::Driver::Types>

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
