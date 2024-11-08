#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <neo4j-client.h>

#define RSCLASS  "Neo4j::Bolt::ResultStream"
#define TXNCLASS  "Neo4j::Bolt::Txn"
#define CXNCLASS "Neo4j::Bolt::Cxn"
#define NODE_CLASS "Neo4j::Bolt::Node"
#define RELATIONSHIP_CLASS "Neo4j::Bolt::Relationship"
#define PATH_CLASS "Neo4j::Bolt::Path"
#define DATETIME_CLASS "Neo4j::Bolt::DateTime"
#define DURATION_CLASS "Neo4j::Bolt::Duration"
#define POINT_CLASS "Neo4j::Bolt::Point"
#define BUFLEN 256

#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))
#define ignore_unused_result(func) if (func) { }
#define value_to_blessed_sv(the_value,the_func,THE_CLASS) (sv_bless(newRV_noinc((SV*) the_func(the_value)),gv_stashpv(THE_CLASS,GV_ADD)))
#define neo4j_type_svpv(the_value) newSVpv(neo4j_typestr(neo4j_type(the_value)),0)

struct cxn_obj {
  neo4j_connection_t *connection;
  bool connected;
  int major_version;
  int minor_version;
  int errnum;
  const char *strerror;
};

typedef struct cxn_obj cxn_obj_t;

struct txn_obj {
  neo4j_transaction_t *tx;
  int errnum;
  const char* strerror;
};

typedef struct txn_obj txn_obj_t;

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

// type handler fns

neo4j_value_t SV_to_neo4j_value(SV *sv);
SV *neo4j_value_to_SV(neo4j_value_t value);

// result stream fns

void new_rs_obj (rs_obj_t **rs_obj);
void reset_errstate_rs_obj (rs_obj_t *rs_obj);
int update_errstate_rs_obj (rs_obj_t *rs_obj);
void new_rs_uc( struct neo4j_update_counts **uc);
void new_rs_stats( rs_stats_t **stats );

// connection fn

void new_cxn_obj(cxn_obj_t **cxn_obj);

