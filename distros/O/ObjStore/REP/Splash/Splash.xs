// -*-C++-*- mode
#include "osp-preamble.h"
#include "osperl.h"
#include "Splash.h"

#undef MIN
#define	MIN(a, b)	((a) < (b) ? (a) : (b))

/* CCov: fatal SERIOUS */
#define SERIOUS warn

/*
static void push_sv_ossv(SV *hk, OSSV *hv)
{
  SV *sv[2] = {hk, osp_thr::ossv_2sv(hv)};
  dSP;
  EXTEND(SP, 2);
  PUSHs(sv[0]);
  PUSHs(sv[1]);
  PUTBACK;
}

// move pushes to ...?
static void push_index_ossv(int xx, OSSV *hv)
{
  assert(hv);
  SV *sv[2] = {sv_2mortal(newSViv(xx)), osp_thr::ossv_2sv(hv)};
  dSP;
  EXTEND(SP, 2);
  PUSHs(sv[0]);
  PUSHs(sv[1]);
  PUTBACK;
}
*/

/*--------------------------------------------- */
/*--------------------------------------------- AV splash_heap */

OSPV_splashheap::OSPV_splashheap(int sz)
  : av(sz,8)
{}
OSPV_splashheap::~OSPV_splashheap()
{ CLEAR(); }
int OSPV_splashheap::FETCHSIZE()
{ return av.count(); }

char *OSPV_splashheap::os_class(STRLEN *len)
{ *len = 15; return "ObjStore::Index"; }
char *OSPV_splashheap::rep_class(STRLEN *len)
{ *len = 27; return "ObjStore::REP::Splash::Heap"; }

int OSPV_splashheap::get_perl_type() { return SVt_PVAV; }

void OSPV_splashheap::CLEAR()
{ av.reset(); }

int OSPV_splashheap::add(OSSVPV *pv)
{
  if (!conf_slot) croak("%p->add(%p): index not configured", this, pv);
  OSSVPV *conf = conf_slot;
  dOSP;
  osp->exam.init(conf->FETCHSIZE() > 2 && conf->avx(2)->istrue());
  osp->exam.load_path(conf->avx(1)->safe_rv());
  if (!osp->exam.load_target('x', pv)) return 0;
  int at = av.count();
  int pi;
  while (at && osp->exam.compare(av[pi=(at-1)/2], 0) < 0) {
    av[at].steal(av[pi]);
    at = pi;
  }
  av[at] = pv;
  return 1;
}

void OSPV_splashheap::SHIFT()
{
  OSSVPV *conf = conf_slot;
  if (!conf) croak("%s->SHIFT: heap unconfigured", os_class(&PL_na));
  if (av.count() == 0) return;
  SV *ret = osp_thr::ospv_2sv(av[0]);
  if (av.count() > 1) {
    OSSVPV *filler = av[av.count()-1].detach();
    assert(filler);
    av.compact(av.count()-1);
    dOSP;
    osp->exam.init(conf->FETCHSIZE() > 2 && conf->avx(2)->istrue());
    osp->exam.load_path(conf->avx(1)->safe_rv());
    osp->exam.load_target('x', filler);
    
    int at=0;
    int leaf = av.count()/2;
    while (at < leaf) {
      int jx = at*2+1;
      int kx = jx+1;
      if (kx < av.count() && osp->exam.compare(av[kx], av[jx]) < 0) jx = kx;
      if (osp->exam.compare(av[jx], 0) > 0) {
	av[at].steal(av[jx]);
	at = jx;
	continue;
      }
      break;
    }
    av[at].attach(filler);
  } else {
    av.compact(0);
  }
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_splashheap::FETCH(SV *sv)
{
  int xx = osp_thr::sv_2aelem(sv);
  if (xx < 0 || xx >= av.count()) return;
  SV *ret = osp_thr::ospv_2sv(av[xx]);
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

/*--------------------------------------------- */
/*--------------------------------------------- AV splash_array */

OSPV_avarray::OSPV_avarray(int sz)
  : av(sz,8)
{}

OSPV_avarray::~OSPV_avarray()
{}

double OSPV_avarray::_percent_filled()
{ croak("OSPV_avarray::_percent_filled: not implemented"); return -1; }

int OSPV_avarray::FETCHSIZE()
{ return av.count(); }

char *OSPV_avarray::os_class(STRLEN *len)
{ *len = 12; return "ObjStore::AV"; }

char *OSPV_avarray::rep_class(STRLEN *len)
{ *len = 25; return "ObjStore::REP::Splash::AV"; }

int OSPV_avarray::get_perl_type()
{ return SVt_PVAV; }

void OSPV_avarray::FETCH(SV *key)
{
  int xx = osp_thr::sv_2aelem(key);
  if (xx < 0 || xx >= av.count()) return;
  SV *ret = osp_thr::ossv_2sv(&av[xx]);
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

OSSV *OSPV_avarray::avx(int xx)
{
  if (xx < 0 || xx >= av.count()) return 0;
  DEBUG_array(warn("OSPV_avarray(0x%x)->FETCH(%d)", this, xx));
  return &av[xx];
}

OSSV *OSPV_avarray::fancy_traverse(char *keyish)
{
  if (_is_blessed()) {
    // This will be optimized once overload '%' works? XXX
    HV *stash = get_stash();
    SV *meth = (SV*) gv_fetchmethod(gv_stashpv("UNIVERSAL",0), "isa"); //XXX wrong
    assert(meth);
    dSP;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(HvNAME(stash), 0)));
    XPUSHs(sv_2mortal(newSVpv("ObjStore::AVHV", 0)));
    PUTBACK;
    int items = perl_call_sv(meth, G_SCALAR);
    assert(items == 1);
    SPAGAIN;
    int avhv = SvTRUEx(POPs);
    PUTBACK;
    if (avhv) {
      OSSVPV *layout = avx(0)->safe_rv();
      OSSV *ki = layout->hvx(keyish);
      if (!ki || ki->natural() != OSVt_IV16)
	croak("%s->traverse('%s'): key indexed to bizarre array slot", 
	      os_class(&PL_na), keyish);
      return avx(OSvIV16(ki));
    }
  }
  return avx(atol(keyish));
}

OSSVPV *OSPV_avarray::traverse1(osp_pathexam &exam)
{ return exam.mod_ossv(fancy_traverse(exam.get_thru()))->as_rv(); }
OSSV *OSPV_avarray::traverse2(osp_pathexam &exam)
{ return exam.mod_ossv(fancy_traverse(exam.get_thru())); }

void OSPV_avarray::make_constant()
{ for (int xx=0; xx < av.count(); xx++) OSvREADONLY_on(&av[xx]); }

void OSPV_avarray::STORE(SV *sv, SV *value)
{
  int xx = osp_thr::sv_2aelem(sv);
  DEBUG_array(warn("OSPV_avarray(0x%x)->STORE(%d)", this, xx));
  if (xx < 0) croak("STORE(%d)", xx);
  av[xx] = value;
  dTHR;
  if (GIMME_V == G_VOID) return;
  SV *ret = osp_thr::ossv_2sv(&av[xx]);
  djSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_avarray::POP()
{	
  int n= av.count()-1;
  if (n >= 0) {
    dTHR;
    if (GIMME_V != G_VOID) {
      SV *ret = osp_thr::ossv_2sv(&av[n]);
      djSP;
      XPUSHs(ret);
      PUTBACK;
    }
    av.compact(n);
  }
}

void OSPV_avarray::SHIFT()
{	
  SV *ret = &PL_sv_undef;
  if (av.count()) {
    dTHR;
    if (GIMME_V != G_VOID) {
      SV *ret = osp_thr::ossv_2sv(&av[0]);
      djSP;
      XPUSHs(ret);
      PUTBACK;
    }
    av.compact(0);
  }
}

void OSPV_avarray::PUSH(int ax, int items)
{
  for (int xx=1; xx < items; xx++) {
    av[av.count()] = ST(xx);
  }
}

void OSPV_avarray::UNSHIFT(int ax, int items)
{
  av.insert(0, items-1);
  for (int xx=0; xx < items-1; xx++) {
    av[xx] = ST(1+xx);
  }
}

void OSPV_avarray::SPLICE(int offset, int length, SV **base, int count)
{
  if (length) {
    dTHR;
    if (GIMME_V == G_ARRAY) {
      SV **sv = new SV*[length];
      for (int xx=0; xx < length; xx++) {
	sv[xx] = osp_thr::ossv_2sv(&av[offset+xx]);
      }
      dSP;
      EXTEND(SP, length);
      for (xx=0; xx < length; xx++) PUSHs(sv[xx]);
      PUTBACK;
      delete [] sv;
    } else if (GIMME_V == G_SCALAR) {
      SV *ret = osp_thr::ossv_2sv(&av[offset]);
      dSP;
      XPUSHs(ret);
      PUTBACK;
    }
  }
  int overlap = MIN(length,count);
  if (overlap) {
    for (int xx=offset; xx < offset+overlap; xx++) {
      av[xx] = base[xx-offset];
    }
  }
  if (length > count) {
    while (length-- > count) av.compact(offset+count);
  } else if (length < count) {
    av.insert(offset + overlap, count - overlap);
    for (; overlap < count; overlap++) {
      av[offset + overlap] = base[overlap];
    }
  }
}

void OSPV_avarray::CLEAR()
{
  for (int xx=0; xx < av.count(); xx++) { av[xx].set_undef(); }
  av.reset();
  assert(av.count() == 0);
}

/*
OSSVPV *OSPV_avarray::new_cursor(os_segment *seg)
{ return new(seg, OSPV_avarray_cs::get_os_typespec()) OSPV_avarray_cs(this); }

OSPV_avarray_cs::OSPV_avarray_cs(OSPV_avarray *_at)
  : OSPV_Cursor(_at)
{ seek_pole(0); }

void OSPV_avarray_cs::seek_pole(int end)
{
  OSPV_avarray *pv = (OSPV_avarray*)focus();
  if (!end) cs=0;
  else {
    cs = pv->av.count()-1;
    SERIOUS("seek_pole('end') is experimental");
  }
}

void OSPV_avarray_cs::at()
{
  OSPV_avarray *pv = (OSPV_avarray*)focus();
  int cnt = pv->av.count();
  if (cs >= 0 && cs < cnt) push_index_ossv(cs, &pv->av[cs]);
}

void OSPV_avarray_cs::next()
{
  OSPV_avarray *pv = (OSPV_avarray*)focus();
  int cnt = pv->av.count();
  at();
  if (cs < cnt) ++cs;
}
*/

/*--------------------------------------------- */
/*--------------------------------------------- AV splash_array OSPVptr */

OSPV_av2array::OSPV_av2array(int sz)
  : av(sz,8)
{}

OSPV_av2array::~OSPV_av2array()
{}

int OSPV_av2array::FETCHSIZE()
{ return av.count(); }

char *OSPV_av2array::os_class(STRLEN *len)
{ *len = 12; return "ObjStore::AV"; }

char *OSPV_av2array::rep_class(STRLEN *len)
{ *len = 28; return "ObjStore::REP::Splash::ObjAV"; }

int OSPV_av2array::get_perl_type()
{ return SVt_PVAV; }

void OSPV_av2array::FETCH(SV *key)
{
  int xx = osp_thr::sv_2aelem(key);
  if (xx < 0 || xx >= av.count()) return;
  SV *ret = osp_thr::ospv_2sv(av[xx]);
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_av2array::STORE(SV *sv, SV *value)
{
  int xx = osp_thr::sv_2aelem(sv);
  if (xx < 0) croak("STORE(%d)", xx);
  ospv_bridge *brval;
  if (!SvOK(value))
      brval = 0;
  else 
      brval = osp_thr::sv_2bridge(value, 1, os_segment::of(this));
  av[xx] = brval? brval->ospv() : 0;
  dTHR;
  if (GIMME_V == G_VOID) return;
  SV *ret = osp_thr::ospv_2sv(av[xx]);
  djSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_av2array::POP()
{	
  int n= av.count()-1;
  if (n >= 0) {
    dTHR;
    if (GIMME_V != G_VOID) {
      SV *ret = osp_thr::ospv_2sv(av[n]);
      djSP;
      XPUSHs(ret);
      PUTBACK;
    }
    av.compact(n);
  }
}

void OSPV_av2array::SHIFT()
{	
  SV *ret = &PL_sv_undef;
  if (av.count()) {
    dTHR;
    if (GIMME_V != G_VOID) {
      SV *ret = osp_thr::ospv_2sv(av[0]);
      djSP;
      XPUSHs(ret);
      PUTBACK;
    }
    av.compact(0);
  }
}

void OSPV_av2array::PUSH(int ax, int items)
{
  for (int xx=1; xx < items; xx++) {
    av[av.count()] = osp_thr::sv_2bridge(ST(xx),1)->ospv();
  }
}

void OSPV_av2array::UNSHIFT(int ax, int items)
{
  av.insert(0, items-1);
  for (int xx=0; xx < items-1; xx++) {
    av[xx] = osp_thr::sv_2bridge(ST(1+xx),1)->ospv();
  }
}

void OSPV_av2array::SPLICE(int offset, int length, SV **base, int count)
{
  if (length) {
    dTHR;
    if (GIMME_V == G_ARRAY) {
      SV **sv = new SV*[length];
      for (int xx=0; xx < length; xx++) {
	sv[xx] = osp_thr::ospv_2sv(av[offset+xx]);
      }
      dSP;
      EXTEND(SP, length);
      for (xx=0; xx < length; xx++) PUSHs(sv[xx]);
      PUTBACK;
      delete [] sv;
    } else if (GIMME_V == G_SCALAR) {
      SV *ret = osp_thr::ospv_2sv(av[offset]);
      dSP;
      XPUSHs(ret);
      PUTBACK;
    }
  }
  int overlap = MIN(length,count);
  if (overlap) {
    for (int xx=offset; xx < offset+overlap; xx++) {
      av[xx] = osp_thr::sv_2bridge(base[xx-offset],1)->ospv();
    }
  }
  if (length > count) {
    while (length-- > count) av.compact(offset+count);
  } else if (length < count) {
    av.insert(offset + overlap, count - overlap);
    for (; overlap < count; overlap++) {
      av[offset + overlap] = osp_thr::sv_2bridge(base[overlap],1)->ospv();
    }
  }
}

void OSPV_av2array::CLEAR()
{
  for (int xx=0; xx < av.count(); xx++) { av[xx].set_undef(); }
  av.reset();
  assert(av.count() == 0);
}

/*--------------------------------------------- */
/*--------------------------------------------- HV splash array #2 */

OSPV_hvarray2::OSPV_hvarray2(int sz)
  : hv(sz,8)
{}

OSPV_hvarray2::~OSPV_hvarray2()
{}

double OSPV_hvarray2::_percent_filled()
{ croak("OSPV_hvarray2::_percent_filled: not implemented"); return -1; }

int OSPV_hvarray2::FETCHSIZE()
{ return hv.count(); }

char *OSPV_hvarray2::os_class(STRLEN *len)
{ *len = 12; return "ObjStore::HV"; }

char *OSPV_hvarray2::rep_class(STRLEN *len)
{ *len = 25; return "ObjStore::REP::Splash::HV"; }

int OSPV_hvarray2::get_perl_type()
{ return SVt_PVHV; }

int OSPV_hvarray2::index_of(char *key)
{
//  warn("OSPV_hvarray2::index_of(%s)", key);
  int ok=0;
  for (int xx=0; xx < hv.count(); xx++) {
    if (hv[xx].valid() && hv[xx].rank(key) == 0) return xx;
  }
  return -1;
}

void OSPV_hvarray2::FETCH(SV *key)
{
  int xx = index_of(SvPV(key, PL_na));
  if (xx < 0) return;
  SV *ret = osp_thr::ossv_2sv(&hv[xx].hv);
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

OSSV *OSPV_hvarray2::hvx(char *key)
{
  int xx = index_of(key);
  OSSV *ret = xx==-1? 0 : &hv[xx].hv;
  DEBUG_hash(warn("OSPV_hvarray2::FETCH[%d] %s => %s",
		  xx, key, ret?ret->stringify():"undef"));
  return ret;
}

OSSVPV *OSPV_hvarray2::traverse1(osp_pathexam &exam)
{ return exam.mod_ossv(hvx(exam.get_thru()))->as_rv(); }
OSSV *OSPV_hvarray2::traverse2(osp_pathexam &exam)
{ return exam.mod_ossv(hvx(exam.get_thru())); }

void OSPV_hvarray2::make_constant()
{ for (int xx=0; xx < hv.count(); xx++) OSvREADONLY_on(&hv[xx].hv); }

void OSPV_hvarray2::STORE(SV *sv, SV *value)
{
  char *key = SvPV(sv, PL_na);
  int xx = -1;
  int open = -1;
  for (int za=0; za < hv.count(); za++) {
    if (!hv[za].valid()) {
      open = za;
    } else {
      if (hv[za].rank(key) == 0) { xx = za; break; }
    }
  }
  if (xx == -1) xx = open;
  if (xx != -1) {
    hv[xx].set_key(key);
  }
  if (xx == -1) {
    xx = hv.count();
    hv[hv.count()].set_key(key);
  }
  hv[xx].hv = value;
  DEBUG_hash(warn("OSPV_hvarray2::STORE[%x] %s => %s",
		  xx, key, hv[xx].hv.stringify()));
  dTHR;
  if (GIMME_V == G_VOID) return;
  SV *ret = osp_thr::ossv_2sv(&hv[xx].hv);
  djSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_hvarray2::DELETE(SV *key)
{
  int xx = index_of(SvPV(key, PL_na));
  if (xx != -1) hv[xx].set_undef();
}

void OSPV_hvarray2::CLEAR()
{
  int cursor = 0;
  while ((cursor = first(cursor)) != -1) {
    hv[cursor].set_undef();
    cursor++;
  }
  hv.reset();
  assert(hv.count()==0);
}

int OSPV_hvarray2::EXISTS(SV *key)
{ return index_of(SvPV(key, PL_na)) != -1; }

int OSPV_hvarray2::first(int start)
{
  int xx;
  for (xx=start; xx < hv.count(); xx++) {
    if (hv[xx].valid()) return xx;
  }
  return -1;
}

struct hvarray2_bridge : osp_smart_object {
  int cursor;
  hvarray2_bridge() : cursor(0) {}
};

void OSPV_hvarray2::FIRST(osp_smart_object **info)
{
  if (! *info) *info = new hvarray2_bridge();
  hvarray2_bridge *mg = (hvarray2_bridge*) *info;
  mg->cursor = first(0);
  if (mg->cursor != -1) {
    SV *out = hv[mg->cursor].key_2sv();
    dSP;
    XPUSHs(out);
    PUTBACK;
  }
}

void OSPV_hvarray2::NEXT(osp_smart_object **info)
{
  assert(*info);
  hvarray2_bridge *mg = (hvarray2_bridge*) *info;
  mg->cursor++;
  mg->cursor = first(mg->cursor);
  if (mg->cursor != -1) {
    SV *out = hv[mg->cursor].key_2sv();
    dSP;
    XPUSHs(out);
    PUTBACK;
  }
}

/*
OSSVPV *OSPV_hvarray2::new_cursor(os_segment *seg)
{ return new(seg, OSPV_hvarray2_cs::get_os_typespec()) OSPV_hvarray2_cs(this); }

OSPV_hvarray2_cs::OSPV_hvarray2_cs(OSPV_hvarray2 *_at)
  : OSPV_Cursor(_at)
{ seek_pole(0); }

void OSPV_hvarray2_cs::seek_pole(int end)
{
  OSPV_hvarray2 *pv = (OSPV_hvarray2*)focus();
  if (!end) cs = 0;
  else {
    cs = pv->hv.count()-1;
    SERIOUS("seek_pole('end') is experimental");
  }
}

void OSPV_hvarray2_cs::at()
{
  OSPV_hvarray2 *pv = (OSPV_hvarray2*)focus();
  int cnt = pv->hv.count();
  if (cs >= 0 && cs < cnt) push_sv_ossv(pv->hv[cs].key_2sv(), &pv->hv[cs].hv);
}

void OSPV_hvarray2_cs::next()
{
  OSPV_hvarray2 *pv = (OSPV_hvarray2*)focus();
  int cnt = pv->hv.count();
  at();
  if (cs < cnt) ++ cs;
  if (cs < cnt) { cs = pv->first(cs); if (cs==-1) cs = cnt; }
}
*/

MODULE = ObjStore::REP::Splash	PACKAGE = ObjStore::REP::Splash

PROTOTYPES: DISABLE

BOOT:
  extern _Application_schema_info ObjStore_REP_Splash_dll_schema_info;
  osp_thr::use("ObjStore::REP::Splash", OSPERL_API_VERSION);
  osp_thr::register_schema("ObjStore::REP::Splash",
	&ObjStore_REP_Splash_dll_schema_info);

MODULE = ObjStore::REP::Splash	PACKAGE = ObjStore::REP::Splash::AV

static void
OSPV_avarray::new(seg, sz)
	SV *seg;
	int sz;
	PPCODE:
	SV *CSV = ST(0);
	os_segment *area = osp_thr::sv_2segment(ST(1));
	PUTBACK;
	if (sz <= 0) {
	  croak("Non-positive cardinality");
	} else if (sz > 100000) {
	  sz = 100000;
	  SERIOUS("Cardinality > 100000; try a more suitable representation");
	}
	OSSVPV *pv;
	NEW_OS_OBJECT(pv, area, OSPV_avarray::get_os_typespec(), OSPV_avarray(sz));
	pv->bless(CSV);
	return;

MODULE = ObjStore::REP::Splash	PACKAGE = ObjStore::REP::Splash::ObjAV

static void
OSSVPV::new(seg, sz)
	SV *seg;
	int sz;
	PPCODE:
	SV *CSV = ST(0);
	os_segment *area = osp_thr::sv_2segment(ST(1));
	PUTBACK;
	if (sz <= 0) {
	  croak("Non-positive cardinality");
	}
	OSSVPV *pv;
	NEW_OS_OBJECT(pv, area, OSPV_av2array::get_os_typespec(), OSPV_av2array(sz));
	pv->bless(CSV);
	return;

MODULE = ObjStore::REP::Splash	PACKAGE = ObjStore::REP::Splash::HV

static void
OSPV_hvarray2::new(seg, sz)
	SV *seg;
	int sz;
	PPCODE:
	SV *CSV = ST(0);
	os_segment *area = osp_thr::sv_2segment(ST(1));
	PUTBACK;
	if (sz <= 0) {
	  croak("Non-positive cardinality");
	} else if (sz > 1000) {
	  sz = 1000;
	  SERIOUS("Cardinality > 1000; try a more suitable representation");
	}
	OSSVPV *pv;
	NEW_OS_OBJECT(pv, area,OSPV_hvarray2::get_os_typespec(), OSPV_hvarray2(sz));
	pv->bless(CSV);
	return;

MODULE = ObjStore::REP::Splash	PACKAGE = ObjStore::REP::Splash::Heap

static void
OSPV_splashheap::new(seg, ...)
	SV *seg;
	PROTOTYPE: $$;$
	PPCODE:
	SV *CSV = ST(0);
	os_segment *area = osp_thr::sv_2segment(ST(1));
	int sz = 20;
	if (items > 2) sz = SvIV(ST(2));
	PUTBACK;
	if (sz <= 0) {
	  croak("Non-positive cardinality");
	} else if (sz > 10000) {
	  sz = 10000;
	  SERIOUS("Cardinality > 10000; try a more suitable representation");
	}
	OSSVPV *pv;
	NEW_OS_OBJECT(pv, area,OSPV_splashheap::get_os_typespec(), OSPV_splashheap(sz));
	pv->bless(CSV);
	return;

void
OSPV_splashheap::_conf_slot(...)
	PPCODE:
	PUTBACK;
	SV *ret = 0;
	if (items == 2) {
	  if (THIS->av.count())
	    croak("Cannot change configuration of an active heap");
	  ospv_bridge *br = osp_thr::sv_2bridge(ST(1), 1, os_segment::of(THIS));
	  THIS->conf_slot = br->ospv();
	} else if (items == 1) {
	  ret = osp_thr::ospv_2sv(THIS->conf_slot);
	} else {
	  croak("OSPV_splashheap(%p)->_conf_slot: bad args", THIS);
	}
	SPAGAIN;
	if (ret) XPUSHs(ret);
