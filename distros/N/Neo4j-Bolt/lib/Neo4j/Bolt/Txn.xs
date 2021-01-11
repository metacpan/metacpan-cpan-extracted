#include "perlbolt.h"
#include "ingyINLINE.h"

#include <errno.h>
#include <string.h>
#include <stdio.h>
#include "connection.h"
#include "transaction.h"

void new_txn_obj( txn_obj_t **txn_obj) {
  Newx(*txn_obj,1,txn_obj_t);
  (*txn_obj)->tx = NULL;
  (*txn_obj)->errnum = 0;
  (*txn_obj)->strerror = "";
  return;
}

// class method
SV *begin_( const char* classname, SV *cxn_ref, int tx_timeout, const char *mode, const char *dbname) {
  txn_obj_t *txn_obj;
  char *climsg;
  new_txn_obj(&txn_obj);
  cxn_obj_t *cxn_obj = C_PTR_OF(cxn_ref, cxn_obj_t);
  neo4j_transaction_t *tx = neo4j_begin_tx(cxn_obj->connection, tx_timeout,
                                             mode, dbname);

  txn_obj->tx = tx;
  if (tx == NULL) {
    txn_obj->errnum = errno;
    Newx(climsg, BUFLEN, char);
    txn_obj->strerror = neo4j_strerror(errno,climsg,BUFLEN);
  }
  SV *txn = newSViv((IV) txn_obj);
  SV *txn_ref = newRV_noinc(txn);
  sv_bless(txn_ref, gv_stashpv(TXNCLASS, GV_ADD));
  SvREADONLY_on(txn);
  return txn_ref;
}

int commit_(SV *txn_ref) {
  txn_obj_t *t = C_PTR_OF(txn_ref,txn_obj_t);
  int i = -1;
  if (neo4j_tx_is_open(t->tx)) {
    i =  neo4j_commit( t->tx );
  }
  return i;
}

int rollback_(SV *txn_ref) {
  txn_obj_t *t = C_PTR_OF(txn_ref,txn_obj_t);
  int i = -1;
  if (neo4j_tx_is_open(t->tx)) {
    i =  neo4j_rollback( t->tx );
  }
  return i;
}

SV *run_query_(SV *txn_ref, const char *cypher_query, SV *params_ref, int send) {
  neo4j_result_stream_t *res_stream;
  txn_obj_t *txn_obj;
  neo4j_transaction_t *tx;
  rs_obj_t *rs_obj;
  const char *evalerr, *evalmsg;
  char *climsg;
  char *s, *t;
  int fail;
  SV *rs;
  SV *rs_ref;
  neo4j_value_t params_p;

  new_rs_obj(&rs_obj);
  // extract transaction
  txn_obj = C_PTR_OF(txn_ref,txn_obj_t);
  tx = txn_obj->tx;
  // check tx state: TODO
  // extract params
  if (SvROK(params_ref) && (SvTYPE(SvRV(params_ref))==SVt_PVHV)) {
    params_p = SV_to_neo4j_value(params_ref);
  }
  else {
    perror("Parameter arg must be a hash reference\n");
    return &PL_sv_undef;
  }
  res_stream = (send >= 1 ?
		neo4j_send_to_tx(tx, cypher_query, params_p) :
		neo4j_run_in_tx(tx, cypher_query, params_p));
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

int errnum_(SV *txn_ref) {
  return C_PTR_OF(txn_ref,txn_obj_t)->errnum;
}

const char *errmsg_(SV *txn_ref) {
  return C_PTR_OF(txn_ref,txn_obj_t)->strerror;
}


MODULE = Neo4j::Bolt::Txn  PACKAGE = Neo4j::Bolt::Txn  

PROTOTYPES: DISABLE


SV *
begin_ (classname, cxn_ref, tx_timeout, mode, dbname)
	const char *	classname
	SV *	cxn_ref
	int	tx_timeout
	const char *	mode
	const char *	dbname

int
commit_ (txn_ref)
	SV *	txn_ref

int
rollback_ (txn_ref)
	SV *	txn_ref

SV *
run_query_ (txn_ref, cypher_query, params_ref, send)
	SV *	txn_ref
	const char *	cypher_query
	SV *	params_ref
	int	send

int
errnum_ (txn_ref)
	SV *	txn_ref

const char *
errmsg_ (txn_ref)
	SV *	txn_ref

