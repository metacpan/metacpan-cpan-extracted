/* partially -*-C++-*- */

extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

#include <osperl.h>
#include "ospdl.h"

extern "C" {
#include "pdl.h"
#define _pdlmagic_H_
#define new new_pdl
#include "pdlcore.h"
#undef new
}

// PDL redefines croak too!
#undef croak
#define croak osp_croak

static int Debug=0;
static HV *PDLStash1;
static Core *PDLAPI;
static pdl *pdl_out_of_scope;

Lib__PDL1::Lib__PDL1()
{
  dims = 0;
  datatype = PDL_D;
  ndims = 0;
  data = 0;
}

Lib__PDL1::~Lib__PDL1()
{ clear(); }

void Lib__PDL1::clear()
{
  dims=0;
  if (data) delete [] data;
  if (dims) delete [] dims;
}

int Lib__PDL1::get_perl_type()
{ return SVt_PVMG; }

void Lib__PDL1::make_constant()
{ croak("not implemented"); }

char *Lib__PDL1::os_class(STRLEN *len)
{ *len = 18; return "ObjStore::Lib::PDL"; }

char *Lib__PDL1::rep_class(STRLEN *len)
{ *len = 18; return "ObjStore::Lib::PDL"; }

void Lib__PDL1::allocate_cells(U32 cnt, int zero)
{
  // Let ObjectStore know what type we are allocating...
  //   This is a mess.
  //
  // Suggestions?

  int width = PDLAPI->howbig(datatype);
  if (cnt > 1024 * 1024 * 1024) croak("PDL size > 1GB; are you serious?");
  assert(!data);
  assert(cnt == calc_nvals());
  switch (datatype) {
    case PDL_B:
      assert(width == sizeof(PDL_Byte) && width == sizeof(char));
      NEW_OS_ARRAY(data, os_segment::of(this), os_typespec::get_char(),
		 char, cnt);
      break;
    case PDL_S:
      assert(width == sizeof(PDL_Short) && width == sizeof(os_int16));
      NEW_OS_ARRAY(data, os_segment::of(this), os_typespec::get_signed_short(),
		 os_int16, cnt);
      break;
    case PDL_US:
      assert(width == sizeof(PDL_Ushort) && width == sizeof(os_unsigned_int16));
      NEW_OS_ARRAY(data, os_segment::of(this), os_typespec::get_unsigned_short(),
		 os_unsigned_int16, cnt);
      break;
    case PDL_L:
      assert(width == sizeof(PDL_Long) && width == sizeof(os_int32));
      NEW_OS_ARRAY(data, os_segment::of(this), os_typespec::get_long(),
		 os_int32, cnt);
      break;
    case PDL_F:
      assert(width == sizeof(PDL_Float) && width == sizeof(float));
      NEW_OS_ARRAY(data, os_segment::of(this), os_typespec::get_float(),
		 float, cnt);
      break;
    case PDL_D:
      assert(width == sizeof(PDL_Double) && width == sizeof(double));
      NEW_OS_ARRAY(data, os_segment::of(this), os_typespec::get_double(),
		 double, cnt);
      break;
    default:
      croak("Unknown datatype code = %d",datatype);
  }
  if (zero) Zero(data, cnt * width, char);
}

U32 Lib__PDL1::calc_nvals()
{
  U32 vals = 1;
  for (int xx=0; xx < ndims; xx++) vals *= dims[xx];
  return vals;
}

void Lib__PDL1::setdims(I32 cnt, I32 *dsz, void *tmpl)
{
  int zero = ndims == 0 && !tmpl;
  assert(cnt >= 0);
  void *old_data = data;
  data=0;
  if (dims) { delete [] dims; dims=0; }
  ndims = cnt;

  NEW_OS_ARRAY(dims, os_segment::of(this), os_typespec::get_signed_int(),
		 int, cnt);
  Copy(dsz, dims, ndims, int);
  U32 cells = calc_nvals();
  allocate_cells(cells, zero);
  if (tmpl) Copy(tmpl, data, cells * PDLAPI->howbig(datatype), char);
  if (old_data) delete [] old_data;
}

void Lib__PDL1::set_datatype(int ndt)
{
  /* be smart about preserving existing values? XXX */
  if (datatype == ndt) return;
  if (data) { delete [] data; data=0; }
  datatype = ndt;
  allocate_cells(calc_nvals(), 0);
}

void Lib__PDL1::copy(Lib__PDL1 &tmpl)
{
  clear();
  datatype = tmpl.datatype;
  ndims = 1;  //avoid Zero
  setdims(tmpl.ndims, tmpl.dims, tmpl.data);
}

Lib__PDL1_c::Lib__PDL1_c(Lib__PDL1 *pdl)
{
  assert(pdl);
  data = pdl->data;
  datatype = pdl->datatype;
  ndims = pdl->ndims;
  if (ndims < 10) {
    dims = def_dims;
    dimincs = def_dimincs;
    loc = def_loc;
  } else {
    dims = new I32[ndims];
    dimincs = new I32[ndims];
    loc = new I32[ndims];
  }
  pos = 0;
  I32 inc = 1;
  for (int dx=0; dx < ndims; dx++) {
    loc[dx] = 0;
    dims[dx] = pdl->dims[dx];
    dimincs[dx] = inc;
    inc *= dims[dx];
  }
}

Lib__PDL1_c::~Lib__PDL1_c()
{
  if (dims != def_dims)
    delete dims;
  if (dimincs != def_dimincs)
    delete dimincs;
  if (loc != def_loc)
    delete loc;
}

void Lib__PDL1_c::seek(I32 *ats)
{
  pos = 0;
  for (int di=0; di < ndims; di++) {
    int at = ats[di];
    if (at >= dims[di] || at < 0)
      croak("Index %d out of range %d at dimension %d", at, dims[di], di);
    pos += at * dimincs[di];
    loc[di] = at;
  }
}

void Lib__PDL1_c::seek(SV **ats)
{
  pos=0;
  for (int di=0; di < ndims; di++) {
    int at = osp_thr::sv_2aelem(ats[di]);
    if (at >= dims[di] || at < 0)
      croak("Index %d out of range %d at dimension %d", at, dims[di], di);
    pos += at * dimincs[di];
    loc[di] = at;
  }
}

void Lib__PDL1_c::setdim(int dx, I32 to)
{
  if (to < 0 || to >= dims[dx])
    croak("Index %d out of range %d at dimension %d", to, dims[dx], dx);
  pos += (to - loc[dx]) * dimincs[dx];
  loc[dx] = to;
}

void Lib__PDL1_c::set(SV *value)
{
  switch (datatype) {
    case PDL_B: ((char*)data)[pos] = SvIV(value); break;
    case PDL_S: ((short*)data)[pos] = SvIV(value); break;
    case PDL_US: ((unsigned short*)data)[pos] = SvIV(value); break;
    case PDL_L: ((long*)data)[pos] = SvIV(value); break;
    case PDL_F: ((float*)data)[pos] = SvNV(value); break;
    case PDL_D: ((double*)data)[pos] = SvNV(value); break;
    default: croak("datatype unknown");
  }
}
void Lib__PDL1_c::set(I32 value)
{
  switch (datatype) {
    case PDL_B: ((char*)data)[pos] = value; break;
    case PDL_S: ((short*)data)[pos] = value; break;
    case PDL_US: ((unsigned short*)data)[pos] = value; break;
    case PDL_L: ((long*)data)[pos] = value; break;
    default: croak("datatype mismatch");
  }
}

void Lib__PDL1_c::set(double value)
{
  switch (datatype) {
    case PDL_F: ((float*)data)[pos] = value; break;
    case PDL_D: ((double*)data)[pos] = value; break;
    default: croak("datatype mismatch");
  }
}

//------------------------------------------------- typemap

static int bridge_counter = 0;
static osp_ring Freelist(0);

struct pdl_bridge : osp_smart_object {
  static osp_ring All;

  osp_ring link;
  pdl *proxy;

#if OSP_BRIDGE_TRACE
  osp_ring al; /* not thread-safe XXX */
  SV *where;
  void *bridge;
#endif

  pdl_bridge();
  void init(Lib__PDL1 *pv);
  virtual void unref();
  virtual void freelist();
  virtual ~pdl_bridge();
};

osp_ring pdl_bridge::All(0);

pdl_bridge::pdl_bridge()
  : link(this)
#if OSP_BRIDGE_TRACE
     , al(this), where(0)
#endif
{
  ++bridge_counter;
  proxy=0;
}

static void init_out_of_scope()
{
  PDL_Long d[1] = {0};
  pdl *it;
  pdl_out_of_scope = it = PDLAPI->null();
  it->state |= PDL_DESTROYING; //always avoid destruction
}

// also called after setdims or set_datatype
void pdl_bridge::init(Lib__PDL1 *pv)
{
#if OSP_BRIDGE_TRACE
  if (al.empty()) {
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
  }
#endif

  assert(pv);
  if (!proxy) {
    proxy = PDLAPI->create(PDL_PERM);
  }
  if (!proxy->sv) {
    PDLAPI->SetSV_PDL(newSV(0), proxy);
    SvREFCNT_inc((SV*) proxy->sv);  // is owned by us
    //Perl_sv_dump( (SV*) proxy->sv);
  }
  proxy->state = PDL_DONTTOUCHDATA | PDL_ALLOCATED;
  if (!pv->data) {
    assert(pv->ndims == 0);
    pv->allocate_cells(1, 1);
  }
  if (proxy->ndims != pv->ndims) {
    if (proxy->dims != proxy->def_dims)
	free(proxy->dims);
    if (proxy->dimincs != proxy->def_dimincs)
	free(proxy->dimincs);

    if (pv->ndims > PDL_NDIMS) {
        proxy->dims = (int*) malloc(pv->ndims*sizeof(int));
	if (!proxy->dims) croak("Out of memory");
        proxy->dimincs = (int*) malloc(pv->ndims*sizeof(int));
	if (!proxy->dimincs) croak("Out of memory");
    } else {
	proxy->dims = proxy->def_dims;
	proxy->dimincs = proxy->def_dimincs;
    }
  }
  proxy->threadids = proxy->def_threadids;
  proxy->threadids[0] = pv->ndims;
  proxy->datatype = pv->datatype;
  proxy->ndims = pv->ndims;
  proxy->data = pv->data;

  Copy(pv->dims, proxy->dims, pv->ndims, int);
  int inc = 1;
  for (int i=0; i < proxy->ndims; i++) {
    proxy->dimincs[i] = inc; inc *= proxy->dims[i];
  }
  proxy->nvals = inc;
}

void pdl_bridge::unref()
{
  assert(proxy);
  if (proxy->sv) {
    SvREFCNT_dec((SV*) proxy->sv);
    if (SvREFCNT((SV*) proxy->sv) > 1) {
      SV *sv = (SV*) proxy->sv;
      //      sv_setiv(sv, (IV) pdl_out_of_scope);
      //proxy->sv = 0;
      SvREFCNT_dec(sv);
      //PDLAPI->destroy(proxy);
      if (Debug) warn("%x undef 1", this);
    } else {
      SvREFCNT_dec((SV*) proxy->sv);
      if (Debug) warn("%x undef 2", this);
    }
  } else {
      PDLAPI->destroy(proxy);
      if (Debug) warn("%x undef 3", this);
  }
  proxy=0;
}

void pdl_bridge::freelist() 
{
  if (Debug >= 1) warn("pdl_bridge::freelist %x", this);
  link.attach(Freelist);
#if OSP_BRIDGE_TRACE
  al.detach();
#endif
}

pdl_bridge::~pdl_bridge()
{
  if (!link.empty()) link.detach();
  --bridge_counter;
#if OSP_BRIDGE_TRACE
  SvREFCNT_dec(where);
#endif
}

static void *ospdl_dynacast(void *obj, HV *stash, int failok)
{
  if (stash == osp_thr::BridgeStash) {
    return obj; /*already ok*/
  }
  else if (stash == PDLStash1) {
    ospv_bridge *br = (ospv_bridge*) obj;
    //BrDEBUG_set(br, 1);
    pdl_bridge *pdlbr;
    Lib__PDL1 *pv = (Lib__PDL1 *) br->ospv();
    if (!pv)
      croak("Attempt to use PDL outside of transaction scope");
    if (!br->info) {
	pdlbr = (pdl_bridge*) Freelist.next_self();
	if (!pdlbr) {
	  pdlbr = new pdl_bridge();
          if (Debug >= 2) warn("creating proxy for 0x%x", br->ospv());
        }
	else {
	  pdlbr->link.detach();
          if (Debug >= 2) warn("reuse proxy for 0x%x", br->ospv());
        }
	pdlbr->init(pv);
	br->info = pdlbr;
#if OSP_BRIDGE_TRACE
	pdlbr->bridge = br;
#endif
    }
    pdlbr = (pdl_bridge*) br->info;
    return pdlbr->proxy;
  }
  else {
    if (!failok)
      croak("Don't know how to convert ObjStore::Lib::PDL to a '%s'",
	 HvNAME(stash));
    return 0;
  }
}

dynacast_fn Lib__PDL1::get_dynacast_meth()
{ return ospdl_dynacast; }


MODULE = ObjStore::Lib::PDL	PACKAGE = ObjStore::Lib::PDL

PROTOTYPES: disable

BOOT:
  extern _Application_schema_info Lib__PDL_dll_schema_info;
  osp_thr::use("ObjStore::Lib::PDL", OSPERL_API_VERSION);
  osp_thr::register_schema("ObjStore::Lib::PDL", &Lib__PDL_dll_schema_info);
  PDLStash1 = gv_stashpv("PDL", 1);
  SV *pdl_core_sv = perl_get_sv("PDL::SHARE", 0);
  if (!pdl_core_sv) croak("PDL is not loaded");
  PDLAPI = (Core*) SvIV(pdl_core_sv);
  assert(sizeof(PDL_Long) == sizeof(os_int32));
  SV *APIV = perl_get_sv("ObjStore::Lib::PDL::APIVERSION", 1);
  sv_setiv(APIV, OBJSTORE_LIB_PDL_VERSION);
  SvREADONLY_on(APIV);
  init_out_of_scope();

void
_allocate(CSV, seg)
	SV *CSV;
	SV *seg;
	PPCODE:
	os_segment *area = osp_thr::sv_2segment(seg);
	PUTBACK;
	OSSVPV *pv;
	NEW_OS_OBJECT(pv, area, Lib__PDL1::get_os_typespec(), Lib__PDL1);
	pv->bless(CSV);
	return;

void
_PurgeFreelist()
	CODE:
	pdl_bridge *pdlbr;
	while (pdlbr = (pdl_bridge*) Freelist.next_self()) {
	  delete pdlbr;
	}
	if (0 && bridge_counter)
	  warn("ObjStore::Lib::PDL: %d proxies are still in use",
		bridge_counter);

int
_set_debug(lv)
	int lv
	CODE:
	RETVAL = Debug;
	Debug = lv;
	OUTPUT:
	RETVAL

void
_inuse_bridges(...)
	PROTOTYPE: ;$
	PPCODE:
	IV show = items>0? sv_true(ST(0)) : 0;
	IV cnt=0;
#if OSP_BRIDGE_TRACE
	pdl_bridge *br = (pdl_bridge*) pdl_bridge::All.next_self();
	while (br) {
	  if (show) {
	    SV *sv = sv_2mortal(newSVpv("",0));
	    sv_catpvf(sv,"[%d]pdl_bridge 0x%x\n", cnt, br);
	    sv_catpvf(sv,"  bridge       : 0x%x\n", br->bridge);
	    sv_catpvf(sv,"  proxy        : 0x%x\n", br->proxy);
	    if (br->proxy)
	      sv_catpvf(sv,"  proxy->sv    : 0x%x\n", br->proxy->sv);
	    if (br->where)
	      sv_catpvf(sv,"  created%s\n", SvPV(br->where, PL_na));
	    XPUSHs(sv);
	  }
	  ++cnt;
	  br = (pdl_bridge*) br->al.next_self();
	}
#else
	warn("_inuse_bridges detail is not available");
#endif

void
OSSVPV::getndims()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(((Lib__PDL1*)THIS)->ndims)));

void
OSSVPV::getdim(y)
	int y;
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(((Lib__PDL1*)THIS)->dims[y])));

void
OSSVPV::setdims(sv)
	SV *sv
	CODE:
	if (!(SvROK(sv) && SvTYPE(SvRV(sv))==SVt_PVAV))
	  croak("setdims: expecting an array ref");
	AV *ar = (AV*) SvRV(sv);
	int ndims = av_len(ar)+1;
	I32 *dims;
	if (ndims) {
	  New(0, dims, ndims, I32);
	  for (int xx=0; xx < ndims; xx++)
	    dims[xx] = SvIV(*av_fetch(ar,xx,0));
	}
	((Lib__PDL1*)THIS)->setdims(ndims, dims);
	if (THIS_bridge->info)
	  ((pdl_bridge*) THIS_bridge->info)->init(((Lib__PDL1*)THIS));

void
OSSVPV::set_datatype(datatype)
	int datatype;
	CODE:
	((Lib__PDL1*)THIS)->set_datatype(datatype);
	if (THIS_bridge->info)
	  ((pdl_bridge*) THIS_bridge->info)->init(((Lib__PDL1*)THIS));

void
copy(THIS)
	OSSVPV *THIS;
	PPCODE:
	OSSVPV *cpy;
	NEW_OS_OBJECT(cpy, os_segment::of(THIS), Lib__PDL1::get_os_typespec(),
		Lib__PDL1);
	((Lib__PDL1*)cpy)->copy(* (Lib__PDL1*)THIS);
	SV *me = osp_thr::ospv_2sv(cpy, 1);
	XPUSHs(me);

void
OSSVPV::upd_data()
	CODE:
	/* do nothing */

void
OSSVPV::at(...)
	PPCODE:
	Lib__PDL1_c pdl((Lib__PDL1*)THIS);
	if (items-1 != pdl.ndims)
	  croak("PDL->set expecting %d dimensions (not %d)", pdl.ndims, items-1);
	pdl.seek(&ST(1));
	SV *ret;
	switch (pdl.datatype) {
	case PDL_B: ret = newSViv(pdl.at_b()); break;
	case PDL_S: ret = newSViv(pdl.at_s()); break;
	case PDL_US: ret = newSViv(pdl.at_us()); break;
	case PDL_L: ret = newSViv(pdl.at_l()); break;
	case PDL_F: ret = newSVnv(pdl.at_f()); break;
	case PDL_D: ret = newSVnv(pdl.at_d()); break;
	default: croak("datatype unknown");
	}
	XPUSHs(sv_2mortal(ret));

void
OSSVPV::set(...)
	PPCODE:
	Lib__PDL1_c pdl((Lib__PDL1*)THIS);
	if (items-1 != pdl.ndims + 1)
	  croak("PDL->set expecting %d dimensions (not %d)", pdl.ndims, items-2);
	pdl.seek(&ST(1));
	pdl.set(ST(items-1));

void
DESTROY(sv)
	SV *sv
	PPCODE:
	ospv_bridge* br;
	br= (ospv_bridge*) typemap_any::try_decode(sv, ospdl_dynacast, 0);
	if (br) {
	  br->leave_perl();
	}
