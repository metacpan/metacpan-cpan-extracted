// -*-C++-*- mode
#include "osp-preamble.h"
#include "osperl.h"
#include "Ring.h"

#undef MAX
#define MAX(x,y) (x>y? x : y)
#undef MIN
#define MIN(x,y) (x<y? x : y)

osp_ring_page::osp_ring_page()
{
  next = prev = 0;
  fill = old_fill = 0;
  first = 0;
}

osp_ring_page::~osp_ring_page()
{
  if (next) next->prev = prev;
  if (prev) prev->next = next;
}

void osp_ring_page::uncache_keys()
{
  keys.set_undef();
}

void osp_ring_page::cache_keys(osp_pathexam &exam, OSSVPV *pv)
{
  exam.load_keypack1(pv, keys);
}

void osp_ring_page::verify_keys(osp_pathexam &exam)
{
  if (!keys.cnt) return;

  osp_keypack1 kp;
  exam.load_keypack1(*first, kp);
  if (!(kp == keys)) croak("Key cache out of sync");
}

int osp_ring_page::qck_cmp(osp_pathexam &exam, int update_ok)
{
  if (update_ok && !keys.cnt)
    exam.load_keypack1(*first, keys);
  return exam.compare(keys, 1);
}

void osp_ring_page::_move(OSPVptr *start, OSPVptr *end, OSPVptr *to)
{
  assert(start <= end);
  if (start < to) {
    to += end - start;
    while (1) {
      to->steal(*end);
      if (start == end) break;
      --end;
      --to;
    }
    /*
    for (int xx=end-start; xx >= 0; xx--) {
      ar[to+xx].steal(ar[start+xx]);
    }
    */
  } else {
    while (1) {
      to->steal(*start);
      if (start == end) break;
      ++start;
      ++to;
    }
    /*
    for (int xx=0; xx <= end-start; xx++) {
      ar[to+xx].steal(ar[start+xx]);
    }
    */
  }
}

void osp_ring_page::reset_first()
{
  if (!first) { first = array(); return; }
  if (first == array()) return;
  OSPVptr *top = array();
  _move(first, first+fill-1, top);
  first = top;
}

OSSVPV *osp_ring_page::shift()
{
  assert(fill > 0);
  if (!first) first = array();
  OSSVPV *pv = first->resolve();
  ++first;
  --fill;
  return pv;
}

OSSVPV *osp_ring_page::pop()
{
  assert(fill > 0);
  --fill;
  if (!first) first = array();
  OSSVPV *pv = (first + fill)->resolve();
  return pv;
}

void osp_ring_page::extend(int to)
{
  reset_first();
  assert(to <= get_max());
  assert(to > fill);
  fill = to;
}

void osp_ring_page::push(SV **base, int items)
{
  reset_first();
  assert(fill + items <= get_max());
  for (int xx=0; xx < items; xx++) {
    *(first + fill) = osp_thr::sv_2bridge(base[xx], 0,
					  os_segment::of(this))->ospv();
    ++fill;
  }
}

void osp_ring_page::push(OSSVPV *pv)
{
  reset_first();
  assert(fill + 1 <= get_max());
  *(first+fill) = pv;
  ++fill;
}

void osp_ring_page::prepare_insert(int items)
{
  uncache_keys();
  OSPVptr *top = array();
  if (!first) first = top;
  assert(fill + items <= get_max());
  if (first - top < items) {
    if (fill) _move(first, first+fill-1, top + items);
    first = top + items;
  }
}

void osp_ring_page::unshift(SV **base, int items)
{
  prepare_insert(items);
  first -= items;
  for (int xx=0; xx < items; xx++) {
    *(first+xx) = osp_thr::sv_2bridge(base[xx], 0, os_segment::of(this))->ospv();
  }
  fill += items;
}

void osp_ring_page::unshift(OSSVPV *pv)
{
  prepare_insert(1);
  --first;
  *first = pv;
  ++fill;
}

void osp_ring_page::fwd_xfer(int at)
{
  int move = fill - at;
  assert(move > 0 && next->avail() >= move);
  next->prepare_insert(move);
  next->first -= move;
  OSPVptr *dst = next->first;
  OSPVptr *src = first + at;
  for (int xx=0; xx < move; xx++) {
    dst->steal(*src);
    ++dst;
    ++src;
  }
  fill -= move;
  next->fill += move;
  // backfill at the same time XXX
}

void osp_ring_page::insert_after(int at, OSSVPV *pv)
{
  reset_first();
  if (at < fill - 1) {
    _move(first + at + 1, first + fill - 1, first + at + 2);
  }
  *(first + at + 1) = pv;
  ++fill;
}

void osp_ring_page::splice(int offset, int length, SV **base, int count)
{
  reset_first();
  if (length != count && offset + length < fill)
    _move(first + offset + length, first + fill-1, first + offset + count);
  for (int xx=offset; xx < offset+count; xx++) {
    *(first + xx) = osp_thr::sv_2bridge(base[xx-offset], 0,
					os_segment::of(this))->ospv();
  }
  fill += count - length;
}

// -------------------------------------------------

int osp_ring_page1::get_max()
{ return OSP_RING_PAGE1_MAX; }

int osp_ring_page1::avail()
{ return OSP_RING_PAGE1_MAX - fill; }

OSPVptr *osp_ring_page1::array()
{ return ar; }

OSPVptr &osp_ring_page1::at(int xx)
{
  if (xx < 0 || xx >= fill)
    croak("Attempt to access unallocated page slot");
  return *(first+xx);
}

// -------------------------------------------------

OSPV_ring_index1::OSPV_ring_index1()
{
  version = 0;
  max = fill = 0;
  first = last = 0;
}

void OSPV_ring_index1::fix_stats()
{
  if (!RG_STALE(this)) return;
  if (first)
    fill += first->fill - first->old_fill;
  if (first != last)
    fill += last->fill - last->old_fill;
  RG_STALE_off(this);
}

U32 OSPV_ring_index1::read_fill()
{
  if (!RG_STALE(this)) return fill;
  else {
    U32 zfill = fill;
    if (first)
      zfill += first->fill - first->old_fill;
    if (first != last)
      zfill += last->fill - last->old_fill;
    return zfill;
  }
}

void OSPV_ring_index1::stale_stats()
{
  // playing tricks to avoid writes
  if (RG_STALE(this)) return;
  first->old_fill = first->fill;
  last->old_fill = last->fill;
  RG_STALE_on(this);
}

osp_ring_page *OSPV_ring_index1::new_page(osp_ring_page *ref, int after)
{
  osp_ring_page *npg;
  fix_stats();
  NEW_OS_OBJECT(npg, os_segment::of(this),
		osp_ring_page1::get_os_typespec(), osp_ring_page1());
  max += npg->get_max();
  if (!ref) {
    assert(fill == 0);
    assert(!first);
    first = last = npg;
    return npg;
  }
  else {
    assert(ref);
    if (after) {
      npg->prev = ref;
      npg->next = ref->next;
    } else {
      npg->next = ref;
      npg->prev = ref->prev;
    }
    if (npg->next)
      npg->next->prev = npg;
    else
      last = npg;
    if (npg->prev)
      npg->prev->next = npg;
    else
      first = npg;
    return npg;
  }
}

osp_ring_page *OSPV_ring_index1::get_page(U32 loc, I16 *offset)
{
  U32 zfill = read_fill();
  U32 pgtop;
  osp_ring_page *pp;
  assert(loc < zfill);
  if (loc < zfill/2) {
    pp = first;
    pgtop = 0;
    while (loc >= pgtop + pp->fill) {
      pgtop += pp->fill;
      pp = pp->next;
      assert(pp);
    }
  }
  else {
    pp = last;
    pgtop = zfill - pp->fill;
    while (loc < pgtop) {
      pp = pp->prev;
      assert(pp);
      pgtop -= pp->fill; 
    }
  }
  *offset = loc - pgtop;
  assert(*offset >= 0 && *offset < pp->fill);
  return pp;
}

OSPV_ring_index1::~OSPV_ring_index1()
{ CLEAR(); }

int OSPV_ring_index1::get_perl_type()
{ return SVt_PVAV; }

char *OSPV_ring_index1::os_class(STRLEN *len)
{ *len = 15; return "ObjStore::Index"; }

char *OSPV_ring_index1::rep_class(STRLEN *len)
{ *len = 26; return "ObjStore::REP::Ring::Index"; }

int OSPV_ring_index1::FETCHSIZE()
{ return read_fill(); }

void OSPV_ring_index1::CLEAR()
{
  fix_stats();
  ++version;
  while (first) {
    first->fill = 0;
    free_page(first);
  }
  fill = 0;
  assert(!max);
}

void OSPV_ring_index1::_debug1(void *)
{
  dOSP;
  osp_pathexam *exam = &osp->exam;
  exam->init();
  exam->load_path(((OSSVPV*)conf)->avx(1)->safe_rv());

  osp_ring_page *pp = first;
  while (pp) {
    pp->verify_keys(*exam);
    pp = pp->next;
  }
}

void OSPV_ring_index1::free_page(osp_ring_page *pp)
{
  fix_stats();
  ++version;
  assert(pp->fill == 0);
  if (first == pp) first = pp->next;
  if (last == pp) last = pp->prev;
  max -= pp->get_max();
  delete pp;
}

void OSPV_ring_index1::Extend(U32 to)
{
  osp_ring_page *pp;
  fix_stats();
  if (to < fill) return;
  pp = last? last : new_page(0,0);
  U32 more = to - fill;
  if (more > pp->avail()) more = pp->avail();
  pp->extend(pp->fill + more);
  fill += more;
  while (fill < to) {
    pp = new_page(pp, 1);
    more = to - fill;
    if (more > pp->avail()) more = pp->avail();
    pp->extend(pp->fill + more);
    fill += more;
  }
}

void OSPV_ring_index1::FETCH(SV *key)
{
  I16 off;
  osp_ring_page *pp;
  U32 to = osp_thr::sv_2aelem(key);
  if (to < 0 || to >= read_fill())
    return;
  pp = get_page(to, &off);
  OSSVPV *pv = pp->at(off).resolve();
  SV *sv = osp_thr::ospv_2sv(pv);
  dSP;
  XPUSHs(sv);
  PUTBACK;
}

void OSPV_ring_index1::STORE(SV *key, SV *nval)
{
  U32 to = osp_thr::sv_2aelem(key);
  I16 off;
  Extend(to+1);
  osp_ring_page *pp = get_page(to, &off);
  if (off == 0) pp->uncache_keys();
  pp->at(off) = osp_thr::sv_2bridge(nval, 0, os_segment::of(this))->ospv();
  dTHR;
  if (GIMME_V == G_VOID) return;
  djSP;
  XPUSHs(sv_mortalcopy(nval));
  PUTBACK;
}

void OSPV_ring_index1::POP()
{
  osp_ring_page *pp = last;
  if (!pp) return;
  stale_stats();
  SV *ret = osp_thr::ospv_2sv(pp->pop());
  if (!pp->fill)
    free_page(pp);
  djSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_ring_index1::SHIFT()
{
  osp_ring_page *pp = first;
  if (!pp) return;
  stale_stats();
  pp->uncache_keys();
  SV *ret = osp_thr::ospv_2sv(pp->shift());
  if (!pp->fill)
    free_page(pp);
  djSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_ring_index1::PUSH(SV **base, int items)
{
  while (items) {
    osp_ring_page *pp = last;
    if (!pp || !pp->avail()) pp = new_page(last, 1);
    stale_stats();
    int chunk = MIN(pp->avail(), items);
    pp->push(base, chunk);
    base += chunk;
    items -= chunk;
  }
}

void OSPV_ring_index1::UNSHIFT(SV **base, int items)
{
  while (items) {
    osp_ring_page *pp = first;
    if (!pp || !pp->avail()) pp = new_page(first, 0);
    else pp->uncache_keys();
    stale_stats();
    int chunk = MIN(pp->avail(), items);
    pp->unshift(base, chunk);
    base += chunk;
    items -= chunk;
  }
}

void OSPV_ring_index1::split(osp_ring_page *pp, int at)
{
  if (!pp->next || pp->next->avail() <= pp->fill - at) new_page(pp, 1);
  pp->uncache_keys();
  pp->fwd_xfer(at);
}

void OSPV_ring_index1::SPLICE(int offset, int length, SV **top, int count)
{
  fix_stats();
  Extend(offset + length);
  osp_ring_page *pp = 0;
  I16 at;
  while (length) {
    if (!pp) { pp = get_page(offset, &at); }
    else {
      pp = pp->next;
      at = 0;
      pp->uncache_keys();
    }
    int chunk = pp->get_max() - at;
    int clen = MIN(length, chunk);
    int ccnt = MIN(count, chunk);

    pp->splice(at, clen, top, ccnt);

    length = MAX(0, length - clen);
    count = MAX(0, count - ccnt);
    top += ccnt;
  }
  if (count) {
    if (!pp) pp = get_page(offset, &at);
    split(pp, at);
    
    fill += count;
    while (count) {
      if (!pp->avail()) pp = new_page(pp, 1);
      int chunk = MIN(pp->avail(), count);
      pp->push(top, chunk);
      top += chunk;
      count -= chunk;
    }
  }
}

OSSVPV *OSPV_ring_index1::new_cursor(os_segment *seg)
{ return new(seg, OSPV_ring_index1_cs::get_os_typespec())
    OSPV_ring_index1_cs(this); }

double OSPV_ring_index1::_percent_filled()
{ return fill/(double)max; }

//-----------------------------------------------------------

void OSPV_ring_index1_cs::CHK_VER()
{
  // incr(version) only happens when pages are freed!
  OSPV_ring_index1 *rp = (OSPV_ring_index1 *) myfocus.resolve();
  STRLEN _len;
  if (version != rp->version)
    croak("Version mismatch on 0x%x=%s", rp, rp->os_class(&_len));
}

OSPV_ring_index1_cs::OSPV_ring_index1_cs(OSPV_ring_index1 *_fo)
{
  myfocus = _fo;
  version = _fo->version;
  page=0;
}

OSSVPV *OSPV_ring_index1_cs::focus()
{ return myfocus; }

I32 OSPV_ring_index1_cs::pos()
{
  if (!RG_POSITION(this)) {
    if (!RG_ATEND(this)) {
      return -1;
    } else {
      OSPV_ring_index1 *rp = (OSPV_ring_index1 *) myfocus.resolve();
      return rp->read_fill();
    }
  } else {
    CHK_VER();
    return abpos;
  }
}

void OSPV_ring_index1_cs::at()
{
  if (!RG_POSITION(this)) return;
  CHK_VER();
  SV *ret = osp_thr::ospv_2sv(page->at(reloff));
  dSP;
  XPUSHs(ret);
  PUTBACK;
}

void OSPV_ring_index1_cs::store(SV *nval)
{
  if (!RG_POSITION(this)) croak("Can't store to unpositioned cursor");
  CHK_VER();
  if (reloff == 0) page->uncache_keys();
  page->at(reloff) = osp_thr::sv_2bridge(nval, 0, os_segment::of(this))->ospv();
}

void OSPV_ring_index1_cs::keys()
{
  if (!RG_POSITION(this)) return;
  CHK_VER();
  OSPV_ring_index1 *rp = (OSPV_ring_index1 *) myfocus.resolve();
  OSSVPV *conf = rp->conf;
  if (!conf) croak("keys() on unconfigured index");
  dOSP;
  osp_pathexam *exam = &osp->exam;
  exam->init();
  exam->load_path(conf->avx(1)->safe_rv());
  exam->load_target('x', page->at(reloff));
  exam->push_keys();
}

void OSPV_ring_index1_cs::moveto(I32 xto)  //unsigned? XXX
{
  OSPV_ring_index1 *rp = (OSPV_ring_index1 *) myfocus.resolve();
  version = rp->version;
  if (xto < 0 || xto >= rp->read_fill()) {
    RG_POSITION_off(this);
    if (xto < 0) RG_ATEND_off(this); else RG_ATEND_on(this);
    return;
  }
  RG_POSITION_on(this);
  abpos = xto;
  page = rp->get_page(xto, &reloff);
}

void OSPV_ring_index1_cs::step(I32 delta)
{
  OSPV_ring_index1 *rp = (OSPV_ring_index1 *) myfocus.resolve();
  CHK_VER();
  abpos += delta;
  if (delta > 0) {
    while (delta) {
      //assert(delta > 0);
      if (!RG_POSITION(this)) {
	if (RG_ATEND(this)) return;
	page = rp->first;
	if (!page) { RG_ATEND_on(this); return; }
	reloff = 0;
	abpos = 0;
	RG_POSITION_on(this);
	--delta;
      } else {
	int chunk = MIN(delta, page->fill-1 - reloff);
	if (chunk) {
	  reloff += chunk;
	  delta -= chunk;
	}
	else {
	  page = page->next;
	  if (!page) {
	    RG_POSITION_off(this);
	    RG_ATEND_on(this);
	    return;
	  }
	  reloff = 0;
	  --delta;
	}
      }
    }
  } else /* delta < 0 */ {
    while (delta) {
      //assert(delta < 0);
      if (!RG_POSITION(this)) {
	if (!RG_ATEND(this)) return;
	page = rp->last;
	if (!page) { RG_ATEND_off(this); return; }
	abpos = rp->read_fill() - 1;
	reloff = page->fill - 1;
	RG_POSITION_on(this);
	++delta;
      } else {
	int chunk = MIN(-delta, reloff);
	if (chunk) {
	  reloff -= chunk;
	  delta += chunk;
	}
	else {
	  page = page->prev;
	  if (!page) {
	    RG_POSITION_off(this);
	    RG_ATEND_off(this);
	    return;
	  }
	  reloff = page->fill - 1;
	  ++delta;
	}
      }
    }
  }
}

// MESSY stuff -------------------------------------

int OSPV_ring_index1::add(OSSVPV *pv)
{
  if (!conf) croak("Index not configured");

  dOSP;
  osp_pathexam *exam = &osp->exam;
  exam->init();
  exam->load_path(((OSSVPV*)conf)->avx(1)->safe_rv());
  if (!exam->load_target('x', pv)) return 0;

  osp_ring_page *pp = last;
  if (!pp || exam->compare(pp->at(pp->fill - 1), 0) >= 0) {
    // can insert as last record
    if (!pp || pp->avail() <= 1) pp = new_page(last, 1);
    stale_stats();
    if (!pp->fill) pp->cache_keys(*exam, pv);
    pp->push(pv);
    return 1;
  }
  
  fix_stats();
  ++fill;

  while (pp && pp->qck_cmp(*exam, 1) < 0) pp = pp->prev;
  if (!pp) {
    pp = first;
    if (!pp || !pp->avail()) pp = new_page(first, 0);
    //warn("4");
    pp->unshift(pv);
    return 1;
  }
  for (int xx = pp->fill - 1; xx >= 0; xx--) {
    if (exam->compare(pp->at(xx), 0) >= 0) {
      if (pp->avail()) {
	//warn("1 [%d]", xx);
	pp->insert_after(xx, pv);
      } else {
	if (xx < pp->fill - 1) {
	  //warn("2");
	  split(pp, xx+1);
	  pp->push(pv);
	} else {
	  //warn("3");
	  osp_ring_page *npg = new_page(pp, 1);
	  pp->fwd_xfer(pp->fill/2);
	  npg->push(pv);
	}
      }
      return 1;
    }
  }
  croak("Add failed?");
  return 0;
}

int OSPV_ring_index1::remove(OSSVPV *pv)
{
  if (!conf) croak("Index not configured");
  croak("Not implemented");
  return 0;
}

int OSPV_ring_index1_cs::seek(osp_pathexam &exam)
{
  OSPV_ring_index1 *rp = (OSPV_ring_index1 *) myfocus.resolve();
  if (rp->version != version || !RG_POSITION(this)) {
    // start at the last page if not already positioned
    page = rp->last;
    // let abpos become invalid
    if (!page) return 0;
  }
  OSSVPV *conf = rp->conf;
  if (!conf) croak("Index not configured");
  exam.load_path(conf->avx(1)->safe_rv());
  if (exam.get_keycnt() < 1) {
    warn("Seek to where?  No keys found");
    return 0;
  }

  dTXN;
  int updt = !txn? 1 : txn->can_update(this);

  //int dir = page->qck_cmp(exam);
  // binary search
  // then linear search
  // give up
}

// cope with descending XXX

MODULE = ObjStore::REP::Ring	PACKAGE = ObjStore::REP::Ring

PROTOTYPES: DISABLE

BOOT:
{
  extern _Application_schema_info ObjStore_REP_Ring_dll_schema_info;
  osp_thr::use("ObjStore::REP::Ring", OSPERL_API_VERSION);
  osp_thr::register_schema("ObjStore::REP::Ring",
	&ObjStore_REP_Ring_dll_schema_info);
}

MODULE = ObjStore::REP::Ring	PACKAGE = ObjStore::REP::Ring::Index

static void
new(clsv, seg)
  SV *clsv;
  SV *seg;
	PPCODE:
	os_segment *area = osp_thr::sv_2segment(seg);
	PUTBACK;
	OSPV_ring_index1 *pv;
	NEW_OS_OBJECT(pv, area, OSPV_ring_index1::get_os_typespec(), OSPV_ring_index1());
	pv->bless(ST(0));
	return;

void
OSSVPV::_conf_slot(...)
	PPCODE:
	PUTBACK;
	OSPV_ring_index1 *pv = (OSPV_ring_index1 *) THIS;
	SV *ret=0;
	if (items == 2) {
	  pv->fix_stats();
	  if (pv->fill) croak("Can't reconfigure non-empty index");
	  pv->conf = SvOK(ST(1))? osp_thr::sv_2bridge(ST(1), 1)->ospv() : 0;
	}
	else {
	  ret = osp_thr::ospv_2sv(pv->conf);
	}
	SPAGAIN;
	if (ret) XPUSHs(ret);
