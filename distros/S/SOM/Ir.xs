#include <somcls.h>
#include <somobj.h>
#include <repostry.h>
#include <containd.h>
#include <containr.h>
#include <attribdf.h>
#include <operatdf.h>
#include <paramdef.h>

/* In SOM 'any' is struct */
#define any Perlish_any

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "common_init.h"

/* We use xsubpp from 5.005_64, and it puts some unexpected macros */
#ifdef CUSTOM_XSUBPP
#  define aTHX_
#endif

#undef any

typedef Contained ContainedContainer;
typedef any SOM____any;

#define tRepositoryNew()	((SOMObject*)RepositoryNew())

#define contained_describe(obj,ev)	\
  ((AttributeDescription*)((Contained_describe((obj),(ev))).value._value))

SV *
contained_within_(Contained *obj, Environment *ev)
{
    sequence(Container) seq = Contained_within(obj,ev);
    SV *sv = newSVpvn((char*)seq._buffer, seq._length * sizeof(Container*));

    if (seq._length)
	SOMFree(seq._buffer);
    return sv;
}

SV *
container_contents_(Container *obj, Environment *ev, char *lim, bool noinh)
{
    sequence(Contained) seq = Container_contents(obj,ev,lim,noinh);
    SV *sv;

    /*printf("seq._buffer=%#lx, seq._length=%ld\n", (long)seq._buffer, (long)seq._length);*/
    sv = newSVpvn((char*)seq._buffer, seq._length * sizeof(Contained*));

    if (seq._length)
	SOMFree(seq._buffer);
    return sv;
}

SV *
container_lookup_name_( Container *obj, Environment *env, char *name, int levels, char *type, bool noinherited)
{
    sequence(Contained) seq = Container_lookup_name(obj,env,name,levels,type,noinherited);
    SV *sv = newSVpvn((char*)seq._buffer, seq._length * sizeof(Contained*));

    if (seq._length)
	SOMFree(seq._buffer);    
    return sv;
}

#define ad_name(ad)		((ad)->name)
#define ad_id(ad)		((ad)->id)
#define ad_defined_in(ad)	((ad)->defined_in)
#define ad_type(ad)		((ad)->type)
#define ad_readonly(ad)		(((ad)->mode) == AttributeDef_READONLY)

#define ad_DESTROY(ad)		SOMFree(ad)

char *
pd_mode(ParameterDef *pd, Environment *env)
{
    int x = ParameterDef__get_mode(pd,env);

    return ((x == ParameterDef_INOUT)
	    ? "INOUT" : ( (x == ParameterDef_IN) 
			  ? "IN" : ( (x == ParameterDef_OUT) 
				     ? "OUT" : "?" ) ) );
}

#define any__type(a,env)	(a)._type

unsigned long
TypeCode_parameter_type_kind(TypeCode tc, Environment *env, long n)
{
    unsigned long inikind = TypeCode_kind(tc, env);
    any a = TypeCode_parameter(tc, env, n);
/*    TypeCode type = a._type; */
/*    unsigned long kind = TypeCode_kind(type, env); */
    unsigned long inikind1 = TypeCode_kind(tc, env);

    if (inikind != tk_string)
	warn("Got unexpected typecode kind %lu", inikind);
    if (inikind != inikind1) {
	unsigned long inikind2;
	warn("Typecode kind mismatch %lu != %lu", inikind, inikind1);
	inikind2 = TypeCode_kind(TC_string, env);
	if (inikind2 != tk_string)
	    warn("TC_string kind mismatch %lu != %lu", inikind2, tk_string);
    }
    return ((unsigned long) &a);
}


MODULE = SOMIr		PACKAGE = SOM	PREFIX = t

PROTOTYPES: ENABLE

Repository *
tRepositoryNew()

MODULE = SOMIr		PACKAGE = ContainedPtr	PREFIX = Contained__get_

char *
Contained__get_name(obj,env)
    Contained	*obj
    Environment *env

char *
Contained__get_id(obj,env)
    Contained	*obj
    Environment *env

char *
Contained__get_defined_in(obj,env)
    Contained	*obj
    Environment *env

# somModifiers attribute of type sequence(somModifier) unsupported


MODULE = SOMIr		PACKAGE = ContainedPtr	PREFIX = contained_

SV *
contained_within_(obj,env)
    Contained	*obj
    Environment *env

AttributeDescription *
contained_describe(obj, env)
    Contained	*obj;
    Environment *env

MODULE = SOMIr		PACKAGE = ContainerPtr	PREFIX = container_

SV *
container_lookup_name_(obj,env,name,levels,type,noinherited)
    Container	*obj;
    Environment *env;
    char	*name;
    int		levels;
    char	*type;
    bool	noinherited;

# describe_contents(obj, env, type, noinherited) not supported

SV *
container_contents_(obj, env, type, noinherited)
    Container	*obj;
    Environment *env;
    char	*type;
    bool	noinherited;

MODULE = SOMIr		PACKAGE = ParameterDefPtr	PREFIX = pd_

char *
pd_mode(pd,env)
    ParameterDef *pd;
    Environment *env

MODULE = SOMIr		PACKAGE = ParameterDefPtr	PREFIX = ParameterDef__get_

TypeCode
ParameterDef__get_type(pd,env)
    ParameterDef *pd;
    Environment *env

MODULE = SOMIr		PACKAGE = OperationDefPtr	PREFIX = OperationDef__get_

TypeCode
OperationDef__get_result(od,env)
    OperationDef *od;
    Environment *env

MODULE = SOMIr		PACKAGE = AttributeDescriptionPtr	PREFIX = ad_

char *
ad_name(ad)
    AttributeDescription *ad;

char *
ad_id(ad)
    AttributeDescription *ad;

char *
ad_defined_in(ad)
    AttributeDescription *ad;

TypeCode
ad_type(ad)
    AttributeDescription *ad;

bool
ad_readonly(ad)
    AttributeDescription *ad;

void
ad_DESTROY(ad)
    AttributeDescription *ad;

MODULE = SOMIr		PACKAGE = TypeCode	PREFIX = TypeCode_

unsigned long
TypeCode_kind(tc,env)
    TypeCode	tc;
    Environment *env

int
TypeCode_param_count(tc,env)
    TypeCode	tc;
    Environment *env

SOM__::any
TypeCode_parameter(tc,env,n)
    TypeCode	tc;
    Environment *env;
    long	n;

unsigned long
TypeCode_parameter_type_kind(tc, env, n)
    TypeCode	tc;
    Environment *env;
    long	n;


MODULE = SOMIr		PACKAGE = SOM__::any	PREFIX = any__

TypeCode
any__type(a,env=0)
    SOM__::any	a;
    Environment *env;

SV *
any__value(a,env)
    SOM__::any	a;
    Environment *env;
  CODE:
    {
	TypeCode tc = a._type;
	unsigned long kind = TypeCode_kind(tc, env);
	RETVAL = sv_newmortal();
	switch (kind) {
	case tk_pointer:
	case tk_void:
	case tk_TypeCode:
	default:
	    croak("panic: do not know how to extract value from any with TypeCode=kind=%lu",
		  kind);
	    break;
	case tk_short:
	    sv_setiv(RETVAL, *(short*)a._value);
	    break;
	case tk_ushort:
	    sv_setuv(RETVAL, *(unsigned short*)a._value);
	    break;
	case tk_long:
	    sv_setiv(RETVAL, *(long*)a._value);
	    break;
	case tk_enum:
	case tk_ulong:
	    sv_setuv(RETVAL, *(unsigned long*)a._value);
	    break;
	case tk_float:
	    sv_setnv(RETVAL, *(float*)a._value);
	    break;
	case tk_double:
	    sv_setnv(RETVAL, *(double*)a._value);
	    break;
	case tk_char:
	    sv_setiv(RETVAL, *(char*)a._value);
	    break;
	case tk_boolean:
	case tk_octet:
	    sv_setuv(RETVAL, *(unsigned char*)a._value);
	    break;
	case tk_string:
	    sv_setpv(RETVAL, *(char**)a._value);
	    break;
	}
    }
