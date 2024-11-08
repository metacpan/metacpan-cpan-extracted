#include "perlbolt.h"
#include <stdio.h>

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
  (*rs_obj)->eval_errcode = savepvs("");
  (*rs_obj)->eval_errmsg = savepvs("");
  (*rs_obj)->errnum = 0;
  (*rs_obj)->strerror = 0;
  return;
}

void reset_errstate_rs_obj (rs_obj_t *rs_obj) {
  Safefree(rs_obj->eval_errcode);
  Safefree(rs_obj->eval_errmsg);
  Safefree(rs_obj->strerror);
  rs_obj->succeed = -1;  
  rs_obj->fail = -1;  
  rs_obj->failure_details = (struct neo4j_failure_details *) NULL;
  rs_obj->eval_errcode = savepvs("");
  rs_obj->eval_errmsg = savepvs("");
  rs_obj->errnum = 0;
  rs_obj->strerror = 0;
  return;
}

int update_errstate_rs_obj (rs_obj_t *rs_obj) {
  char climsg[BUFLEN];
  int fail;
  fail = neo4j_check_failure(rs_obj->res_stream);
  if (fail != 0) {
    rs_obj->succeed = 0;
    rs_obj->fail = 1;
    rs_obj->fetched = -1;
    rs_obj->errnum = fail;
    Safefree(rs_obj->strerror);
    rs_obj->strerror = savepv( neo4j_strerror(fail, climsg, sizeof(climsg)) );
    if (fail == NEO4J_STATEMENT_EVALUATION_FAILED) {
      rs_obj->failure_details = neo4j_failure_details(rs_obj->res_stream);
      Safefree(rs_obj->eval_errcode);
      Safefree(rs_obj->eval_errmsg);
      rs_obj->eval_errcode = savepv( rs_obj->failure_details->code );
      rs_obj->eval_errmsg  = savepv( rs_obj->failure_details->message );
    }
  }
  else {
    rs_obj->succeed = 1;
    rs_obj->fail = 0;
    Safefree(rs_obj->strerror);
    rs_obj->strerror = savepvs("");
  }
  return fail;
}

MODULE = Neo4j::Bolt::CResultStream  PACKAGE = Neo4j::Bolt::CResultStream

PROTOTYPES: DISABLE
