// -*-C++-*- mode
#include <osp-preamble.h>
#include <osperl.h>
#include "ODI.h"

/* CCov: fatal SERIOUS */
#define SERIOUS warn

/*--------------------------------------------- */
/*--------------------------------------------- HV os_dictionary */

OSPV_hvdict::OSPV_hvdict(os_unsigned_int32 card)
  : hv(card,
       os_dictionary::signal_dup_keys |
       os_collection::pick_from_empty_returns_null |
       os_dictionary::dont_maintain_cardinality)
{}

OSPV_hvdict::~OSPV_hvdict()
{
  os_cursor cs(hv);
  OSSV *at;
  for (at = (OSSV*) cs.first(); at; at = (OSSV*) cs.next()) {
    delete at;
  }
}

int OSPV_hvdict::FETCHSIZE()
{ return hv.update_cardinality(); }

char *OSPV_hvdict::os_class(STRLEN *len)
{ *len = 12; return "ObjStore::HV"; }

char *OSPV_hvdict::rep_class(STRLEN *len)
{ *len = 22; return "ObjStore::REP::ODI::HV"; }

int OSPV_hvdict::get_perl_type()
{ return SVt_PVHV; }

OSSV *OSPV_hvdict::hvx(char *key)
{
  OSSV *ret = hv.pick(key);
  DEBUG_hash(warn("OSPV_hvdict::FETCH %s => %s", key, ret? ret->stringify() : "<0x0>"));
  return ret;
}

void OSPV_hvdict::FETCH(SV *key)
{
  OSSV *val = hv.pick(SvPV(key, PL_na));
  if (!val) return;
  SV *ret = osp_thr::ossv_2sv(val);
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

OSSVPV *OSPV_hvdict::traverse1(osp_pathexam &exam)
{ return exam.mod_ossv(hvx(exam.get_thru()))->as_rv(); }
OSSV *OSPV_hvdict::traverse2(osp_pathexam &exam)
{ return exam.mod_ossv(hvx(exam.get_thru())); }

void OSPV_hvdict::make_constant()
{
  os_cursor cs(hv);
  for (OSSV *at = (OSSV*) cs.first(); at; at = (OSSV*) cs.next())
    OSvREADONLY_on(at);
}

void OSPV_hvdict::STORE(SV *sv, SV *nval)
{
  STRLEN keylen;
  char *key = SvPV(sv,keylen);
  if (keylen == 0)
    croak("ObjStore: os_dictionary cannot store a zero length hash key");
  hkey tmpkey(key);
  OSSV *ossv = (OSSV*) hv.pick(&tmpkey);
  if (ossv) {
    *ossv = nval;
  } else {
    ossv = osp_thr::plant_sv(os_segment::of(this), nval);
    hv.insert(&tmpkey, ossv);
  }
  DEBUG_hash(warn("OSPV_hvdict::INSERT(%s=%s)", key, ossv->stringify()));
  dTHR;
  //  if (GIMME_V == G_VOID) return;
  SV *ret = osp_thr::ossv_2sv(ossv);
  djSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_hvdict::DELETE(SV *key)
{
  hkey tmpkey(SvPV(key, PL_na));
  OSSV *val = hv.pick(&tmpkey);
  if (!val) return;
  hv.remove_value(&tmpkey);
  DEBUG_hash(warn("OSPV_hvdict::DELETE(%s) deleting hash value 0x%x", key, val));
  val->set_undef();
  delete val;
}

void OSPV_hvdict::CLEAR()
{
  os_cursor cs(hv);
  OSSV *at;
  for (at = (OSSV*) cs.first(); at; at = (OSSV*) cs.next()) {
    assert(at);
    at->set_undef();
    delete at;
  }
  hv.clear();
}

int OSPV_hvdict::EXISTS(SV *key)
{
  int out = hv.pick(SvPV(key, PL_na)) != 0;
  DEBUG_hash(warn("OSPV_hvdict::EXISTS %s => %d", SvPV(key, PL_na), out));
  return out;
}

struct hvdict_bridge : osp_smart_object {
  os_cursor cs;
  hvdict_bridge(const os_collection &myco) : cs(myco) {}
};

void OSPV_hvdict::FIRST(osp_smart_object **info)
{
  if (! *info) *info = new hvdict_bridge(hv);
  os_cursor *cs = &((hvdict_bridge*)*info)->cs;
  hkey *k1;
  if (!cs->first()) return;
  k1 = (hkey*) hv.retrieve_key(*cs);
  assert(k1);
  SV *ret = k1->to_sv();
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_hvdict::NEXT(osp_smart_object **info)
{
  assert(*info);
  os_cursor *cs = &((hvdict_bridge*)*info)->cs;
  hkey *k1=0;
  if (!cs->next()) return;
  k1 = (hkey*) hv.retrieve_key(*cs);
  assert(k1);
  SV *ret = k1->to_sv();
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

/*
OSSVPV *OSPV_hvdict::new_cursor(os_segment *seg)
{ return new(seg, OSPV_hvdict_cs::get_os_typespec()) OSPV_hvdict_cs(this); }

OSPV_hvdict_cs::OSPV_hvdict_cs(OSPV_hvdict *_at)
  : OSPV_Cursor(_at), cs(_at->hv)
{ seek_pole(0); }

void OSPV_hvdict_cs::seek_pole(int end)
{
  reset_2pole = end;
  if (end) { 
    SERIOUS("seek_pole('end') is experimental");
  }
}

void OSPV_hvdict_cs::at()
{
  if (reset_2pole != -1) {
    if (reset_2pole == 0) cs.first();
    else croak("nope");
    reset_2pole = -1;
  }
  if (cs.null()) return;

  OSSV *ossv = (OSSV*) cs.retrieve();
  if (ossv) {
    SV *sv[2] = {
      ((hkey*) ((OSPV_hvdict*)focus())->hv.retrieve_key(cs))->to_sv(),
      osp_thr::ossv_2sv(ossv)
    };
    dSP;
    EXTEND(SP,2);
    PUSHs(sv[0]);
    PUSHs(sv[1]);
    PUTBACK;
  }
}

void OSPV_hvdict_cs::next()
{ at(); cs.next(); }
*/


MODULE = ObjStore::REP::ODI		PACKAGE = ObjStore::REP::ODI

PROTOTYPES: DISABLE

BOOT:
  extern _Application_schema_info ObjStore_REP_ODI_dll_schema_info;
  osp_thr::use("ObjStore::REP::ODI", OSPERL_API_VERSION);
  osp_thr::register_schema("ObjStore::REP::ODI",
	&ObjStore_REP_ODI_dll_schema_info);
  os_index_key(hkey, hkey::rank, hkey::hash);
#ifdef USE_THREADS
  os_collection::set_thread_locking(1);
#else
  os_collection::set_thread_locking(0);
#endif

MODULE = ObjStore::REP::ODI		PACKAGE = ObjStore::REP::ODI::HV

static void
OSPV_hvdict::new(seg, sz)
	SV *seg;
	int sz;
	PPCODE:
	os_segment *area = osp_thr::sv_2segment(ST(1));
	PUTBACK;
	if (sz <= 0) croak("Non-positive cardinality");
	OSSVPV *pv;
	NEW_OS_OBJECT(pv, area, OSPV_hvdict::get_os_typespec(), OSPV_hvdict(sz));
	pv->bless(ST(0));
	return;

