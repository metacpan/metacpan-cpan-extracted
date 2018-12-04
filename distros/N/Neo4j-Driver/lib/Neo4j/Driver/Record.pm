use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Record;
# ABSTRACT: Container for Cypher result values
$Neo4j::Driver::Record::VERSION = '0.09';

use Carp qw(carp croak);
use JSON::PP;

use Neo4j::Driver::ResultSummary;


sub get {
	my ($self, $field) = @_;
	
	if ( ! defined $field ) {
		carp "Ambiguous get() on " . __PACKAGE__ . " with multiple fields" if @{$self->{row}} > 1;
		return $self->{row}->[0];
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
	my ($self, $field) = @_;
	carp __PACKAGE__ . "->get_bool is deprecated";
	
	my $value = $self->get($field);
	return $value if ! ref $value;
	return $value if $value != JSON::PP::false;
	return undef;  ##no critic (ProhibitExplicitReturnUndef)
}


sub data {
	my ($self) = @_;
	
	my %data = ();
	foreach my $key ( $self->{column_keys}->list ) {
		$data{$key} = $self->{row}->[ $self->{column_keys}->key($key) ];
	}
	return \%data;
}


sub summary {
	my ($self) = @_;
	
	$self->{_summary} //= Neo4j::Driver::ResultSummary->new;
	return $self->{_summary}->init;
}


sub stats {
	my ($self) = @_;
	carp __PACKAGE__ . "->stats is deprecated; use summary instead";
	
	return $self->{_summary} ? $self->{_summary}->counters : {};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Record - Container for Cypher result values

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 use Neo4j::Driver;
 my $session = Neo4j::Driver->new->basic_auth(...)->session;
 
 my $query = 'MATCH (m:Movie) RETURN m.name, m.year';
 my $records = $session->run($query)->list;
 foreach my $record ( @$records ) {
   say $record->get('m.name');
 }
 
 $query .= ' ORDER BY m.year LIMIT 1';
 my $record = $session->run($query)->single;
 say 'Age of oldest movie: ', $record->get(1);

=head1 DESCRIPTION

Container for Cypher result values. Records are returned from Cypher
statement execution, contained within a StatementResult. A record is
a form of ordered map and, as such, contained values can be accessed
by either positional index or textual key.

=head1 METHODS

L<Neo4j::Driver::Record> implements the following methods.

=head2 get

 my $value1 = $record->get('field_key');
 my $value2 = $record->get(2);

Get a value from this record, either by field key or by zero-based
index.

If there is only a single field, C<get> may be called without
parameters.

 my $value = $session->run('RETURN "It works!"')->single->get;
 my $value = $session->run('RETURN "two", "fields"')->single->get;  # fails

Nodes, relationships and maps are returned as hash references of
their properties. Lists and paths are returned as array references.
Boolean values are returned as JSON types; use C<!!> to force-convert
to a plain Perl boolean value if necessary.

=head2 data

 my $hashref = $record->data;
 my $value = $hashref->{field_key};

Return the keys and values of this record as a hash reference.

=head1 EXPERIMENTAL FEATURES

L<Neo4j::Driver::Record> implements the following experimental
features. These are subject to unannounced modification or removal
in future versions. Expect your code to break if you depend upon
these features.

=head2 C<column_keys>

 my $size = $record->{column_keys}->count;
 $record->{column_keys}->add('new_field_key');

Allows adding new columns to the record's field key / index
resolution used by the C<get> method. Can be used to synthesize
'virtual' fields based on other data in the result. The new fields
can then be accessed just like regular columns.

=head2 C<graph>

 my $nodes = $record->{graph}->{nodes};
 my $rels  = $record->{graph}->{relationships};

Allows accessing the graph response the Neo4j server can deliver via
HTTP. Requires the C<return_graph> field to be set on the
L<Transaction|Neo4j::Driver::Transaction>
before the statement is executed.

=head2 C<meta>

 my $meta = $record->{meta};

Allows accessing the entity meta data that some versions of the Neo4j
server provide.

=head1 SEE ALSO

L<Neo4j::Driver>,
L<Neo4j Java Driver|https://neo4j.com/docs/api/java-driver/current/index.html?org/neo4j/driver/v1/Record.html>,
L<Neo4j JavaScript Driver|https://neo4j.com/docs/api/javascript-driver/current/class/src/v1/record.js~Record.html>,
L<Neo4j .NET Driver|https://neo4j.com/docs/api/dotnet-driver/current/html/dfbf8228-17a4-99ed-58bb-81b638ae788a.htm>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2018 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
