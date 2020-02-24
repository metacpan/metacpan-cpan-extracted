package Neo4j::Bolt::ResultStream;
BEGIN {
  our $VERSION = "0.11";
  require Neo4j::Bolt::Cxn;
  eval 'require Neo4j::Bolt::Config; 1';
}
use Inline C => Config =>
  LIBS => $Neo4j::Bolt::Config::extl,
  INC => $Neo4j::Bolt::Config::extc,  
  version => $VERSION,
  name => __PACKAGE__;


use Inline C => <<'END_BOLT_RS_C';
#include <neo4j-client.h>
#define RSCLASS  "Neo4j::Bolt::ResultStream"
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))
#define BUFLEN 100

SV* neo4j_value_to_SV( neo4j_value_t value);

struct rs_stats {
  unsigned long long result_count;
  unsigned long long available_after;
  unsigned long long consumed_after;
  struct neo4j_update_counts *update_counts;
};

typedef struct rs_stats rs_stats_t;

struct rs_obj {
  neo4j_result_stream_t *res_stream;
  int succeed;
  int fail;
  int fetched;
  const struct neo4j_failure_details *failure_details;
  rs_stats_t *stats;
  char *eval_errcode;
  char *eval_errmsg;
  int errnum;
  const char *strerror;
};

typedef struct rs_obj rs_obj_t;

void new_rs_obj (rs_obj_t **rs_obj);
void reset_errstate_rs_obj (rs_obj_t *rs_obj);
int update_errstate_rs_obj (rs_obj_t *rs_obj);

void fetch_next_ (SV *rs_ref) {
  SV *perl_value;
  rs_obj_t *rs_obj;
  neo4j_result_t *result;
  neo4j_result_stream_t *rs;
  neo4j_value_t value;
  struct neo4j_update_counts cts;
  int i,n,fail;
  Inline_Stack_Vars;
  Inline_Stack_Reset;

  rs_obj = C_PTR_OF(rs_ref,rs_obj_t);
  if (rs_obj->fetched == 1) {
    Inline_Stack_Done;
    return;
  }
  reset_errstate_rs_obj(rs_obj);

  rs = rs_obj->res_stream;
  n = neo4j_nfields(rs);
  if (!n) {
    fail = update_errstate_rs_obj(rs_obj);
    if (fail) {
      Inline_Stack_Done;
      return;
    }
  }  
  result = neo4j_fetch_next(rs);
  if (result == NULL) {
    if (errno) {
      fail = update_errstate_rs_obj(rs_obj);
    } else {
      rs_obj->fetched = 1;
      // collect stats
      cts = neo4j_update_counts(rs);
      rs_obj->stats->result_count = neo4j_result_count(rs);
      rs_obj->stats->available_after = neo4j_results_available_after(rs);
      rs_obj->stats->consumed_after = neo4j_results_consumed_after(rs);
      memcpy(rs_obj->stats->update_counts, &cts, sizeof(struct neo4j_update_counts));
    }
    Inline_Stack_Done;
    return;
  }
  for (i=0; i<n; i++) {
    value = neo4j_result_field(result, i);
    perl_value = neo4j_value_to_SV(value);
    Inline_Stack_Push( perl_value );
  }
  Inline_Stack_Done;
  return;
}

int nfields_(SV *rs_ref) {
  return neo4j_nfields( C_PTR_OF(rs_ref,rs_obj_t)->res_stream );
}

void fieldnames_ (SV *rs_ref) {
  neo4j_result_stream_t *rs;
  int nfields;
  int i;
  rs = C_PTR_OF(rs_ref,rs_obj_t)->res_stream;
  nfields = neo4j_nfields(rs);
  Inline_Stack_Vars;
  Inline_Stack_Reset;
  for (i = 0; i < nfields; i++) 
    Inline_Stack_Push(sv_2mortal(newSVpv(neo4j_fieldname(rs,i),0)));
  Inline_Stack_Done;
  return;
}

int success_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->succeed;
}
int failure_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->fail;
}
int client_errnum_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->errnum;
}
const char *server_errcode_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->eval_errcode;
}
const char *server_errmsg_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->eval_errmsg;
}
const char *client_errmsg_ (SV *rs_ref) {
 return C_PTR_OF(rs_ref,rs_obj_t)->strerror;
}

UV result_count_ (SV *rs_ref) {
 if (C_PTR_OF(rs_ref,rs_obj_t)->fetched == 1) {
   return C_PTR_OF(rs_ref,rs_obj_t)->stats->result_count;
 } else {
   return 0;
 }
}
UV available_after_ (SV *rs_ref) {
 if (C_PTR_OF(rs_ref,rs_obj_t)->fetched == 1) {
   return C_PTR_OF(rs_ref,rs_obj_t)->stats->available_after;
 } else {
   return 0;
 }
}
UV consumed_after_ (SV *rs_ref) {
 if (C_PTR_OF(rs_ref,rs_obj_t)->fetched == 1) {
   return C_PTR_OF(rs_ref,rs_obj_t)->stats->consumed_after;
 } else {
   return 0;
 }
}

void update_counts_ (SV *rs_ref) {
  struct neo4j_update_counts *uc;
  Inline_Stack_Vars;
  Inline_Stack_Reset;
  if (C_PTR_OF(rs_ref,rs_obj_t)->fetched != 1) {
    Inline_Stack_Done;
    return;
  }
  uc = C_PTR_OF(rs_ref,rs_obj_t)->stats->update_counts;

  Inline_Stack_Push( newSViv( (const UV) uc->nodes_created ));
  Inline_Stack_Push( newSViv( (const UV) uc->nodes_deleted ));
  Inline_Stack_Push( newSViv( (const UV) uc->relationships_created ));
  Inline_Stack_Push( newSViv( (const UV) uc->relationships_deleted ));
  Inline_Stack_Push( newSViv( (const UV) uc->properties_set ));
  Inline_Stack_Push( newSViv( (const UV) uc->labels_added ));
  Inline_Stack_Push( newSViv( (const UV) uc->labels_removed ));
  Inline_Stack_Push( newSViv( (const UV) uc->indexes_added ));
  Inline_Stack_Push( newSViv( (const UV) uc->indexes_removed ));
  Inline_Stack_Push( newSViv( (const UV) uc->constraints_added ));
  Inline_Stack_Push( newSViv( (const UV) uc->constraints_removed ));
  Inline_Stack_Done;
  return;
}

void DESTROY (SV *rs_ref) {
  rs_obj_t *rs_obj;
  rs_obj = C_PTR_OF(rs_ref,rs_obj_t);
  neo4j_close_results(rs_obj->res_stream);
  Safefree(rs_obj->stats->update_counts);
  Safefree(rs_obj->stats);
  Safefree(rs_obj);
  return;
}

END_BOLT_RS_C

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

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Bolt::Cxn>.

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE

This software is Copyright (c) 2019-2020 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

1;
