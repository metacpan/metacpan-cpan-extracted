package Neo4j::Bolt::ResultStream;
use v5.12;
use warnings;

BEGIN {
  our $VERSION = "0.5001";
  require Neo4j::Bolt::Cxn;
  require Neo4j::Bolt::CResultStream;
  require XSLoader;
  XSLoader::load();
}

sub fetch_next { shift->fetch_next_ }
sub nfields { shift->nfields_ }
sub field_names { shift->fieldnames_ }
sub success { shift->success_ }
sub failure { shift->failure_ }
sub client_errnum { shift-> client_errnum_ }
sub client_errmsg { shift-> client_errmsg_ }
sub server_errmsg { shift-> server_errmsg_ }
sub server_errcode { shift-> server_errcode_ }

sub update_counts {
  my $self = shift;
  my %uc;
  my @tags = qw/nodes_created nodes_deleted
		relationships_created relationships_deleted
		properties_set
		labels_added labels_removed
		indexes_added indexes_removed
		constraints_added constraints_removed/;
  my @vals = $self->update_counts_;
  return unless @vals;
  @uc{@tags} = @vals;
  return \%uc;
}

=head1 NAME

Neo4j::Bolt::ResultStream - Iterator on Neo4j Bolt query response

=head1 SYNOPSIS

 use Neo4j::Bolt;
 $cxn = Neo4j::Bolt->connect("bolt://localhost:7687");

 $stream = $cxn->run_query(
   "MATCH (a) RETURN labels(a) as lbls, count(a) as ct"
 );
 while ( my @row = $stream->fetch_next ) {
   print "For label set [".join(',',@{$row[0]})."] there are $row[1] nodes.\n";
 }
 # check that the stream emptied cleanly...
 unless ( $stream->success ) {
   print STDERR "Uh oh: ".($stream->client_errmsg || $stream->server_errmsg);
 }

=head1 DESCRIPTION

L<Neo4j::Bolt::ResultStream> objects are created by a successful query 
performed on a L<Neo4j::Bolt::Cxn>. They are iterated to obtain the rows
of the response as Perl arrays (not arrayrefs).

=head1 METHODS

=over

=item fetch_next()

Obtain the next row of results as an array. Returns false when done.

=item update_counts()

If a write query is successful, returns a hashref containing the
numbers of items created or removed in the query. The keys indicate
the items, as follows:

 nodes_created
 nodes_deleted
 relationships_created
 relationships_deleted
 properties_set
 labels_added
 labels_removed
 indexes_added
 indexes_removed
 constraints_added
 constraints_removed

If query is unsuccessful, or the stream is not completely fetched yet,
returns undef (check L</"server_errmsg()">).

=item field_names()

Obtain the column names of the response as an array (not arrayref).

=item nfields()

Obtain the number of fields in the response row as an integer.

=item success(), failure()

Use these to check whether fetch_next() succeeded. They indicate the 
current error state of the result stream. If 

  $stream->success == $stream->failure == -1

then the stream has been exhausted.

=item client_errnum()

=item client_errmsg()

=item server_errcode()

=item server_errmsg()

If C<$stream-E<gt>success> is false, these will indicate what happened.

If the error occurred within the C<libneo4j-client> code,
C<client_errnum()> will provide the C<errno> and C<client_errmsg()>
the associated error message. This is a probably a good time to file a
bug report.

If the error occurred at the server, C<server_errcode()> and
C<server_errmsg()> will contain information sent by the server. In
particular, Cypher syntax errors will appear here.

=item result_count_()

=item available_after()

=item consumed_after()

These are performance numbers that the server provides after the 
stream has been fetched out. result_count_() is the number of rows
returned, available_after() is the time in ms it took the server to 
provide the stream, and consumed_after() is the time it took the 
client (you) to pull them all.

=back

=head1 LIMITATIONS

The results of Cypher C<EXPLAIN> or C<PROFILE> queries are
currently unsupported. If you need to access such results,
consider using L<Neo4j::Driver> or the interactive
L<Neo4j Browser|https://neo4j.com/docs/browser-manual/current/>
instead of this module.

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Bolt::Cxn>.

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE

This software is Copyright (c) 2019-2024 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

1;
