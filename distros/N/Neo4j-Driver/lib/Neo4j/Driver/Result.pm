use v5.12;
use warnings;

package Neo4j::Driver::Result 1.02;
# ABSTRACT: Result of running a Cypher query (a stream of records)


use Carp qw(croak);

use Neo4j::Driver::Record;
use Neo4j::Driver::ResultSummary;


our $fake_attached = 0;  # 1: simulate an attached stream (only used in testing)


sub new {
	# uncoverable pod (private method)
	my ($class) = @_;
	
	return bless { buffer => [] }, $class;
}


sub keys {
	my ($self) = @_;
	
	return @{ $self->{result}->{columns} // [] };
}


sub list {
	my ($self) = @_;
	
	$self->_fill_buffer;
	$self->{exhausted} = 1;
	return wantarray ? @{$self->{buffer}} : $self->{buffer};
}


sub size {
	my ($self) = @_;
	
	return scalar @{$self->list};
}


sub single {
	my ($self) = @_;
	
	croak 'There is not exactly one result record' if $self->size != 1;
	my ($record) = $self->list;
	$record->{_summary} = $self->_summary;
	return $record;
}


sub _as_fully_buffered {
	my ($self) = @_;
	
	$self->{attached} = $fake_attached;
	return $self if $fake_attached;  # (only used in testing)
	
	# JSON results are completely available immediately and can be fully
	# buffered right away, avoiding the need to loop through _fetch_next().
	# (also used in Bolt/Jolt testing, $gather_results 1)
	$self->{buffer} = $self->{result}->{data};
	$self->{field_names_cache} = Neo4j::Driver::Record::_field_names_cache( $self->{result} );
	$self->_init_record( $_ ) for @{ $self->{buffer} };
	return $self;
}


sub _fill_buffer {
	my ($self, $minimum) = @_;
	
	return 0 unless $self->{attached};
	
	$self->{field_names_cache} //= Neo4j::Driver::Record::_field_names_cache( $self->{result} );
	
	# try to get at least $minimum records on the buffer
	my $buffer = $self->{buffer};
	my $count = 0;
	my $next = 1;
	while ( (! $minimum || @$buffer < $minimum)
			&& ($next = $self->_fetch_next) ) {
		push @$buffer, $next;
		$count++;
	}
	
	# _fetch_next was called, but didn't return records => end of stream; detach
	if (! $next) {
		$self->{result}->{stats} = $self->{stream}->update_counts if $self->{stream};
		$self->{cxn} = undef;  # decrease reference count, allow garbage collection
		$self->{stream} = undef;
		$self->{attached} = 0;
	}
	
	return $count;
}


sub _fetch_next {
	my ($self) = @_;
	
	# simulate a JSON-backed result stream (only used in testing, $fake_attached 1)
	$self->{json_cursor} //= 0;
	my $record = $self->{result}->{data}->[ $self->{json_cursor}++ ];
	return undef unless $record;  ##no critic (ProhibitExplicitReturnUndef)
	return $self->_init_record( $record );
}


sub fetch {
	my ($self) = @_;
	
	return if $self->{exhausted};  # fetch() mustn't destroy a list() buffer
	$self->_fill_buffer(2);
	my $next = shift @{$self->{buffer}};
	$self->{exhausted} = ! $next;
	return $next;
}


sub peek {
	my ($self) = @_;
	
	$self->_fill_buffer(1);
	return scalar $self->{buffer}->[0];
}


sub has_next {
	my ($self) = @_;
	
	return 0 if $self->{exhausted};
	$self->_fill_buffer(1);
	return scalar @{$self->{buffer}};
}


sub consume {
	my ($self) = @_;
	
	1 while $self->fetch;  # Exhaust the result stream
	return $self->_summary;
}


sub summary {
	# uncoverable pod (see consume)
	warnings::warnif deprecated => "summary() in Neo4j::Driver::Result is deprecated; use consume() instead";
	&_summary;
}


sub _summary {
	my ($self) = @_;
	
	$self->_fill_buffer;
	
	$self->{summary} //= Neo4j::Driver::ResultSummary->new( $self->{result}, $self->{notifications}, $self->{query}, $self->{server_info} );
	
	return $self->{summary};
}


sub _bool_values {
	no if $^V ge v5.36, 'warnings', 'experimental::builtin';
	if ( $^V ge v5.36 ) {
		return builtin::false(), builtin::true();
	}
	else {
		require JSON::PP;
		return JSON::PP::false(), JSON::PP::true();
	}
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Result - Result of running a Cypher query (a stream of records)

=head1 VERSION

version 1.02

=head1 SYNOPSIS

 $result = $session->run( ... );
 
 # Stream result records
 while ( $record = $result->fetch ) {
   ...
 }
 
 # List result records
 @records = $result->list;
 $records = $result->list;  # array ref
 $record_count = $result->size;
 
 # Shortcut for results with a single record only
 $record = $result->single;
 
 @field_keys = $result->keys;
 $summary = $result->consume;
 
 # For error checking, call any method on the result to ensure
 # the query has executed before leaving the try block
 try {
   $result = $transaction->run( ... );
   $result->has_next;
 }
 catch ($e) { ... }

=head1 DESCRIPTION

The result of running a Cypher query, conceptually a stream of
records. The result stream can be navigated through using C<fetch()>
to consume records one at a time, or be consumed in its entirety
using C<list()> to get an array of all records.

Result streams typically are initially attached to the active
session. As records are retrieved from the stream, they may be
buffered locally in the driver. Once I<all> data on the result stream
has been retrieved from the server and buffered locally, the stream
becomes B<detached.>

Result streams are valid until the next query
is run on the same session or (if the result was retrieved within
an explicit transaction) until the transaction is closed, whichever
comes first. When a result stream has become invalid I<before> it
was detached, calling any methods in this class may fail.

Some result handlers may automatically detach a result stream
immediately when the result is made available by the server.
Such result streams are valid indefinitely.
In driver S<version 0.xx,> this happened for all HTTP results.
This behaviour is subject to change in future versions and
shouldn't be relied upon.

To obtain a query result, call L<Neo4j::Driver::Transaction/"run">.

=head1 METHODS

L<Neo4j::Driver::Result> implements the following methods.

=head2 consume

 $summary = $result->consume;

Return the L<Neo4j::Driver::ResultSummary>.

Calling this method fully exhausts the result and invalidates the
result stream, discarding any remaining records. If you want to
access records I<after> retrieving the summary, you should use
C<list()> before C<consume()> to buffer all records into memory.

Before driver S<version 0.44>, the summary was retrieved with
the C<summary()> method, which didn't exhaust the result.
That method has since been deprecated, matching a corresponding
change in S<Neo4j 4.0>.

=head2 fetch

 while ($record = $result->fetch) {
   ...
 }

Navigate to and retrieve the next L<Record|Neo4j::Driver::Record> in
this result.

When a record is fetched, that record is removed from the result
stream. Once all records have been fetched, the result stream is
exhausted and C<fetch()> returns C<undef>.

=head2 has_next

 while ($record = $result->fetch) {
   print $record->get('field');
   print ', ' if $result->has_next;
 }

Whether the next call to C<fetch()> will return a record.

Calling this method may change the internal stream buffer and
detach the result, but will never exhaust it.

=head2 keys

 @keys = $result->keys;

Retrieve the column names (field keys) of the records this result
contains. In scalar context, return the number of columns.

=head2 list

 @records = $result->list;
 $records = $result->list;  # arrayref

Return the entire list of all L<Record|Neo4j::Driver::Record>s that
remain in the result stream. Calling this method exhausts the result
stream.

The list is internally buffered by this class. Calling this method
multiple times returns the buffered list.

In scalar context, returns an array reference (discouraged in new code).

=head2 peek

 $record = $result->peek;

Obtain the next L<Record|Neo4j::Driver::Record> from this result
without actually navigating to it and consuming it. The record
is left in the internal stream buffer for further processing.
If there is no next record, return C<undef>.

=head2 single

 $name = $session->run('... LIMIT 1')->single->get('name');

Return the single L<Record|Neo4j::Driver::Record> left in the result
stream, failing if there is not exactly one record left. Calling this
method exhausts the result stream.

The returned record is internally buffered by this class. Calling this
method multiple times returns the buffered record.

=head2 size

 $record_count = $result->size;

Return the count of records that calling C<list()> would yield.

Calling this method may exhaust the result stream and may buffer all records
for use by C<list()>.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Driver::B<Record>>

=item * L<Neo4j::Driver::B<ResultSummary>>

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
