#include "perlbolt.h"
#include "ingyINLINE.h"

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
    Inline_Stack_Push( sv_2mortal(perl_value) );
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

SV *get_failure_details(SV *rs_ref) {
    rs_obj_t *rs_obj = C_PTR_OF(rs_ref,rs_obj_t);
    neo4j_result_stream_t *rs = rs_obj->res_stream;
    const struct neo4j_failure_details *faild = neo4j_failure_details(rs_obj->res_stream);
//    if (faild->line == 0)
//    {
//	return &PL_sv_undef;
//    }
    HV *hv = newHV();
    // UTF-8 issues here? need SvUTF8_on(pv)?
    hv_stores(hv, "code", newSVpv(faild->code,0));
    hv_stores(hv, "message", newSVpv(faild->message,0));
    hv_stores(hv, "description", newSVpv(faild->description,0));
    hv_stores(hv, "context", newSVpv(faild->context,0));
    hv_stores(hv, "line", newSViv( (IV) faild->line ));
    hv_stores(hv, "column", newSViv( (IV) faild->column ));
    hv_stores(hv, "offset", newSViv( (IV) faild->offset ));
    hv_stores(hv, "context_offset", newSViv( (IV) faild->context_offset ));
    SV* sv = newRV_noinc( (SV*)hv );
    SvREADONLY_on(sv);
    return sv;
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

  mXPUSHu( (const UV) uc->nodes_created );
  mXPUSHu( (const UV) uc->nodes_deleted );
  mXPUSHu( (const UV) uc->relationships_created );
  mXPUSHu( (const UV) uc->relationships_deleted );
  mXPUSHu( (const UV) uc->properties_set );
  mXPUSHu( (const UV) uc->labels_added );
  mXPUSHu( (const UV) uc->labels_removed );
  mXPUSHu( (const UV) uc->indexes_added );
  mXPUSHu( (const UV) uc->indexes_removed );
  mXPUSHu( (const UV) uc->constraints_added );
  mXPUSHu( (const UV) uc->constraints_removed );
  Inline_Stack_Done;
  return;
}

void DESTROY (SV *rs_ref) {
  rs_obj_t *rs_obj;
  rs_obj = C_PTR_OF(rs_ref,rs_obj_t);
  neo4j_close_results(rs_obj->res_stream);
  Safefree(rs_obj->eval_errcode);
  Safefree(rs_obj->eval_errmsg);
  Safefree(rs_obj->strerror);
  Safefree(rs_obj->stats->update_counts);
  Safefree(rs_obj->stats);
  Safefree(rs_obj);
  return;
}


MODULE = Neo4j::Bolt::ResultStream  PACKAGE = Neo4j::Bolt::ResultStream  

PROTOTYPES: DISABLE


void
fetch_next_ (rs_ref)
	SV *	rs_ref
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fetch_next_(rs_ref);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
nfields_ (rs_ref)
	SV *	rs_ref

void
fieldnames_ (rs_ref)
	SV *	rs_ref
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fieldnames_(rs_ref);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
success_ (rs_ref)
	SV *	rs_ref

int
failure_ (rs_ref)
	SV *	rs_ref

int
client_errnum_ (rs_ref)
	SV *	rs_ref

const char *
server_errcode_ (rs_ref)
	SV *	rs_ref

const char *
server_errmsg_ (rs_ref)
	SV *	rs_ref

const char *
client_errmsg_ (rs_ref)
	SV *	rs_ref

UV
result_count_ (rs_ref)
	SV *	rs_ref

UV
available_after_ (rs_ref)
	SV *	rs_ref

UV
consumed_after_ (rs_ref)
	SV *	rs_ref

SV *
get_failure_details (rs_ref)
        SV *    rs_ref

void
update_counts_ (rs_ref)
	SV *	rs_ref
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        update_counts_(rs_ref);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
DESTROY (rs_ref)
	SV *	rs_ref
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(rs_ref);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

