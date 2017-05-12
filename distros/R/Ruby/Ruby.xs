/*
	$Id: Ruby.xs,v 1.6 2004/04/14 07:15:05 jigoro Exp $
*/

#include "ruby_pm.h"

#define STACK_EXTEND { const char stack_extend[ 1024*2 ]; (void)stack_extend; }

#define INSTALL_GVAR(sv, name) sv_magicext(sv, NULL, PERL_MAGIC_ext, &gvar_vtbl, (char*)name, (I32)strlen(name))

static ID id_to_f;
static ID id_to_i;
static ID id_new;
static ID id_equals;

#define XSANY_method ((ID)XSANY.any_ptr)

ID plrb_id_call_from_perl;

XS(XS_Ruby_VALUE_new)
{
	dVAR; dXSARGS;
	SV* selfsv;
	VALUE result;
	PERL_UNUSED_VAR(cv);

	if(items == 0) croak("Not enough arguments for new");

	STACK_EXTEND;

	/*
	 * "ClassName" or RubyClass
	 */
	selfsv = ST(0);

	result = Funcall(ruby_self(selfsv), id_new, (items - 1), &ST(1));

	ST(0) = sv_newmortal();

	sv_set_value_direct(ST(0), result, SvPOK(selfsv) ? SvPVX(selfsv) : NULL);

	XSRETURN(1);
}


XS(XS_Ruby_function_dispatcher)
{
	dXSARGS;
	VALUE result;
	HV* stash = GvSTASH(CvGV(cv));
	VALUE pkgobj = plrb_get_package(HvNAME(stash));

	STACK_EXTEND;

	rb_ivar_set(pkgobj, plrb_id_call_from_perl, ID2SYM(XSANY_method));

	result = Funcall(pkgobj, XSANY_method, items, &ST(0));

	if(GIMME_V != G_VOID){
		ST(0) = VALUE2SV(result);
		XSRETURN(1);
	}
	else{
		XSRETURN_EMPTY;
	}
}

XS(XS_Ruby_method_dispatcher)
{
	dXSARGS;
	VALUE self;
	VALUE result;

	if(items == 0) croak("Not enough arguments for %s", GvNAME(CvGV(cv)));
	STACK_EXTEND;

	self   = ruby_self(ST(0));
	result = Funcall(self, XSANY_method, (items - 1), &ST(1));

	if(GIMME_V != G_VOID){
		ST(0) = VALUE2SV(result);
		XSRETURN(1);
	}
	else{
		XSRETURN_EMPTY;
	}
}

XS(XS_Ruby_class_holder)
{
	dXSARGS;

	PERL_UNUSED_VAR(items);

	ST(0) = VALUE2SV((VALUE)XSANY.any_ptr);
	XSRETURN(1);
}


/* 
   "OVERLOAD:" keyword is broken (as of xsubpp v1.9508),
*/


XS(XS_Ruby_op_eqne);
XS(XS_Ruby_op_eqne)
{
	dXSARGS;
	dXSI32; /* I32 ix */

	SV* lhs;
	SV* rhs;
	int result;

	if(items != 3) croak("Wrong number of arguments");
	STACK_EXTEND;

	if(!SvTRUE(ST(2))){
		lhs = ST(0);
		rhs = ST(1);
	}
	else{
		rhs = ST(0);
		lhs = ST(1);
	}

	result = RTEST(Funcall(SV2VALUE(lhs), id_equals, 1, &rhs)) ? ix : !ix;

	ST(0) = result ? &PL_sv_yes : &PL_sv_no;

	XSRETURN(1);
}

XS(XS_Ruby_op_unary);
XS(XS_Ruby_op_unary)
{
	dXSARGS;
	VALUE RETVAL;

	if(items != 3) croak("Wrong number of arguments");
	STACK_EXTEND;

	RETVAL = Funcall(SV2VALUE(ST(0)), XSANY_method, 0, NULL);

	ST(0) = VALUE2SV(RETVAL);
	XSRETURN(1);
}

XS(XS_Ruby_op_transfunc_unary);
XS(XS_Ruby_op_transfunc_unary)
{
	dXSARGS;
	VALUE RETVAL;

	if(items != 3) croak("Wrong number of arguments");
	STACK_EXTEND;

	RETVAL = Funcall(rb_mMath, XSANY_method, 1, &ST(0));

	ST(0) = VALUE2SV(RETVAL);
	XSRETURN(1);
}


XS(XS_Ruby_op_binary);
XS(XS_Ruby_op_binary)
{
	dXSARGS;
	SV* lhs;
	SV* rhs;
	VALUE RETVAL;

	if(items != 3) croak("Wrong number of arguments");
	STACK_EXTEND;

	if(!SvTRUE(ST(2))){
		lhs = ST(0);
		rhs = ST(1);
	}
	else{
		rhs = ST(0);
		lhs = ST(1);
	}
	RETVAL = Funcall(SV2VALUE(lhs), XSANY_method, 1, &rhs);

	ST(0) = VALUE2SV(RETVAL);

	XSRETURN(1);
}

XS(XS_Ruby_op_transfunc_binary);
XS(XS_Ruby_op_transfunc_binary)
{
	dXSARGS;
	SV* args[2];
	VALUE RETVAL;
	STACK_EXTEND;

	if(items != 3) croak("Wrong number of arguments");

	if(!SvTRUE(ST(2))){
		args[0] = ST(0);
		args[1] = ST(1);
	}
	else{
		args[1] = ST(0);
		args[0] = ST(1);
	}

	RETVAL = Funcall(rb_mMath, XSANY_method, 2, args);

	ST(0) = VALUE2SV(RETVAL);
	XSRETURN(1);
}

#define DEFINE_OPERATOR_AS(pl_op, rb_op, optype) do{\
		cv = newXS("Ruby::Object::(" pl_op, CAT2(XS_Ruby_op_, optype), file);\
		XSANY.any_ptr = (void*)rb_intern(rb_op);\
	} while(0)

#define DEFINE_OPERATOR(op,optype) DEFINE_OPERATOR_AS(op, op, optype)

inline static void
register_overload(pTHX)
{
	char* file = __FILE__;
	CV* cv;

	id_equals  = rb_intern("==");

	plrb_id_call_from_perl = rb_intern("call_from_perl");

	/* equals */
	cv = newXS("Ruby::Object::(==", XS_Ruby_op_eqne, file);
	XSANY.any_i32 = TRUE;

	cv = newXS("Ruby::Object::(!=", XS_Ruby_op_eqne, file);
	XSANY.any_i32 = FALSE;

	/* xs operators */

	DEFINE_OPERATOR("+", binary);
	DEFINE_OPERATOR("-", binary);
	DEFINE_OPERATOR("*", binary);
	DEFINE_OPERATOR("/", binary);

	DEFINE_OPERATOR("%", binary);
	DEFINE_OPERATOR("**",binary);
	DEFINE_OPERATOR("<<",binary);
	DEFINE_OPERATOR(">>",binary);

	DEFINE_OPERATOR("~", unary);
	DEFINE_OPERATOR("|", binary);
	DEFINE_OPERATOR("&", binary);
	DEFINE_OPERATOR("^", binary);

	DEFINE_OPERATOR("<=>", binary);
	DEFINE_OPERATOR("<",   binary);
	DEFINE_OPERATOR("<=",  binary);
	DEFINE_OPERATOR(">",   binary);
	DEFINE_OPERATOR(">=",  binary);

	DEFINE_OPERATOR_AS("neg", "-@", unary);
	DEFINE_OPERATOR_AS("int", "to_i", unary);

	DEFINE_OPERATOR("abs", unary);

	DEFINE_OPERATOR("atan2", transfunc_binary);
	DEFINE_OPERATOR("cos",   transfunc_unary);
	DEFINE_OPERATOR("sin",   transfunc_unary);
	DEFINE_OPERATOR("exp",   transfunc_unary);
	DEFINE_OPERATOR("log",   transfunc_unary);
	DEFINE_OPERATOR("sqrt",  transfunc_unary);

}

/* used in typemap */
static ID
sv2id(pTHX_ SV* sv)
{
	ID id;
	if(isVALUE(sv)){
		id = SYMBOL_P(SvVALUE(sv))
			? SYM2ID(SvVALUE(sv))
			: (ID)plrb_protect1((plrb_func_t)rb_to_id, SvVALUE(sv));
	}
	else{
		STRLEN len;
		const char* str = SvPV(sv, len);
		if(len == 0){
			plrb_raise(rb_eArgError, "Empty symbol string");
		}
		id = rb_intern(str);
	}

	return id;
}

static int
mg_get_gvar(pTHX_ SV* sv, MAGIC* mg)
{
	const char* name = (const char*)mg->mg_ptr;

	sv_setsv(sv, VALUE2SV(rb_gv_get(name))); /* XXX no sv_setsv_value2sv() */

	return 0;
}
static int
mg_set_gvar(pTHX_ SV* sv, MAGIC* mg)
{
	const char* name = (const char*)mg->mg_ptr;

	plrb_protect((plrb_func_t)rb_gv_set, 2, (VALUE)name, SV2VALUE(sv));

	return 0;
}
MGVTBL gvar_vtbl = {
	mg_get_gvar,
	mg_set_gvar,
	NULL, /* mg_len */
	NULL, /* mg_clear */
	NULL, /* mg_free */
	NULL, /* mg_copy */
	NULL, /* mg_dup */
	NULL, /* mg_local */
};

MODULE = Ruby	PACKAGE = Ruby

PROTOTYPES: DISABLE

BOOT:
{
	RUBY_INIT_STACK;
	plrb_initialize(aTHX);
	register_overload(aTHX);
	id_to_f    = rb_intern("to_f");
	id_to_i    = rb_intern("to_i");
	id_new     = rb_intern("new");
	newXS("Ruby::Object::new", XS_Ruby_VALUE_new, __FILE__);
	newCONSTSUB(NULL, "Ruby::nil",   newSVvalue(Qnil));
	newCONSTSUB(NULL, "Ruby::true",  newSVvalue(Qtrue));
	newCONSTSUB(NULL, "Ruby::false", newSVvalue(Qfalse));
}

void
END(...)
INIT:
	STACK_EXTEND;
CODE:
	PERL_UNUSED_ARG(items);
	plrb_finalize(aTHX);


VALUE
_string_handler(source, result, str_context)
	SV* source
	SV* result
ALIAS:
	_string_handler  = 0
	_integer_handler = 1
	_float_handler   = 2
PREINIT:
	int base;
	bool all_digit;
	STRLEN len;
	const char* str;
INIT:
	STACK_EXTEND;
CODE:
	switch(ix){
	case 0: /* string */
		str = SvPV(result, len);
		RETVAL = rb_str_new(str, (long)len);
		break;
	case 1: /* integer */
		str = SvPV(source, len);
		if(str[0] == '0'){
			switch(str[1]){
			case 'b': case 'B':
				base = 2;
				break;
			case 'x': case 'X':
				base = 16;
				break;
			default:
				base = 8;
			}
		}
		else{
			base = 10;
		}

		RETVAL = rb_cstr_to_inum(str, base, FALSE);
		break;

	case 2: /* integer or float */
		/* Integer literals are interpreted as NV if they are too large,
		   but Ruby can deal with such large integers.
		 */
		str = SvPV(source, len);
		all_digit = TRUE;
		{
			const char* p = str;
			while(*p){
				if(!isDIGIT(*p)){
					all_digit = FALSE;
					break;
				}
				p++;
			}
		}
		RETVAL = all_digit
			? rb_cstr_to_inum(str, 10, FALSE)
			: rb_float_new(SvNV(result));
		break;
	default:
		RETVAL = Qnil; /* not reached */
	}
OUTPUT:
	RETVAL

MODULE = Ruby	PACKAGE = Ruby::Object

SV*
hashify(obj, rhs, flag)
	SV* obj
PREINIT:
	HV* ivtbl = newHV();
CODE:
	sv_magic((SV*)ivtbl, obj, PERL_MAGIC_tied, Nullch, 0); /* tie */
	RETVAL = newRV_noinc((SV*)ivtbl);
OUTPUT:
	RETVAL

SV*
FIRSTKEY(obj)
	VALUE obj
PREINIT:
	VALUE methods;
	VALUE arg = Qtrue;
	long i1, i2;
INIT:
	STACK_EXTEND;
CODE:
	methods = rb_class_instance_methods(1, &arg, CLASS_OF(obj));

	/* grep{ str[0] != '=' && str[-1] '=' } @methods */
	for (i1 = i2 = 0; i1 < RARRAY_LEN(methods); i1++) {
		VALUE v = RARRAY_PTR(methods)[i1];
		long len = RSTRING_LEN(v);
		if(rb_type(v) == T_STRING
			&& len > 0
			&& !isPUNCT(RSTRING_PTR(v)[ 0 ])
			&& RSTRING_PTR(v)[len-1] == '='){

			if (i1 != i2) {
				rb_str_set_len(v, len-1); /* chop for '=' */
				rb_ary_store(methods, i2, v);
			}
			i2++;
		}
	}

	switch(i2){
	case 0:
		XSRETURN_EMPTY;
	case 1:
		arg = RARRAY_PTR(methods)[0];
		break;
	default:
		RARRAY_LEN(methods) = i2-1;
		arg = RARRAY_PTR(methods)[i2-1];
		rb_ivar_set(obj, rb_intern("__perl_each__"), methods);
	}
	StringValue(arg);
	RETVAL = newSVpvn(RSTRING_PTR(arg), RSTRLEN(arg));
OUTPUT:
	RETVAL

SV*
NEXTKEY(obj, last_key)
	VALUE obj
PREINIT:
	VALUE methods;
	VALUE v;
INIT:
	STACK_EXTEND;
CODE:
	methods = rb_ivar_get(obj, rb_intern("__perl_each__"));
	if(NIL_P(methods)){
		XSRETURN_EMPTY;
	}
	v = RARRAY_PTR(methods)[ --RARRAY_LEN(methods) ]; /* pop */
	if( RARRAY_LEN(methods) == 0 ){
		rb_ivar_set(obj, rb_intern("__perl_each__"), Qnil); /* free */
	}
	StringValue(v);
	RETVAL = newSVpvn(RSTRING_PTR(v), RSTRLEN(v));
OUTPUT:
	RETVAL

VALUE
FETCH(obj, attr)
	VALUE obj
	SV*   attr
INIT:
	STACK_EXTEND;
CODE:
	RETVAL = Funcall(obj, sv2id(aTHX_ attr), 0, NULL);
OUTPUT:
	RETVAL

void
STORE(obj, attr, val)
	VALUE obj
	SV*   attr
	SV*   val
PREINIT:
	SV* attr_assign;
INIT:
	STACK_EXTEND;
CODE:
	attr_assign = newSVpvf("%" SVf "=", attr);
	sv_2mortal(attr_assign);
	Funcall(obj, sv2id(aTHX_ attr_assign), 1, &val);


VALUE
clone(obj, ...)
	VALUE obj
INIT:
	STACK_EXTEND;
CODE:
	RETVAL = plrb_protect1((plrb_func_t)rb_obj_clone, obj);
OUTPUT:
	RETVAL

SV*
stringify(obj, ...)
	VALUE obj
PREINIT:
	STRLEN len;
	const char* str;
INIT:
	STACK_EXTEND;
CODE:
	str = ValuePV(obj, len);
	RETVAL = newSVpvn(str, len);
	V2S_INFECT(obj, RETVAL);
OUTPUT:
	RETVAL

SV*
numify(obj, ...)
	VALUE obj
PREINIT:
	int depth = 0;
	VALUE v;
INIT:
	STACK_EXTEND;
CODE:
	v = obj;
	numsv: switch(TYPE(v)){
		case T_FIXNUM:
			RETVAL = newSViv((IV)FIX2INT(v));
			break;

		case T_FLOAT:
			RETVAL = newSVnv((NV)RFLOAT_VALUE(v));
			break;

		case T_BIGNUM:
			RETVAL = newSVnv((NV)rb_big2dbl(v));
			break;

		default:
			if(depth > 3) goto error;

			if(rb_respond_to(v, id_to_f)){
				v = Funcall(v, id_to_f, 0, NULL);
				depth++;
				goto numsv;
			}
			else if(rb_respond_to(v, id_to_i)){
				v = Funcall(v, id_to_i, 0, NULL);
				depth++;
				goto numsv;
			}
			else{
				error:
				plrb_raise(rb_eTypeError, "Cannot convert %s into Numeric",
					rb_obj_classname(obj));
			}
			RETVAL = &PL_sv_undef; /* not reached */
	}
	V2S_INFECT(obj, RETVAL);
OUTPUT:
	RETVAL

void
boolify(obj, ...)
	VALUE obj
CODE:
	ST(0) = RTEST(obj) ? &PL_sv_yes : &PL_sv_no;


void
DESTROY(obj)
	SV* obj
INIT:
	STACK_EXTEND;
CODE:
	delSVvalue(obj);

VALUE
send(obj, method, ...)
	VALUE obj
	ID    method
INIT:
	STACK_EXTEND;
CODE:
	RETVAL = Funcall(obj, method, items - 2, &ST(2));
OUTPUT:
	RETVAL

bool
kind_of(obj, super)
	SV* obj
	const char* super
INIT:
	STACK_EXTEND;
CODE:
	RETVAL = (bool)rb_obj_is_kind_of( ruby_self(obj), plrb_name2class(aTHX_ super));
OUTPUT:
	RETVAL

bool
respond_to(obj, method)
	SV* obj
	ID  method
INIT:
	STACK_EXTEND;
CODE:
	RETVAL = (bool)plrb_protect((plrb_func_t)rb_respond_to, 2, ruby_self(obj), (VALUE)method);
OUTPUT:
	RETVAL

void
alias(klass, new_name, orig_name)
	SV* klass
	ID new_name
	ID orig_name
INIT:
	STACK_EXTEND;
CODE:
	plrb_protect((plrb_func_t)rb_alias, 3, ruby_self(klass), (VALUE)new_name, (VALUE)orig_name);



void
STORABLE_freeze(...)
ALIAS:
	STRABLE_thaw = 1
CODE:
	PERL_UNUSED_VAR(items);
	PERL_UNUSED_VAR(ix);
	croak("Can't %s Ruby object", GvNAME(CvGV(cv)));



MODULE = Ruby	PACKAGE = Ruby

void
rubyify(sv)
	VALUE sv
INIT:
	STACK_EXTEND;
CODE:
	ST(0) = sv_newmortal();
	sv_set_value_direct(ST(0), sv, NULL);
	XSRETURN(1);

VALUE
rb_define_class(name, base)
	const char* name
	const char* base
INIT:
	STACK_EXTEND;
CODE:
	RETVAL = plrb_protect((plrb_func_t)rb_define_class, 2, name, name2class(base));
OUTPUT:
	RETVAL

VALUE
rb_eval(source, ...)
	SV* source
PREINIT:
	SV* pkg;
	const char* file;
	int   line;
INIT:
	STACK_EXTEND;
CODE:
	/* package */
	pkg  = (items >= 2 && SvOK(ST(1))) ? ST(1)             : &PL_sv_undef;
	/* file */
	file = (items >= 3 && SvOK(ST(2))) ? SvPV_nolen(ST(2)) : "(ruby eval)";
	/* line */
	line = (items >= 4 && SvOK(ST(3))) ? SvIV      (ST(3)) : 1;

	RETVAL = plrb_eval(aTHX_ source, pkg, file, line);
OUTPUT:
	RETVAL


bool
rb_require(library)
	const char* library
INIT:
	STACK_EXTEND;
CODE:
	RETVAL = (bool)plrb_protect1((plrb_func_t)rb_require, (VALUE)library);
OUTPUT:
	RETVAL


void
puts(...)
ALIAS:
	puts = 0
	p = 1
PREINIT:
	PerlIO* out;
	STRLEN rslen;
	const char* rspv = ValuePV(rb_default_rs, rslen);
INIT:
	STACK_EXTEND;
CODE:
	out = IoOFP(GvIO(PL_defoutgv));

	if(items){
		int i;
		for(i = 0; i < items; i++){
			SV* sv = ST(i);
			STRLEN len;
			const char* pv;
			volatile VALUE v;

			if(isVALUE(sv)){
				v = SvVALUE(sv);
				if(ix) v = plrb_protect1((plrb_func_t)rb_inspect, v); /* p() */ 

				pv = ValuePV(v, len);
			}
			else{
				if(ix) sv = sv_inspect(sv); /* p() */

				pv = sv_to_s(sv, len);
			}

			PerlIO_write(out, pv, len);
			PerlIO_write(out, rspv, rslen);
		}
	}
	else{
		PerlIO_write(out, rspv, rslen);
	}

#define METHOD_DISPATCHER   PTR2IV(XS_Ruby_method_dispatcher)
#define FUNCTION_DISPATCHER PTR2IV(XS_Ruby_function_dispatcher)

CV*
rb_install_method(perl_name, ruby_name, prototype = &PL_sv_undef)
	char* perl_name
	ID  ruby_name
	SV* prototype
ALIAS:
	rb_install_method   = METHOD_DISPATCHER
	rb_install_function = FUNCTION_DISPATCHER
INIT:
	STACK_EXTEND;
CODE:
	RETVAL = newXS(perl_name, (XSUBADDR_t)ix, __FILE__);

	CvXSUBANY(RETVAL).any_ptr = (void*)ruby_name;

	/*if(ix == METHOD_DISPATCHER) CvLVALUE_on(RETVAL);*/

	if(SvOK(prototype)){
		STRLEN len;
		const char* pv = SvPV(prototype, len);
		sv_setpvn((SV*)RETVAL, pv, len);
	}
OUTPUT:
	RETVAL

void
rb_install_class(perl_class, ruby_class)
	const char* perl_class
	const char* ruby_class
INIT:
	STACK_EXTEND;
CODE:
	plrb_install_class(aTHX_ perl_class, name2class(ruby_class));


void
rb_install_global_variable(sv, ruby_gvar)
	SV* sv
	const char* ruby_gvar
CODE:
	INSTALL_GVAR(sv, ruby_gvar);
	mg_get(sv);

#define T_EXCEPTION T_CLASS

VALUE
rb_c(name)
	const char* name
PROTOTYPE: *
ALIAS:
	rb_c = T_CLASS
	rb_e = T_EXCEPTION
	rb_m = T_MODULE
INIT:
	STACK_EXTEND;
CODE:
	PERL_UNUSED_VAR(ix);
	RETVAL = plrb_name2class(aTHX_ name);
OUTPUT:
	RETVAL
