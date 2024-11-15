use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Record;
# ABSTRACT: Container for Cypher result values
$Neo4j::Driver::Record::VERSION = '0.51';

use Carp qw(croak);
use JSON::MaybeXS 1.003003 qw(is_bool);

use Neo4j::Driver::ResultSummary;


# Based on _looks_like_number() in JSON:PP 4.05, originally by HAARG.
# Modified on 2020 OCT 13 to detect only integers (column index).
sub _looks_like_int {
	my $value = shift;
	# if the utf8 flag is on, it almost certainly started as a string
	return if utf8::is_utf8($value);
	# detect numbers
	# string & "" -> ""
	# number & "" -> 0 (with warning)
	# nan and inf can detect as numbers, so check with * 0
	no warnings 'numeric';
	return unless length((my $dummy = "") & $value);
	return unless $value eq int $value;
	return unless $value * 0 == 0;
	return 1;
}


sub get {
	my ($self, $field) = @_;
	
	if ( ! defined $field ) {
		warnings::warnif ambiguous => "Ambiguous get() on " . __PACKAGE__ . " with multiple fields" if @{$self->{row}} > 1;
		return $self->{row}->[0];
	}
	
	croak "Field '' not present in query result" if ! length $field;
	
	my $unambiguous_key = $self->{column_keys}->{$field};
	return $self->{row}->[$unambiguous_key] if defined $unambiguous_key;
	
	if ( _looks_like_int $field ) {
		croak "Field $field not present in query result" if $field < 0 || $field >= @{$self->{row}};
		return $self->{row}->[$field];
	}
	
	my $key = $self->{column_keys}->key($field);
	croak "Field '$field' not present in query result" if ! defined $key;
	return $self->{row}->[$key];
}


# The various JSON modules for Perl tend to represent a boolean false value
# using a blessed scalar overloaded to evaluate to false in Perl expressions.
# This almost always works perfectly fine. However, some tests might not expect
# a non-truthy value to be blessed, which can result in wrong interpretation of
# query results. The get_bool method was meant to ensure boolean results would
# evaluate correctly in such cases. Given that such cases are rare and that no
# specific examples for such cases are currently known, this method now seems
# superfluous.
sub get_bool {
	# uncoverable pod (see Deprecations.pod)
	my ($self, $field) = @_;
	warnings::warnif deprecated => __PACKAGE__ . "->get_bool is deprecated";
	
	my $value = $self->get($field);
	no if $^V ge v5.36, 'warnings', 'experimental::builtin';
	return undef if ! $value && $^V ge v5.36 && builtin::is_bool $value;
	return $value if ! is_bool $value;
	return $value if !! $value;
	return undef;  ##no critic (ProhibitExplicitReturnUndef)
}


sub data {
	my ($self) = @_;
	
	my %data = ();
	foreach my $key (keys %{ $self->{column_keys} }) {
		$data{$key} = $self->{row}->[ $self->{column_keys}->key($key) ];
	}
	return \%data;
}


sub summary {
	my ($self) = @_;
	
	$self->{_summary} //= Neo4j::Driver::ResultSummary->new;
	return $self->{_summary}->_init;
}


sub stats {
	# uncoverable pod (see Deprecations.pod)
	my ($self) = @_;
	warnings::warnif deprecated => __PACKAGE__ . "->stats is deprecated; use summary instead";
	
	return $self->{_summary} ? $self->{_summary}->counters : {};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Record - Container for Cypher result values

=head1 VERSION

version 0.51

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
statement execution, contained within a Result. A record is
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

=item * L<Neo4j::Driver::Types>

=item * Equivalent documentation for the official Neo4j drivers:
L<Record (Java)|https://neo4j.com/docs/api/java-driver/5.26/org.neo4j.driver/org/neo4j/driver/Record.html>,
L<Record (JavaScript)|https://neo4j.com/docs/api/javascript-driver/5.26/class/lib6/record.js~Record.html>,
L<IRecord (.NET)|https://neo4j.com/docs/api/dotnet-driver/5.26/api/Neo4j.Driver.IRecord.html>

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
