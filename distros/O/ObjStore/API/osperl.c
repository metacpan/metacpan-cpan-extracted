// Switch to -*-c++-*- mode please!

#define OSPERL_PRIVATE
#include "osp-preamble.h"
#include "osperl.h"
#include <ostore/coll.hh>

/* CCov: off */

int osp_thr::sv_dump_on_error = 1;

#define OR_RETURN_UNDEF(cond) if (!(cond)) return &PL_sv_undef;

/* CCov: fatal OLD_SUPPORT_CODE SERIOUS RETURN_BADNAME */
#define OLD_SUPPORT_CODE
#define SERIOUS warn
#define RETURN_BADNAME(len) *len=3;return "???"

void osp_thr::use(const char *YourName, int ver)
{
  if (ver != OSPERL_API_VERSION)
    croak("ObjStore API mismatch; please recompile '%s'\n", YourName);
}

void osp_ring::verify()
{
  // still doubly linked correctly?
  osp_ring *cs = next;
  while (cs != this) {
    assert(cs);
    cs = cs->next;
  }
  cs = prev;
  while (cs != this) {
    assert(cs);
    cs = cs->prev;
  }
}

/* CCov: on */

/*--------------------------------------------- schema */

HV *osp_thr::Schema = 0;

void osp_thr::register_schema(char *cl, _Application_schema_info *sch)
{
  assert(Schema);
  assert(cl);
  assert(sch);
  STRLEN len = strlen(cl);
  SV *sv = osp_thr::any_2sv(sch, "ObjStore::Schema");
  hv_store(Schema, cl, len, sv, 0);
}

/*--------------------------------------------- typemap services */

HV *typemap_any::MyStash=0;
IV typemap_any::Instances=0;

SV *osp_thr::any_2sv(void *any, char *CLASS)
{
  if (!any) return &PL_sv_undef;
  SV *ret = newSV(0);
  sv_setref_pv(ret, CLASS, new typemap_any(any));
  return ret;
}

os_segment *osp_thr::sv_2segment(SV *sv)
{
  if (sv_isa(sv, "ObjStore::Segment"))
    return (os_segment*) typemap_any::decode(sv);
  if (SvPOK(sv) && strEQ(SvPV(sv, PL_na), "transient"))
    return os_segment::get_transient_segment();
  if (osp_thr::sv_dump_on_error)
      Perl_sv_dump(sv);
  croak("sv_2segment only accepts ObjStore::Segment");
  return 0;
}

void *typemap_any::my_dynacast(void *obj, HV *stash, int failok)
{
  if (failok) return 0;
  croak("Don't know how to convert ObjStore object to a '%s'", HvNAME(stash));
  return 0;
}

void *typemap_any::try_decode(SV *sv, dynacast_fn want, int nuke)
{
  SV *orig = sv;
  if (SvROK(sv)) {
    sv = SvRV(sv);
    if (SvOBJECT(sv) && SvTYPE(sv) == SVt_PVMG) {
      typemap_any *ta = (typemap_any*) SvIV(sv);
      void *ret = ta->ptr;
      assert(ret);
      if (ta->dynacast != want) return 0;
      if (nuke) delete ta;
      return ret;
    }
  }
  if (osp_thr::sv_dump_on_error)
      Perl_sv_dump(orig);
  croak("ObjStore typemap_any");
  return 0;
}

void *typemap_any::decode(SV *sv, int nuke)
{
  SV *orig = sv;
  if (SvROK(sv)) {
    sv = SvRV(sv);
    if (SvOBJECT(sv) && SvTYPE(sv) == SVt_PVMG) {
      typemap_any *ta = (typemap_any*) SvIV(sv);
      void *ret = ta->ptr;
      assert(ret);
      if (ta->dynacast != ta->my_dynacast)
	ret = (*ta->dynacast)(ret, ta->MyStash, 0);
      if (nuke) delete ta;
      return ret;
    }
  }
  if (osp_thr::sv_dump_on_error)
      Perl_sv_dump(orig);
  croak("ObjStore typemap_any");
  return 0;
}

void *osp_thr::default_dynacast(void *obj, HV *stash, int failok)
{
  if (failok) return 0;
  croak("Don't know how to convert ObjStore object to a '%s'", HvNAME(stash));
  return 0;
}

ospv_bridge *osp_thr::sv_2bridge(SV *ref, int force, os_segment *near)
{
// Is tied?  Examine tied object, extract ospv_bridge from '~'
// Is OSSV in a PVMG?

  DEBUG_decode(Perl_sv_dump(ref));

  // Must check before SvOK
  if (SvGMAGICAL(ref))
    mg_get(ref);

  if (!SvOK(ref)) {
    if (force)
      croak("sv_2bridge: Use of uninitialized value");
    return 0;
  }

  if (!SvROK(ref)) {
    if (force) {
	if (osp_thr::sv_dump_on_error)
	    Perl_sv_dump(ref);
	croak("sv_2bridge: Expecting persistent data");
    }
    return 0;
  }
  SV *nval = SvRV(ref);

  ospv_bridge *br = 0;
  do {
    if (!SvOBJECT(nval)) break;
    if (SvTYPE(nval) == SVt_PVHV || SvTYPE(nval) == SVt_PVAV) {
      MAGIC *magic = mg_find(nval, '~');
      if (!magic) break;
      SV *mgobj = (SV*) magic->mg_obj;
      if (!SvROK(mgobj)) break;
      br = (ospv_bridge*) SvIV((SV*)SvRV(mgobj));
    } else if (SvTYPE(nval) == SVt_PVMG) {
      br = (ospv_bridge*) SvIV(nval);
      if (br->dynacast != osp_thr::default_dynacast) {
	DEBUG_dynacast(warn("Trying dynacast(0x%x) to ObjStore::Bridge",
			    br->dynacast));
	/* unfortunately this will give an illegal instruction
	   exception (or worse) if the dynacast isn't a function pointer */
	br = (ospv_bridge*) (br->dynacast)(br, BridgeStash, 1);
      }
    }
  } while (0);

  if (br) {
    // until exceptions are more reliable XXX
    if (br->invalid()) {
      croak("sv_2bridge: persistent data out of scope");
    }
#if OSP_SAFE_BRIDGE
    if (br->holding && !br->manual_hold && br->is_weak()) {
      warn("sv_2bridge: HOLD needed; a transient variable has the only reference to a persistent object");
    }
#endif
    return br;
  }
  if (!near) {
    if (!force) return 0;
    if (osp_thr::sv_dump_on_error)
	Perl_sv_dump(ref);
    croak("sv_2bridge: a persistent object is manditory");
  }
  {
    dSP;
    PUSHSTACK;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(osp_thr::any_2sv(near, "ObjStore::Segment")));
    XPUSHs(ref);
    PUTBACK;
    assert(osp_thr::stargate);
    int count = perl_call_sv(osp_thr::stargate, G_SCALAR);
    assert(count==1);
    SPAGAIN;
    br = osp_thr::sv_2bridge(POPs, 0);
    PUTBACK;
    POPSTACK;
    if (!br) croak("ObjStore::stargate returned useless junk");
    //  warn("stargate returned:");
    //  br->dump();
  }
  return br;
}

static SV *ospv_2bridge(OSSVPV *pv, int hold=0)
{
  dOSP;
  ospv_bridge *br = (ospv_bridge*) osp->ospv_freelist.next_self();
  if (br) {
    br->link.detach();
  } else {
    br = new ospv_bridge;
  }
  br->init(pv);
  if (hold) br->hold();
  SV *rv = sv_setref_pv(newSV(0), 0, (void*)br);
  return rv;
}

SV *osp_thr::wrap(OSSVPV *ospv, SV *br)
{
  HV *stash = ospv->get_stash();
  switch (ospv->get_perl_type()) {
  case SVt_PVMG:{
    sv_bless(br, stash);
    sv_2mortal(br);
    DEBUG_wrap({ warn("mgwrap %p", ospv); Perl_sv_dump(br); });
    return br;}
  case SVt_PVHV:
  case SVt_PVAV:{
    SV *tied;
    if (ospv->get_perl_type() == SVt_PVHV) {
      tied = sv_2mortal((SV*) newHV());		// %tied
    } else {
      tied = sv_2mortal((SV*) newAV());		// @tied
    }
    sv_bless(br, BridgeStash);
    sv_magic(tied, br, '~', Nullch, 0);		// magic tied, '~', $mgobj
    --SvREFCNT(br);				// like ref_noinc
    
    sv_magic(tied, Nullsv, 'P', Nullch, 0);	// tie tied, CLASS

    SV *rv = newRV_inc(tied);			// $rv = \tied
    sv_2mortal(rv);
    (void)sv_bless(rv, stash);
    
    DEBUG_wrap({ warn("[av]wrap %p", ospv); Perl_sv_dump(rv); });
    return rv;}
  }
  croak("osp::ossv_2sv: unknown perl type (%d)", ospv->get_perl_type());
  return 0;
}

SV *osp_thr::ospv_2sv(OSSVPV *pv, int hold)
{
  OR_RETURN_UNDEF(pv);
  return wrap(pv, ospv_2bridge(pv, hold));
}

SV *osp_thr::ossv_2sv(OSSV *ossv, int hold)
{
  SV *ret;
  // We must to trade speed for paranoia --
  if (!ossv) return &PL_sv_undef;
  switch (ossv->natural()) {
  case OSVt_UNDEF:
  case OSVt_UNDEF2:
    return &PL_sv_undef;
  case OSVt_IV32:
    OR_RETURN_UNDEF(ossv->vptr);
    ret = sv_2mortal(newSViv(OSvIV32(ossv)));
    break;
  case OSVt_NV:
    OR_RETURN_UNDEF(ossv->vptr);
    ret = sv_2mortal(newSVnv(OSvNV(ossv)));
    break;
  case OSVt_PV:
    if (!ossv->vptr) ret = sv_2mortal(newSVpvn("", 0)); //use immortal XXX
    else {
      // Problems with eliding the copy:
      // 1. What if the persistent copy is deleted?  Read transactions only.
      // 2. They can not be packaged as simple SVPV because of the need
      //    to invalidate them. (?? revisit)
      // 3. There is significant bookkeeping overhead to invalidate
      //    at the end of the transaction.  Maybe for long strings
      //    only after the regex engine can handle streams?
      ret = sv_2mortal(newSVpvn((char*) ossv->vptr, ossv->xiv));
    }
    break;
  case OSVt_RV:{
    OR_RETURN_UNDEF(ossv->vptr);
    OSSVPV *pv = (OSSVPV*) ossv->vptr;
    ret = wrap(pv, ospv_2bridge(pv, hold));
    break;
  }
  case OSVt_IV16:
    ret = sv_2mortal(newSViv(OSvIV16(ossv)));
    break;
  case OSVt_1CHAR:
    ret = sv_2mortal(newSVpvn((char*)&ossv->xiv, 1));
    break;
  default:
    SERIOUS("OSSV %s is not implemented", ossv->type_2pv());
    return &PL_sv_undef;
  }
  assert(ret);
  if (OSvREADONLY(ossv)) SvREADONLY_on(ret); //XXX
  return ret;
}

OSSV *osp_thr::plant_ospv(os_segment *seg, OSSVPV *pv)
{
  assert(pv);
  OSSV *ossv;
  NEW_OS_OBJECT(ossv, os_segment::of(pv), OSSV::get_os_typespec(), OSSV(pv));
  return ossv;
}

OSSV *osp_thr::plant_sv(os_segment *seg, SV *nval)
{
  OSSV *ossv=0;
  assert(nval);
  assert(seg);
  if (SvROK(nval)) {
    ospv_bridge *br = osp_thr::sv_2bridge(nval, 1, seg);
    assert(br);
    OSSVPV *pv = br->ospv();
    assert(pv);
    NEW_OS_OBJECT(ossv, os_segment::of(pv), OSSV::get_os_typespec(), OSSV(pv));
  } else {
    NEW_OS_OBJECT(ossv, seg, OSSV::get_os_typespec(), OSSV(nval));
  }
  assert(ossv);
  return ossv;
}

unsigned long osp_thr::sv_2aelem(SV *sv)
{
  unsigned long xx;
  if (SvIOK(sv)) {
    xx = SvIVX(sv);
  } else if (Perl_looks_like_number(sv)) {
    xx = SvIV(sv);
  } else {
    warn("Argument \"%s\" isn't numeric in aelem", SvPV(sv,PL_na));
    xx = 0;
  }
  return xx;
}

/*--------------------------------------------- OSSV */

OSSV::OSSV() : _type(OSVt_UNDEF)
{}

OSSV::OSSV(SV *nval) : _type(OSVt_UNDEF)
{ this->operator=(nval); }

OSSV::OSSV(OSSVPV *nval) : _type(OSVt_UNDEF)
{ s(nval); }

OSSV::~OSSV()
{
  _type &= ~(OSVf_INDEXED|OSVf_READONLY);
  set_undef();
}

I32 OSSV::as_iv()
{
  switch (natural()) {
  case OSVt_IV32: return OSvIV32(this);
  case OSVt_NV: return OSvNV(this);
  case OSVt_IV16: return OSvIV16(this);
  case OSVt_UNDEF: case OSVt_UNDEF2: warn("Use of uninitialized value");
  default: return 0;
  }
}

double OSSV::as_nv()
{
  switch (natural()) {
  case OSVt_IV32: return OSvIV32(this);
  case OSVt_NV: return OSvNV(this);
  case OSVt_IV16: return OSvIV16(this);
  case OSVt_UNDEF: case OSVt_UNDEF2: warn("Use of uninitialized value");
  default: return 0;
  }
}

OSSVPV *OSSV::as_rv()
{ return this && natural() == OSVt_RV? (OSSVPV*) vptr : 0; }

OSSVPV *OSSV::safe_rv()
{
  if (!this) croak("safe_rv called with null pointer");
  if (natural() != OSVt_RV) croak("%s is not an object", type_2pv());
  return (OSSVPV*)vptr;
}

int OSSV::PvREFok()
{ return natural() == OSVt_RV; }

void OSSV::PvREF_inc(void *nval)
{
  assert (PvREFok());
  if (nval) vptr = nval;
  assert(vptr != 0);
  ((OSSVPV*)vptr)->REF_inc();
}

void OSSV::PvREF_dec()
{
  assert (PvREFok());
  ((OSSVPV*)vptr)->REF_dec();
  vptr = 0;
}

// wacky but assists C++ templates in calling undef
OSSV *OSSV::operator=(int zero)
{
  assert(zero == 0);
  set_undef();
  return this;
}

// Should always try to store numbers in the smallest space that
// preserves precision.  Is this correct?
OSSV *OSSV::operator=(SV *nval)
{
  char *tmp; STRLEN tmplen;

  DEBUG_decode(Perl_sv_dump(nval));

  if (SvGMAGICAL(nval))
    mg_get(nval);

  if (SvROK(nval)) {
    dTHR;
    ENTER;
    SAVETMPS;
    s(osp_thr::sv_2bridge(nval, 1, os_segment::of(this)));
    FREETMPS;
    LEAVE;
  } else if (SvIOKp(nval)) {
    s((os_int32) SvIV(nval));
  } else if (SvNOKp(nval)) {
    s((double) SvNV(nval));
  } else if (SvPOK(nval) || SvPOKp(nval)) {
    tmp = SvPV(nval, tmplen);
    s(tmp, tmplen);
  } else if (! SvOK(nval)) {
    set_undef();
  } else {
      if (osp_thr::sv_dump_on_error)
	  Perl_sv_dump(nval);
    croak("OSSV=(SV*): unknown type");
  }
  return this;
}

// Must preserve flags (like shared) that can easily become unset!
OSSV *OSSV::operator=(const OSSV &nval)
{ croak("OSSV::operator=(const OSSV &): use memcpy/memmove instead"); return 0; }
OSSV *OSSV::operator=(OSSV &nval)
{ croak("OSSV::operator=(OSSV &): use memcpy/memmove instead"); return 0; }

// DANGER! This is ONLY to assist in memcpy'ing OSSVs between arrays.
void OSSV::FORCEUNDEF()
{
  _type = OSVt_UNDEF;
  vptr=0;        // seems to be necessary for ObjectStore sanity
}

int OSSV::folded_typeof() const
{
  int ty = OSvTYPE(this);
  switch (ty) {
  case OSVt_UNDEF:
  case OSVt_UNDEF2:
    return OSVt_UNDEF;
  case OSVt_PV:
  case OSVt_1CHAR:
    return OSVt_PV;
  default:
    return ty;
  }
}

int OSSV::is_set()
{ return (OSvTYPE(this) != OSVt_UNDEF && OSvTYPE(this) != OSVt_UNDEF2); }

// prepare to switch to new datatype
int OSSV::morph(int nty)
{
  if (OSvTYPE(this) == nty) return 0;

  if (PvREFok()) PvREF_dec();
  switch (OSvTYPE(this)) {
  case OSVt_UNDEF: case OSVt_UNDEF2: break;
  case OSVt_IV32:  delete ((OSPV_iv*)vptr); vptr=0; break;
  case OSVt_NV:    delete ((OSPV_nv*)vptr); vptr=0; break;

  case OSVt_PV:
    if (vptr) {
      DEBUG_assign(warn("OSSV(0x%x)->morph(pv): deleting string '%s' 0x%x",
			this, vptr, vptr));
      delete [] ((char*)vptr);
      vptr = 0;
    }
    break;

  case OSVt_RV: 
    assert(vptr==0);
    break;
  case OSVt_IV16: break;
  case OSVt_1CHAR: break;

  default: croak("OSSV(0x%p)->morph type %s unknown! (serious error)",
		 this, OSSV::type_2pv(OSvTYPE(this)));
  }
  OSvTYPE_set(this, nty);
  return 1;
}

static char osp_no_modify[] = "ObjStore: attempt to modify READONLY %s='%s'";
#define OSvTRYWRITE(sv)						\
STMT_START {							\
  if (((sv)->_type & (OSVf_INDEXED|OSVf_READONLY)))		\
    croak(osp_no_modify, sv->type_2pv(), sv->stringify());	\
} STMT_END

void OSSV::set_undef()
{
  OSvTRYWRITE(this);
  morph(OSVt_UNDEF);
}

void OSSV::s(os_int32 nval)
{
  OSvTRYWRITE(this);
  if (((os_int16) (nval & 0xffff)) == nval) {
    morph(OSVt_IV16);
    xiv = nval;
    DEBUG_assign(warn("OSSV(0x%x)->s(%d:xi)", this, nval));
  } else {
    if (morph(OSVt_IV32)) {
      NEW_OS_OBJECT(vptr, os_segment::of(this),
		    OSPV_iv::get_os_typespec(), OSPV_iv);
    }
    OSvIV32(this) = nval;
    DEBUG_assign(warn("OSSV(0x%x)->s(%d:i)", this, nval));
  }
}

void OSSV::s(double nval)
{
  OSvTRYWRITE(this);
  register os_int32 i32_nval = nval;
  if (i32_nval == nval) {
    s(i32_nval);
  } else {
    if (morph(OSVt_NV)) {
      NEW_OS_OBJECT(vptr, os_segment::of(this), OSPV_nv::get_os_typespec(), OSPV_nv);
    }
    OSvNV(this) = nval;
    DEBUG_assign(warn("OSSV(0x%x)->s(%f:n)", this, nval));
  }
}

void osp_thr::record_new(void *vptr, char *when, char *type, int ary)
{
#ifdef DEBUG_ALLOCATION
  if (vptr) {
    char *str = 0;
    os_reference diag(vptr);
    str = diag.dump();

    if (!ary) {
      warn("new %s %s\n", type, str);
    } else {
      warn("new %s %s[%d]\n", type, str, ary);
    }
    delete str;
  }
#endif
}

void OSSV::s(char *nval, os_unsigned_int32 nlen)
{
  OSvTRYWRITE(this);
  // Go through extra contortions for speed...
  if (nlen == 0) {
    morph(OSVt_PV);
    if (vptr) {
//      DEBUG_assign(warn("OSSV(0x%x)->s(): deleting string 0x%x", this, vptr));
      delete [] ((char*)vptr);
      vptr = 0;
    }
    xiv = 0;
    return;

  } else if (nlen == 1) {
    morph(OSVt_1CHAR);
    ((char*)&xiv)[0] = nval[0];
    return;
  }
  //
  // Null terminate strings longer than 16 characters:
  //
  // 1. It's not such a big waste of space after 16 characters.
  // 2. It might be possible to avoid copies later.
  //
  int LONGISH = 0;
  if (nlen > 16) {
    LONGISH = 1;
    if (nlen > 32760) {
      warn("ObjStore: string of length %d truncated to 32760 bytes", nlen);
      nlen = 32760;
    }
  }
  if (!morph(OSVt_PV)) {
    if (xiv == nlen) {
      //already ok
      assert(vptr);
    } else {
      if (vptr) {
//	DEBUG_assign(warn("OSSV(0x%x)->s(): deleting string 0x%x", this, vptr));
	delete [] ((char*)vptr);
      }
      NEW_OS_ARRAY(vptr, os_segment::of(this), os_typespec::get_char(), char,
		   nlen+LONGISH);
      if (LONGISH) ((char*)vptr)[nlen] = 0;
    }
  } else {
    NEW_OS_ARRAY(vptr, os_segment::of(this), os_typespec::get_char(), char,
		 nlen+LONGISH);
    if (LONGISH) ((char*)vptr)[nlen] = 0;
  }
  //  warn("fill '%s'\n", nval);
  memcpy(vptr, nval, nlen);
  xiv = nlen;
  //  DEBUG_assign(warn("OSSV(0x%x)->s(%s, %d): 0x%x", this, nval, nlen, vptr));
}

void OSSV::s(OSSVPV *nval)
{ 
  OSvTRYWRITE(this);
  assert(nval);
  STRLEN len;
  DEBUG_assign(warn("OSSV(0x%x)->s(%s=0x%x)", this, nval->os_class(&len), nval));
  if (morph(OSVt_RV)) {
    PvREF_inc(nval);
  } else if (vptr != nval) {
    PvREF_dec();
    PvREF_inc(nval);
  }
}

void OSSV::s(ospv_bridge *br)
{
  if (br->pv) { s(br->pv); return; }
  croak("OSSV::s(ospv_bridge*): assertion failed");
}

void OSSV::s(OSSV &_nval)
{ 
  OSSV *nval = &_nval;
  switch (nval->natural()) {
  case OSVt_UNDEF: case OSVt_UNDEF2: set_undef(); break;
  case OSVt_IV32:  s(OSvIV32(nval)); break;
  case OSVt_NV:    s(OSvNV(nval)); break;
  case OSVt_PV:    s((char*) nval->vptr, nval->xiv); break;
  case OSVt_RV:    s(OSvRV(nval)); break;
  case OSVt_IV16:  s(OSvIV16(nval)); break;
  case OSVt_1CHAR: s((char*)&nval->xiv, 1); break;
  default:         croak("OSSV::s(OSSV&): assertion failed");
  }
}

char OSSV::strrep1[64];
char *OSSV::stringify(char *buf)    //limited to 63 chars
{
  if (!buf) {
    // debugging ONLY!
    buf = strrep1;
  }
  switch (natural()) {
  case OSVt_UNDEF: case OSVt_UNDEF2: return "<UNDEF>";
  case OSVt_IV32:  sprintf(buf, "%ld", OSvIV32(this)); break;
  case OSVt_NV:    sprintf(buf, "%f", OSvNV(this)); break;
  case OSVt_PV:{
    STRLEN len;
    char *s1 = OSvPV(this, len);
    if (len > 60) len = 60;
    if (len) memcpy(buf, s1, len);
    buf[len]=0;
    break;}
  case OSVt_RV:    sprintf(buf, "OBJECT(0x%p)", vptr); break;
  case OSVt_IV16:  sprintf(buf, "%d", xiv); break;
  case OSVt_1CHAR: sprintf(buf, "'%c'", (char*) &xiv); break;
  default:
    warn("SV %s has no string representation", type_2pv());
    buf[0]=0;
    break;
  }
  return buf;
}

int OSSV::istrue()
{
  switch (natural()) {
  case OSVt_UNDEF: case OSVt_UNDEF2:  return 0;
  case OSVt_IV32:   return OSvIV32(this) != 0;
  case OSVt_NV:     return OSvNV(this) != 0;
  case OSVt_PV:     return xiv != 0;
    //  case OSVt_RV:     return 1;
  case OSVt_IV16:   return OSvIV16(this) != 0;
  case OSVt_1CHAR:  return 1;
  default:	    SERIOUS("istrue: unknown type"); return 0;
  }
}
 
// this  <cmp>  that
//   -1 less than
//        =0=
//  1 greater than

#ifdef say
#  undef say
#endif
#ifdef OSP_DEBUG
#  define say(x)				\
STMT_START {					\
  retval=(x);					\
  goto RET;					\
} STMT_END
#else
#  define say(x) return (x);
#endif

int OSSV::compare(OSSV *that)
{
  int retval;
  int t1 = folded_typeof();
  int t2 = that->folded_typeof();
  if (t1 == t2) {
    switch (t1) {
    case OSVt_UNDEF:
      say(0);
    case OSVt_IV32:  
      say(OSvIV32(this) - OSvIV32(that));
    case OSVt_NV:
      if (OSvNV(this) == OSvNV(that)) {
	say(0);
      } else if (OSvNV(this) < OSvNV(that)) {
	say(-1);
      } else {
	say(1);
      }
    case OSVt_PV: {  //adapted from sv_cmp
      STRLEN l1,l2;
      char *pv1 = OSvPV(this, l1);
      char *pv2 = OSvPV(that, l2);
      if (!l1) say(l2 ? -1 : 0);
      if (!l2) say(1);
      retval = memcmp((void*)pv1, (void*)pv2, l1 < l2 ? l1 : l2);
      if (retval) say(retval < 0 ? -1 : 1);
      if (l1 == l2) {
	say(0);
      } else {
	say(l1 < l2 ? -1 : 1);
      }
    }
    case OSVt_IV16:
      say(OSvIV16(this) - OSvIV16(that));
    default:
      croak("OSSV: type '%s' not comparible", type_2pv(t1));
      return 0;
    }
  } else {  //unfortunately, this is a fairly likely case
    if (t1 != OSVt_PV && t2 != OSVt_PV) {
      double v1,v2;
      switch (t1) {
      case OSVt_UNDEF: say(-1);
      case OSVt_IV32:  v1 = OSvIV32(this); break;
      case OSVt_NV:    v1 = OSvNV(this); break;
      case OSVt_IV16:  v1 = OSvIV16(this); break;
      default:
	croak("OSSV: %s not numerically comparible", type_2pv(t1)); return 0;
      }
      switch (t2) {
      case OSVt_UNDEF: say(1);
      case OSVt_IV32:  v2 = OSvIV32(that); break;
      case OSVt_NV:    v2 = OSvNV(that); break;
      case OSVt_IV16:  v2 = OSvIV16(that); break;
      default:
	croak("OSSV: %s not numerically comparible", type_2pv(t2)); return 0;
      }
      assert(v1 != v2); //type mixup should be impossible
      if (v1 < v2) {
	say(-1);
      } else {
	say(1);
      }
    } else {
      if (t1 == OSVt_UNDEF) say(-1);
      else if (t2 == OSVt_UNDEF) say(1);
      else {
        // This sucks.  We have to stringify the non-string
        // OSSV and then do a string comparison.  Slow, but correct.
        STRLEN l1,l2;
        char buf[90];
        char *pv1;
        char *pv2;
        if (t1 == OSVt_PV) {
          pv1 = OSvPV(this, l1);
        } else {
          this->stringify(buf);
          pv1 = buf;
          l1 = strlen(buf);
        }
        if (t2 == OSVt_PV) {
          pv2 = OSvPV(that, l2);
        } else {
          that->stringify(buf);
          pv2 = buf;
          l2 = strlen(buf);
        }
        // copied from above
        if (!l1) say(l2 ? -1 : 0);
        if (!l2) say(1);
        retval = memcmp((void*)pv1, (void*)pv2, l1 < l2 ? l1 : l2);
        if (retval) say(retval < 0 ? -1 : 1);
        if (l1 == l2) {
          say(0);
        } else {
          say(l1 < l2 ? -1 : 1);
	}
      }
    }
  }
  croak("compare didn't");

 RET:
  DEBUG_compare({
    char buf1[64];
    warn("compare '%s' '%s' => %d",
	 this->stringify(buf1), that->stringify(), retval);
  });
  return retval;
}
#undef say

/* CCov: off */

void OSSV::verify_correct_compare()
{
  OSSV o1,o2;

  assert(o1.compare(&o2) == 0);
  assert(o1.istrue() == 0);
  o1.s(4);
  assert(o1.istrue());
  o1.s(40000);
  assert(o1.istrue());
  o1.s(1.5);
  assert(o1.istrue());
  o1.s("test", 4);
  assert(o1.istrue());

  o1.set_undef();
  o2.s("test", 4);
  assert(o1.compare(&o2) < 0);
  assert(o2.compare(&o1) > 0);
  o2.s(1.5);
  assert(o1.compare(&o2) < 0);
  assert(o2.compare(&o1) > 0);

  o1.s(.5);
  o2.s(.5);
  assert(o1.compare(&o2) == 0);
  o2.s(1.5);
  assert(o1.compare(&o2) < 0 && o2.compare(&o1) > 0);

  o1.s(1);
  o2.s(2);
  assert(o1.compare(&o2) < 0 && o2.compare(&o1) > 0);
  o2.s(40000);
  assert(o1.compare(&o2) < 0 && o2.compare(&o1) > 0);
  o2.s(1.5);
  assert(o1.compare(&o2) < 0 && o2.compare(&o1) > 0);

  o1.s(40000);
  o2.s(50000);
  assert(o1.compare(&o2) < 0 && o2.compare(&o1) > 0);

  o1.s("", 0);
  o2.s("", 0);
  assert(o1.compare(&o2) == 0);
  o2.s("test", 4);
  assert(o1.compare(&o2) < 0 && o2.compare(&o1) > 0);
  o1.s("abc", 3);
  assert(o1.compare(&o2) < 0 && o2.compare(&o1) > 0);
  o1.s("abcd", 4);
  assert(o1.compare(&o2) < 0 && o2.compare(&o1) > 0);
  o1.s("test", 4);
  assert(o1.compare(&o2) == 0);
  o2.s("test2", 5);
  assert(o1.compare(&o2) < 0 && o2.compare(&o1) > 0);
  
  o1.s("a", 1);
  o2.s("abc", 3);
  assert(o1.compare(&o2) < 0);

  // reconcile s(OSSV&)
  o1.set_undef();
  o2.s(o1);
  assert(o1.compare(&o2) == 0);
  o1.s(20000);
  o2.s(o1);
  assert(o1.compare(&o2) == 0);
  o1.s(40000);
  o2.s(o1);
  assert(o1.compare(&o2) == 0);
  o1.s(.5);
  o2.s(o1);
  assert(o1.compare(&o2) == 0);
  o1.s("1", 1);
  o2.s(o1);
  assert(o1.compare(&o2) == 0);
  o1.s("string", 1);
  o2.s(o1);
  assert(o1.compare(&o2) == 0);

  // there's nothing like 100% ...
}

char OSSV::strrep2[64];
char *OSSV::type_2pv(int ty)  //DEBUGGING ONLY
{
  switch (ty) {
   case OSVt_UNDEF: case OSVt_UNDEF2:  return "undef";
   case OSVt_IV32:   return "int32";
   case OSVt_NV:     return "double";
   case OSVt_PV:     return "string";
   case OSVt_RV:     return "OBJECT";
   case OSVt_IV16:   return "int16";
   case OSVt_1CHAR:  return "char";
   default:
     sprintf(strrep2, "ossv(%d)", ty);
     return strrep2;
  }
}

char *OSSV::type_2pv()  //DEBUGGING ONLY
{
  int ty = natural();
  switch (ty) {
   case OSVt_UNDEF: case OSVt_UNDEF2: return "undef";
   case OSVt_IV32:   return "int32";
   case OSVt_NV:     return "double";
   case OSVt_PV:     return "string";
   case OSVt_RV:
     sprintf(strrep2, "OBJECT(0x%p)", vptr);
     return strrep2;
   case OSVt_IV16:   return "int16";
   case OSVt_1CHAR:  return "char";
   default:
     sprintf(strrep2, "ossv(%d)", ty);
     return strrep2;
  }
}
/* CCov: on */

/*--------------------------------------------- OSSVPV */

OSSVPV::OSSVPV()
  : _refs(0), _weak_refs(0), classname(0)
{
  DEBUG_refcnt(warn("new OSSVPV(0x%x)", this));
}
OSSVPV::~OSSVPV()
{
  DEBUG_refcnt(warn("~OSSVPV(0x%x)", this));
  if (OSPvBLESS2(this) && classname) ((OSSVPV*)classname)->REF_dec();
}

// C++ API for perl 'bless' (elaborate version)
void OSSVPV::bless(SV *stashname)
{
  DEBUG_bless(warn("0x%x->bless('%s')", this, SvPV(stashname, PL_na)));
  SV *me = osp_thr::ospv_2sv(this, 1);
  dSP;
  // We must avoid the user-level bless since otherwise the bless glue
  // will enter deep recursion (it creates persistent objects too).
  STRLEN cur1, cur2;
  char *pv1 = SvPV(stashname, cur1);
  char *pv2 = os_class(&cur2);
  if (cur1 == cur2 && memcmp((void*)pv1, (void*)pv2, cur1) == 0) {
    // Can avoid storing the bless-to for an object in its default package.
    XPUSHs(me);
    PUTBACK;
    return;
  }
  PUSHMARK(SP);
  XPUSHs(me);
  XPUSHs(sv_mortalcopy(stashname));
  PUTBACK;
  perl_call_pv("ObjStore::bless", G_SCALAR);
}

int OSSVPV::_is_blessed()
{ return classname != 0; }

HV *OSSVPV::get_stash()
{
  if (!classname) {
    STRLEN len;
    char *name = os_class(&len);
    // use cache? XXX
    return gv_stashpvn(name,len,1);
  }

  // BE FASTER!!
  char *CLASS;
  STRLEN CLEN;
  OSPV_Generic *blessinfo;

  if (OSPvBLESS2(this)) {
    blessinfo = (OSPV_Generic*)classname;
    OSSV *str = blessinfo->avx(1);
    CLASS = OSvPV(str, CLEN);
  } else {
    // CLASS must be null terminated!
    CLASS = (char*) classname;
    CLEN = strlen(CLASS);
    blessinfo = 0;
    OLD_SUPPORT_CODE
  }

  // will need to lock? XXX
  SV **msvp = hv_fetch(osp_thr::CLASSLOAD, CLASS, CLEN, 0); //in CACHE?
  //  warn("classload fetch '%s' => 0x%x", CLASS, msvp? *msvp : 0);
  if (msvp) return (HV*) *msvp;

  return load_stash_cache(CLASS, CLEN, blessinfo);
}

HV *OSSVPV::load_stash_cache(char *CLASS, STRLEN CLEN, OSPV_Generic *blessinfo)
{
  // CAN BE SLOW AS MUD; SAFETY SAFETY SAFETY!
  STRLEN len;
  // MAYBE READ-ONLY!!
  //  if (OSPvINUSE(this)) {
  //    char *name = os_class(&len);
  //    return gv_stashpvn(name,len,1);
  //  }
  //  OSPvINUSE_on(this);
  SV *bsv = osp_thr::ospv_2sv(blessinfo);
  char *oscl = os_class(&len);
  if (len != strlen(oscl)) croak("os_class(): length of %s is wrong", oscl);
  SV *ldr = perl_get_sv("ObjStore::CLASSLOAD", 0);
  SV *olderr = sv_mortalcopy(ERRSV);
  assert(ldr);
  dSP;
  PUSHSTACK;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  EXTEND(SP, 3);
  PUSHs(bsv);
  SV *sv1, *sv2;
  assert(len);
  PUSHs(sv1 = sv_2mortal(newSVpv(oscl, len)));
  PUSHs(sv2 = sv_2mortal(newSVpv(CLASS, CLEN)));
  PUTBACK;
  int count = perl_call_sv(ldr, G_SCALAR|G_EVAL);
  SPAGAIN;
  SV *toclass = POPs;
  if (SvTRUE(ERRSV) || count != 1) {
    /* need to print ERRSV again? */
    croak("&$ObjStore::CLASSLOAD('%s', '%s') failure\t%s",
	  SvPV(sv1, PL_na), SvPV(sv2, PL_na), SvPV(ERRSV, PL_na));
  }
  sv_setsv(ERRSV, olderr);
  if (!SvPOK(toclass)) {
    croak("&$ObjStore::CLASSLOAD('%s', '%s') returned non-string", 
	  SvPV(sv1, PL_na), SvPV(sv2, PL_na));
  }
  HV *stash = gv_stashsv(toclass, 1);
  SvREFCNT_inc(stash);
  hv_store(osp_thr::CLASSLOAD, CLASS, CLEN, (SV*)stash, 0);
  //  warn("classload '%s' => 0x%x", CLASS, stash);
  PUTBACK;
  POPSTACK;
  FREETMPS;
  LEAVE;
  //  OSPvINUSE_off(this);
  return stash;
}

static const os_unsigned_int32 REFCNT32 = 4294967285UL;    // 2**32 - 10

U32 OSSVPV::get_refcnt()
{ return _refs; }

void OSSVPV::REF_inc() {
  DEBUG_refcnt(warn("OSSVPV(0x%x)->REF_inc() from %d", this, _refs));
  _refs++;
  if (_refs > REFCNT32) croak("OSSVPV::REF_inc(): _refs > %ud", REFCNT32);
}

void OSSVPV::REF_dec() { 
  if (_refs == 0) {
    SERIOUS("ObjStore: attempt to free unreferenced object (0x%p)", this);
    return;
  }
  if (_refs == 1 && classname != 0 && !OSPvINUSE(this)) {
    // cache last lookup to avoid gv_fetchmethod? XXX
    SV *meth=0;
    HV *pkg = get_stash();
    if (pkg)
      meth = (SV*) gv_fetchmeth(pkg, "NOREFS", 6, 0);
    if (meth) {
      OSPvINUSE_on(this); //protect from race condition
      DEBUG_norefs(warn("%x->enter NOREFS", this));
      SV *br = ospv_2bridge(this, 1);
      SV *me = osp_thr::wrap(this, br);
      dSP;
      ENTER;
      PUSHMARK(SP);
      XPUSHs(me);
      PUTBACK;
      perl_call_sv((SV*)GvCV(meth), G_DISCARD|G_EVAL|G_KEEPERR);
      ((osp_bridge*) SvIV(SvRV(br)))->leave_txn(); //must avoid extra ref!
      LEAVE;
      DEBUG_norefs(warn("%x->exit NOREFS", this));
      OSPvINUSE_off(this);
    } else {
      DEBUG_norefs(warn("%x->NOREFS not found", this));
    }
    // Probably should support the exact same re-bless symantics
    // that DESTROY supports. XXX
  }
  _refs--;
  DEBUG_refcnt(warn("OSSVPV(0x%x)->REF_dec() to %d", this, _refs));
  if (_refs == 0) {
    DEBUG_norefs(warn("OSSVPV(0x%x): begin delete", this));
    delete this;
    DEBUG_norefs(warn("OSSVPV(0x%x): finish delete", this));
  }
}

int OSSVPV::get_perl_type()
{ return SVt_PVMG; }

dynacast_fn OSSVPV::get_dynacast_meth()
{ return osp_thr::default_dynacast; }

void OSSVPV::_debug1(void *)
{}

static void save_cxxdelete(void *blk)
{ delete blk; }

/* CCov: fatal NOTFOUND */
void OSSVPV::NOTFOUND(char *meth)
{
  os_reference myref(this);
  char *dump = myref.dump();
  SAVEDESTRUCTOR(save_cxxdelete, dump);
  STRLEN len;

  // A dump of the reference can be used to examine the
  // exact memory in osverifydb or osinspector!  Very useful.

  croak("OSSVPV%s @ 0x%p refcnt(%d): '%s' method unavailable for os_class='%s', rep_class='%s'", dump, this, _refs, meth, os_class(&len), rep_class(&len));
}

char *OSSVPV::os_class(STRLEN *len)  { RETURN_BADNAME(len); }
char *OSSVPV::rep_class(STRLEN *len) { RETURN_BADNAME(len); }
void OSSVPV::make_constant() { NOTFOUND("make_constant"); }

void OSSVPV::fwd2rep(char *methname, int ax, int items)
{
  SV *meth=0;
  STRLEN len;
  char *rep = rep_class(&len);
  HV *pkg = gv_stashpvn(rep, len, 0);
  if (pkg) meth = (SV*) gv_fetchmethod(pkg, methname);
  if (!meth) NOTFOUND(methname);

  PUSHMARK(PL_stack_base + ax - 1);
  PL_stack_sp = PL_stack_base + ax - 1 + items;
  perl_call_sv(meth, GIMME_V);
}

// Gack!
int OSSVPV::is_OSPV_Generic() { return 0; }
int OSSVPV::is_OSPV_Ref2() { return 0; }

/*--------------------------------------------- ospv_bridge */

void osp_smart_object::unref() {}
void osp_smart_object::freelist() { delete this; }
osp_smart_object::~osp_smart_object() {}

ospv_bridge::ospv_bridge()
{ pv=0; }

ospv_bridge::~ospv_bridge()
{
  assert(!pv);
  assert(!info);
}

void ospv_bridge::init(OSSVPV *_pv)
{
  assert(!pv); // one at a time please!
  osp_bridge::init(_pv->get_dynacast_meth());
  // optimize! XXX
  info = 0;
  pv = _pv;
  BrDEBUG_set(this, 0);

  STRLEN junk;
  DEBUG_bridge(this,warn("ospv_bridge 0x%x->new(%s=0x%x transient=%d)",
			 this, pv->os_class(&junk), pv,
			 os_segment::of(pv) == os_segment::of(0)));
  if (os_segment::of(pv) == os_segment::of(0)) {
    assert(!txsv);
    pv->REF_inc();
    holding = 1;
    manual_hold = 1;
    return;
  }
  else {
    cache_txsv();
  }

#if OSP_SAFE_BRIDGE
  osp_txn *txn = get_transaction();
  holding = txn->can_update(pv);
  if (holding) {
    enter_txn(txn);
    // hard to tell
    //    if (pv->_refs == 0) croak("attempt to read a deleted object");
    pv->REF_inc();
  }
#endif
}

OSSVPV *ospv_bridge::ospv()
{ return pv; }

void ospv_bridge::hold()
{
  if (detached) croak("attempt to hold invalid object");
    // hard to tell
  //  if (pv->_refs == 0) croak("attempt to read a deleted object");
  if (manual_hold) return;
  manual_hold=1;
  if (!holding) {
    enter_txn(get_transaction());
    pv->REF_inc();  //will blow up if read-only OK
    holding = 1;
  }
}

int ospv_bridge::is_weak()
{ return pv->_refs == 1; }

void ospv_bridge::unref()
{
  if (!pv) return;
  if (info) info->unref();

  // avoid single thread race condition
  OSSVPV *copy = pv; pv=0;
  DEBUG_bridge(this, warn("ospv_bridge 0x%x->unref(pv=0x%x)",
			  this, copy));
  if (!holding) return;

  // going out of scope might happen after the next transaction has started
  if (!txsv || 
      !((osp_txn*) typemap_any::decode(txsv))->can_update(copy)) return;

  copy->REF_dec();
  DEBUG_bridge(this, warn("ospv_bridge 0x%x->REF_dec(pv=0x%x) RC=%d",
			  this, copy, copy->get_refcnt()));
}

void ospv_bridge::freelist()
{
  dOSP;
  //DEBUG_bridge(this, warn("ospv_bridge 0x%x->freelist info=0x%x", this, info));
  if (info) { info->freelist(); info=0; }
  link.attach(osp->ospv_freelist);
}

//---------------------------------------------- OSPV INTERFACES --

void OSSVPV::POSH_CD(SV *to) { NOTFOUND("POSH_CD"); }
OSSVPV *OSSVPV::traverse1(osp_pathexam &exam)
{ NOTFOUND("traverse1"); return 0; }
OSSV *OSSVPV::traverse2(osp_pathexam &exam)
{ NOTFOUND("traverse2"); return 0; }
int OSSVPV::FETCHSIZE()
{ NOTFOUND("FETCHSIZE"); return 0; }

double OSPV_Container::_percent_filled()
{ NOTFOUND("_percent_filled"); return -1; }
OSSVPV *OSPV_Container::new_cursor(os_segment *seg)
{ NOTFOUND("new_cursor"); return 0; }
void OSPV_Container::CLEAR() { NOTFOUND("CLEAR"); }

/*--------------------------------------------- GENERIC */

OSSV *OSSVPV::hvx(char *) { NOTFOUND("hvx"); return 0; }
OSSV *OSSVPV::avx(int) { NOTFOUND("avx"); return 0; }

int OSPV_Generic::is_OSPV_Generic() { return 1; }
void OSPV_Generic::FIRST(osp_smart_object **) { NOTFOUND("FIRST"); }
void OSPV_Generic::NEXT(osp_smart_object **) { NOTFOUND("NEXT"); }

// HASH
void OSPV_Generic::FETCH(SV *) { NOTFOUND("FETCH"); }
void OSPV_Generic::POSH_CD(SV *to) { FETCH(to); }
void OSPV_Generic::STORE(SV *, SV *) { NOTFOUND("STORE"); }
void OSPV_Generic::DELETE(SV *) { NOTFOUND("DELETE"); }
int OSPV_Generic::EXISTS(SV *) { NOTFOUND("EXISTS"); return 0; }

// ARRAY
void OSPV_Generic::POP() { NOTFOUND("POP"); }
void OSPV_Generic::SHIFT() { NOTFOUND("SHIFT"); }
void OSPV_Generic::PUSH(int ax, int items) { NOTFOUND("PUSH"); }
void OSPV_Generic::UNSHIFT(int ax, int items) { NOTFOUND("UNSHIFT"); }
void OSPV_Generic::SPLICE(int, int, SV **, int) { NOTFOUND("SPLICE"); }

// INDEX
int OSPV_Generic::add(OSSVPV*) { NOTFOUND("add"); return 0; }
int OSPV_Generic::remove(OSSVPV*) { NOTFOUND("remove"); return 0; }
void OSPV_Generic::configure(int ax, int items)
{ fwd2rep("configure", ax, items); }

// REFERENCES
OSPV_Ref2::OSPV_Ref2() {}
char *OSPV_Ref2::os_class(STRLEN *len) { *len = 13; return "ObjStore::Ref"; }
os_database *OSPV_Ref2::get_database() { NOTFOUND("get_database"); return 0; }
char *OSPV_Ref2::dump() { NOTFOUND("dump"); return 0; }
OSSVPV *OSPV_Ref2::focus() { NOTFOUND("focus"); return 0; }
int OSPV_Ref2::deleted() { NOTFOUND("deleted"); return 0; }
int OSPV_Ref2::is_OSPV_Ref2() { return 1; }


// CURSORS
char *OSPV_Cursor2::os_class(STRLEN *len)
{ *len = 16; return "ObjStore::Cursor"; }
char *OSPV_Cursor2::rep_class(STRLEN *len)
{ return focus()->rep_class(len); }

//override like REFS if cross-database allowed
/*
os_database *OSPV_Cursor2::get_database()
{ return os_database::of(this); }
int OSPV_Cursor2::deleted()
{ return 0; }
*/
//cross-database

OSSVPV *OSPV_Cursor2::focus() { NOTFOUND("focus"); return 0; }
void OSPV_Cursor2::moveto(I32){ NOTFOUND("moveto"); }
void OSPV_Cursor2::step(I32) { NOTFOUND("step"); }
void OSPV_Cursor2::keys() { NOTFOUND("keys"); }
void OSPV_Cursor2::at() { NOTFOUND("at"); }
void OSPV_Cursor2::store(SV*) { NOTFOUND("store"); }
int OSPV_Cursor2::seek(osp_pathexam &) { NOTFOUND("seek"); return 0; }
void OSPV_Cursor2::ins(SV*, int) { NOTFOUND("ins"); }
void OSPV_Cursor2::del(SV*, int) { NOTFOUND("del"); }
I32 OSPV_Cursor2::pos() { NOTFOUND("pos"); return -1; }
void OSPV_Cursor2::stats() { NOTFOUND("stats"); }

//--------------------------------------------------- osp_pathexam

const int osp_keypack1::max = OSP_PATHEXAM_MAXKEYS;

osp_keypack1::osp_keypack1()
{ cnt=0; pad1=0; }

void osp_keypack1::set_undef()
{
  cnt=0;
  for (int xx=0; xx < max; xx++)
    keys[xx].set_undef();
}

int osp_keypack1::operator==(osp_keypack1 &kp)
{
  if (kp.cnt != cnt) return 0;
  for (int xx=0; xx < cnt; xx++)
    if (keys[xx].compare(&kp.keys[xx])) return 0;
  return 1;
}

osp_pathexam::osp_pathexam(int _desc)
{ init(_desc); }

void osp_pathexam::init(int _desc)
{
  descending = _desc;
  pathcnt = 0;
  keycnt = 0;
  target = 0;
  conflict = 0;
}

void osp_pathexam::set_descending(int yes)
{ descending = yes; }

void osp_pathexam::load_path(OSSVPV *paths)
{
  pathcnt = paths->FETCHSIZE();
  if (pathcnt < 1)
    croak("Path is empty");
  else if (pathcnt > OSP_PATHEXAM_MAXKEYS)
    croak("Path has %d keys (%d max)", pathcnt, OSP_PATHEXAM_MAXKEYS);
  else {
    assert(pathcnt <= OSP_PATHEXAM_MAXKEYS);
    for (int xa=0; xa < pathcnt; xa++) {
      OSSVPV *pth;
      pth = paths->avx(xa)->safe_rv();
      if (pth->FETCHSIZE() < 1)
	croak("Empty path component");
      assert(xa >= 0 && xa < OSP_PATHEXAM_MAXKEYS);
      pcache[xa] = pth;
    }
  }
}

// mode == 'x'      do nothing
//
// mode == 's'      set read-only exclusive
//     traverse1: READONLY or fail if ROEXCL set; set ROEXCL
//     traverse2: READONLY or fail if ROEXCL set; set ROEXCL
//
// mode == 'u'      unset read-only exclusive
//     traverse1; READONLY or unset ROEXCL
//     traverse2; READONLY or unset ROEXCL
//

OSSV *osp_pathexam::path_2key(int zpath, OSSVPV *obj, char _mode)
{
  OSSVPV *path = pcache[zpath];
  int len = path->FETCHSIZE();
  mode = _mode;
  for (int px=0; px < len; px++) {
    OSSV *tmp1 = path->avx(px);
    thru = OSvPV(tmp1, thru_len);
    if (px < len-1) {
      obj = obj->traverse1(*this);
      if (!obj) break;
    } else {
      OSSV *ret = obj->traverse2(*this);
      if (ret) {
	// traverse2 should have checked already; do assertion:
	assert(ret->natural() != OSVt_RV);
	return ret;
      }
    }
  }
  return 0;
}

void osp_pathexam::set_conflict()
{ conflict = thru; }

void osp_pathexam::no_conflict()
{
  assert(target);
  if (conflict) {
    croak("Attempt to add %s(0x%p) '%s' to multiple indices using the same indexing key '%s'",
	  target->os_class(&PL_na), target, kv_string(), conflict);
  }
}

// NOTE: An index conflict is only a problem if we are actually going
// to add the record to the index.  If the record is already added,
// setting lots of index flags isn't going to matter because they
// are already set.  OTOH, if the record fails the pathexam half
// way through we should back-out all the index flags that were
// set.  This doesn't happen yet, so the flags could become set
// unnecessarily and permenantly.  This could be construed as a bug
// but getting the right behavior is a hassel.  It's almost not
// worth it.  Perhaps the current behavior should be documented? XXX

// THE WORK-AROUND IS TO GET THE KEYS TWICE; THE FIRST TIME JUST
// TO SEE IF IT WORKS; THE SECOND TIME TO SET THE INDEX FLAGS.  YUCK.

int osp_pathexam::load_target(char _mode, OSSVPV *pv)
{
  if (!pathcnt) croak("no path loaded");
  keycnt = 0;
  conflict = 0;
  tmpkey = 0;
  target = pv;
  if (pv->is_OSPV_Ref2())
    pv = ((OSPV_Ref2*)pv)->focus();

  for (int xa=0; xa < pathcnt; xa++) {
    OSSV *kv = path_2key(xa, pv, _mode);
    if (!kv || !kv->is_set()) return 0; //need to undo flag changes; yuck XXX
    keys[xa] = kv;
    ++keycnt;
  }
  return 1;
}

OSSV *osp_pathexam::mod_ossv(OSSV *sv)
{
  if (sv && !OSvREADONLY(sv) && sv->is_set()) {
    if (get_mode() == 's') {
      if (OSvINDEXED(sv)) {
	set_conflict();
	DEBUG_pathexam(warn("conflict %s", get_thru()));
      }
      else OSvINDEXED_on(sv);
    } else if (get_mode() == 'u') {
      OSvINDEXED_off(sv);
    }
  }
  return sv;
}

// This API is a bit strange because we need to read off
// the perl stack (which can be relocated).  See XSUB.h.
void osp_pathexam::load_args(int ax, int items)
{
  int args = items - 1;
  if (args > OSP_PATHEXAM_MAXKEYS) {
    warn("Too many keys (%d) in load_args -- truncated to %d keys",
	 args, OSP_PATHEXAM_MAXKEYS);
    args = OSP_PATHEXAM_MAXKEYS;
  }
  keycnt = 0;
  conflict = 0;
  for (int xa=0; xa < args; xa++) {
    tmpkeys[xa] = ST(1+xa);
    keys[xa] = &tmpkeys[xa];
    ++keycnt;
  }
}

char *osp_pathexam::kv_string()
{
  char buf[64]; //XXX danger!
  SV *kv = newSVpvn("",0);
  SAVEFREESV(kv);
  int maxcnt = pathcnt > keycnt? pathcnt : keycnt;
  for (int p1=0; p1 < maxcnt; p1++) {
    if (p1 < pathcnt) {
      OSSVPV *path = pcache[p1];
      int plen = path->FETCHSIZE();
      for (int p2=0; p2 < plen; p2++) {
	sv_catpv(kv, path->avx(p2)->stringify(buf));
	if (p2 < plen-1) sv_catpv(kv, "/");
      }
    }
    if (p1 < keycnt) {
      if (p1 < pathcnt) sv_catpv(kv,"=");
      sv_catpv(kv, keys[p1]->stringify(buf));
    }
    if (p1 < maxcnt-1) sv_catpv(kv, ", ");
  }
  return SvPV(kv, PL_na);
}

void osp_pathexam::push_keys()
{
  SV *sv[OSP_PATHEXAM_MAXKEYS];
  for (int kx=0; kx < keycnt; kx++) {
    sv[kx] = osp_thr::ossv_2sv(get_key(kx));
  }
  dSP;
  EXTEND(SP, get_keycnt());
  for (kx=0; kx < get_keycnt(); kx++)
    PUSHs(sv[kx]);
  PUTBACK;
}

int osp_pathexam::compare(osp_keypack1 &kpk, int partial)
{
  if (!pathcnt) croak("no path loaded");
  int cmp;
  for (int kx=0; kx < pathcnt; kx++) {
    if (kx >= keycnt) {
	if (partial) return 0;
	return descending? 1 : -1;
    }
    OSSV *k1 = keys[kx];
    if (kx >= kpk.cnt) return descending? -1 : 1;
    OSSV *k2 = &kpk.keys[kx];
    cmp = k1->compare(k2);
    if (cmp) break;
  }
  return descending? -cmp : cmp;
}

void osp_pathexam::load_keypack1(OSSVPV *dat, osp_keypack1 &kpk)
{
  if (!pathcnt) croak("no path loaded");
  if (dat->is_OSPV_Ref2()) dat = ((OSPV_Ref2*)dat)->focus();
  tmpkey = OSP_PATHEXAM_MAXKEYS;
  kpk.cnt=0;
  for (int kx=0; kx < pathcnt; kx++) {
    OSSV *k1 = path_2key(kx, dat);
    if (!k1) return;
    kpk.keys[kpk.cnt++].s(*k1); //could be optimized...maybe XXX
  }
}

int osp_pathexam::compare(OSSVPV *dat, int partial)
{
  if (!pathcnt) croak("no path loaded");
  if (dat->is_OSPV_Ref2()) dat = ((OSPV_Ref2*)dat)->focus();
  tmpkey = OSP_PATHEXAM_MAXKEYS;
  int cmp;
  for (int kx=0; kx < pathcnt; kx++) {
    if (kx >= keycnt) {
	if (partial) return 0;
	return descending? 1 : -1;
    }
    OSSV *k1 = keys[kx];
    OSSV *k2 = path_2key(kx, dat);
    if (!k2) return descending? -1 : 1;
    cmp = k1->compare(k2);
    if (cmp) break;
  }
  return descending? -cmp : cmp;
}

// This is mostly used for comparisons between already
// indexed records.  It assumes that all paths will
// resolve on both records.
int osp_pathexam::compare(OSSVPV *d1, OSSVPV *d2)
{
  if (!pathcnt) croak("no path loaded");
  if (d1->is_OSPV_Ref2()) d1 = ((OSPV_Ref2*)d1)->focus();
  if (d2->is_OSPV_Ref2()) d2 = ((OSPV_Ref2*)d2)->focus();
  tmpkey = OSP_PATHEXAM_MAXKEYS;
  int cmp;
  for (int kx=0; kx < pathcnt; kx++) {
    OSSV *z1 = path_2key(kx, d1);
    OSSV *z2 = path_2key(kx, d2);
    assert(z1 && z2);
    cmp = z1->compare(z2);
    if (cmp) break;
  }
  return descending? -cmp : cmp;
}

/*--------------------------------------------- hvent2 */

hvent2::hvent2() : hk(0)
{}

hvent2::~hvent2()
{
  //  OSvROCLEAR(&hv); //?XXX
  if (hk) delete [] hk; hk=0;
}

void hvent2::FORCEUNDEF()
{ hk=0; hv.FORCEUNDEF(); }

void hvent2::set_undef()
{ if (hk) delete [] hk; hk=0; hv.set_undef(); }

int hvent2::valid() const
{ return hk != 0; }

void hvent2::set_key(char *nkey)
{
  assert(nkey);
  set_undef();
  int len = strlen(nkey)+1;
  NEW_OS_ARRAY(hk, os_segment::of(this), os_typespec::get_char(), char, len);
  //  hk = new(os_segment::of(this), os_typespec::get_char(), len) char[len];
  //  warn("fill '%s'\n", nkey);
  memcpy(hk, nkey, len);
}

SV *hvent2::key_2sv()
{
  assert(hk);
  return sv_2mortal(newSVpv(hk, 0));
}

/* Added to support stupid C++ templates, then I decided just to rewrite
   all the collection types in C.
hvent2 *hvent2::operator=(int zero)
{
  assert(zero==0);
  set_undef();
  return this;
}
*/

int hvent2::rank(const char *v2)
{
  assert(hk != 0 && v2 != 0);
  return strcmp(hk, v2);
}

//////////////////////////////////////////////////////////////////////
// adapted from perl 5.004_64 //
void
mysv_lock(SV *sv)
{
#ifdef USE_THREADS
    dTHR;
    MAGIC *mg = condpair_magic(sv);
    MUTEX_LOCK(MgMUTEXP(mg));
    if (MgOWNER(mg) == thr)
	MUTEX_UNLOCK(MgMUTEXP(mg));
    else {
	while (MgOWNER(mg))
	    COND_WAIT(MgOWNERCONDP(mg), MgMUTEXP(mg));
	MgOWNER(mg) = thr;
	DEBUG_L(PerlIO_printf(PerlIO_stderr(), "0x%lx: pp_lock lock 0x%lx\n",
			      (unsigned long)thr, (unsigned long)sv);)
	MUTEX_UNLOCK(MgMUTEXP(mg));
	save_destructor(unlock_condpair, sv);
    }
#endif
}

