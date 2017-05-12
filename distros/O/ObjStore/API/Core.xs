//
// ALERT:  EVERYTHING IN THIS FILE IS PROBABLY MISORGANIZED
// OR OF DUBIOUS VALUE?
//

#include "osp-preamble.h"
#include "osperl.h"
#include "core.h"

// protected reference
OSPV_Ref2_protect::OSPV_Ref2_protect(OSSVPV *pv) : myfocus(pv)
{}
OSPV_Ref2_protect::OSPV_Ref2_protect(char *dump, os_database *db)
{ myfocus.load(dump, db); }
os_database *OSPV_Ref2_protect::get_database()
{ return myfocus.get_database(); }
int OSPV_Ref2_protect::deleted()
{ return myfocus.deleted() || focus()->_refs == 0; } //little hack
char *OSPV_Ref2_protect::dump()
{ return myfocus.dump(); }
OSSVPV *OSPV_Ref2_protect::focus()
{ assert(_refs); return (OSSVPV*) myfocus.resolve(); }

// hard reference
OSPV_Ref2_hard::OSPV_Ref2_hard(OSSVPV *pv) : myfocus(pv)
{}
OSPV_Ref2_hard::OSPV_Ref2_hard(char *dump, os_database *db)
{ myfocus.load(dump, db); }
os_database *OSPV_Ref2_hard::get_database()
{ return myfocus.get_database(); }
int OSPV_Ref2_hard::deleted()  //only during NOREFS
{ return focus()->_refs == 0; }
char *OSPV_Ref2_hard::dump()
{ return myfocus.dump(); }
OSSVPV *OSPV_Ref2_hard::focus()
{ assert(_refs); return (OSSVPV*) myfocus.resolve(); }


//////////////////////////////////////////////////////////////////////
// DEPRECIATED
/* CCov: off */
OSPV_Ref::OSPV_Ref(OSSVPV *_at) : myfocus(_at)
{}

OSPV_Ref::OSPV_Ref(char *dump, os_database *db)
{ myfocus.load(dump, db); }

OSPV_Ref::~OSPV_Ref()
{}

char *OSPV_Ref::os_class(STRLEN *len)
{ *len = 26; return "ObjStore::DEPRECIATED::Ref"; }

os_database *OSPV_Ref::get_database()
{ return myfocus.get_database(); }

char *OSPV_Ref::dump()
{ return myfocus.dump(); }

int OSPV_Ref::deleted()
{ return myfocus.deleted() || focus()->_refs == 0; }

OSSVPV *OSPV_Ref::focus()
{ return (OSSVPV*) myfocus.resolve(); }

//////////////////////////////////////////////////////////////////////
// DEPRECIATED
OSPV_Cursor::OSPV_Cursor(OSSVPV *_at) : OSPV_Ref(_at)
{}
char *OSPV_Cursor::os_class(STRLEN *len)
{ *len = 29; return "ObjStore::DEPRECIATED::Cursor"; }
void OSPV_Cursor::seek_pole(int)
{ NOTFOUND("seek_pole"); }
void OSPV_Cursor::at()
{ NOTFOUND("at"); }
void OSPV_Cursor::next()
{ NOTFOUND("next"); }

// These APIs should be non-type specific! XXX

MODULE = ObjStore::CORE	PACKAGE = ObjStore

void
_inuse_bridges(...)
	PROTOTYPE: ;$
	PPCODE:
	IV show = items>0? sv_true(ST(0)) : 0;
	IV cnt=0;
#if OSP_BRIDGE_TRACE
	osp_bridge *br = (osp_bridge*) osp_bridge::All.next_self();
	while (br) {
	  if (show) {
	    SV *sv = sv_2mortal(newSVpv("",0));
	    sv_catpvf(sv,"[%d]osp_bridge 0x%x\n", cnt, br);
	    sv_catpvf(sv,"  refs         : %d\n", br->refs);
	    sv_catpvf(sv,"  detached     : %d\n", br->detached);
	    sv_catpvf(sv,"  manual_hold  : %d\n", br->manual_hold);
	    sv_catpvf(sv,"  holding      : %d\n", br->holding);
	    sv_catpvf(sv,"  txsv         : 0x%x\n", br->txsv);
	    if (br->where)
	      sv_catpvf(sv,"  created%s\n", SvPV(br->where, PL_na));
	    XPUSHs(sv);
	  }
	  ++cnt;
	  br = (osp_bridge*) br->al.next_self();
	}
#else
	if (show) warn("_inuse_bridges detail is not available");
	XPUSHs(sv_2mortal(newSViv(osp_bridge::Inuse)));
#endif

MODULE = ObjStore::CORE	PACKAGE = ObjStore::UNIVERSAL

void
OSSVPV::_new_ref(type, sv1)
	int type;
	SV *sv1;
	PPCODE:
	PUTBACK;
	os_segment *seg = osp_thr::sv_2segment(sv1);
	SV *ret;
	OSSVPV *tpv;
	if (type == 0) {
	  NEW_OS_OBJECT(tpv, seg, OSPV_Ref2_protect::get_os_typespec(),
			OSPV_Ref2_protect(THIS));
	  ret = osp_thr::ospv_2sv(tpv, 1);
	} else if (type == 1) {
	  NEW_OS_OBJECT(tpv, seg, OSPV_Ref2_hard::get_os_typespec(),
			OSPV_Ref2_hard(THIS));
	  ret = osp_thr::ospv_2sv(tpv, 1);
	} else { croak("OSSVPV->new_ref(): unknown type"); }
	SPAGAIN;
	XPUSHs(ret);

MODULE = ObjStore::CORE	PACKAGE = ObjStore::Ref

void
_load(CLASS, sv1, type, dump, db)
	SV *CLASS;
	SV *sv1;
	int type;
	char *dump;
	os_database *db;
	PPCODE:
	PUTBACK;
	os_segment *seg = osp_thr::sv_2segment(sv1);
	OSPV_Ref2 *ref;
	if (type == 0) {
	  ref = new (seg, OSPV_Ref2_protect::get_os_typespec())
			OSPV_Ref2_protect(dump, db);
	} else if (type == 1) {
	  ref = new (seg, OSPV_Ref2_hard::get_os_typespec())
			OSPV_Ref2_hard(dump, db);
	} else { croak("OSSVPV->_load(): unknown type"); }
	ref->bless(CLASS);
	return;

#-----------------------------# Cursor

MODULE = ObjStore::CORE	PACKAGE = ObjStore::DEPRECIATED::Cursor

void
OSPV_Cursor::moveto(side)
	SV *side
	CODE:
	if (SvPOKp(side)) {
	  char *str = SvPV(side, PL_na);
	  if (strEQ(str, "end")) THIS->seek_pole(1);
	  else warn("%p->moveto(%s): undefined", THIS, str);
	} else if (SvIOK(side)) {
	  if (SvIV(side)==0 || SvIV(side)==-1) THIS->seek_pole(0);
	  else warn("%p->moveto(%d): unsupported", THIS, SvIV(side));
	} else croak("moveto");

void
OSPV_Cursor::at()
	PPCODE:
	PUTBACK; THIS->at(); return;

void
OSPV_Cursor::next()
	PPCODE:
	PUTBACK; THIS->next(); return;

#-----------------------------# Ref

MODULE = ObjStore::CORE	PACKAGE = ObjStore::DEPRECIATED::Ref

os_database *
OSPV_Ref::get_database()
	PREINIT:
	char *CLASS = "ObjStore::Database";

int
OSPV_Ref::deleted()

void
OSPV_Ref::focus()
	PPCODE:
	PUTBACK;
	SV *sv = osp_thr::ospv_2sv(THIS->focus());
	SPAGAIN;
	XPUSHs(sv);

