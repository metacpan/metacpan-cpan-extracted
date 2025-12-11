package Neo4j::Bolt::Cxn;
use v5.12;
use warnings;

use Carp qw/croak/;

BEGIN {
  our $VERSION = "0.5001";
  require Neo4j::Bolt::CTypeHandlers;
  require Neo4j::Bolt::ResultStream;
  require XSLoader;
  XSLoader::load();
}
sub default_db () { $Neo4j::Bolt::DEFAULT_DB // "" }

sub errnum { shift->errnum_ }
sub errmsg { shift->errmsg_ }
sub reset_cxn { shift->reset_ }

sub server_id { shift->server_id_ }
sub protocol_version { shift->protocol_version_ }

sub run_query {
  my $self = shift;
  my ($query, $parms, $db) = @_;
  unless ($query) {
    croak "Arg 1 should be Cypher query string";
  }
  if ($parms && !(ref $parms == 'HASH')) {
    croak "Arg 2 should be a hashref of { param => \$value, ... }";
  }
  croak "No connection" unless $self->connected;
  utf8::upgrade($query);
  return $self->run_query_($query, $parms // {}, 0, $db // default_db);
}

sub send_query {
  my $self = shift;
  my ($query, $parms, $db) = @_;
  unless ($query) {
    croak "Arg 1 should be Cypher query string";
  }
  if ($parms && !(ref $parms == 'HASH')) {
    croak "Arg 2 should be a hashref of { param => \$value, ... }";
  }
  croak "No connection" unless $self->connected;
  utf8::upgrade($query);
  return $self->run_query_($query, $parms ? $parms : {}, 1, $db // default_db );
}

sub do_query {
  my $self = shift;
  my $stream = $self->run_query(@_);
  my @results;
  if ($stream->success_) {
    while (my @row = $stream->fetch_next_) {
      push @results, [@row];
    }
  }
  return wantarray ? ($stream, @results) : $stream;
}

=head1 NAME

Neo4j::Bolt::Cxn - Container for a Neo4j Bolt connection

=head1 SYNOPSIS

 use Neo4j::Bolt;
 $cxn = Neo4j::Bolt->connect("bolt://localhost:7687");
 unless ($cxn->connected) {
   die "Problem connecting: ".$cxn->errmsg;
 }
 $stream = $cxn->run_query(
   "MATCH (a) RETURN head(labels(a)) as lbl, count(a) as ct",
 );
 if ($stream->failure) {
   print STDERR "Problem with query run: ".
                 ($stream->client_errmsg || $stream->server_errmsg);
 }

=head1 DESCRIPTION

L<Neo4j::Bolt::Cxn> is a container for a Bolt connection, instantiated by
a call to C<< Neo4j::Bolt->connect() >>.

=head1 METHODS

=over

=item connected()

True if server connected successfully. If not, see L</"errnum()"> and
L</"errmsg()">.

=item protocol_version()

Returns a string representing the major and minor Bolt protocol version of the 
server, as "<major>.<minor>", or the empty string if not connected.

=item run_query($cypher_query, [$param_hash], [$db_name])

Run a L<Cypher|https://neo4j.com/docs/cypher-manual/current/> query on
the server. Returns a L<Neo4j::Bolt::ResultStream> which can be iterated
to retrieve query results as Perl types and structures. [$param_hash]
is an optional hashref of the form C<{ param =E<gt> $value, ... }>.
If C<$db_name> is not given, the value of the global variable
C<$Neo4j::Bolt::DEFAULT_DB> will be used instead.

=item send_query($cypher_query, [$param_hash], [$db_name])

Send a L<Cypher|https://neo4j.com/docs/cypher-manual/current/> query to
the server. All results (except error info) are discarded.

=item do_query($cypher_query, [$param_hash], [$db_name])

  ($stream, @rows) = do_query($cypher_query);
  $stream = do_query($cypher_query, $param_hash);

Run a L<Cypher|https://neo4j.com/docs/cypher-manual/current/> query on
the server, and iterate the stream to retrieve all result
rows. C<do_query> is convenient for running write queries (e.g.,
C<CREATE (a:Bloog {prop1:"blarg"})> ), since it returns the $stream
with L<Neo4j::Bolt::ResultStream/update_counts> ready for reading.

=item reset_cxn()

Send a RESET message to the Neo4j server. According to the L<Bolt
protocol|https://boltprotocol.org/v1/>, this should force any currently
processing query to abort, forget any pending queries, clear any
failure state, dispose of outstanding result records, and roll back
the current transaction.

=item errnum(), errmsg()

Current error state of the connection. If

 $cxn->connected == $cxn->errnum == 0

then you have a virgin Cxn object that came from someplace other than
C<< Neo4j::Bolt->connect() >>, which would be weird.

=item server_id()

 print $cxn->server_id;  # "Neo4j/3.3.9"

Get the server ID string, including the version number. C<undef> if
connecting wasn't successful or the server didn't identify itself.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Bolt::ResultStream>.

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
