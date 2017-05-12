// -*-C++-*- mode
//
// The code duplication is unfortunate.  Ah well!
//

#include "osp-preamble.h"
#include "osperl.h"
#include "FatTree.h"
#include "XSthr.h"

#undef MIN
#define	MIN(a, b)	((a) < (b) ? (a) : (b))

/* CCov: fatal SERIOUS */
#define SERIOUS warn

struct FatTree_thr {
  XPVTC tc;
};
static FatTree_thr *construct_thr()
{
  FatTree_thr *ti = new FatTree_thr;
  init_tc(&ti->tc);
  return ti;
}
static void destory_thr(FatTree_thr *ti) //hook up XXX
{
  TcTV(&ti->tc) = 0;
  free_tc(&ti->tc);
}
dXSTHRINIT(FatTree, construct_thr(), "ObjStore::REP::FatTree::ThreadInfo");

#define dGCURSOR(dex)				\
  FatTree_thr *gl;				\
  XSTHRINFO(FatTree, gl);				\
  tc_refocus(&gl->tc, dex)

//--------------------------- ---------------------------
OSPV_fattree_av::OSPV_fattree_av()
{ init_tv(&ary); }

OSPV_fattree_av::~OSPV_fattree_av()
{ avfree_tv(&ary); }

char *OSPV_fattree_av::os_class(STRLEN *len)
{ *len = 12; return "ObjStore::AV"; }

char *OSPV_fattree_av::rep_class(STRLEN *len)
{ *len = 26; return "ObjStore::REP::FatTree::AV"; }

int OSPV_fattree_av::get_perl_type()
{ return SVt_PVAV; }

void OSPV_fattree_av::make_constant()
{
  OSSV *ret;
  dGCURSOR(&ary);
  tc_moveto(&gl->tc, 0);
  while (1) {
    if (!avtc_fetch(&gl->tc, &ret)) break;
    OSvREADONLY_on(ret);
    tc_step(&gl->tc, 1);
  }
}

int OSPV_fattree_av::FETCHSIZE()
{ return TvFILL(&ary); }

void OSPV_fattree_av::FETCH(SV *key)
{ 
  OSSV *val = avx(osp_thr::sv_2aelem(key));
  SV *ret = osp_thr::ossv_2sv(val);
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

OSSV *OSPV_fattree_av::avx(int xx)
{
  if (xx < 0 || xx >= TvFILL(&ary)) return 0;
  dGCURSOR(&ary);
  tc_moveto(&gl->tc, xx);
  OSSV *ret=0;
  avtc_fetch(&gl->tc, &ret);
  return ret;
}

void OSPV_fattree_av::STORE(SV *where, SV *value)
{
  int xx = osp_thr::sv_2aelem(where);
  if (xx < 0) croak("STORE(%d)", xx);
  dGCURSOR(&ary);
  tc_moveto(&gl->tc, xx);
  while (xx >= TvFILL(&ary)) {
    avtc_insert(&gl->tc, &PL_sv_undef);
    tc_moveto(&gl->tc, xx);
  }
  avtc_store(&gl->tc, value);
  dTHR;
  if (GIMME_V == G_VOID) return;
  OSSV *ret=0;
  avtc_fetch(&gl->tc, &ret);
  SV *sv = osp_thr::ossv_2sv(ret);
  djSP;
  XPUSHs(sv);
  PUTBACK;
}

void OSPV_fattree_av::POP()
{	
  OSSV *ret0;
  dGCURSOR(&ary);
  if (TvFILL(&ary) == 0) return;
  tc_moveto(&gl->tc, TvFILL(&ary)-1);
  dTHR;
  if (GIMME_V != G_VOID) {
    avtc_fetch(&gl->tc, &ret0);
    SV *ret = osp_thr::ossv_2sv(ret0);
    djSP;
    XPUSHs(ret);
    PUTBACK;
  }
  avtc_delete(&gl->tc);
}

void OSPV_fattree_av::SHIFT()
{
  OSSV *ret0;
  dGCURSOR(&ary);
  if (TvFILL(&ary) == 0) return;
  tc_moveto(&gl->tc, 0);
  dTHR;
  if (GIMME_V != G_VOID) {
    avtc_fetch(&gl->tc, &ret0);
    SV *ret = osp_thr::ossv_2sv(ret0);
    djSP;
    XPUSHs(ret);
    PUTBACK;
  }
  avtc_delete(&gl->tc);
}

void OSPV_fattree_av::PUSH(int ax, int items)
{
  dGCURSOR(&ary);
  for (int xx=1; xx < items; xx++) {
    tc_moveto(&gl->tc, TvFILL(&ary)+1);
    avtc_insert(&gl->tc, ST(xx));
  }
}

void OSPV_fattree_av::UNSHIFT(int ax, int items)
{
  dGCURSOR(&ary);
  for (int xx=0; xx < items-1; xx++) {
    tc_moveto(&gl->tc, xx);
    avtc_insert(&gl->tc, ST(1+xx));
  }
}

void OSPV_fattree_av::SPLICE(int offset, int length, SV **base, int count)
{
  dGCURSOR(&ary);
  if (length) {
    dTHR;
    if (GIMME_V == G_ARRAY) {
      dSP;
      SV **sv = new SV*[length];
      tc_moveto(&gl->tc, offset);
      for (int xx=0; xx < length; xx++) {
	OSSV *ret;
	int ok = avtc_fetch(&gl->tc, &ret);
	assert(ok);
	sv[xx] = osp_thr::ossv_2sv(ret);
	tc_step(&gl->tc, 1);
      }
      EXTEND(SP, length);
      for (xx=0; xx < length; xx++) PUSHs(sv[xx]);
      PUTBACK;
      delete [] sv;
    } else if (GIMME_V == G_SCALAR) {
      tc_moveto(&gl->tc, offset);
      OSSV *tmp;
      int ok = avtc_fetch(&gl->tc, &tmp);
      assert(ok);
      dSP;
      SV *ret = osp_thr::ossv_2sv(tmp);
      XPUSHs(ret);
      PUTBACK;
    }
  }
  int overlap = MIN(length,count);
  if (overlap) {
    tc_moveto(&gl->tc, offset);
    for (int xx=offset; xx < offset+overlap; xx++) {
      avtc_store(&gl->tc, base[xx-offset]);
      tc_step(&gl->tc, 1);
    }
  }
  if (length > count) {
    tc_moveto(&gl->tc, offset+count);
    while (length-- > count) avtc_delete(&gl->tc);
  } else if (length < count) {
    tc_moveto(&gl->tc, offset+length);
    for (; overlap < count; overlap++) {
      avtc_insert(&gl->tc, base[overlap]);
      tc_step(&gl->tc, 1);
    }
  }
}

void OSPV_fattree_av::CLEAR()
{
  XPVTC tc;     //keep our own cursor for nesting
  init_tc(&tc);
  tc_refocus(&tc, &ary);
  tc_moveto(&tc, 0);
  while (TvFILL(&ary))
    avtc_delete(&tc);
  free_tc(&tc);
}

//--------------------------- ---------------------------
OSPV_fattree_av2::OSPV_fattree_av2()
{ init_tv(&ary); }

OSPV_fattree_av2::~OSPV_fattree_av2()
{ av2free_tv(&ary); }

char *OSPV_fattree_av2::os_class(STRLEN *len)
{ *len = 12; return "ObjStore::AV"; }

char *OSPV_fattree_av2::rep_class(STRLEN *len)
{ *len = 29; return "ObjStore::REP::FatTree::ObjAV"; }

int OSPV_fattree_av2::get_perl_type()
{ return SVt_PVAV; }

int OSPV_fattree_av2::FETCHSIZE()
{ return TvFILL(&ary); }

void OSPV_fattree_av2::FETCH(SV *key)
{ 
  int xx = osp_thr::sv_2aelem(key);
  if (xx < 0 || xx >= TvFILL(&ary)) return;
  dGCURSOR(&ary);
  tc_moveto(&gl->tc, xx);
  OSSVPV *val=0;
  av2tc_fetch(&gl->tc, &val);
  SV *ret = osp_thr::ospv_2sv(val);
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_fattree_av2::STORE(SV *where, SV *value)
{
  int xx = osp_thr::sv_2aelem(where);
  if (xx < 0) croak("STORE(%d)", xx);
  dGCURSOR(&ary);
  tc_moveto(&gl->tc, xx);
  while (xx >= TvFILL(&ary)) {
    av2tc_insert(&gl->tc, 0);
    tc_moveto(&gl->tc, xx);
  }
  av2tc_store(&gl->tc, osp_thr::sv_2bridge(value, 1)->ospv());
  dTHR;
  if (GIMME_V == G_VOID) return;
  OSSVPV *ret=0;
  av2tc_fetch(&gl->tc, &ret);
  SV *sv = osp_thr::ospv_2sv(ret);
  djSP;
  XPUSHs(sv);
  PUTBACK;
}

void OSPV_fattree_av2::POP()
{	
  OSSVPV *ret0;
  dGCURSOR(&ary);
  if (TvFILL(&ary) == 0) return;
  tc_moveto(&gl->tc, TvFILL(&ary)-1);
  dTHR;
  if (GIMME_V != G_VOID) {
    av2tc_fetch(&gl->tc, &ret0);
    SV *ret = osp_thr::ospv_2sv(ret0);
    djSP;
    XPUSHs(ret);
    PUTBACK;
  }
  av2tc_delete(&gl->tc);
}

void OSPV_fattree_av2::SHIFT()
{
  OSSVPV *ret0;
  dGCURSOR(&ary);
  if (TvFILL(&ary) == 0) return;
  tc_moveto(&gl->tc, 0);
  dTHR;
  if (GIMME_V != G_VOID) {
    av2tc_fetch(&gl->tc, &ret0);
    SV *ret = osp_thr::ospv_2sv(ret0);
    djSP;
    XPUSHs(ret);
    PUTBACK;
  }
  av2tc_delete(&gl->tc);
}

void OSPV_fattree_av2::PUSH(int ax, int items)
{
  dGCURSOR(&ary);
  for (int xx=1; xx < items; xx++) {
    tc_moveto(&gl->tc, TvFILL(&ary)+1);
    av2tc_insert(&gl->tc, osp_thr::sv_2bridge(ST(xx), 1)->ospv());
  }
}

void OSPV_fattree_av2::UNSHIFT(int ax, int items)
{
  dGCURSOR(&ary);
  for (int xx=0; xx < items-1; xx++) {
    tc_moveto(&gl->tc, xx);
    av2tc_insert(&gl->tc, osp_thr::sv_2bridge(ST(1+xx), 1)->ospv());
  }
}

void OSPV_fattree_av2::SPLICE(int offset, int length, SV **base, int count)
{
  dGCURSOR(&ary);
  if (length) {
    dTHR;
    if (GIMME_V == G_ARRAY) {
      dSP;
      SV **sv = new SV*[length];
      tc_moveto(&gl->tc, offset);
      for (int xx=0; xx < length; xx++) {
	OSSVPV *ret;
	int ok = av2tc_fetch(&gl->tc, &ret);
	assert(ok);
	sv[xx] = osp_thr::ospv_2sv(ret);
	tc_step(&gl->tc, 1);
      }
      EXTEND(SP, length);
      for (xx=0; xx < length; xx++) PUSHs(sv[xx]);
      PUTBACK;
      delete [] sv;
    } else if (GIMME_V == G_SCALAR) {
      tc_moveto(&gl->tc, offset);
      OSSVPV *tmp;
      int ok = av2tc_fetch(&gl->tc, &tmp);
      assert(ok);
      dSP;
      SV *ret = osp_thr::ospv_2sv(tmp);
      XPUSHs(ret);
      PUTBACK;
    }
  }
  int overlap = MIN(length,count);
  if (overlap) {
    tc_moveto(&gl->tc, offset);
    for (int xx=offset; xx < offset+overlap; xx++) {
      av2tc_store(&gl->tc, osp_thr::sv_2bridge(base[xx-offset],1)->ospv());
      tc_step(&gl->tc, 1);
    }
  }
  if (length > count) {
    tc_moveto(&gl->tc, offset+count);
    while (length-- > count) av2tc_delete(&gl->tc);
  } else if (length < count) {
    tc_moveto(&gl->tc, offset+length);
    for (; overlap < count; overlap++) {
      av2tc_insert(&gl->tc, osp_thr::sv_2bridge(base[overlap], 1)->ospv());
      tc_step(&gl->tc, 1);
    }
  }
}

void OSPV_fattree_av2::CLEAR()
{
  XPVTC tc;     //keep our own cursor for nesting
  init_tc(&tc);
  tc_refocus(&tc, &ary);
  tc_moveto(&tc, 0);
  while (TvFILL(&ary))
    av2tc_delete(&tc);
  free_tc(&tc);
}

//--------------------------- ---------------------------

OSPV_fatindex2::OSPV_fatindex2()
{ init_tv(&tv); conf_slot=0; }

OSPV_fatindex2::~OSPV_fatindex2()
{
  CLEAR(); 
  dex2free_tv(&tv);
  if (conf_slot) conf_slot->REF_dec();
}

char *OSPV_fatindex2::os_class(STRLEN *len)
{ *len = 15; return "ObjStore::Index"; }

char *OSPV_fatindex2::rep_class(STRLEN *len)
{ *len = 29; return "ObjStore::REP::FatTree::Index"; }

int OSPV_fatindex2::get_perl_type()
{ return SVt_PVAV; }

void OSPV_fatindex2::CLEAR()
{
  if (!conf_slot) {
    assert(TvFILL(&tv) == 0);
    return;
  }
  dOSP;
  osp_pathexam exam;  //keep our own cursor for nesting
  exam.init();
  exam.load_path(conf_slot->avx(2)->safe_rv());
  XPVTC tc;
  init_tc(&tc);     //keep our own cursor for nesting
  tc_refocus(&tc, &tv);
  tc_moveto(&tc, 0);
  OSSVPV *pv;
  while (dex2tc_fetch(&tc, &pv)) {
    exam.load_target('u', pv);
    pv->REF_dec();
    tc_step(&tc, 1);
  }
  dex2tv_clear(&tv);
  free_tc(&tc);
}

int OSPV_fatindex2::add(OSSVPV *target)
{
  STRLEN na;
  if (!conf_slot)
    croak("%s->add(%p): index not configured", os_class(&na), target);
  int unique = conf_slot->avx(1)->istrue();

  dOSP;
  osp_pathexam *exam = &osp->exam;
  exam->init();
  exam->load_path(conf_slot->avx(2)->safe_rv());
  if (!exam->load_target('x', target)) return 0;

  dGCURSOR(&tv);
  if (dex2tc_seek(&gl->tc, unique, *exam)) {
    OSSVPV *obj;
    if (unique) {
      dex2tc_fetch(&gl->tc, &obj);
      if (obj == target) {
	return 0; //already added
      } else {
	croak("%s->add(): attempt to insert two distinct records (0x%p & 0x%p) matching '%s' into a unique index", os_class(&na), target, obj, exam->kv_string());
      }
    } else {
      dex2tc_fetch(&gl->tc, &obj);
      if (obj == target) return 0; //already added
      while (1) {
	if (!tc_step(&gl->tc, 1)) break;
	dex2tc_fetch(&gl->tc, &obj);
	if (obj == target) return 0; //already added
	int cmp;
	cmp = exam->compare(obj, 0);
	if (cmp != 0) {
	  tc_step(&gl->tc, -1); //none match; must backup and add it
	  break;
	}
      }
    }
  }
  exam->load_target('s', target);
  exam->no_conflict();
  DEBUG_index(warn("%p->add(%p)", this, target));
  target->REF_inc();
  dex2tc_insert(&gl->tc, target);
  return 1;
}

int OSPV_fatindex2::remove(OSSVPV *target)
{
  STRLEN na;
  assert(conf_slot);
  int unique = conf_slot->avx(1)->istrue();

  dOSP;
  osp_pathexam *exam = &osp->exam;
  exam->init();
  exam->load_path(conf_slot->avx(2)->safe_rv());
  if (!exam->load_target('u', target))
    croak("%s->remove: %s could not be a member (%s)",
	  os_class(&na), target->os_class(&na), exam->kv_string());

  dGCURSOR(&tv);
  int match = dex2tc_seek(&gl->tc, unique, *exam);
  if (!match)
    croak("%s->remove: (%s) not found", os_class(&na), exam->kv_string());
  if (unique) {
    OSSVPV *obj;
    dex2tc_fetch(&gl->tc, &obj);
    if (target != obj) croak("%p->remove: pointer mismatch at (%s)",
			     this, exam->kv_string());
  } else {
    OSSVPV *obj;
    while (dex2tc_fetch(&gl->tc, &obj)) {
      if (obj == target) break;
      if (!tc_step(&gl->tc, 1))
	croak("%s->remove: (%s) not found",
	      os_class(&na), exam->kv_string());
      int cmp;
      cmp = exam->compare(obj, 0);
      if (cmp != 0)
	croak("%s->remove: (%s) not found",
	      os_class(&na), exam->kv_string());
    }
  }
  DEBUG_index(warn("%p->remove(%p)", this, target));
  dex2tc_delete(&gl->tc);
  target->REF_dec();
  return 1;
}

/*
need pathexam stuff XXX

void OSPV_fatindex2::POP()
{	
  OSSV *ret0;
  dGCURSOR(&tv);
  if (TvFILL(&tv) == 0) return;
  tc_moveto(&gl->tc, TvFILL(&tv)-1);
  dSP;
  if (GIMME_V != G_VOID) {
    dex2tc_fetch(&gl->tc, &ret0);
    XPUSHs(osp_thr::ossv_2sv(ret0));
    PUTBACK;
  }
  dex2tc_delete(&gl->tc);
}

void OSPV_fatindex2::SHIFT()
{
  OSSV *ret0;
  dGCURSOR(&tv);
  if (TvFILL(&tv) == 0) return;
  tc_moveto(&gl->tc, 0);
  dSP;
  if (GIMME_V != G_VOID) {
    dex2tc_fetch(&gl->tc, &ret0);
    XPUSHs(osp_thr::ossv_2sv(ret0));
    PUTBACK;
  }
  dex2tc_delete(&gl->tc);
}
*/

// XXX factor?
void OSPV_fatindex2::FETCH(SV *key)
{
  if (!conf_slot) return;
  unsigned long xx = osp_thr::sv_2aelem(key);
  dGCURSOR(&tv);
  tc_moveto(&gl->tc, xx);
  OSSVPV *pv=0;
  dex2tc_fetch(&gl->tc, &pv);
  SV *sv = osp_thr::ospv_2sv(pv);
  dSP;
  XPUSHs(sv);
  PUTBACK;
}

double OSPV_fatindex2::_percent_filled()
{ 
  SERIOUS("_percent_filled() is experimental");
  return TvFILL(&tv) / (double) (TvMAX(&tv) * dex2TnWIDTH);
}
int OSPV_fatindex2::FETCHSIZE()
{ return TvFILL(&tv); }

OSSVPV *OSPV_fatindex2::new_cursor(os_segment *seg)
{ return new(seg, OSPV_fatindex2_cs::get_os_typespec()) OSPV_fatindex2_cs(this); }

//--------------------------- ---------------------------

OSPV_fatindex2_cs::OSPV_fatindex2_cs(OSPV_fatindex2 *_at)
{
  init_tc(&tc);
  if (osp_thr::can_update(this, _at)) _at->REF_inc();
  tc_refocus(&tc, &_at->tv);
  myfocus = _at;
}

OSPV_fatindex2_cs::~OSPV_fatindex2_cs()
{
  if (osp_thr::can_update(this, myfocus)) myfocus->REF_dec();
  free_tc(&tc);
}

OSSVPV *OSPV_fatindex2_cs::focus()
{ return myfocus; }

void OSPV_fatindex2_cs::moveto(I32 xto)
{ tc_moveto(&tc, xto); }
void OSPV_fatindex2_cs::step(I32 delta)
{ tc_step(&tc, delta); }
I32 OSPV_fatindex2_cs::pos()
{ return tc_pos(&tc); }

void OSPV_fatindex2_cs::keys()
{
  OSSVPV *pv;
  if (dex2tc_fetch(&tc, &pv)) {
    dOSP;
    osp_pathexam *exam = &osp->exam;
    exam->init();
    exam->load_path(myfocus->conf_slot->avx(2)->safe_rv());
    exam->load_target('x', pv);
    exam->push_keys();
  }
}

int OSPV_fatindex2_cs::seek(osp_pathexam &exam)
{
  OSSVPV *conf = myfocus->conf_slot;
  exam.load_path(conf->avx(2)->safe_rv());
  if (exam.get_keycnt() < 1) {
    warn("Seek to where?  No keys given");
    return 0;
  }
  if (exam.get_pathcnt() < 1) {
    warn("Seek with no path.  Is index configured?");
    return 0;
  }
  return dex2tc_seek(&tc, conf->avx(1)->istrue(), exam);
}

void OSPV_fatindex2_cs::at()
{
  OSSVPV *pv;
  if (dex2tc_fetch(&tc, &pv)) {
    SV *ret = osp_thr::ospv_2sv(pv);
    dSP;
    XPUSHs(ret);
    PUTBACK;
  }
}

void OSPV_fatindex2_cs::_debug1(void *)
{
#ifdef TV_DUMP
  if (!TcDEBUGSEEK(&tc)) TcFLAGS(&tc) |= TCptv_DEBUGSEEK;
  else dex2tc_dump(&tc);
#endif
}

//--------------------------- ---------------------------

OSPV_fatindex3::OSPV_fatindex3()
{ init_tv(&tv); }

OSPV_fatindex3::~OSPV_fatindex3()
{
  CLEAR(); 
  dex3free_tv(&tv);
}

char *OSPV_fatindex3::os_class(STRLEN *len)
{ *len = 15; return "ObjStore::Index"; }

char *OSPV_fatindex3::rep_class(STRLEN *len)
{ *len = 31; return "ObjStore::REP::FatTree::KCIndex"; }

int OSPV_fatindex3::get_perl_type()
{ return SVt_PVAV; }

void OSPV_fatindex3::CLEAR()
{
  if (!conf_slot) {
    assert(TvFILL(&tv) == 0);
    return;
  }
  dOSP;
  osp_pathexam exam;  //keep our own cursor for nesting
  exam.init();
  exam.load_path(conf_slot.resolve()->avx(2)->safe_rv());
  XPVTC tc;
  init_tc(&tc);     //keep our own cursor for nesting
  tc_refocus(&tc, &tv);
  tc_moveto(&tc, 0);
  OSSVPV *pv;
  while (dex3tc_fetch(&tc, &pv)) {
    exam.load_target('u', pv);
    tc_step(&tc, 1);
  }
  dex3tv_clear(&tv);
  free_tc(&tc);
}

int OSPV_fatindex3::add(OSSVPV *target)
{
  STRLEN na;
  if (!conf_slot)
    croak("%s->add(%p): index not configured", os_class(&na), target);
  int unique = conf_slot.resolve()->avx(1)->istrue();

  dOSP;
  osp_pathexam *exam = &osp->exam;
  exam->init();
  exam->load_path(conf_slot.resolve()->avx(2)->safe_rv());
  if (!exam->load_target('x', target)) return 0;

  dGCURSOR(&tv);
  if (dex3tc_seek(&gl->tc, unique, *exam)) {
    OSSVPV *obj;
    if (unique) {
      dex3tc_fetch(&gl->tc, &obj);
      if (obj == target) {
	return 0; //already added
      } else {
	croak("%s->add(): attempt to insert two distinct records (0x%p & 0x%p) matching '%s' into a unique index", os_class(&na), target, obj, exam->kv_string());
      }
    } else {
      dex3tc_fetch(&gl->tc, &obj);
      if (obj == target) return 0; //already added
      while (1) {
	if (!tc_step(&gl->tc, 1)) break;
	dex3tc_fetch(&gl->tc, &obj);
	if (obj == target) return 0; //already added
	int cmp;
	cmp = exam->compare(obj, 0);
	if (cmp != 0) {
	  tc_step(&gl->tc, -1); //none match; must backup and add it
	  break;
	}
      }
    }
  }
  exam->load_target('s', target);
  exam->no_conflict();
  DEBUG_index(warn("%p->add(%p)", this, target));
  dex3tc_insert(*exam, &gl->tc, target);
  return 1;
}

int OSPV_fatindex3::remove(OSSVPV *target)
{
  STRLEN na;
  assert(conf_slot);
  int unique = conf_slot.resolve()->avx(1)->istrue();

  dOSP;
  osp_pathexam *exam = &osp->exam;
  exam->init();
  exam->load_path(conf_slot.resolve()->avx(2)->safe_rv());
  if (!exam->load_target('u', target))
    croak("%s->remove: %s could not be a member (%s)",
	  os_class(&na), target->os_class(&na), exam->kv_string());

  dGCURSOR(&tv);
  int match = dex3tc_seek(&gl->tc, unique, *exam);
  if (!match)
    croak("%s->remove: (%s) not found", os_class(&na), exam->kv_string());
  if (unique) {
    OSSVPV *obj;
    dex3tc_fetch(&gl->tc, &obj);
    if (target != obj) croak("%p->remove: pointer mismatch at (%s)",
			     this, exam->kv_string());
  } else {
    OSSVPV *obj;
    while (dex3tc_fetch(&gl->tc, &obj)) {
      if (obj == target) break;
      if (!tc_step(&gl->tc, 1))
	croak("%s->remove: (%s) not found", os_class(&na), exam->kv_string());
      int cmp;
      cmp = exam->compare(obj, 0);
      if (cmp != 0)
	croak("%s->remove: (%s) not found", os_class(&na), exam->kv_string());
    }
  }
  DEBUG_index(warn("%p->remove(%p)", this, target));
  dex3tc_delete(*exam, &gl->tc);
  return 1;
}

void OSPV_fatindex3::FETCH(SV *key)
{
  if (!conf_slot) return;
  unsigned long xx = osp_thr::sv_2aelem(key);
  dGCURSOR(&tv);
  tc_moveto(&gl->tc, xx);
  OSSVPV *pv=0;
  dex3tc_fetch(&gl->tc, &pv);
  SV *sv = osp_thr::ospv_2sv(pv);
  dSP;
  XPUSHs(sv);
  PUTBACK;
}

int OSPV_fatindex3::FETCHSIZE()
{ return TvFILL(&tv); }

OSSVPV *OSPV_fatindex3::new_cursor(os_segment *seg)
{ return new(seg, OSPV_fatindex3_cs::get_os_typespec()) OSPV_fatindex3_cs(this); }

//--------------------------- ---------------------------

OSPV_fatindex3_cs::OSPV_fatindex3_cs(OSPV_fatindex3 *_at)
{
  init_tc(&tc);
  tc_refocus(&tc, &_at->tv);
  obj = _at;
}

OSPV_fatindex3_cs::~OSPV_fatindex3_cs()
{ free_tc(&tc); }

OSSVPV *OSPV_fatindex3_cs::focus()
{ return myfocus(); }

void OSPV_fatindex3_cs::moveto(I32 xto) { tc_moveto(&tc, xto); }
void OSPV_fatindex3_cs::step(I32 delta) { tc_step(&tc, delta); }
I32 OSPV_fatindex3_cs::pos() { return tc_pos(&tc); }

void OSPV_fatindex3_cs::keys()
{
  OSSVPV *pv;
  if (dex2tc_fetch(&tc, &pv)) {
    dOSP;
    osp_pathexam *exam = &osp->exam;
    exam->init();
    exam->load_path(conf_slot()->avx(2)->safe_rv());
    exam->load_target('x', pv);
    exam->push_keys();
  }
}

int OSPV_fatindex3_cs::seek(osp_pathexam &exam)
{
  OSSVPV *conf = conf_slot();
  exam.load_path(conf->avx(2)->safe_rv());
  if (exam.get_keycnt() < 1) {
    warn("Seek to where?  No keys given");
    return 0;
  }
  if (exam.get_pathcnt() < 1) {
    warn("Seek with no path.  Is index configured?");
    return 0;
  }
  return dex3tc_seek(&tc, conf->avx(1)->istrue(), exam);
}

void OSPV_fatindex3_cs::at()
{
  OSSVPV *pv;
  if (dex3tc_fetch(&tc, &pv)) {
    SV *ret = osp_thr::ospv_2sv(pv);
    dSP;
    XPUSHs(ret);
    PUTBACK;
  }
}

MODULE = ObjStore::REP::FatTree		PACKAGE = ObjStore::REP::FatTree

PROTOTYPES: DISABLE

BOOT:
  extern _Application_schema_info ObjStore_REP_FatTree_dll_schema_info;
  osp_thr::use("ObjStore::REP::FatTree", OSPERL_API_VERSION);
  osp_thr::register_schema("ObjStore::REP::FatTree",
	&ObjStore_REP_FatTree_dll_schema_info);
  XSTHRBOOT(FatTree);

MODULE = ObjStore::REP::FatTree		PACKAGE = ObjStore::REP::FatTree::AV

static void
OSSVPV::new(seg, sz)
	SV *seg;
	int sz;
	PPCODE:
	SV *CSV = ST(0);
	os_segment *area = osp_thr::sv_2segment(ST(1));
	PUTBACK;
	if (sz < 40) {
	  SERIOUS("ObjStore::REP::FatTree::AV->new(%d): representation not efficient for small arrays", sz);
	}
	OSPV_fattree_av *pv;
	NEW_OS_OBJECT(pv, area, OSPV_fattree_av::get_os_typespec(), OSPV_fattree_av());
	pv->bless(CSV);
	return;

MODULE = ObjStore::REP::FatTree		PACKAGE = ObjStore::REP::FatTree::ObjAV

static void
OSSVPV::new(seg, sz)
	SV *seg;
	int sz;
	PPCODE:
	SV *CSV = ST(0);
	os_segment *area = osp_thr::sv_2segment(ST(1));
	PUTBACK;
	if (sz < 40) {
	  SERIOUS("ObjStore::REP::FatTree::ObjAV->new(%d): representation not efficient for small arrays", sz);
	}
	OSPV_fattree_av2 *pv;
	NEW_OS_OBJECT(pv, area, OSPV_fattree_av2::get_os_typespec(), OSPV_fattree_av2());
	pv->bless(CSV);
	return;

MODULE = ObjStore::REP::FatTree		PACKAGE = ObjStore::REP::FatTree::Index

static void
OSPV_fatindex2::new(seg)
	SV *seg;
	PPCODE:
	os_segment *area = osp_thr::sv_2segment(ST(1));
	PUTBACK;
	OSPV_fatindex2 *pv;
	if (area == os_segment::get_transient_segment())
	  croak("transient indices are too easily corrupted");
	NEW_OS_OBJECT(pv, area, OSPV_fatindex2::get_os_typespec(), OSPV_fatindex2());
	pv->bless(ST(0));
	return;

void
OSPV_fatindex2::_conf_slot(...)
	PPCODE:
	PUTBACK;
	SV *ret = 0;
	if (items == 2) {
	  if (TvFILL(&THIS->tv)) {
	    croak("Configuration of an active index cannot be changed");
	  }
	  ospv_bridge *br = osp_thr::sv_2bridge(ST(1), 1, os_segment::of(THIS));
	  OSSVPV *nconf = br->ospv();
	  nconf->REF_inc();
	  if (THIS->conf_slot) THIS->conf_slot->REF_dec();
	  THIS->conf_slot = nconf;
	} else if (items == 1) {
	  ret = osp_thr::ospv_2sv(THIS->conf_slot);
	} else {
	  croak("OSPV_fatindex2(%p)->_conf_slot: bad args", THIS);
	}
	SPAGAIN;
	if (ret) XPUSHs(ret);

MODULE = ObjStore::REP::FatTree		PACKAGE = ObjStore::REP::FatTree::KCIndex

static void
OSPV_fatindex3::new(seg)
	SV *seg;
	PPCODE:
	os_segment *area = osp_thr::sv_2segment(ST(1));
	PUTBACK;
	OSPV_fatindex3 *pv;
	if (area == os_segment::get_transient_segment())
	  croak("transient indices are too easily corrupted");
	NEW_OS_OBJECT(pv, area, OSPV_fatindex3::get_os_typespec(), OSPV_fatindex3());
	pv->bless(ST(0));
	return;

void
OSPV_fatindex3::_conf_slot(...)
	PPCODE:
	PUTBACK;
	SV *ret = 0;
	if (items == 2) {
	  if (TvFILL(&THIS->tv))
	    croak("Configuration of an active index cannot be changed");
	  ospv_bridge *br = osp_thr::sv_2bridge(ST(1), 1, os_segment::of(THIS));
	  THIS->conf_slot = br->ospv();
	} else if (items == 1) {
	  ret = osp_thr::ospv_2sv(THIS->conf_slot);
	} else {
	  croak("OSPV_fatindex3(%p)->_conf_slot: bad args", THIS);
	}
	SPAGAIN;
	if (ret) XPUSHs(ret);
