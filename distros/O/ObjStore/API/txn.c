#include "osp-preamble.h"
#include "osperl.h"
#include "XSthr.h"

/* CCov: off */

void osp_croak(const char* pat, ...)
{
  dSP;
  SV *msg = NEWSV(0,0);
  va_list args;
//  perl_require_pv("Carp.pm");
  va_start(args, pat);
  sv_vsetpvfn(msg, pat, strlen(pat), &args, Null(SV**), 0, Null(bool*));
  va_end(args);
  SvREADONLY_on(msg);
  SAVEFREESV(msg);
  PUSHMARK(sp);
  XPUSHs(msg);
  PUTBACK;
  perl_call_pv("Carp::croak", G_DISCARD);
}

/* CCov: on */

/*--------------------------------------------- per-thread context */

/* CCov: off */

// Since perl_exception has no parent and is never signalled, we always
// get an unhandled exception when ObjectStore dies.
DEFINE_EXCEPTION(perl_exception,"Perl/ObjectStore Exception!",0);

// Constructor for our dynamically allocated tix_handler
dytix_handler::dytix_handler() : hand(&perl_exception) {}

static void ehook(tix_exception_p cause, os_int32 value, os_char_p report)
{
  dOSP;
  osp->cause = cause;
  osp->value = value;
  osp->report = report;
  Perl_sighandler(SIGSEGV);
}

/* CCov: on */

#define OSP_THR_SIGNATURE 0x4f535054
dXSTHRINIT(osp, new osp_thr, "ObjStore::ThreadInfo")

osp_thr *osp_thr::fetch()
{
  osp_thr *ret;
  XSTHRINFO(osp, ret);
//  assert(ret->signature == OSP_THR_SIGNATURE);
  return ret;
}

int osp_thr::DEBUG_schema()
{
  osp_thr *ret = fetch();
  if (ret->debug & 0x20000) return 1;
  SV *sv = perl_get_sv("ObjStore::REGRESS", 1);
  if (sv_true(sv)) return 1;
  return 0;
}

SV *osp_thr::stargate=0;
HV *osp_thr::CLASSLOAD;
HV *osp_thr::BridgeStash;
SV *osp_thr::TXGV;
AV *osp_thr::TXStack;

extern "C" XS(boot_ObjStore__CORE);

void osp_thr::boot()
{
  dSP; 
  int items; 
  XSTHRBOOT(osp);
  tix_exception::set_unhandled_exception_hook(ehook);
  HV *feat = perl_get_hv("ObjStore::FEATURE", 1);
  hv_store(feat, "bridge_trace", 12, boolSV(OSP_BRIDGE_TRACE), 0);
  hv_store(feat, "safe_bridge", 11, boolSV(OSP_SAFE_BRIDGE), 0);
  CLASSLOAD = perl_get_hv("ObjStore::CLASSLOAD", 1);
  BridgeStash = gv_stashpv("ObjStore::Bridge", 1);
  SvREFCNT_inc((SV*) BridgeStash);
  TXGV = (SV*) gv_stashpv("ObjStore::Transaction", 0);
  assert(TXGV);
  // SvREFCNT_inc(TXGV) ??
  TXStack = perl_get_av("ObjStore::Transaction::Stack", 1);
//  condpair_magic((SV*) TXStack); //init for later
  SvREADONLY_on(TXStack);

  newXS("ObjStore::CORE::boot2", boot_ObjStore__CORE, __FILE__);  // goofy XXX 
}

osp_thr::osp_thr()
  : ospv_freelist(0)
{
  // Fortunately, only Digital UNIX requires this for threads.
  //   (Windows NT & threads unsupported)
  // OS_ESTABLISH_FAULT_HANDLER;

  hand = new dytix_handler();
  signature = OSP_THR_SIGNATURE;
  debug = 0;
  report=0;
}

osp_thr::~osp_thr()
{
  ospv_bridge *br;
  while (br = (ospv_bridge*) ospv_freelist.next_self()) {
    delete br;
  }
  // OS_END_FAULT_HANDLER;
}

/*--------------------------------------------- per-transaction context */

osp_txn *osp_txn::current()
{
  if (av_len(osp_thr::TXStack) < 0) return 0;
  SV *sv = *av_fetch(osp_thr::TXStack, av_len(osp_thr::TXStack), 0);
  return (osp_txn*) typemap_any::decode(sv);
}

osp_txn::osp_txn(os_transaction::transaction_type_enum _tt,
		 os_transaction::transaction_scope_enum scope_in)
  : tt(_tt), ts(scope_in), link(0)
{
//  serial = next_txn++;
  os = os_transaction::begin(tt, scope_in);

  DEBUG_txn(warn("txn(%p)->new(%s, %s)", this,
		 tt==os_transaction::read_only? "read":
		 tt==os_transaction::update? "update":
		 tt==os_transaction::abort_only? "abort_only":
		 "unknown",
		 ts==os_transaction::local? "local":
		 ts==os_transaction::global? "global":
		 "unknown"));

  SV *myself = osp_thr::any_2sv(this, "ObjStore::Transaction");
  SvREADONLY_off(osp_thr::TXStack);
  av_push(osp_thr::TXStack, myself);
  SvREADONLY_on(osp_thr::TXStack);
}

/* CCov:off */
// EXPERIMENTAL
void osp_txn::prepare_to_commit()
{ assert(os); os->prepare_to_commit(); }
int osp_txn::is_prepare_to_commit_invoked()
{ assert(os); return os->is_prepare_to_commit_invoked(); }
int osp_txn::is_prepare_to_commit_completed()
{ assert(os); return os->is_prepare_to_commit_completed(); }
/* CCov:on */

void osp_txn::post_transaction()
{
/* After the transaction is complete, post_transaction() is called
   twice, before the eval unwinds and after. */

  DEBUG_txn(warn("%p->post_transaction", this));

  osp_bridge *br;
  while (br = (osp_bridge*) link.next_self()) {
    br->leave_txn();
    assert(br->link.empty());
  }
  assert(link.empty());
}

int osp_txn::can_update(os_database *db)
{
  return (os && !os->is_aborted() && tt != os_transaction::read_only && 
	  db && db->is_writable());
}

int osp_txn::can_update(void *vptr)
{
  if (!os || os->is_aborted() || tt == os_transaction::read_only) return 0;
  os_database *db = os_database::of(vptr);
  return db && db->is_writable();
}

int osp_txn::is_aborted()
{
  // returns true after commit? XXX
  return !os || os->is_aborted();
}

void osp_txn::abort()
{
  os_transaction *copy = os;
  os = 0;
  if (!copy) return;
  if (!copy->is_aborted()) {
    DEBUG_txn(warn("txn(%p)->abort", this));
    os_transaction::abort(copy);
  }
  delete copy;
  pop();
}

void osp_txn::commit()
{
  os_transaction *copy = os;
  os = 0;
  if (!copy) return;
  if (!copy->is_aborted()) {
    assert(link.empty());
    DEBUG_txn(warn("txn(%p)->commit", this));
    os_transaction::commit(copy);
  }
  delete copy;
  pop();
}

void osp_txn::pop()
{
  assert(os==0);
  SvREADONLY_off(osp_thr::TXStack);
  SV *myself = av_pop(osp_thr::TXStack);
  assert(myself != &PL_sv_undef);
  SvREADONLY_on(osp_thr::TXStack);
  post_transaction();
  SvREFCNT_dec(myself);
}

void osp_txn::checkpoint()
{
  if (!os)
    croak("ObjStore: no transaction to checkpoint");
  if (os->is_aborted())
    croak("ObjStore: cannot checkpoint an aborted transaction");
  assert(link.empty());
  os_transaction::checkpoint(os);
}

/*--------------------------------------------- osp_bridge */

IV osp_bridge::Instances=0;
IV osp_bridge::Inuse=0;
osp_ring osp_bridge::All(0);

osp_bridge::osp_bridge()
  : link(this)
#if OSP_BRIDGE_TRACE
     , al(this), where(0)
#endif
{
  ++Instances;
}

void osp_bridge::init(dynacast_fn dcfn)
{
  assert(link.empty());
  dynacast = dcfn;
  detached = 0;
  holding = 0;
  manual_hold = 0;
  refs = 1;
  txsv = 0;
  
#if OSP_BRIDGE_TRACE
  SvREFCNT_dec(where);
  dSP;
  PUSHSTACK;
  PUSHMARK(SP);
  XPUSHs(&PL_sv_no);
  perl_call_pv("Carp::longmess", G_SCALAR);
  SPAGAIN;
  where = SvREFCNT_inc(POPs);
  PUTBACK;
  POPSTACK;
  al.attach(All);
#endif
  ++Inuse;
}

void osp_bridge::cache_txsv()
{
  assert(av_len(osp_thr::TXStack) >= 0);
  txsv = SvREFCNT_inc(*av_fetch(osp_thr::TXStack,av_len(osp_thr::TXStack), 0));
}

osp_txn *osp_bridge::get_transaction()
{
  assert(txsv);
  osp_txn *txn = (osp_txn*) typemap_any::decode(txsv);
  if (!txn) {
    // should be impossible XXX
    warn("array:");
    Perl_sv_dump((SV*)osp_thr::TXStack);
    croak("Transaction null!  Race condition?");
  }
  return txn;
}

void osp_bridge::enter_txn(osp_txn *txn)
{
  mysv_lock(osp_thr::TXGV);
  // should be per-thread
  assert(link.empty());
  assert(txn);
  link.attach(txn->link);
  ++refs;
  //  DEBUG_bridge(this, warn("osp_bridge(%p)->enter_txn refs=%d link=%d",
  //			  this, refs, link.empty()));
}

void osp_bridge::leave_perl()
{
  DEBUG_bridge(this, warn("osp_bridge(%p)->leave_perl", this));
  --refs;
  leave_txn();
}
void osp_bridge::leave_txn()
{
  if (!detached) {
    unref();
  //DEBUG_bridge(this,warn("osp_bridge(%p) detach link=%d", this, link.empty()));
    if (!link.empty()) {
      mysv_lock(osp_thr::TXGV);
      // should be per-thread
      --refs;
      link.detach();
    }
    if (txsv) {
      SvREFCNT_dec(txsv);
      txsv = 0;
    }
    detached=1;
  }
  assert(refs >= 0);
  DEBUG_bridge(this, warn("osp_bridge(%p)->leave_txn(refs=%d)", this, refs));
  if (refs == 0) {
    freelist();
    --Inuse;
#if OSP_BRIDGE_TRACE
    al.detach();
#endif
  }
}
int osp_bridge::invalid()
{ return detached; }
void osp_bridge::freelist() //move to freelist
{ delete this; }
osp_bridge::~osp_bridge()
{
  --Instances;
  DEBUG_bridge(this, warn("osp_bridge(%p)->DESTROY", this));
#if OSP_BRIDGE_TRACE
  SvREFCNT_dec(where);
#endif
}

void osp_bridge::hold()
{ croak("bridge::hold()"); }
void osp_bridge::unref()
{ croak("osp_bridge::unref()"); }
int osp_bridge::is_weak()
{ croak("osp_bridge::is_weak()"); return 0; }

