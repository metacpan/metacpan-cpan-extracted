package Neo4j::Bolt::Cxn;
use Neo4j::Client;

BEGIN {
  our $VERSION = "0.20";
  require Neo4j::Bolt::TypeHandlersC;
}
# use Inline 'global';
use Inline P => Config => LIBS => $Neo4j::Client::LIBS,
  INC => $Neo4j::Client::CCFLAGS,
  version => $VERSION,
  name => __PACKAGE__;
  
use Inline P => <<'END_BOLT_CXN_C';
#include <neo4j-client.h>
#include <errno.h>
#define RSCLASS  "Neo4j::Bolt::ResultStream"
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))
#define BUFLEN 100

neo4j_value_t SV_to_neo4j_value(SV *sv);


struct cxn_obj {
  neo4j_connection_t *connection;
  int connected;
  int errnum;
  const char *strerror;
};

typedef struct cxn_obj cxn_obj_t;

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
int update_errstate_rs_obj (rs_obj_t *rs_obj);
void reset_errstate_rs_obj (rs_obj_t *rs_obj);

void new_rs_uc( struct neo4j_update_counts **uc) {
  Newx(*uc, 1, struct neo4j_update_counts);
  (*uc)->nodes_created=0;
  (*uc)->nodes_deleted=0;
  (*uc)->relationships_created=0;
  (*uc)->relationships_deleted=0;
  (*uc)->properties_set=0;
  (*uc)->labels_added=0;
  (*uc)->labels_removed=0;
  (*uc)->indexes_added=0;
  (*uc)->indexes_removed=0;
  (*uc)->constraints_added=0;
  (*uc)->constraints_removed=0;
  return;
}

void new_rs_stats( rs_stats_t **stats ) {
  struct neo4j_update_counts *uc;
  new_rs_uc(&uc);
  Newx(*stats, 1, rs_stats_t);
  (*stats)->result_count = 0;
  (*stats)->available_after = 0;
  (*stats)->consumed_after = 0;
  (*stats)->update_counts = uc;
  return;
}

void new_rs_obj (rs_obj_t **rs_obj) {
  rs_stats_t *stats;
  Newx(*rs_obj, 1, rs_obj_t);
  new_rs_stats(&stats);
  (*rs_obj)->succeed = -1;  
  (*rs_obj)->fail = -1;  
  (*rs_obj)->fetched = 0;
  (*rs_obj)->failure_details = (struct neo4j_failure_details *) NULL;
  (*rs_obj)->stats = stats;
  (*rs_obj)->eval_errcode = "";
  (*rs_obj)->eval_errmsg = "";
  (*rs_obj)->errnum = 0;
  (*rs_obj)->strerror = "";
  return;
}

void reset_errstate_rs_obj (rs_obj_t *rs_obj) {
  rs_obj->succeed = -1;  
  rs_obj->fail = -1;  
  rs_obj->failure_details = (struct neo4j_failure_details *) NULL;
  rs_obj->eval_errcode = "";
  rs_obj->eval_errmsg = "";
  rs_obj->errnum = 0;
  rs_obj->strerror = "";
  return;
}

int update_errstate_rs_obj (rs_obj_t *rs_obj) {
  const char *evalerr, *evalmsg;
  char *climsg;
  char *s, *t;
  int fail;
  fail = neo4j_check_failure(rs_obj->res_stream);
  if (fail) {
    rs_obj->succeed = 0;
    rs_obj->fail = 1;
    rs_obj->fetched = -1;
    rs_obj->errnum = fail;
    Newx(climsg, BUFLEN, char);
    rs_obj->strerror = neo4j_strerror(fail, climsg, BUFLEN);
    if (fail == NEO4J_STATEMENT_EVALUATION_FAILED) {
      rs_obj->failure_details = neo4j_failure_details(rs_obj->res_stream);
      evalerr = neo4j_error_code(rs_obj->res_stream);
      Newx(s, strlen(evalerr)+1,char);
      rs_obj->eval_errcode = strcpy(s,evalerr);
      evalmsg = neo4j_error_message(rs_obj->res_stream);
      Newx(t, strlen(evalmsg)+1,char);
      rs_obj->eval_errmsg = strcpy(t,evalmsg);
    }
  }
  else {
    rs_obj->succeed = 1;
    rs_obj->fail = 0;
  }
  return fail;
}

SV *run_query_( SV *cxn_ref, const char *cypher_query, SV *params_ref, int send)
{
  neo4j_result_stream_t *res_stream;
  cxn_obj_t *cxn_obj;
  rs_obj_t *rs_obj;
  const char *evalerr, *evalmsg;
  char *climsg;
  char *s, *t;
  int fail;
  SV *rs;
  SV *rs_ref;
  neo4j_connection_t *cxn;
  neo4j_value_t params_p;
  
  new_rs_obj(&rs_obj);
  // extract connection
  cxn_obj = C_PTR_OF(cxn_ref,cxn_obj_t);
  if (!cxn_obj->connected) {
    cxn_obj->errnum = ENOTCONN;
    cxn_obj->strerror = "Not connected";
    return &PL_sv_undef;    
  }

  // extract params
  if (SvROK(params_ref) && (SvTYPE(SvRV(params_ref))==SVt_PVHV)) {
    params_p = SV_to_neo4j_value(params_ref);
  }
  else {
    perror("Parameter arg must be a hash reference\n");
    return &PL_sv_undef;
  }
  res_stream = (send >= 1 ?
                neo4j_send(cxn_obj->connection, cypher_query, params_p) :
                neo4j_run(cxn_obj->connection, cypher_query, params_p));
  rs_obj->res_stream = res_stream;
  fail = update_errstate_rs_obj(rs_obj);
  if (send >= 1) {
    rs_obj->fetched = 1;
  }
  rs = newSViv((IV) rs_obj);
  rs_ref = newRV_noinc(rs);
  sv_bless(rs_ref, gv_stashpv(RSCLASS, GV_ADD));
  SvREADONLY_on(rs);
  return rs_ref;
}

int connected(SV *cxn_ref) {
  return C_PTR_OF(cxn_ref,cxn_obj_t)->connected;
}

int errnum_(SV *cxn_ref) {
  return C_PTR_OF(cxn_ref,cxn_obj_t)->errnum;
}

const char *errmsg_(SV *cxn_ref) {
  return C_PTR_OF(cxn_ref,cxn_obj_t)->strerror;
}

void reset_ (SV *cxn_ref)
{
  int rc;
  char *climsg;
  cxn_obj_t *cxn_obj;
  cxn_obj = C_PTR_OF(cxn_ref,cxn_obj_t);
  rc = neo4j_reset( cxn_obj->connection );
  if (rc < 0) {
    cxn_obj->errnum = errno;
    Newx(climsg, BUFLEN, char);
    cxn_obj->strerror = neo4j_strerror(errno, climsg, BUFLEN);
  } 
  return;
}

const char *server_id_(SV *cxn_ref) {
  return neo4j_server_id( C_PTR_OF(cxn_ref,cxn_obj_t)->connection );
}

void DESTROY (SV *cxn_ref)
{
  neo4j_close( C_PTR_OF(cxn_ref,cxn_obj_t)->connection );
  return;
}

END_BOLT_CXN_C

sub errnum { shift->errnum_ }
sub errmsg { shift->errmsg_ }
sub reset_cxn { shift->reset_ }

sub server_id { shift->server_id_ }

sub run_query {
  my $self = shift;
  my ($query, $parms) = @_;
  unless ($query) {
    die "Arg 1 should be Cypher query string";
  }
  if ($parms && !(ref $parms == 'HASH')) {
    die "Arg 2 should be a hashref of { param => $value, ... }";
  }
  return $self->run_query_($query, $parms ? $parms : {}, 0);
}

sub send_query {
  my $self = shift;
  my ($query, $parms) = @_;
  unless ($query) {
    die "Arg 1 should be Cypher query string";
  }
  if ($parms && !(ref $parms == 'HASH')) {
    die "Arg 2 should be a hashref of { param => $value, ... }";
  }
  return $self->run_query_($query, $parms ? $parms : {}, 1);
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
   print STDERR "Problem connecting: ".$cxn->errmsg;
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

=item run_query($cypher_query, [$param_hash])

Run a L<Cypher|https://neo4j.com/docs/cypher-manual/current/> query on
the server. Returns a L<Neo4j::Bolt::ResultStream> which can be iterated
to retrieve query results as Perl types and structures. [$param_hash]
is an optional hashref of the form C<{ param =E<gt> $value, ... }>.

=item send_query($cypher_query, [$param_hash])

Send a L<Cypher|https://neo4j.com/docs/cypher-manual/current/> query to
the server. All results (except error info) are discarded.

=item do_query($cypher_query, [$param_hash])

  ($stream, @rows) = do_query($cypher_query);
  $stream = do_query($cypher_query, $param_hash);

Run a L<Cypher|https://neo4j.com/docs/cypher-manual/current/> query on
the server, and iterate the stream to retrieve all result
rows. C<do_query> is convenient for running write queries (e.g.,
C<CREATE (a:Bloog {prop1:"blarg"})> ), since it returns the $stream
with L<Neo4j::Bolt::ResultStream/update_counts> ready for reading.


=item run_query_( $cypher_query, $param_hash, $send )

Run a L<Cypher|https://neo4j.com/docs/cypher-manual/current/> query on
the server. Returns a L<Neo4j::Bolt::ResultStream> which can be iterated
to retrieve query results as Perl types and structures. C<$param_hash> is
a hashref of the form C<< { param => $value, ... } >>. If there are no params
to be set, use C<{}>. 

If C<$send> is 1, run_query_ will simply send the query and discard
any results (including query stats). Set C<$send> to 0 and follow up
with L<Neo4j::Bolt::ResultStream/fetch_next_()> to retrieve results.

Easier to use C<run_query>, C<send_query>, C<do_query>.

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

This software is Copyright (c) 2019-2020 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

1;
