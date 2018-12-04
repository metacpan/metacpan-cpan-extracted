use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::StatementResult;
# ABSTRACT: Result of running a Cypher statement (a list of records)
$Neo4j::Driver::StatementResult::VERSION = '0.09';

use Carp qw(carp croak);

use Neo4j::Driver::Record;
use Neo4j::Driver::ResultColumns;
use Neo4j::Driver::ResultSummary;


sub new {
	my ($class, $result, $summary) = @_;
	
	my $self = {
		blessed => 0,
		result => $result,
		summary => $summary,
	};
	return bless $self, $class;
}


sub _column_keys {
	my ($self) = @_;
	
	return Neo4j::Driver::ResultColumns->new($self->{result});
}


sub keys {
	my ($self) = @_;
	
	# Don't break encapsulation by just returning the original reference
	# because ResultColumns depends on the {columns} field being intact.
	my @keys = ();
	@keys = @{ $self->{result}->{columns} } if $self->{result}->{columns};
	return wantarray ? @keys : [@keys];
}


sub list {
	my ($self) = @_;
	
	my $l = $self->{result}->{data};
	if ( ! $self->{blessed} ) {
		my $column_keys = $self->_column_keys;
		foreach my $a (@$l) {
			bless $a, 'Neo4j::Driver::Record';
			$a->{column_keys} = $column_keys;
		}
		$self->{blessed} = 1;
	}
	
	return wantarray ? @$l : $l;
}


sub size {
	my ($self) = @_;
	
	return 0 unless $self->{result};
	return scalar @{$self->{result}->{data}};
}


sub single {
	my ($self) = @_;
	
	croak 'There is not exactly one result record' if $self->size != 1;
	my ($record) = $self->list;
	$record->{_summary} = $self->summary if $self->{result}->{stats};
	return $record;
}


sub summary {
	my ($self) = @_;
	
	$self->{summary} //= Neo4j::Driver::ResultSummary->new;
	return $self->{summary}->init;
}


sub stats {
	my ($self) = @_;
	carp __PACKAGE__ . "->stats is deprecated; use summary instead";
	
	return $self->{result}->{stats} ? $self->summary->counters : {};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::StatementResult - Result of running a Cypher statement (a list of records)

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 use Neo4j::Driver;
 my $session = Neo4j::Driver->new->basic_auth(...)->session;
 
 my $result = $session->run('MATCH (m:Movie) RETURN m.name, m.year');
 my $record_count = $result->size;
 my @records = @{ $result->list };
 
 my $query = 'MATCH (m:Movie) WHERE id(m) = {id} RETURN m.name';
 my $name = $session->run($query, id => 12)->single->get('m.name');

=head1 DESCRIPTION

The result of running a Cypher statement, conceptually a list of
records. The standard way of navigating through the result returned
by the database is to iterate over the list it provides. Results are
valid indefinitely.

=head1 METHODS

L<Neo4j::Driver::StatementResult> implements the following methods.

=head2 keys

 my @keys = @{ $result->keys };

Retrieve the column names of the records this result contains.

=head2 list

 my @records = @{ $result->list };

Return the entire list of all L<Record|Neo4j::Driver::Record>s in the
result.

=head2 single

 my $name = $session->run('... LIMIT 1')->single->get('name');

Return the single L<Record|Neo4j::Driver::Record> in the result,
failing if there is not exactly one record in the result.

=head2 size

 my $record_count = $result->size;

Return the count of records in the result.

=head2 summary

 my $result_summary = $result->summary;

Return a L<Neo4j::Driver::ResultSummary> object.

The C<summary> method will fail unless the transaction has been
modified to request statistics before the statement was run.

 my $transaction = $session->begin_transaction;
 $transaction->{return_stats} = 1;
 my $result = $transaction->run('...');

As a special case, L<Record|Neo4j::Driver::Record>s returned by the
C<single> method also have a C<summary> method that works the same
way.

 my $record = $transaction->run('...')->single;
 my $result_summary = $record->summary;

=head1 EXPERIMENTAL FEATURES

L<Neo4j::Driver::StatementResult> implements the following
experimental features. These are subject to unannounced modification
or removal in future versions. Expect your code to break if you
depend upon these features.

=head2 Calling in list context

 my @keys = $result->keys;
 my @records = $result->list;

The C<keys> and C<list> methods try to Do What You Mean if called in
list context.

=head1 SEE ALSO

L<Neo4j::Driver>,
L<Neo4j::Driver::Record>,
L<Neo4j::Driver::ResultSummary>,
L<Neo4j Java Driver|https://neo4j.com/docs/api/java-driver/current/index.html?org/neo4j/driver/v1/StatementResult.html>,
L<Neo4j JavaScript Driver|https://neo4j.com/docs/api/javascript-driver/current/class/src/v1/result.js~Result.html>,
L<Neo4j .NET Driver|https://neo4j.com/docs/api/dotnet-driver/current/html/1ddb9dbe-f40f-26a3-e6f0-7be417980044.htm>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2018 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
