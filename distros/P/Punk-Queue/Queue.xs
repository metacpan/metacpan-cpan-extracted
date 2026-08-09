/*
 * Queue.xs - root XS file
 *
 * Thin wrapper: resolves the File::Raw::JSON C ABI, includes the C
 * implementation headers in strict dependency order, then pulls in the
 * per-package XS fragments from xs/ via INCLUDE: (the Punk / Chandra /
 * Open::API layout).
 *
 * The headers below are implementation headers full of static functions,
 * not an interface. The public C contract is include/pq_abi.h, which
 * arrives in phase 7 once these have stopped moving.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pq_compat.h"          /* perl shims + the croaking allocators;
                                 * must precede every other pq_ header    */

#include "frj_abi.h"            /* File::Raw::JSON's ABI, via EU::Depends */
#include "pq_frj.h"             /* ...and the lazy resolver for it        */

#include "pq_time.h"            /* epoch seconds + the clock delta        */
#include "pq_sql.h"             /* statement assembly, the name rules     */
#include "pq_dbi.h"             /* the pooled DBI seam                    */
#include "pq_job.h"             /* the job column list and row decode     */
#include "pq_log.h"             /* per-job log lines                      */
#include "pq_claim.h"           /* the claim parts both backends share    */
#include "pq_migrate.h"         /* the migration runner                   */
#include "pq_migrate_sqlite.h"  /* the SQLite schema                      */
#include "pq_migrate_pg.h"      /* the PostgreSQL schema                  */
#include "pq_sqlite.h"          /* the SQLite divergences                 */
#include "pq_pg.h"              /* the PostgreSQL divergences             */
#include "pq_backend.h"         /* shared ops + per-driver dispatch       */
#include "pq_lock.h"            /* the two lock disciplines               */
#include "pq_repair.h"          /* broadcast/receive + the repair passes  */
#include "hm_abi.h"             /* Hyperman's ABI, vendored (soft dep)    */
#include "pq_hm.h"              /* ...and the optional lazy resolver      */
#include "pq_queue.h"           /* the Punk::Queue front (needs pq_hm:
                                 * perform's timeout layers pick alarm or
                                 * a loop timer by whether a loop is live) */
#include "pq_cron.h"            /* the cron parser + next-occurrence walk */
#include "pq_sched.h"           /* cron storage + the leader tick         */
#include "pq_worker.h"          /* the worker child state machine         */
#include "pq_inserver.h"        /* the in-server claim tick (web workers) */
#include "pq_super.h"           /* the supervisor process pool            */

MODULE = Punk::Queue        PACKAGE = Punk::Queue

PROTOTYPES: DISABLE

INCLUDE: xs/queue.xs
INCLUDE: xs/backend.xs
INCLUDE: xs/backend_sqlite.xs
INCLUDE: xs/backend_pg.xs
INCLUDE: xs/job.xs
INCLUDE: xs/worker.xs
INCLUDE: xs/cron.xs
