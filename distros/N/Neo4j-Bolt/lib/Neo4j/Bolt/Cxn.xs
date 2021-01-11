#include "perlbolt.h"
#include "ingyINLINE.h"

#include <errno.h>
#include <stdio.h>
#include "connection.h"

SV *run_query_( SV *cxn_ref, const char *cypher_query, SV *params_ref, int send, const char *dbname)
{
  neo4j_result_stream_t *res_stream;
  cxn_obj_t *cxn_obj;
  neo4j_connection_t *cxn;
  rs_obj_t *rs_obj;
  const char *evalerr, *evalmsg;
  char *climsg;
  char *s, *t;
  int fail;
  SV *rs;
  SV *rs_ref;
  neo4j_value_t params_p;

  new_rs_obj(&rs_obj);
  // extract connection
  cxn_obj = C_PTR_OF(cxn_ref,cxn_obj_t);
  if (!cxn_obj->connected) {
    cxn_obj->errnum = ENOTCONN;
    cxn_obj->strerror = "Not connected";
    return &PL_sv_undef;
  }
  cxn = cxn_obj->connection;
  
  // extract params
  if (SvROK(params_ref) && (SvTYPE(SvRV(params_ref))==SVt_PVHV)) {
    params_p = SV_to_neo4j_value(params_ref);
  }
  else {
    perror("Parameter arg must be a hash reference\n");
    return &PL_sv_undef;
  }
  if (cxn->version < 4)
  {
      res_stream = (send >= 1 ?
		    neo4j_send(cxn, cypher_query, params_p) :
		    neo4j_run(cxn, cypher_query, params_p));
  }
  else
  {
      res_stream = (send >= 1 ?
		    neo4j_send_to_db(cxn, cypher_query, params_p, dbname) :
		    neo4j_run_in_db(cxn, cypher_query, params_p, dbname));
  }
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

bool connected(SV *cxn_ref) {
  return C_PTR_OF(cxn_ref,cxn_obj_t)->connected;
}

int errnum_(SV *cxn_ref) {
  return C_PTR_OF(cxn_ref,cxn_obj_t)->errnum;
}

const char *errmsg_(SV *cxn_ref) {
    return (const char *)  C_PTR_OF(cxn_ref,cxn_obj_t)->strerror;
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
    cxn_obj->strerror = neo4j_strerror(errno, climsg, BUFLEN-1);
  }
  return;
}

const char *server_id_(SV *cxn_ref) {
  return neo4j_server_id( C_PTR_OF(cxn_ref,cxn_obj_t)->connection );
}

const char *protocol_version_(SV *cxn_ref) {
    if (C_PTR_OF(cxn_ref,cxn_obj_t)->connected)
    {
	uint32_t V = C_PTR_OF(cxn_ref,cxn_obj_t)->major_version;
	uint32_t v = C_PTR_OF(cxn_ref,cxn_obj_t)->minor_version;
	char *vstr;
	Newx(vstr, 32, char);
	snprintf(vstr, 32, "%d.%d",(int)V,(int)v);
	return vstr;
    }
    else {
	return "";
    }
}

void DESTROY (SV *cxn_ref)
{
  neo4j_close( C_PTR_OF(cxn_ref,cxn_obj_t)->connection );
  return;
}


MODULE = Neo4j::Bolt::Cxn  PACKAGE = Neo4j::Bolt::Cxn  

PROTOTYPES: DISABLE


SV *
run_query_ (cxn_ref, cypher_query, params_ref, send, dbname)
	SV *	cxn_ref
	const char *	cypher_query
	SV *	params_ref
	int	send
        const char *    dbname

int
connected (cxn_ref)
	SV *	cxn_ref

int
errnum_ (cxn_ref)
	SV *	cxn_ref

const char *
errmsg_ (cxn_ref)
	SV *	cxn_ref

void
reset_ (cxn_ref)
	SV *	cxn_ref
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        reset_(cxn_ref);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

const char *
server_id_ (cxn_ref)
	SV *	cxn_ref

const char *
protocol_version_ (cxn_ref)
        SV *    cxn_ref

void
DESTROY (cxn_ref)
	SV *	cxn_ref
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(cxn_ref);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

