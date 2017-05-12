#include "osp-preamble.h"
#include "osperl.h"

/*

void
readonly(sv)
	SV *sv
	PPCODE:
	if (!sv || !SvANY(sv)) XSRETURN_NO;
	if (SvREADONLY(sv)) XSRETURN_YES;
	XSRETURN_NO;


*/

// A few bits of the ObjectStore API are callable outside a
// transaction.  We need to wrap each of these in OSP_START0
// & OSP_END0

static char *private_root_name = "_osperl_private";

// avoid bad spelling
static char *ObjStore_Database = "ObjStore::Database";
static char *ObjStore_Segment = "ObjStore::Segment";

static void save_cxxvdelete(void *blk)
{ delete [] blk; }

//----------------------------- Constants

static os_fetch_policy str_2fetch(char *str)
{
  if (strEQ(str, "segment")) return os_fetch_segment;
  if (strEQ(str, "page")) return os_fetch_page;
  if (strEQ(str, "stream")) return os_fetch_stream;
  croak("str_2fetch: '%s' unrecognized", str);
  return (os_fetch_policy) 0;
}

static objectstore_lock_option str_2lock_option(char *str)
{
  if (strEQ(str, "as_used")) return objectstore::lock_as_used;
  if (strEQ(str, "read")) return objectstore::lock_segment_read;
  if (strEQ(str, "write")) return objectstore::lock_segment_write;
  croak("str_2lock_option: '%s' unrecognized", str);
  return (objectstore_lock_option) 0;
}

XS(XS_ObjStore_translate)
{ assert(osp_thr::stargate); perl_call_sv(osp_thr::stargate, G_SCALAR); }

//----------------------------- Dynamic Schemas!

#include <ostore/client/dll_fndr.hh>

struct osperl_schema_loader : os_DLL_finder {
  osperl_schema_loader();
  virtual ~osperl_schema_loader();
  virtual os_DLL_handle load_DLL(const char *, os_boolean error_if_not_found);
  virtual os_boolean equal_DLL_identifiers_same_prefix(const char* id1, 
						       const char* id2);
};

osperl_schema_loader::osperl_schema_loader()
{ register_("perl"); }
osperl_schema_loader::~osperl_schema_loader()
{ unregister("perl"); }

os_DLL_handle
osperl_schema_loader::load_DLL(const char *what, os_boolean error_if_not_found)
{
  dTHR;
  assert(strncmp(what, "perl:", 5)==0);
  if (osp_thr::DEBUG_schema())
	warn("autoload DLL '%s' force=%d", what, error_if_not_found);
//  if (!error_if_not_found) return 0;
  char *file = new char[strlen(what)+3];
  const char *s1 = what+5;
  char *s2 = file;
  while (1) {
    if (s1[0] == ':' && s1[1] == ':') { *s2++ = '/'; s1+=2; continue; }
    *s2 = *s1;
    if (*s2 == 0) break;
    ++s1; ++s2;
  }
  strcpy(s2, ".pm");
//  warn("require %s", file);
  perl_require_pv(file);
  if (SvTRUE(ERRSV))
	croak("Attempt to load schema '%s' (via %s) failed: %s",
		what, file, SvPV(ERRSV, PL_na));
  return file;
}

os_boolean
osperl_schema_loader::equal_DLL_identifiers_same_prefix(const char* id1, 
							const char* id2)
{ return strcmp(id1,id2)==0; }

//----------------------------- Exceptions

static void osp_unwind_part2(void *vptr)
{
  osp_thr *osp = (osp_thr*) vptr;
#ifndef _OS_CPP_EXCEPTIONS
  osp->hand->hand._unwind_part_2();
#endif
  // this is just a NOP when using C++ exceptions?
  delete osp->hand;
  osp->hand = new dytix_handler();
}

//----------------------------- ObjStore

MODULE = ObjStore	PACKAGE = ObjStore

PROTOTYPES: ENABLE

BOOT:
  PUTBACK;
  /*
 "As a prerequisite, such extensions must not need to do anything in
  their BOOT: section which needs to be done at runtime rather than
  compile time." -- the perl compiler
  */
  osp_thr::boot();
  osp_thr::use("ObjStore", OSPERL_API_VERSION);
  OSSV::verify_correct_compare();
  typemap_any::MyStash = gv_stashpv("ObjStore", 1);
//
#ifdef _OS_CPP_EXCEPTIONS
  // Must switch perl to use ANSI C++ exceptions!
  perl_require_pv("ExtUtils/ExCxx.pm");
  if (SvTRUE(ERRSV)) croak(SvPV(ERRSV,na));
#endif
//
  osp_thr::Schema = perl_get_hv("ObjStore::SCHEMA", TRUE);
//
  extern _Application_schema_info ObjStore_dll_schema_info;
  osp_thr::register_schema("ObjStore", &ObjStore_dll_schema_info);
//
  newXSproto("ObjStore::translate", XS_ObjStore_translate, file, "$$");
//
  HV *szof = perl_get_hv("ObjStore::sizeof", TRUE);


void
_mark_method(sub)
	SV *sub
	PPCODE:
#ifdef CVf_METHOD
	if (SvROK(sub)) {
	    sub = SvRV(sub);
	    if (SvTYPE(sub) != SVt_PVCV)
		sub = Nullsv;
	} else {
	    char *name = SvPV(sub, PL_na);
	    sub = (SV*)perl_get_cv(name, FALSE);
	}
	if (!sub)
	    croak("invalid subroutine reference or name");
	CvFLAGS(sub) |= CVf_METHOD;
#endif

void
_sv_dump_on_error(yes)
	int yes;
	CODE:
	osp_thr::sv_dump_on_error = yes;

void
reftype(ref)
	SV *ref
	PPCODE:
	if (!SvROK(ref)) XSRETURN_NO;
	ref = SvRV(ref);
	XSRETURN_PV(sv_reftype(ref, 0));

void
blessed(sv)
	SV *sv
	PPCODE:
	if(!sv_isobject(sv))  /*snarfed from builtin:GBARR*/
	  XSRETURN_UNDEF;
	XSRETURN_PV(sv_reftype(SvRV(sv),TRUE));

void
_sv_dump(sv)
	SV *sv
	CODE:
	Perl_sv_dump(sv);

void
_debug(mask)
	int mask
	PPCODE:
	dOSP ;
	int old = osp->debug;
	osp->debug = mask;
	XSRETURN_IV(old);


char *
_SEGV_reason()
	PPCODE:
	dOSP;
	if (!osp->report) XSRETURN_UNDEF;
#ifndef _OS_CPP_EXCEPTIONS
	osp->hand->hand._unwind_part_1(osp->cause, osp->value, osp->report);
#endif
	SAVEDESTRUCTOR(osp_unwind_part2, osp);
	XPUSHs(sv_2mortal(newSVpv(osp->report, 0)));
	osp->cause = 0;
	osp->value = 0;
	osp->report = 0;

SV *
set_stargate(code)
	SV *code
	CODE:
	ST(0) = osp_thr::stargate? sv_mortalcopy(osp_thr::stargate):&PL_sv_undef;
	if (!osp_thr::stargate) { osp_thr::stargate = newSVsv(code); }
	else { sv_setsv(osp_thr::stargate, code); }

void
release_name()
	PPCODE:
	XSRETURN_PV((char*) objectstore::release_name());

void
os_version()
	PPCODE:
	// (rad perl style version number... :-)
	XSRETURN_NV(objectstore::release_major() + objectstore::release_minor()/100 + objectstore::release_maintenance()/10000);

double
get_unassigned_address_space()
	CODE:
	RETVAL = objectstore::get_unassigned_address_space(); //64bit? XXX
	OUTPUT:
	RETVAL

void
_set_client_name(name)
	char *name;
	CODE:
	objectstore::set_client_name(name);

void
_set_cache_size(sz)
	int sz
	CODE:
	objectstore::set_cache_size(sz);

void
_initialize()
	CODE:
{
	objectstore::initialize(0);  //any harm in allowing reinit? XXX
	objectstore::set_auto_open_mode(objectstore::auto_open_disable);
	objectstore::set_incremental_schema_installation(1);
	/*LEAK*/ new osperl_schema_loader();
#ifdef USE_THREADS
	objectstore::set_thread_locking(1);
#else
	objectstore::set_thread_locking(0);
#endif
}

void
shutdown()
	CODE:
	objectstore::shutdown();

bool
network_servers_available()
	CODE:
	RETVAL = objectstore::network_servers_available();
	OUTPUT:
	RETVAL

void
_typemap_any_destroy(obj)
	SV *obj
	CODE:
	typemap_any::decode(obj,1);

int
_typemap_any_count()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(typemap_any::Instances)));

void
get_page_size()
	PPCODE:
	XSRETURN_IV(objectstore::get_page_size());

os_database *
_lookup(path, mode)
	char *path;
	int mode;
	CODE:
	char *CLASS = ObjStore_Database;
	RETVAL = os_database::lookup(path, mode);
	RETVAL->set_check_illegal_pointers(1);
	OUTPUT:
	RETVAL

int
return_all_pages()
	CODE:
	RETVAL = objectstore::return_all_pages();
	OUTPUT:
	RETVAL

void
get_all_servers()
	PPCODE:
	char *CLASS = "ObjStore::Server";
	os_int32 num = objectstore::get_n_servers();
	if (num == 0) XSRETURN_EMPTY;
	os_server_p *svrs = new os_server_p[num];
	SAVEDESTRUCTOR(save_cxxvdelete, svrs);
	objectstore::get_all_servers(num, svrs, num);
	EXTEND(sp, num);
	int xx;
	for (xx=0; xx < num; xx++) {
	  PUSHs(sv_2mortal(osp_thr::any_2sv(svrs[xx], CLASS)));
	}

#-----------------------------# Schema

MODULE = ObjStore	PACKAGE = ObjStore::Schema

void
os_DLL_schema_info::load(path)
	char *path
	CODE:
	if (osp_thr::DEBUG_schema())
	  warn("ObjStore::Schema::load('%s')", path);
	THIS->DLL_loaded(path);
	/* maybe return os_schema_handle?? */

void
os_DLL_schema_info::unload()
	CODE:
	THIS->DLL_unloaded();

#-----------------------------# Notification

MODULE = ObjStore	PACKAGE = ObjStore

void
subscribe(...)
	PPCODE:
	PUTBACK;
	if (items == 0) return;
	os_subscription *subs = new os_subscription[items];
	SAVEDESTRUCTOR(save_cxxvdelete, subs);
	for (int xa=0; xa < items; xa++) {
	  ospv_bridge *br = osp_thr::sv_2bridge(ST(xa), 1);
	  subs[xa].assign(br->ospv());
	}
	os_notification::subscribe(subs, items);
	return;

void
unsubscribe(...)
	PPCODE:
	PUTBACK;
	if (items == 0) return;
	os_subscription *subs = new os_subscription[items];
	SAVEDESTRUCTOR(save_cxxvdelete, subs);
	for (int xa=0; xa < items; xa++) {
	  ospv_bridge *br = osp_thr::sv_2bridge(ST(xa), 1);
	  subs[xa].assign(br->ospv());
	}
	os_notification::unsubscribe(subs, items);
	return;

MODULE = ObjStore	PACKAGE = ObjStore::Notification

PROTOTYPES: DISABLE

static void
os_notification::set_queue_size(size)
	int size;

static void
os_notification::queue_status()
	PPCODE:
	os_unsigned_int32 sz, pend, over;
	os_notification::queue_status(sz, pend, over);
	EXTEND(SP, 3);
	PUSHs(sv_2mortal(newSViv(sz)));
	PUSHs(sv_2mortal(newSViv(pend)));
	PUSHs(sv_2mortal(newSViv(over)));

static int
os_notification::_get_fd()

static void
os_notification::receive(...)
	PROTOTYPE: $;$
	PPCODE:
	os_int32 timeout = -1;
	if (items > 1) timeout = SvNV(ST(1)) * 1000;
	os_notification *note;
	if (os_notification::receive(note, timeout)) {
	  XPUSHs(sv_2mortal(osp_thr::any_2sv(note, "ObjStore::Notification")));
	} else {
	  XPUSHs(&PL_sv_undef);
	}

void
os_notification::_get_database()
	PPCODE:
	XPUSHs(sv_2mortal(osp_thr::any_2sv(THIS->get_database(),
		 "ObjStore::Database")));

void
os_notification::focus()
	PPCODE:
	PUTBACK;
	SV *ret;
	ret = osp_thr::ospv_2sv((OSSVPV *) THIS->get_reference().resolve());
	SPAGAIN;
	XPUSHs(ret);

void
os_notification::why()
	PPCODE:
	char *str = (char*) THIS->get_string();
	assert(str);
	// number slot is reserved
	XPUSHs(sv_2mortal(newSVpv(str, 0)));

void
DESTROY(obj)
	SV *obj
	CODE:
	delete (os_notification *) typemap_any::decode(obj,1);

MODULE = ObjStore	PACKAGE = ObjStore::UNIVERSAL

void
OSSVPV::notify(why, ...)
	SV *why
	PROTOTYPE: $$;$
	CODE:
	int now=0;
	if (items == 3) {
	  if (SvPOK(ST(2)) && strEQ(SvPV(ST(2), PL_na), "now")) now=1;
	  else if (SvPOK(ST(2)) && strEQ(SvPV(ST(2), PL_na), "commit")) now=0;
	  else croak("%p->notify('%s', $when)", THIS, SvPV(why, PL_na));
	} else {
	  warn("%p->notify($string): assuming $when eq 'commit', please specify",THIS);
	}
	os_notification note;
	note.assign(THIS, 0, SvPV(why, PL_na)); //number slot is reserved
	if (now) os_notification::notify_immediate(&note, 1);
	else     os_notification::notify_on_commit(&note, 1);

#-----------------------------# Transaction

MODULE = ObjStore	PACKAGE = ObjStore::Transaction

osp_txn *
new(...)
	PROTOTYPE: $;$$
	PPCODE:
	char *CLASS = "ObjStore::Transaction";
	os_transaction::transaction_type_enum tt;
	os_transaction::transaction_scope_enum scope;
	os_transaction *cur = os_transaction::get_current();
	if (!cur) {
	  tt = os_transaction::read_only;
	  scope = os_transaction::local;
	} else {
	  tt = cur->get_type();
	  scope = cur->get_scope();
	}
	for (int arg=1; arg < items; arg++) {
	  char *spec = SvPV(ST(arg), PL_na);
	  if (strEQ(spec, "read")) tt = os_transaction::read_only;
	  else if (strEQ(spec, "update")) tt = os_transaction::update;
	  else if (strEQ(spec, "abort_only") ||
	         strEQ(spec, "abort")) tt = os_transaction::abort_only;
	  else if (strEQ(spec, "local")) scope = os_transaction::local;
	  else if (strEQ(spec, "global")) scope = os_transaction::global;
	  else croak("ObjStore::Transaction::new(): unknown spec '%s'", spec);
	}
	new osp_txn(tt, scope);
	SV **tsv = av_fetch(osp_thr::TXStack, AvFILL(osp_thr::TXStack), 0);
	assert(tsv);
	XPUSHs(sv_2mortal(SvREFCNT_inc(*tsv)));

void
DESTROY(obj)
	SV *obj
	CODE:
	delete (osp_txn *) typemap_any::decode(obj,1);

void
osp_txn::top_level()
	PPCODE:
	XSRETURN_IV(AvFILL(osp_thr::TXStack) == -1);

bool
osp_txn::is_aborted()

void
osp_txn::abort()

void
osp_txn::commit()

void
osp_txn::checkpoint()

void
osp_txn::name(...)
	PROTOTYPE: $;$
	PPCODE:
	if (!THIS->os) XSRETURN_UNDEF;
	if (items == 2) {
	  THIS->os->set_name(SvPV(ST(1), PL_na));
	} else {
	  char *str = THIS->os->get_name();
	  XPUSHs(newSVpv(str, 0));
	  delete str;
	}

void
osp_txn::post_transaction()

void
get_current()
	PPCODE:
	if (av_len(osp_thr::TXStack) == -1) XSRETURN_UNDEF;
	SV **tsv = av_fetch(osp_thr::TXStack, av_len(osp_thr::TXStack), 0);
	assert(tsv);
	XPUSHs(sv_mortalcopy(*tsv));

void
osp_txn::get_type()
	PPCODE:
	switch (THIS->tt) {
	case os_transaction::abort_only: XSRETURN_PV("abort_only");
	case os_transaction::read_only: XSRETURN_PV("read");
	case os_transaction::update: XSRETURN_PV("update");
	}
	croak("os_transaction::get_type(): unknown transaction type");

MODULE = ObjStore	PACKAGE = ObjStore

void
_set_transaction_priority(pri)
	int pri;
	CODE:
	objectstore::set_transaction_priority(pri);

bool
is_lock_contention()
	CODE:
	RETVAL = objectstore::is_lock_contention();
	OUTPUT:
	RETVAL

char *
get_lock_status(ospv)
	OSSVPV *ospv
	CODE:
	int st;
	st = objectstore::get_lock_status(ospv);
	switch (st) {
	case os_read_lock: RETVAL = "read"; break;
	case os_write_lock: RETVAL = "write"; break;
	default: XSRETURN_NO;
	}
	OUTPUT:
	RETVAL

void
lock_timeout(rw,...)
	char *rw;
	PROTOTYPE: $;$
	PPCODE:
	// ODI went COMPLETELY OVERBOARD optimizing this API...  :-)
	int is_read=-1;
	if (strEQ(rw,"read")) is_read=1;
	else if (strEQ(rw,"write")) is_read=0;
	if (is_read==-1) croak("lock_timeout: read or write?");
	if (items == 1) {
	  int tm = (is_read ?
		objectstore::get_readlock_timeout() :
		objectstore::get_writelock_timeout());
	  if (tm == -1) { XSRETURN_UNDEF; } 
	  else { XPUSHs(sv_2mortal(newSVnv(tm/(double)1000))); }
	} else {
	  int tm = SvOK(ST(1))? SvNV(ST(1))*1000 : -1;
	  if (is_read) objectstore::set_readlock_timeout(tm);
	  else         objectstore::set_writelock_timeout(tm);
	}

#-----------------------------# Server

MODULE = ObjStore	PACKAGE = ObjStore::Server

char *
os_server::get_host_name()

int
os_server::connection_is_broken()

void
os_server::disconnect()

void
os_server::reconnect()

void
os_server::get_databases()
	PPCODE:
	char *CLASS = ObjStore_Database;
	os_int32 num = THIS->get_n_databases();
	assert(num > 0);  //?
	os_database_p *dbs = new os_database_p[num];
	SAVEDESTRUCTOR(save_cxxvdelete, dbs);
	THIS->get_databases(num, dbs, num);
	EXTEND(sp, num);
	int xx;
	for (xx=0; xx < num; xx++) {
	  PUSHs(sv_2mortal(osp_thr::any_2sv(dbs[xx], CLASS)));
	}

#-----------------------------# Database

MODULE = ObjStore	PACKAGE = ObjStore

int
get_n_databases()
	CODE:
	RETVAL = os_database::get_n_databases();
	OUTPUT:
	RETVAL

MODULE = ObjStore	PACKAGE = ObjStore::Database

void
os_database::_open(read_only)
	int read_only
	PPCODE:
	THIS->open(read_only);
	XSRETURN_YES;

void
os_database::_open_mvcc()
	PPCODE:
	THIS->open_mvcc();
	XSRETURN_YES;

void
os_database::close()
	CODE:
	/*warn("%p=ObjStore::Database->close()", THIS); /*XXX*/
	THIS->close();

void
os_database::_destroy()
	CODE:
	THIS->destroy();

void
os_database::get_host_name()
	PPCODE:
	char *path = THIS->get_host_name();
	XPUSHs(sv_2mortal(newSVpv(path, 0)));
	delete path;

void
os_database::get_pathname()
	PPCODE:
	char *path = THIS->get_pathname();
	XPUSHs(sv_2mortal(newSVpv(path, 0)));
	delete path;

void
os_database::get_relative_directory()
	PPCODE:
	char *path = THIS->get_relative_directory();
	if (!path) XSRETURN_UNDEF;
	XPUSHs(sv_2mortal(newSVpv(path, 0)));
	delete path;

void
os_database::get_id(...)
	PPCODE:
	os_database_id *id = THIS->get_id();
	XPUSHs(sv_2mortal(newSVpvf("%08p%08p%08p",id->word0,id->word1,id->word2)));

int
os_database::get_default_segment_size()

int
os_database::get_sector_size()

int
os_database::size()

int
os_database::size_in_sectors()

time_t
os_database::time_created()

char *
os_database::is_open()
	CODE:
	if (THIS->is_open_mvcc()) RETVAL = "mvcc";
	else if (THIS->is_open_read_only()) RETVAL = "read";
	else if (THIS->is_open()) RETVAL = "update";
	else XSRETURN_NO;
	OUTPUT:
	RETVAL

void
os_database::is_writable()
	PPCODE:
	// not ODI spec; but more useful
	if (THIS->is_open_read_only()) XSRETURN_NO;
	osp_txn *txn = osp_txn::current();
	if (txn && txn->tt == os_transaction::read_only) XSRETURN_NO;
	XSRETURN_YES;

void
os_database::set_fetch_policy(policy, ...)
	char *policy;
	PROTOTYPE: $;$
	CODE:
	int bytes=4096;
	if (items == 3) bytes = SvIV(ST(2));
	else if (items > 3) croak("os_database::set_fetch_policy(policy, [sz])");
	THIS->set_fetch_policy(str_2fetch(policy), bytes);

void
os_database::set_lock_whole_segment(policy)
	char *policy;
	CODE:
	THIS->set_lock_whole_segment(str_2lock_option(policy));

void
os_database::subscribe()
	CODE:
	os_notification::subscribe(THIS);

void
os_database::unsubscribe()
	CODE:
	os_notification::unsubscribe(THIS);

os_segment *
os_database::get_default_segment()
	CODE:
	char *CLASS = ObjStore_Segment;
	RETVAL = THIS->get_default_segment();
	OUTPUT:
	RETVAL

os_segment *
os_database::get_segment(num)
	int num
	CODE:
	char *CLASS = ObjStore_Segment;
	RETVAL = THIS->get_segment(num);
	OUTPUT:
	RETVAL

void
os_database::get_all_segments()
	PPCODE:
	char *CLASS = ObjStore_Segment;
	os_int32 num = THIS->get_n_segments();
	assert(num > 0); //?ok
	os_segment_p *segs = new os_segment_p[num];
	SAVEDESTRUCTOR(save_cxxvdelete, segs);
	THIS->get_all_segments(num, segs, num);
	EXTEND(sp, num);
	int xx;
	for (xx=0; xx < num; xx++) {
	  PUSHs(sv_2mortal(osp_thr::any_2sv(segs[xx], CLASS)));
	}

void
os_database::_PRIVATE_ROOT()
	PPCODE:
	osp_txn *txn = osp_txn::current();
	os_database_root *rt = THIS->find_root(private_root_name);
	if (!rt && txn && txn->can_update(THIS)) {
	  rt = THIS->create_root(private_root_name);
	  rt->set_value(0, OSSV::get_os_typespec());
	}
	XPUSHs(sv_2mortal(osp_thr::any_2sv(rt, "ObjStore::Root")));

void
os_database::get_all_roots()
	PPCODE:
	char *CLASS = "ObjStore::Root";
	os_int32 num = THIS->get_n_roots();
	if (num == 0) XSRETURN_EMPTY;
	os_database_root_p *roots = new os_database_root_p[num];
	THIS->get_all_roots(num, roots, num);
	for (int xx=0; xx < num; xx++) {
	  assert(roots[xx]);
	  char *nm = roots[xx]->get_name();
	  int priv = strEQ(nm, private_root_name);
	  if (!priv) XPUSHs(sv_2mortal(osp_thr::any_2sv(roots[xx], CLASS)));
	}
	delete [] roots;

#-----------------------------# Root

MODULE = ObjStore	PACKAGE = ObjStore::Database

os_database_root *
os_database::create_root(name)
	char *name
	PREINIT:
	char *CLASS = "ObjStore::Root";
	CODE:
	DEBUG_root(warn("%p->create_root(%s)", THIS, name));
	RETVAL = THIS->create_root(name);
	assert(RETVAL);
	RETVAL->set_value(0, OSSV::get_os_typespec());
	OUTPUT:
	RETVAL

os_database_root *
os_database::find_root(name)
	char *name
	PREINIT:
	char *CLASS = "ObjStore::Root";
	CODE:
	if (strEQ(name, private_root_name)) XSRETURN_UNDEF; //force awareness
	DEBUG_root(warn("%p->find_root(%s)", THIS, name));
	RETVAL = THIS->find_root(name);
	DEBUG_root(warn("%p->find_root(%s) = %p", THIS, name, RETVAL));
	OUTPUT:
	RETVAL

MODULE = ObjStore	PACKAGE = ObjStore::Root

void
os_database_root::destroy()
	CODE:
	DEBUG_root(warn("%p->destroy_root()", THIS));
	OSSV *old = (OSSV*) THIS->get_value();
	if (old) delete old;
	delete THIS;

char *
os_database_root::get_name()

void
os_database_root::get_value()
	PPCODE:
	PUTBACK ;
	OSSV *ossv = (OSSV*) THIS->get_value(OSSV::get_os_typespec());
	DEBUG_root(warn("%p->get_value() = OSSV=%p", THIS, ossv));
	SV *ret;
	ret = osp_thr::ossv_2sv(ossv);
	SPAGAIN ;
	XPUSHs(ret);

void
os_database_root::set_value(sv)
	SV *sv
	PPCODE:
	PUTBACK ;
	os_segment *WHERE = os_database::of(THIS)->get_default_segment();
	OSSVPV *pv=0;
	ospv_bridge *br = osp_thr::sv_2bridge(sv, 1, WHERE);
	pv = br->ospv();
	// Disallow scalars in roots because it is fairly useless and messy.
	OSSV *ossv = (OSSV*) THIS->get_value(OSSV::get_os_typespec());
	if (ossv) {
	  DEBUG_root(warn("%p->set_value(): OSSV(%p)=%p", THIS, ossv, pv));
	  ossv->s(pv);
	} else {
	  DEBUG_root(warn("%p->set_value(): planting %p", THIS, pv));
	  ossv = osp_thr::plant_ospv(WHERE, pv);
	  THIS->set_value(ossv, OSSV::get_os_typespec());
	}
	return;

#-----------------------------# Segment

MODULE = ObjStore	PACKAGE = ObjStore::Database

os_segment *
os_database::_create_segment()
	PREINIT:
	char *CLASS = ObjStore_Segment;
	CODE:
	RETVAL = THIS->create_segment();
	OUTPUT:
	RETVAL

MODULE = ObjStore	PACKAGE = ObjStore::Segment

os_segment *
get_transient_segment()
	CODE:
	char *CLASS = ObjStore_Segment;
	RETVAL = os_segment::get_transient_segment();
	OUTPUT:
	RETVAL

void
os_segment::_destroy()
	CODE:
	THIS->destroy();

bool
os_segment::is_empty()

bool
os_segment::is_deleted()

int
os_segment::return_memory(now)
	int now

int
os_segment::size()

int
os_segment::set_size(new_sz)
	int new_sz

int
os_segment::unused_space()

int
os_segment::get_number()

void
os_segment::subscribe()
	CODE:
	os_notification::subscribe(THIS);

void
os_segment::unsubscribe()
	CODE:
	os_notification::unsubscribe(THIS);

void
os_segment::set_comment(info)
	char *info
	CODE:
	char short_info[32];
	strncpy(short_info, info, 31);
	short_info[31] = 0;
	THIS->set_comment(short_info);

void
os_segment::get_comment()
	PPCODE:
	char *cm = THIS->get_comment();
	XPUSHs(sv_2mortal(newSVpv(cm, 0)));
	delete cm;

void
os_segment::lock_into_cache()

void
os_segment::unlock_from_cache()

void
os_segment::set_fetch_policy(policy, ...)
	char *policy;
	PROTOTYPE: $;$
	CODE:
	int bytes=4096;
	if (items == 3) bytes = SvIV(ST(2));
	else if (items > 3) croak("os_database::set_fetch_policy(policy, [sz])");
	THIS->set_fetch_policy(str_2fetch(policy), bytes);

void
os_segment::set_lock_whole_segment(policy)
	char *policy;
	CODE:
	THIS->set_lock_whole_segment(str_2lock_option(policy));

os_database *
os_segment::_database_of()
	PREINIT:
	char *CLASS = ObjStore_Database;
	CODE:
	RETVAL = THIS->database_of();
	OUTPUT:
	RETVAL

#-----------------------------# Bridge

MODULE = ObjStore	PACKAGE = ObjStore::Bridge

void
osp_bridge::DESTROY()
	CODE:
	THIS->leave_perl();

#-----------------------------# UNIVERSAL

MODULE = ObjStore	PACKAGE = ObjStore::UNIVERSAL

void
DESTROY(sv)
	SV *sv
	CODE:
	// This is a bit sloppy but it will be fixed when the typemap
	// is re-implemented.
	if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVMG) {
	  ospv_bridge *br = osp_thr::sv_2bridge(sv, 1);
	  br->leave_perl();
	}

void
OSSVPV::DELETED(...)
	PROTOTYPE: $;$
	PPCODE:
	STRLEN len;
	if (items == 1)
	  XPUSHs(boolSV(OSPvDELETED(THIS)));
	else if (items == 2) {
	  if (sv_true(ST(1)))
	    OSPvDELETED_on(THIS);
	  else if (OSPvDELETED(THIS))
	    croak("Cannot undelete OSSVPV=0x%p os_class='%s' rep_class='%s'",
		THIS, THIS->os_class(&len), THIS->rep_class(&len));
	}

void
OSSVPV::_debug1()
	CODE:
	THIS->_debug1(ST(0));

bool
_is_persistent(sv)
	SV *sv;
	CODE:
	ospv_bridge *br = osp_thr::sv_2bridge(sv, 0);
	RETVAL = br && os_segment::of(br->ospv()) != os_segment::of(0);
	OUTPUT:
	RETVAL

void
_pstringify(THIS, ...)
	SV *THIS;
	PROTOTYPE: $;$$
	PPCODE:
	ospv_bridge *br = osp_thr::sv_2bridge(THIS, 0);
	SV *ret;
	if (!br) {
	  STRLEN len;
	  int amagic = SvAMAGIC(THIS);  // concurrency problem? XXX
	  SvAMAGIC_off(THIS);
	  char *str = sv_2pv(THIS, &len);
	  if (amagic) SvAMAGIC_on(THIS);
	  assert(str);
	  ret = newSVpv(str, len);
	} else {
	  //This doesn't work after some exceptions!!
	  //STRLEN CLEN;
	  //char *CLASS = br->ospv()->blessed_to(&CLEN);
	  //
	  //optimize!! XXX
	  ret = newSVpvf("%s=%s(0x%p)",	HvNAME(SvSTASH(SvRV(THIS))),
			 sv_reftype(SvRV(THIS), 0), br->ospv());
	}
	XPUSHs(sv_2mortal(ret));

void
_pnumify(...)
	PPCODE:
	int max = items <= 2? items : 2;
	IV ret=0;
	for (int sx=0; sx < max; sx++) {
	  SV *sv = ST(sx);
	  if (SvGMAGICAL(sv))
	    mg_get(sv);
	  if (!SvOK(sv))
	    continue;
	  if (!SvROK(sv)) {
	    if (SvIOKp(sv) || SvIOK(sv)) {
	      ret += SvIV(sv);
	      continue;
	    }
	    else {
	      sv_dump(sv);
	      croak("_pnumify: argument #%d not a reference", sx);
	    }
	  }
 	  else {
	    ospv_bridge *br = osp_thr::sv_2bridge(sv, 0);
	    if (!br) {
	      ret = (IV) SvRV(sv);
	    } else {
	      ret = (IV) br->ospv();
	    }
	  }
	}
	XPUSHs(sv_2mortal(newSViv(ret)));

bool
_peq(a1, a2, ign)
	SV *a1
	SV *a2
	SV *ign
	CODE:
	ospv_bridge *b1 = osp_thr::sv_2bridge(a1, 0);
	ospv_bridge *b2 = osp_thr::sv_2bridge(a2, 0);
	if (!b1 || !b2) XSRETURN_NO;
	//warn("b1=%p b2=%p", b1->ospv(), b2->ospv());
	RETVAL = b1->ospv() == b2->ospv();
	OUTPUT:
	RETVAL

bool
_pneq(a1, a2, ign)
	SV *a1
	SV *a2
	SV *ign
	CODE:
	ospv_bridge *b1 = osp_thr::sv_2bridge(a1, 0);
	ospv_bridge *b2 = osp_thr::sv_2bridge(a2, 0);
	if (!b1 || !b2) XSRETURN_YES;
	//warn("b1=%p b2=%p", b1->ospv(), b2->ospv());
	RETVAL = b1->ospv() != b2->ospv();
	OUTPUT:
	RETVAL

void
OSSVPV::_debug(yes)
	int yes;
	PPCODE:
	BrDEBUG_set(THIS_bridge, yes);

void
OSSVPV::_refcnt()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(THIS->_refs)));

void
OSSVPV::_blessto_slot(...)
	PROTOTYPE: ;$
	PPCODE:
	PUTBACK;
	// only persistent objects get a persistent blessing
	// so this code does not leak memory
	if (items == 2) {
	  ospv_bridge *br = osp_thr::sv_2bridge(ST(1), 1);
	  OSSVPV *nval = (OSSVPV*) br->ospv();
	  nval->REF_inc();
	  if (OSPvBLESS2(THIS) && THIS->classname)
	    ((OSSVPV*)THIS->classname)->REF_dec();
	  OSPvBLESS2_on(THIS);
	  THIS->classname = (char*)nval;
	}
	if (OSPvBLESS2(THIS) && GIMME_V != G_VOID) {
	  SV *ret = osp_thr::ospv_2sv((OSSVPV*)THIS->classname);
	  SPAGAIN;
	  XPUSHs(ret);
	  PUTBACK;
	}
	return;

os_database *
OSSVPV::_database_of()
	CODE:
	char *CLASS = ObjStore_Database;
	RETVAL = os_database::of(THIS);
	OUTPUT:
	RETVAL

os_segment *
OSSVPV::segment_of()
	CODE:
	char *CLASS = ObjStore_Segment;
	RETVAL = os_segment::of(THIS);
	OUTPUT:
	RETVAL

void
OSSVPV::os_class()
	PPCODE:
	STRLEN len;
	char *str = THIS->os_class(&len);
	XPUSHs(sv_2mortal(newSVpv(str, len)));

void
OSSVPV::rep_class()
	PPCODE:
	STRLEN len;
	char *str = THIS->rep_class(&len);
	XPUSHs(sv_2mortal(newSVpv(str, len)));

void
OSSVPV::get_pointer_numbers()
	PPCODE:
	os_unsigned_int32 n1,n2,n3;
	objectstore::get_pointer_numbers(THIS, n1, n2, n3);
	XPUSHs(sv_2mortal(newSVpvf("%08p%08p", n1, n3)));

void
OSSVPV::HOLD()
	PPCODE:
	THIS_bridge->hold();
	if (GIMME_V != G_VOID) XPUSHs(sv_mortalcopy(ST(0))); //?

void
OSSVPV::const()
	PPCODE:
	THIS->make_constant();

#-----------------------------# Container

MODULE = ObjStore	PACKAGE = ObjStore::Container

double
OSPV_Container::_percent_filled()
	CODE:
	warn("_percent_filled is experimental");
	RETVAL = THIS->_percent_filled();
	if (RETVAL < 0 || RETVAL > 1) XSRETURN_UNDEF;
	OUTPUT:
	RETVAL

void
OSPV_Container::_new_cursor(sv1)
	SV *sv1;
	PPCODE:
	PUTBACK;
	os_segment *seg = osp_thr::sv_2segment(sv1);
	SV *ret = osp_thr::ospv_2sv(THIS->new_cursor(seg), 1);
	SPAGAIN;
	XPUSHs(ret);

void
OSPV_Container::POSH_CD(keyish)
	SV *keyish
	PPCODE:
	PUTBACK;
	THIS->POSH_CD(keyish);
	return;

int
OSPV_Container::FETCHSIZE()

#-----------------------------# PathExam

MODULE = ObjStore	PACKAGE = ObjStore::PathExam

static osp_pathexam *
osp_pathexam::new(...)
	PROTOTYPE: $;$
	CODE:
	int desc=0;
	if (items == 2) {
	  desc = sv_true(ST(1));
	}
	RETVAL = new osp_pathexam(desc);
	OUTPUT:
	RETVAL

void
osp_pathexam::load_path(pth)
	OSSVPV *pth

void
osp_pathexam::load_args(...)
	CODE:
	THIS->load_args(ax, items);

char *
osp_pathexam::stringify()
	CODE:
	RETVAL = THIS->kv_string();
	OUTPUT:
	RETVAL

void
osp_pathexam::keys()
	PPCODE:
	PUTBACK;
	THIS->push_keys();
	return;

void
osp_pathexam::load_target(pv)
	OSSVPV *pv;
	CODE:
	THIS->load_target('x', pv);

int
osp_pathexam::compare(to)
	OSSVPV *to
	CODE:
	RETVAL = THIS->compare(to, 1);
	OUTPUT:
	RETVAL

#-----------------------------# AV

MODULE = ObjStore	PACKAGE = ObjStore::AV

void
OSPV_Generic::FETCH(xx)
	SV *xx;
	PPCODE:
	PUTBACK;
	THIS->FETCH(xx);
	return;

void
OSPV_Generic::STORE(xx, nval)
	SV *xx;
	SV *nval;
	PPCODE:
	PUTBACK;
	if (SvGMAGICAL(nval))
	    mg_get(nval);
	THIS->STORE(xx, nval);
	return;

void
OSPV_Generic::CLEAR()

void
OSPV_Generic::POP()
	PPCODE:
	PUTBACK;
	THIS->POP();
	return;

void
OSPV_Generic::SHIFT()
	PPCODE:
	PUTBACK;
	THIS->SHIFT();
	return;

void
OSPV_Generic::PUSH(...)
	CODE:
	PUTBACK;
	THIS->PUSH(ax, items);
	SPAGAIN;
	ST(0) = sv_2mortal(newSViv(items - 1));
	XSRETURN(1);

void
OSPV_Generic::UNSHIFT(...)
	CODE:
	PUTBACK;
	THIS->UNSHIFT(ax, items);
	SPAGAIN;
	ST(0) = sv_2mortal(newSViv(items - 1));
	XSRETURN(1);

void
OSPV_Generic::SPLICE(...)
	PROTOTYPE: $$;$@
	CODE:
	PUTBACK;
	int size = THIS->FETCHSIZE();
	// Mirror the logic in pp_splice; GACK!
	int offset = osp_thr::sv_2aelem(ST(1));
	if (offset < 0) offset += size;
	if (offset < 0) croak("Modification of non-creatable array value attempted, subscript %d", offset);
	if (offset > size) offset = size;
	int length = items >= 3 ? osp_thr::sv_2aelem(ST(2)) : size+1;
	if (length < 0) length = 0;
	int after = size - (offset + length);
	if (after < 0) length += after;
	int toadd = items - 3;
	if (toadd < 0) toadd=0;
	SV **copy;
	if (toadd) {
	  copy = new SV*[toadd];
	  for (int xx=0; xx < toadd; xx++) {
	    copy[xx] = sv_mortalcopy(ST(xx+3));
	  }
	}
	// We have copies so we can pop the args off the stack
	// and forward to SPLICE.  SPLICE can push stuff back
	// on the stack so it is important to return without PUTBACK.
	PL_stack_sp = PL_stack_base + ax - 1;
	//
	//warn("SPLICE(off=%d,len=%d,@%d)", offset, length, toadd);
	THIS->SPLICE(offset, length, copy, toadd);
	if (toadd) {
	  delete [] copy;
	}
	return;

#-----------------------------# HV

MODULE = ObjStore	PACKAGE = ObjStore::HV

void
OSPV_Generic::FETCH(key)
	SV *key;
	PPCODE:
	PUTBACK;
	THIS->FETCH(key);
	return;

void
OSPV_Generic::STORE(key, nval)
	SV *key;
	SV *nval;
	PPCODE:
	PUTBACK;
	THIS->STORE(key, nval);
	return;

void
OSPV_Generic::DELETE(key)
	SV *key
	PPCODE:
	PUTBACK;
	THIS->DELETE(key);
	return;

bool
OSPV_Generic::EXISTS(key)
	SV *key

void
OSPV_Generic::FIRSTKEY()
	PPCODE:
	PUTBACK;
	THIS->FIRST(&THIS_bridge->info);
	return;

void
OSPV_Generic::NEXTKEY(...)
	PPCODE:
	if (items > 2) croak("NEXTKEY: too many arguments");
	PUTBACK;
	THIS->NEXT(&THIS_bridge->info);
	return;

void
OSPV_Generic::CLEAR()

#-----------------------------# Index

MODULE = ObjStore	PACKAGE = ObjStore::Index

void
OSPV_Generic::configure(...)
	CODE:
	// NOTE: This does not pop args off of the stack.
	THIS->configure(ax, items);
	return;

void
OSPV_Generic::add(sv)
	SV *sv;
	PPCODE:
	PUTBACK;
	ospv_bridge *br = osp_thr::sv_2bridge(sv, 1, os_segment::of(THIS));
	OSSVPV *pv = br->ospv();
	int added = THIS->add(pv);
	SPAGAIN;
	if (added && GIMME_V != G_VOID) {
	  PUSHs(osp_thr::ospv_2sv(pv));
	}

void
OSPV_Generic::remove(sv)
	SV *sv
	PPCODE:
	PUTBACK;
	ospv_bridge *br = osp_thr::sv_2bridge(sv, 1);
	int rmd = THIS->remove(br->ospv());
	SPAGAIN;
	XPUSHs(boolSV(rmd));

#-----------------------------# Ref

MODULE = ObjStore	PACKAGE = ObjStore::Ref

os_database *
OSPV_Ref2::_get_database()
	PREINIT:
	char *CLASS = ObjStore_Database;
	CODE:				//should be just like lookup
	RETVAL = THIS->get_database();
	RETVAL->set_check_illegal_pointers(1);
	OUTPUT:
	RETVAL

void
OSPV_Ref2::dump()
	PPCODE:
	char *str = THIS->dump();
	XPUSHs(sv_2mortal(newSVpv(str,0)));
	delete str;

int
OSPV_Ref2::deleted()

void
OSPV_Ref2::focus()
	PPCODE:
	PUTBACK;
	SV *sv = osp_thr::ospv_2sv(THIS->focus());
	SPAGAIN;
	XPUSHs(sv);

#-----------------------------# Cursor

MODULE = ObjStore	PACKAGE = ObjStore::Cursor

void
OSPV_Cursor2::focus()
	PPCODE:
	PUTBACK;
	SV *sv = osp_thr::ospv_2sv(THIS->focus());
	SPAGAIN;
	XPUSHs(sv);

void
OSPV_Cursor2::moveto(where)
	int where

void
OSPV_Cursor2::step(delta)
	int delta
	PPCODE:
	PUTBACK;
	THIS->step(delta);
	return;

void
OSPV_Cursor2::each(...)
	PROTOTYPE: ;$
	PPCODE:
	int delta = 1;
	if (items == 2) {
	  if (!SvIOK(ST(1))) croak("each only accepts integer step sizes");
	  delta = SvIV(ST(1));
	}
	PUTBACK;
	THIS->step(delta);
	THIS->at();
	return;

void
OSPV_Cursor2::at()
	PPCODE:
	PUTBACK;
	THIS->at();
	return;

void
OSPV_Cursor2::store(nval)
	SV *nval
	PPCODE:
	PUTBACK;
	THIS->store(nval);
	return;

void
OSPV_Cursor2::seek(...)
	CODE:
	PUTBACK;
	osp_pathexam *exam;
	if (SvROK(ST(1))) {
	  exam = (osp_pathexam*) typemap_any::decode(ST(1));
	} else {
	  dOSP;
	  osp->exam.init();
	  osp->exam.load_args(ax, items);
	  exam = &osp->exam;
	}
	ST(0) = boolSV(THIS->seek(*exam));
	XSRETURN(1);

int
OSPV_Cursor2::pos()

void
OSPV_Cursor2::keys()
	PPCODE:
	PUTBACK;
	THIS->keys();
	return;


MODULE = ObjStore	PACKAGE = ObjStore::Database

void
os_database::_allow_external_pointers(yes)
	int yes
	CODE:
	if (yes) warn("allow_external_pointers is extremely dangerous");
	THIS->allow_external_pointers(yes);

