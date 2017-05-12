#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <mozilla/nsID.h>


MODULE = Mozilla::nsID		PACKAGE = Mozilla::nsID		

SV *new_empty(const char* myclass)
	INIT:
		SV *obj_ref;
		SV *obj;
		nsID *id;
	CODE:
		obj_ref = newSViv(0);
		obj = newSVrv(obj_ref, myclass);
		id = new nsID;
		memset(id, 0, sizeof(*id));
		sv_setiv(obj, (IV) id);
		SvREADONLY_on(obj);
		RETVAL = obj_ref;
	OUTPUT:
		RETVAL
		
SV *new(const char* myclass, unsigned int m0, unsigned short m1 , unsigned short m2, SV *m3)
	PREINIT:
		SV *obj_ref;
		SV *obj;
		nsID *id;
		I32 m3_len;
		int i;
	INIT:
		if ((!SvROK(m3)) || (SvTYPE(SvRV(m3)) != SVt_PVAV)
				|| ((m3_len = av_len((AV *)SvRV(m3))) < 0)) {
			XSRETURN_UNDEF;
		}
	CODE:
		obj_ref = newSViv(0);
		obj = newSVrv(obj_ref, myclass);
		id = new nsID;
		id->m0 = m0;
		id->m1 = m1;
		id->m2 = m2;
		for (i = 0; i <= m3_len && i < 8; i++) {
			id->m3[i] = (unsigned char)
				SvNV(*av_fetch((AV *) SvRV(m3), i, 0));
		}
		sv_setiv(obj, (IV) id);
		SvREADONLY_on(obj);
		RETVAL = obj_ref;
	OUTPUT:
		RETVAL

unsigned int m0(SV *obj)
	CODE:
		RETVAL = ((nsID *) SvIV(SvRV(obj)))->m0;
	OUTPUT:
		RETVAL

unsigned short m1(SV *obj)
	CODE:
		RETVAL = ((nsID *) SvIV(SvRV(obj)))->m1;
	OUTPUT:
		RETVAL

unsigned int m2(SV *obj)
	CODE:
		RETVAL = ((nsID *) SvIV(SvRV(obj)))->m2;
	OUTPUT:
		RETVAL

void m3(SV *obj)
	INIT:
		nsID *id;
		int i;
	PPCODE:
		id = (nsID *) SvIV(SvRV(obj));
		for (i = 0; i < sizeof(id->m3); i++) {
			XPUSHs(sv_2mortal(newSVnv(id->m3[i])));
		}

SV *ToString(SV *obj)
	INIT:
		char *str;
		SV *res;
	CODE:
		str = ((nsID *) SvIV(SvRV(obj)))->ToString();
		res = newSVpvf("%s", str);
		free(str);
		RETVAL = res;
	OUTPUT:
		RETVAL

int Parse(SV *obj, const char *str)
	INIT:
		PRBool res;
	CODE:
		res = ((nsID *) SvIV(SvRV(obj)))->Parse(str);
		if (!res) {
			XSRETURN_UNDEF;
		}
		RETVAL = 1;
	OUTPUT:
		RETVAL

void DESTROY(SV* obj)
	INIT:
		nsID *id;
	CODE:
		id = (nsID *) SvIV(SvRV(obj));
		delete id;
