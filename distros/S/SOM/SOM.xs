#include <somcls.h>
#include <somobj.h>

/* In SOM 'any' is struct */
#define any Perlish_any

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "common_init.h"

/* We may use xsubpp from 5.005_64, and it puts some unexpected macros */
#ifdef CUSTOM_XSUBPP
#  define aTHX_
#endif

#undef any

#define tk_shift_	(' ' + 1)

#ifndef SOM_VA_INIBUFSIZE
#  define SOM_VA_INIBUFSIZE (sizeof(void*) * 20)
#endif

typedef struct mysomVa {
  char *start;
  va_list current;
  char *last;
//  char buf[SOM_VA_BUFSIZE];
} *MYsomVaBuf;

MYsomVaBuf 
MYsomVaBuf_create(void *ign1 , int ign2)
{
  MYsomVaBuf vb;

  New(1313, vb, 1, struct mysomVa);
  New(1314, vb->start, SOM_VA_INIBUFSIZE, char);
  vb->current = (va_list)vb->start;
  vb->last = vb->start + SOM_VA_INIBUFSIZE;
  return vb;
}

int
MYsomVaBuf_add(MYsomVaBuf vb, char *arg, int type)
{
  /* Max size is double... */
  if ((char *)vb->current + sizeof(double) > vb->last) {
    STRLEN l = (char *)vb->current - vb->start;
    STRLEN size = vb->last - vb->start;

    size *= 2;
    Renew(vb->start, size, char);
    vb->current = (va_list)(vb->start + l);
    vb->last = vb->start + size;
  }
	switch (type) {
        case tk_TypeCode:
        default:
            croak("Do not know how to treat specifier %d for varargs",
                  type);
        case tk_short:
	    va_arg(vb->current, short) = *(short*)arg;
	    break;
        case tk_ushort:
	    va_arg(vb->current,unsigned short) = *(unsigned short*)arg;
	    break;
        case tk_long:
	    va_arg(vb->current, long) = *(long*)arg;
	    break;
        case tk_ulong:
	    va_arg(vb->current, unsigned long) = *(unsigned long*)arg;
	    break;
        case tk_float:
	    va_arg(vb->current, float) = *(float*)arg;
	    break;
        case tk_double:
	    va_arg(vb->current, double) = *(double*)arg;
	    break;
        case tk_char:
	    va_arg(vb->current, char) = *(char*)arg;
	    break;
        case tk_boolean:
	    va_arg(vb->current, int) = *(int*)arg;
	    break;
        case tk_octet:
	    va_arg(vb->current, unsigned char) = *(unsigned char*)arg;
	    break;
        case tk_enum:
	    va_arg(vb->current, unsigned long) = *(unsigned long*)arg;
	    break;
        case tk_string:
	    va_arg(vb->current, char*) = *(char**)arg;
	    break;
        case tk_pointer:
	    va_arg(vb->current, void*) = *(void**)arg;
	    break;
        case tk_objref:
	    va_arg(vb->current, SOMObject*) = *(SOMObject**)arg;
	    break;
	}
  return 1;
}

void
MYsomVaBuf_get_valist(MYsomVaBuf vb, va_list *vap)
{
   *vap = (va_list)vb->start;
}

void
MYsomVaBuf_destroy(MYsomVaBuf vb)
{
  Safefree(vb->start);
  Safefree(vb);
}

Environment *main_ev;

SOMClass *
PSOM_Find_Class(char *name, int major, int minor, char *dll)
{
  somId nameId = SOM_IdFromString(name);
  SOMClass *classobj;

  if (dll)
    classobj = _somFindClsInFile(SOMClassMgrObject, nameId, major, minor, dll);
  else
    classobj = _somFindClass(SOMClassMgrObject, nameId, major, minor);

  SOMFree(nameId);
  return classobj;
}

int
PSOM_Dispatch0(SOMObject *obj, char *name)
{
  somId methId = SOM_IdFromString(name);
  SOMClass *classobj;
  int rc;

  rc = _somDispatch(obj, /*retval*/ (somToken *) 0, methId, obj, main_ev);

  SOMFree(methId);
  return rc;
}

/* SOMObject_somDispatch() exits the process if method cannot be resolved */
static int
MYsomDispatch( SOMObject *obj,    /* target for somDispatch */
	       somToken *ret,    /* dispatched method result */
	       somId methId,  /* the somId for meth */
	       va_list start_val)
{
    SOMClass *class = _somGetClass(obj);
    somMethodData    md;
    int rc = _somGetMethodData(class, methId, &md);

    if (!rc)
	croak("Can't resolve a SOM method");
    return somApply(obj, ret, &md, start_val);
}

#define PSOM_NewObject(classobj) ((SOMObject *) _somNew(classobj))

#define ttk_void() tk_void
#define ttk_short() tk_short
#define ttk_ushort() tk_ushort
#define ttk_long() tk_long
#define ttk_ulong() tk_ulong
#define ttk_float() tk_float
#define ttk_double() tk_double
#define ttk_char() tk_char
#define ttk_boolean() tk_boolean
#define ttk_octet() tk_octet
#define ttk_enum() tk_enum
#define ttk_string() tk_string
#define ttk_pointer() tk_pointer
#define ttk_objref() tk_objref

#define tSOMClass()		_SOMClass
#define tSOMObject()		_SOMObject
#define tSOMClassMgr()		_SOMClassMgr
#define tSOMClassMgrObject()	SOMClassMgrObject

#define ptrsize()		sizeof(char*)

MODULE = SOM		PACKAGE = SOM	PREFIX = t

PROTOTYPES: ENABLE

int
ptrsize()

int
ttk_void()

int
ttk_short()

int
ttk_ushort()

int
ttk_long()

int
ttk_ulong()

int
ttk_float()

int
ttk_double()

int
ttk_char()

int
ttk_boolean()

int
ttk_octet()

int
ttk_enum()

int
ttk_string()

int
ttk_pointer()

int
ttk_objref()

SOMClass *
tSOMClass()

SOMClass *
tSOMObject()

SOMClass *
tSOMClassMgr()

SOMObject *
tSOMClassMgrObject()

MODULE = SOM		PACKAGE = SOM	PREFIX = PSOM_

BOOT:
 somEnvironmentNew();
 main_ev = somGetGlobalEnvironment();
 newXS("SOM::bootstrap_DSOM", boot_DSOM, file);
 newXS("SOM::bootstrap_SOMIr", boot_SOMIr, file);
 newXS("SOM::bootstrap_SOMObject", boot_SOMObject, file);

SOMClass *
PSOM_Find_Class(name, major = 0, minor = 0, dll = 0)
    char *name;
    int major;
    int minor;
    char *dll;

MODULE = SOM		PACKAGE = SOMClassPtr	PREFIX = PSOM_

SOMObject *
PSOM_NewObject(classobj)
    SOMClass *classobj

MODULE = SOM		PACKAGE = SOMObjectPtr	PREFIX = _som

SOMClass *
_somGetClass(obj)
    SOMObject *obj

char *
_somGetClassName(obj)
    SOMObject *obj

MODULE = SOM		PACKAGE = SOMObjectPtr	PREFIX = PSOM_

int
PSOM_Dispatch0(obj, meth)
    SOMObject *obj;
    char *meth;

int
PSOM_Dispatch_templ(obj, meth, templ, ...)
    SOMObject *obj;
    char *meth;
    char *templ;
PPCODE:
  {
    union { short s; unsigned short us; long l; unsigned long ul;
	    char c; unsigned char uc; float f; double d; char *cp; void *vp;
	    SOMObject *op;
    } ret_buffer, par_buffer;
    va_list start_val;
    MYsomVaBuf vb;
    somToken *ret = 0;
    char *t = templ;
    int is_oidl = 0;
    int i = 3;			/* ordinal of a parameter */
    somId methId = SOM_IdFromString(meth);
    int rc;
    SV *retsv;
    IV tmp;

    if (!*t)
	croak("A zero length template");

    if (*t++ == 'o')
	is_oidl = 1;

    if (!*t)
	croak("No return specifier in a template");

    /* Return value: */
    switch (*t - tk_shift_) {
    case tk_pointer:
    case tk_TypeCode:
    default:
	croak("Do not know how to treat specifier '%c'==%d for return value in '%s'",
	      (*t ? *t : '?'), (int)(*t - tk_shift_), templ);
    case tk_void:
	break;
    case tk_short:
    case tk_ushort:
    case tk_long:
    case tk_ulong:
    case tk_float:
    case tk_double:
    case tk_char:
    case tk_boolean:
    case tk_octet:
    case tk_enum:
    case tk_string:
    case tk_objref:
//    case tk_pointer:
	ret = (somToken *)&ret_buffer;
    }

    vb = (MYsomVaBuf)MYsomVaBuf_create(NULL, 0);
    if (!vb)
	croak("Cannot create VaBuf");
    MYsomVaBuf_add(vb, (char *)&obj, tk_pointer);
    if (!is_oidl)
	MYsomVaBuf_add(vb, (char *)&main_ev, tk_pointer);
    while (*++t) {
	int type = *t - tk_shift_;
	STRLEN n_a;

	if (i >= items)
	    croak("Too few arguments");
	switch (type) {
        case tk_pointer:
        case tk_TypeCode:
        default:
            croak("Do not know how to treat specifier '%c'==%d for parameter in '%s'",
                  (*t ? *t : '?'), type, templ);
        case tk_short:
	    par_buffer.s = (short)SvIV(ST(i));
	    break;
        case tk_ushort:
	    par_buffer.us = (unsigned short)SvIV(ST(i));
	    break;
        case tk_long:
	    par_buffer.l = (long)SvIV(ST(i));
	    break;
        case tk_ulong:
	    par_buffer.ul = (unsigned long)SvIV(ST(i));
	    break;
        case tk_float:
	    par_buffer.f = (float)SvNV(ST(i));
	    break;
        case tk_double:
	    par_buffer.d = (double)SvNV(ST(i));
	    break;
        case tk_char:
	    par_buffer.c = (char)SvIV(ST(i));
	    break;
        case tk_boolean:
	    par_buffer.l = SvTRUE(ST(i));
	    break;
        case tk_octet:
	    par_buffer.uc = (unsigned char)SvIV(ST(i));
	    break;
        case tk_enum:
	    par_buffer.ul = (unsigned long)SvIV(ST(i));
	    break;
        case tk_string:
	    par_buffer.cp = SvPV(ST(i), n_a);
	    break;
	case tk_objref:
	    if (!sv_derived_from(ST(i), "SOMObjectPtr"))
		croak("Argument %d is not of type SOMObjectPtr", i);
	    tmp = SvIV((SV*)SvRV(ST(i)));
	    par_buffer.op = (SOMObject *) tmp;
	    break;
/*        case tk_pointer:
	    par_buffer.vp = (void*)SvPV(ST(i), n_a);
	    break;*/
	}
	if (!MYsomVaBuf_add(vb, (char *)&par_buffer, type))
	    croak("Error while adding to VaBuf, type=%d", type);
	i++;
    }

    if (i != items)
	croak("Too many arguments");

    MYsomVaBuf_get_valist(vb, &start_val);
    rc = MYsomDispatch(
            obj,    /* target for somDispatch */
            ret,    /* dispatched method result */
            methId,  /* the somId for meth */
            start_val);     /* target and args for _set_msg */
    SOMFree(methId);
    MYsomVaBuf_destroy(vb);

    if (!rc)
	croak("Error dispatching a method");
    if (!ret)
	XSRETURN(0);		/* Nothing to return */

    retsv = sv_newmortal();
    switch (templ[1] - tk_shift_) {
    case tk_pointer:
    case tk_void:
    case tk_TypeCode:
    default:
	croak("panic: do not know how to treat specifier '%c'==%d for return value in '%s'",
	      (*t ? *t : '?'), (int)(*t - tk_shift_), templ);
	break;
    case tk_short:
	sv_setiv(retsv, ret_buffer.s);
	break;
    case tk_ushort:
	sv_setuv(retsv, ret_buffer.us);
	break;
    case tk_long:
	sv_setiv(retsv, ret_buffer.l);
	break;
    case tk_enum:
    case tk_ulong:
	sv_setuv(retsv, ret_buffer.ul);
	break;
    case tk_float:
	sv_setnv(retsv, ret_buffer.f);
	break;
    case tk_double:
	sv_setnv(retsv, ret_buffer.d);
	break;
    case tk_char:
	sv_setiv(retsv, ret_buffer.c);
	break;
    case tk_boolean:
    case tk_octet:
	sv_setuv(retsv, ret_buffer.uc);
	break;
    case tk_string:
	sv_setpv(retsv, ret_buffer.cp);
	break;
    case tk_objref:
	sv_setref_pv(retsv, "SOMObjectPtr", (void*)ret_buffer.op);
	break;
    }
    PUSHs(retsv);
  }
