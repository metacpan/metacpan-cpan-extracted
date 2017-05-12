/*
	$Id: perlobject.c,v 1.1 2004/04/11 05:06:39 jigoro Exp $

	Perl object in Ruby environment

	see Init_perl() for interface details.

*/

/* module Perl */

#include "ruby_pm.h"

#if MY_RUBY_VERSION_INT >= 190
#include <ruby/st.h>
#else
#include <st.h> /* ST_CONTINUE */
#endif

#define plrb_any_mark NULL

#define fetch(var, create) plrb_fetch(aTHX_ var,create)

#define perl_class_new(pkg,len)   plrb_perl_class_new(aTHX_ pkg, len)
#define perl_package_new(pkg,len) plrb_perl_package_new(aTHX_ pkg, len)

#define SvSetup(obj, klass, sv) do{\
	obj = Data_Wrap_Struct(klass, plrb_any_mark, plrb_any_free, (void*)sv);\
	S2V_INFECT(sv, obj);\
	if(SvREADONLY(sv)) OBJ_FREEZE(obj);\
	} while(0)

#define STORE_AS_SV(value) newSVvalue(value)

#define FL_G_VOID   FL_USER1
#define FL_G_SCALAR FL_USER2
#define FL_G_ARRAY  FL_USER3

VALUE plrb_mPerl;    /* for access to Perl feature */
VALUE plrb_cAny;
VALUE plrb_cScalar;
VALUE plrb_cRef;
VALUE plrb_cArray;
VALUE plrb_cHash;
VALUE plrb_cCode;
VALUE plrb_cGlob;
VALUE plrb_eExc;

VALUE plrb_cClass;
VALUE plrb_cPackage;

VALUE plrb_top_self;

VALUE plrb_undef;

static VALUE packages; /* package register */
static VALUE classes;  /* class register */

static ID id_cmp;   /* <=> */
static ID id_equal; /* ==  */

static VALUE sym_method_added;

static VALUE plrb_call_sv(VALUE self, SV* func, int method, int argc, VALUE* argv);

static VALUE plrb_scalar_to_float(VALUE);
static VALUE plrb_scalar_to_str(VALUE);
static VALUE plrb_scalar_to_int(VALUE);

static VALUE plrb_package_inspect(VALUE self);

static void
plrb_any_free(SV* sv)
{
	dTHX;
	SvREFCNT_dec(sv);
}

VALUE
plrb_any_new_noinc(pTHX_ SV* sv)
{
	VALUE klass;
	VALUE obj;

	if(!sv) return Qnil;

	switch(SvTYPE(sv)){
	case SVt_PVGV:
		sv = newRV_noinc(sv);
		klass = plrb_cGlob;
		goto setup;

	case SVt_PVAV:
	case SVt_PVHV:
	case SVt_PVCV:
		sv = newRV_noinc(sv);
		break;

	case SVt_PVIO:
		return io2pio((IO*)sv);
	default:
		NOOP;
	}

	if(SvROK(sv)){
		switch(SvTYPE(SvRV(sv))){
		case SVt_PVAV:
			klass = plrb_cArray;
			break;
		case SVt_PVHV:
			klass = plrb_cHash;
			break;
		case SVt_PVCV:
			klass = plrb_cCode;
			break;
		case SVt_PVGV:
			if(sv_derived_from(sv, "IO::Handle")){
				klass = plrb_cPerlIO;
			}
			else{
				klass = plrb_cGlob;
			}
			break;
		case SVt_PVIO:
			return io2pio( (IO*) SvRV(sv) );

		default:
			klass = plrb_cRef;
		}
	}
	else{
		klass = plrb_cScalar;
	}

	setup:

	SvSetup(obj, klass, sv);

	return obj;
}
VALUE
plrb_any_new2_noinc(pTHX_ VALUE klass, SV* sv)
{
	VALUE obj;

	if(!sv) return plrb_undef;

	SvSetup(obj, klass, sv);

	return obj;
}

static VALUE
plrb_sv_alloc(VALUE klass)
{
	dTHX;
	SV* sv = newSV(0);
	return any_new2_noinc(klass, sv);
}
static VALUE
plrb_av_alloc(VALUE klass)
{
	dTHX;
	AV* av = newAV();
	return any_new2_noinc(klass, newRV_noinc((SV*)av));
}
static VALUE
plrb_hv_alloc(VALUE klass)
{
	dTHX;
	HV* hv = newHV();
	return any_new2_noinc(klass, newRV_noinc((SV*)hv));
}

static VALUE
plrb_perl_pkg_create(VALUE klass, const char* pkg)
{
	dTHX;
	VALUE obj;
	SV* sv;

	if(strEQ(pkg, "Ruby")){
		return plrb_top_self;
	}

	sv = newSVpvn(pkg, strlen(pkg));

	SvSetup(obj, klass, sv);

	return obj;
}

VALUE
plrb_get_package(const char* name)
{
	ID id;
	VALUE pkg;

	static const char* name_cache = "";
	static VALUE       pkg_cache = Qnil;

	if(strEQ(name_cache, name)){
		return pkg_cache;
	}

	id = rb_intern(name);
	pkg = rb_attr_get(packages, id);

	if(NIL_P(pkg)){
		pkg = plrb_perl_pkg_create(plrb_cPackage, name);

		rb_ivar_set(packages, id, pkg);
	}

	name_cache = name;
	pkg_cache  = pkg;

	return pkg;
}

VALUE
plrb_get_class(const char* name)
{
	ID id = rb_intern(name);
	VALUE pkg = rb_attr_get(classes, id);

	if(NIL_P(pkg)){
		pkg = plrb_perl_pkg_create(plrb_cClass, name);

		rb_ivar_set(classes, id, pkg);
	}
	return pkg;
}

/* module Perl */

static VALUE
plrb_perl_eval(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	dSP;
	SV* sv;
	VALUE ret;

	VALUE vsrc;

	PERL_UNUSED_ARG(self);

	rb_scan_args(argc, argv, "1", &vsrc);

	StringValue(vsrc);
	sv = newSVpvn(RSTRING_PTR(vsrc), RSTRLEN(vsrc));

	rb_set_errinfo(Qnil);

	eval_sv(sv, G_SCALAR);
	SvREFCNT_dec(sv);

	SPAGAIN;
	sv = POPs;

	ret = SV2VALUE(sv);

	if(SvTRUE(ERRSV)){
		if(!NIL_P(rb_errinfo())){
			rb_exc_raise(rb_errinfo());
		}
		else{
			rb_raise(plrb_eExc, "%" SVf, ERRSV);
		}
	}
	return ret;
}

static VALUE
plrb_perl_require(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	VALUE modname;
	SV* sv;
	PERL_UNUSED_ARG(self);

	rb_scan_args(argc, argv, "1", &modname);

	StringValue(modname);
	sv = newSVpvn(RSTRING_PTR(modname), RSTRLEN(modname));

	Perl_load_module(aTHX_ PERL_LOADMOD_NOIMPORT, sv, Nullsv, Nullsv);

	return Qtrue;
}


static VALUE
plrb_perl_string(VALUE self, VALUE str)
{
	dTHX;
	SV* sv;
	VALUE s;

	PERL_UNUSED_ARG(self);

	s = rb_obj_as_string(str);
	sv = newSVpvn(RSTRING_PTR(s), RSTRLEN(s));

	V2S_INFECT(str, sv);
	return any_new_noinc( sv );
}
static VALUE
plrb_perl_integer(VALUE self, VALUE iv){
	dTHX;
	SV* sv;
	VALUE i;

	PERL_UNUSED_ARG(self);

	i = rb_Integer(iv);
	sv = newSViv((IV)NUM2INT(i));

	V2S_INFECT(iv, sv);
	return any_new_noinc( sv );
}
static VALUE
plrb_perl_float(VALUE self, VALUE nv){
	dTHX;
	SV* sv;
	VALUE n;

	PERL_UNUSED_ARG(self);

	n = rb_Float(nv);
	sv = newSVnv(RFLOAT_VALUE(n));

	V2S_INFECT(nv, sv);
	return any_new_noinc( sv );
}

static VALUE
plrb_perl_undef()
{
	return plrb_undef;
}


static VALUE
plrb_perl_package(VALUE self, VALUE name){
	VALUE pkg;
	ID id = rb_to_id(name);

	PERL_UNUSED_ARG(self);

	pkg = plrb_get_package(rb_id2name(id));

	if(rb_block_given_p()){
		rb_obj_instance_eval(0, NULL, pkg);
	}

	return pkg;
}
static VALUE
plrb_perl_class(VALUE self, VALUE name){
	VALUE pkg;
	ID id = rb_to_id(name);

	PERL_UNUSED_ARG(self);

	pkg = plrb_get_class(rb_id2name(id));

	if(rb_block_given_p()){
		rb_obj_instance_eval(0, NULL, pkg);
	}

	return pkg;
}
static VALUE
plrb_fetch(pTHX_ const char* name, I32 create)
{
	char t;

	if(!name) return Qnil;

	t = name[0];
	if(t == '$' || t == '@' || t == '%' || t == '&' || t == '*'){
		name++;
	}

	if(name[0] == '\0'){
		rb_raise(rb_eArgError, "Fetching empty symbol name");
	}


	switch(t){
	case '$':
		return SV2VALUE(get_sv(name, create));
	case '@':
		return any_new((SV*)get_av(name, create));
	case '%':
		return any_new((SV*)get_hv(name, create));
	case '&':
		return any_new((SV*)get_cv(name, create));
	case '*':
		return any_new((SV*)gv_fetchpv(name, create, SVt_PVGV));
	}

	return plrb_get_class(name);
}

static VALUE
plrb_perl_fetch(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	volatile VALUE name;
	VALUE createflag;

	PERL_UNUSED_ARG(self);

	if(rb_scan_args(argc, argv, "11", &name, &createflag) == 1)
		createflag = Qtrue;

	return fetch(StringValueCStr(name), RTEST(createflag) ? TRUE : FALSE);
}
static VALUE
plrb_package_fetch(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	SV* pkg = valueSV(self);
	volatile VALUE name;
	VALUE createflag;
	const char* pv;
	STRLEN pvlen;
	char t;

	char smallbuf[64];
	volatile VALUE largebuf;

	STRLEN fullnamelen;
	char* fullname;
	char* p;


	if(rb_scan_args(argc, argv, "11", &name, &createflag) == 1)
		createflag = Qtrue;

	StringValue(name);
	pv    = RSTRING_PTR(name);
	pvlen = RSTRLEN(name);

	fullnamelen = SvCUR(pkg) + 2 + pvlen; /* pkg :: name */

	if( fullnamelen >= (sizeof(smallbuf)/sizeof(char))){
		largebuf = rb_str_buf_new((long)fullnamelen);
		p = fullname = RSTRING_PTR(largebuf);
	}
	else{
		p = fullname = smallbuf;
	}

 	t = pv[0];
	if(!(t == '$' || t == '@' || t == '%' || t == '&' || t == '*')){
		rb_raise(rb_eArgError, "Unrecognized symbol type");
	}

	p[0] = t;
	p += 1; /* type char */

	memcpy(p, SvPVX(pkg), SvCUR(pkg));
	p += SvCUR(pkg);

	memcpy(p, "::", 2);
	p += 2;

	memcpy(p, pv+1, pvlen-1);

	fullname[fullnamelen] = '\0';

	return fetch(fullname, RTEST(createflag) ? TRUE : FALSE);
}


/* class Perl::Any */

static VALUE
plrb_undef_p(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);
	SvGETMAGIC(sv);

	return !SvOK(sv) ? Qtrue : Qfalse;
}
static VALUE
plrb_defined_p(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);
	SvGETMAGIC(sv);

	return SvOK(sv) ? Qtrue : Qfalse;
}

static VALUE
plrb_true_p(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);
	SvGETMAGIC(sv);

	return SvTRUE(sv) ? Qtrue : Qfalse;
}
static VALUE
plrb_false_p(VALUE self)
{
	return plrb_true_p(self) ? Qfalse : Qtrue;
}


/* Any::<=> */
static VALUE
plrb_cmp(VALUE self, VALUE other)
{
	dTHX;

	if(isSV(other)){
		SV* lhs = valueSV(self);
		SV* rhs = valueSV(other);
		SV* tmpsv;

		if((SvAMAGIC(lhs) || SvAMAGIC(rhs))
			&& (tmpsv = amagic_call(lhs, rhs, scmp_amg, 0))) /* call overloaded <=> */
		{

			return (tmpsv && SvOK(tmpsv)) ? INT2FIX(SvIV(tmpsv)) : Qnil;
		}

		return INT2FIX(IN_LOCALE_RUNTIME
				? sv_cmp_locale(lhs, rhs)
				: sv_cmp       (lhs, rhs));
	}
	else {

		if(rb_obj_is_kind_of(other, rb_cNumeric)){

			if(SvIOK(valueSV(self))){
				return rb_funcall2(plrb_scalar_to_int(self), id_cmp, 1, &other);
			}
			else if(looks_like_number(valueSV(self))){
				return rb_funcall2(plrb_scalar_to_float(self),id_cmp, 1, &other);
			}
		}

		return rb_funcall2(plrb_scalar_to_str(self),   id_cmp, 1, &other);
	}

	return Qnil;
}

/* Any::== */

static VALUE
plrb_eq(VALUE self, VALUE other)
{
	dTHX;

	if(isSV(other)){

		SV* lhs = valueSV(self);
		SV* rhs = valueSV(other);
		SV* tmpsv;

		if((SvAMAGIC(lhs) || SvAMAGIC(rhs))
			&& (tmpsv = amagic_call(lhs, rhs, seq_amg, 0))) /* call overloaded == */
		{

			return (tmpsv && SvOK(tmpsv)) ? Qtrue : Qfalse;
		}

		return strEQ(SvPV_nolen_const(lhs), SvPV_nolen_const(rhs)) ? Qtrue : Qfalse;
	}
	else {
		if(rb_obj_is_kind_of(other, rb_cNumeric)){

			if(SvIOK(valueSV(self))){
				return rb_funcall2(plrb_scalar_to_int(self), id_equal, 1, &other);
			}
			else if(looks_like_number(valueSV(self))){
				return rb_funcall2(plrb_scalar_to_float(self),id_equal, 1, &other);
			}
		}
		else{
			return rb_funcall2(plrb_scalar_to_str(self),   id_equal, 1, &other);
		}
	}
	return Qnil;
}

/* Any::eql? */
static VALUE
plrb_equal(VALUE self, VALUE other)
{
	if (self == other) return Qtrue;

	if(rb_obj_class(self) == rb_obj_class(other)){

		return valueSV(self) == valueSV(other) ? Qtrue : Qfalse;

	}

	return Qfalse;
}

static VALUE
plrb_to_ref(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);

	return any_new_noinc(newRV_inc(sv));
}

static VALUE
plrb_inspect(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);
	SV* ins = sv_inspect(sv);

	return rb_str_new_sv(ins);

#if 0
	VALUE result = rb_str_new("#<Perl::", 8);

	rb_str_cat2(result, sv_reftype(SvROK(sv) ? SvRV(sv) : sv, 0));
	rb_str_cat(result, "(0x", 3);
	rb_str_append(result, rb_big2str(rb_uint_new(PTR2UV(sv)), 16));
	rb_str_cat(result, ") ", 2);

	rb_str_cat2(result, SvPVX(ins));

	rb_str_cat(result, ">", 1);

	return result;
#endif
}

#define Modify(v) plrb_any_modify(aTHX_ v)
static void
plrb_any_modify(pTHX_ VALUE v)
{
	SV* sv = valueSV(v);

	if(OBJ_FROZEN(v) || SvREADONLY(sv)){
		rb_raise(rb_eTypeError, PL_no_modify);
	}
	if(rb_safe_level() >= 4){
		if(! OBJ_TAINTED(v) )
			rb_raise(rb_eSecurityError, PL_no_security, "modify", "while running -T4 switch");
	}
}

/* class Perl::Glob */

static VALUE
plrb_glob_fetch(VALUE self, VALUE elem)
{
	dTHX;
	GV* gv = (GV*)valueRV(self);
	SV* sv = NULL;
	ID id;

	static ID id_scalar, id_array, id_hash, id_io, id_code, id_name, id_package, id_class;

	id = rb_to_id(elem);

	if(!id_scalar){
		id_scalar = rb_intern("SCALAR");
		id_array  = rb_intern("ARRAY");
		id_hash   = rb_intern("HASH");
		id_io     = rb_intern("IO");
		id_code   = rb_intern("CODE");
		id_name   = rb_intern("NAME");
		id_package= rb_intern("PACKAGE");
		id_class  = rb_intern("CLASS");
	}

	if(id == id_scalar){
		return any_new_noinc(SvOK(GvSV(gv)) ? newRV_inc(GvSV(gv)) : NULL);
	}
	else if(id == id_array){
		sv = (SV*)GvAV(gv);
	}
	else if(id == id_hash){
		sv = (SV*)GvHV(gv);
	}
	else if(id == id_code){
		sv = (SV*)GvCV(gv);
	}
	else if(id == id_io){
		return GvIO(gv) ? gv2pio(gv) : Qnil;
	}
	else if(id == id_name){
		return rb_str_new(GvNAME(gv), (long)GvNAMELEN(gv));
	}
	else if(id == id_package){
		return plrb_get_package(HvNAME(GvSTASH(gv)));
	}
	else if(id == id_class){
		return plrb_get_class(HvNAME(GvSTASH(gv)));
	}

	if(sv) return any_new(sv);

	return Qnil;
}


/* class Perl::Scalar */


/* calc hash value for Hash */
static VALUE
plrb_scalar_hash(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);

	STRLEN len;
	const char* s = SvPV(sv, len);
	I32 hash;
	PERL_HASH(hash, s, len);

	return INT2FIX(hash);
}

/* eql? for Hash */
static VALUE
plrb_scalar_eql(VALUE self, VALUE other)
{
	dTHX;

	if(self == other) return Qtrue;

	if(isSV(other)){
		return sv_eq(valueSV(self), valueSV(other)) ? Qtrue : Qfalse;
	}
	return Qfalse;
}


static VALUE
plrb_scalar_coerce(VALUE self, VALUE other)
{
	dTHX;
	SV* sv = valueSV(self);
	if(SvIOK(sv) || (SvNOK(sv) && (((NV)SvIV(sv)) == SvNV(sv)))){
		return rb_assoc_new(other, rb_int_new((long)SvIV(sv)));
	}
	else if(looks_like_number(sv)){
		return rb_assoc_new(other, rb_float_new(SvNV(sv)));
	}

	return Qnil;
}

const char*
plrb_sv_to_s(pTHX_ SV* sv, STRLEN* lenp)
{
	const char* pv;

	SvGETMAGIC(sv);

	if(!SvOK(sv)){
		pv = "undef";
		*lenp = 5;
	}
	else if(sv == &PL_sv_yes){
		pv = "yes";
		*lenp = 3;
	}
	else if(sv == &PL_sv_no){
		pv = "no";
		*lenp = 2;
	}
	else{
		pv = SvPV(sv, *lenp);
	}

	return pv;
}

static VALUE
plrb_scalar_to_s(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);
	STRLEN len;
	const char* pv = sv_to_s(sv, len);
	VALUE v = rb_str_new(pv, (long)len);

	S2V_INFECT(sv, v);

	return v;
}

static VALUE
plrb_scalar_to_str(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);

	SvGETMAGIC(sv);

	return rb_str_new_sv(sv);
}
static VALUE
plrb_scalar_to_int(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);
	VALUE value;

	SvGETMAGIC(sv);

	if(SvIOK(sv)){
		value = rb_int_new((long)SvIV(sv));
	}
	else if(SvNOK(sv)){
		value = rb_dbl2big(SvNV(sv));
	}
	else{
		value = rb_cstr_to_inum(SvPV_nolen_const(sv), 10, Qtrue);
	}

	S2V_INFECT(sv, value);
	return value;
}
static VALUE
plrb_scalar_to_float(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);
	VALUE value;

	SvGETMAGIC(sv);

	value = rb_float_new(SvNV(sv));

	S2V_INFECT(sv, value);
	return value;
}


static VALUE
plrb_scalar_empty_p(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);

	SvGETMAGIC(sv);

	if(SvPOK(sv)){
		return SvCUR(sv) == 0 ? Qtrue : Qfalse;
	}
	else if(SvTYPE(sv) == SVt_NULL){
		return Qtrue;
	}

	return Qnil;
}
static VALUE
plrb_scalar_size(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);

	SvGETMAGIC(sv);

	if(SvOK(sv)){
		STRLEN len;
		(void)SvPV(sv, len);
		return UINT2NUM(len);
	}
	return Qnil;
}

static void
sv_mod_check(SV* sv, char* p, STRLEN len)
{
	if(!SvPOK(sv) || SvPVX(sv) != p || SvCUR(sv) != len){
		rb_raise(rb_eRuntimeError, "Perl::Scalar modified");
	}
}

static VALUE
plrb_scalar_each_line(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	SV* sv;
	STRLEN len;
	char* pv;
	char* p;
	char* pend;
	char* s;

	int newline;
	VALUE rs;
	char* rspv;
	STRLEN rslen;

	VALUE line;

	if (rb_scan_args(argc, argv, "01", &rs) == 0) {
		rs = rb_rs;
	}

	if(NIL_P(rs)){
		rb_yield(self);
		return self;
	}

	rs = rb_obj_as_string(rs);
	rspv  = RSTRING_PTR(rs);
	rslen = RSTRLEN(rs);

	sv = valueSV(self);
	SvGETMAGIC(sv);

	p = pv = SvPV(sv, len);
	pend = p+len;

	if(rslen == 0){
		newline = '\n';
	}
	else{
		newline = rspv[rslen-1];
	}

	ENTER;
	SAVETMPS;

	for(s = p, p += rslen; p < pend; p++){
		if(rslen == 0 && *p == '\n'){
			if(*++p != '\n') continue;
			while(*p == '\n') p++;
		}
		if(pv < p && p[-1] == newline &&
			(rslen <= 1 ||
				rb_memcmp(RSTRING_PTR(rs), p-rslen, (long)rslen) == 0)){

			line = any_new2_noinc(CLASS_OF(self), newSVpvn(s, (STRLEN)(p-s)));

			V2V_INFECT(self, line);
			rb_yield(line);

			sv_mod_check(sv, pv, len);
			s = p;
		}
	}

	if(s != pend){
		if(p > pend) p = pend;
		line = any_new2_noinc(CLASS_OF(self), newSVpvn(s, (STRLEN)(p-s)));

		V2V_INFECT(self, line);

		rb_yield(line);
	}

	FREETMPS;
	LEAVE;

	return self;
}

static VALUE
plrb_scalar_concat(VALUE self, VALUE other)
{
	dTHX;

	Modify(self);

	other = rb_obj_as_string(other);

	sv_catpvn_mg(valueSV(self), RSTRING_PTR(other), RSTRLEN(other));

	V2V_INFECT(other, self);
	return self;
}


static VALUE
plrb_scalar_set(VALUE self, VALUE other)
{
	dTHX;

	Modify(self);

	sv_set_value(valueSV(self), other);

	return self;
}


/* for Range */

static VALUE
plrb_scalar_succ(VALUE self)
{
	dTHX;
	SV* sv = sv_2mortal(newSVsv(valueSV(self)));
	VALUE result;

	sv_inc(sv);

	result = SV2VALUE(sv);
	V2V_INFECT(self, result);

	return result;
}


static VALUE
plrb_any_method_invoke(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);
	const char* meth_s;
	HV* stash = NULL;
	GV* gv    = NULL;

	if(argc == 0){
		rb_raise(rb_eArgError, "No method given");
	}

	meth_s  = rb_id2name(rb_to_id(argv[0]));

	if(SvROK(sv)){
		stash = SvSTASH(SvRV(sv));
	}
	else if(SvPOK(sv)){
		stash = gv_stashpv(SvPVX(sv), TRUE);
	}

	if(stash)
		gv = gv_fetchmethod(stash, meth_s);


	if(gv){
		argv[0] = self;

		return plrb_call_sv(self, (SV*)(gv), G_METHOD, argc, argv);
	}
	else{
		return rb_call_super(argc, argv);
	}
}

static VALUE
plrb_scalar_send(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	/*SV* sv = valueSV(self);*/
	SV* sv;
	VALUE method;

	if(argc == 0){
		rb_raise(rb_eArgError, "No method given");
	}

	method = argv[0];

	sv = newSVpv(rb_id2name(rb_to_id(method)), 0);
	argv[0] = self;

	return plrb_call_sv(self, sv, G_METHOD, argc, argv);
}


/* class Perl::Ref */

static VALUE
plrb_ref_deref(VALUE self)
{
	dTHX;
	SV* sv = valueRV(self);

	return SV2VALUE(sv);
}

/* class Perl::Array */

static VALUE
plrb_array_to_ary(VALUE self)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);
	VALUE result;
	int i, len;

	len = av_len(ary)+1;
	result = rb_ary_new2(len);

	for(i = 0; i < len; i++){
		SV** svp = av_fetch(ary, i, FALSE);
		rb_ary_push(result, svp ? SV2VALUE(*svp) : Qnil);
	}

	V2V_INFECT(self, result);
	return result;
}

static VALUE
plrb_array_join(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);
	int len;
	VALUE vsep;
	int seplen;
	char* sepstr;

	VALUE result;
	int i;

	rb_scan_args(argc, argv, "01", &vsep);

	if(NIL_P(vsep)){
		SV* sep = get_sv("\"", FALSE);
		if(sep && SvOK(sep)){
			sepstr = SvPV(sep, seplen);
		}
		else{
			seplen = 0;
			sepstr = "";
		}
	}
	else{
		StringValue(vsep);
		seplen = RSTRLEN(vsep);
		sepstr = RSTRING_PTR(vsep);
	}

	len = av_len(ary)+1;
	result = rb_str_buf_new(len*10);

	for(i = 0; i < len; i++){
		SV** svp;

		if(i != 0){
			rb_str_buf_cat(result, sepstr, seplen);
		}

		svp = av_fetch(ary, i, FALSE);

		if(svp){
			STRLEN l;
			const char* s = SvPV(*svp, l);
			rb_str_buf_cat(result, s, (long)l);
		}
	}

	V2V_INFECT(self, result);

	return result;
}

static VALUE
plrb_array_push(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);
	int i;

	Modify(self);

	for(i = 0; i < argc; i++){
		av_push(ary, newSVvalue(argv[i]));
	}
	return self;
}

static VALUE
plrb_array_pop(VALUE self)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);

	Modify(self);

	return SV2VALUE(av_pop(ary));
}

static VALUE
plrb_array_shift(VALUE self)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);

	Modify(self);

	return SV2VALUE(av_shift(ary));
}
static VALUE
plrb_array_unshift(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);
	int i;

	Modify(self);

	av_unshift(ary, argc);
	for(i = 0; i < argc; i++){
		av_store(ary, i, STORE_AS_SV(argv[i]));
	}

	return self;
}

static VALUE
plrb_array_aref(VALUE self, VALUE idx)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);
	SV** svp;

	if(SYMBOL_P(idx)){
		rb_raise(rb_eTypeError, "Symbol as array index");
	}

	svp = av_fetch(ary, NUM2INT(idx), TRUE);

	return svp ? SV2VALUE(*svp) : Qnil;
}

static VALUE
plrb_array_aset(VALUE self, VALUE idx, VALUE val)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);

	if(SYMBOL_P(idx)){
		rb_raise(rb_eTypeError, "Symbol as array index");
	}

	Modify(self);

	av_store(ary, NUM2INT(idx), STORE_AS_SV(val));
	return val;
}

static VALUE
plrb_array_each(VALUE self)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);
	SV** svp;
	long i;
	long len = av_len(ary)+1;
	for(i = 0; i < len; i++){
		svp = av_fetch(ary, i, FALSE);
		rb_yield(svp ? SV2VALUE(*svp) : Qnil);
	}
	return self;
}

static VALUE
plrb_array_empty_p(VALUE self)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);

	return av_len(ary) == -1 ? Qtrue : Qfalse;
}

static VALUE
plrb_array_size(VALUE self)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);

	return INT2NUM(av_len(ary)+1);
}

static VALUE
plrb_array_clear(VALUE self)
{
	dTHX;
	AV* ary = (AV*)valueRV(self);

	Modify(self);

	av_clear(ary);

	return self;
}


/* class Perl::Hash */

static VALUE
plrb_hash_to_hash(VALUE self)
{
	dTHX;
	HV* hash = (HV*)valueRV(self);
	HE* entry;
	char* key;
	I32   klen;
	SV*   val;
	VALUE rubyhash = rb_hash_new();

	hv_iterinit(hash);

	while( (entry = hv_iternext(hash)) ){
		key = hv_iterkey(entry, &klen);
		val = hv_iterval(hash, entry);

		rb_hash_aset(rubyhash, rb_str_new(key, klen), SV2VALUE(val));
	}

	V2V_INFECT(self, rubyhash);

	return rubyhash;
}

static VALUE
plrb_hash_aref(VALUE self, VALUE key)
{
	dTHX;
	HV* hash = (HV*)valueRV(self);
	SV** svp;

	key = rb_obj_as_string(key);

	svp = hv_fetch(hash, RSTRING_PTR(key), RSTRING_LEN(key), FALSE);

	return svp ? SV2VALUE(*svp) : Qnil;
}

static VALUE
plrb_hash_aset(VALUE self, VALUE key, VALUE val)
{
	dTHX;
	HV* hash = (HV*)valueRV(self);

	Modify(self);

	key = rb_obj_as_string(key);

	hv_store(hash, RSTRING_PTR(key), RSTRING_LEN(key), STORE_AS_SV(val), 0);

	return val;
}

static VALUE
plrb_hash_each_key(VALUE self)
{
	dTHX;
	HV* hash = (HV*)valueRV(self);
	HE* entry;
	char* key;
	I32   klen;
	SV* ksv;

	hv_iterinit(hash);

	while( (entry = hv_iternext(hash)) ){
		key = hv_iterkey(entry, &klen);

		ksv = newSVpvn(key, (STRLEN)klen);
		SvREADONLY_on(ksv);

		rb_yield(any_new_noinc(ksv));
	}

	return self;
}

static VALUE
plrb_hash_each_value(VALUE self)
{
	dTHX;
	HV* hash = (HV*)valueRV(self);
	HE* entry;
	SV* val;

	hv_iterinit(hash);

	while( (entry = hv_iternext(hash)) ){
		val = hv_iterval(hash, entry);

		rb_yield(SV2VALUE(val));
	}

	return self;
}

static VALUE
plrb_hash_each_pair(VALUE self)
{
	dTHX;
	HV* hash = (HV*)valueRV(self);
	HE* entry;
	char* key;
	I32   klen;
	SV*   val;
	SV*   ksv;

	hv_iterinit(hash);

	while( (entry = hv_iternext(hash)) ){
		key = hv_iterkey(entry, &klen);
		val = hv_iterval(hash, entry);

		ksv = newSVpvn(key, (STRLEN)klen);
		SvREADONLY_on(ksv);

		rb_yield_values(2, any_new_noinc(ksv), SV2VALUE(val));
	}

	return self;
}

static VALUE
plrb_hash_delete(VALUE self, VALUE key)
{
	dTHX;
	HV* hash = (HV*)valueRV(self);

	Modify(self);

	key = rb_obj_as_string(key);
	hv_delete(hash, RSTRING_PTR(key), RSTRING_LEN(key), G_DISCARD);

	return self;
}

static VALUE
plrb_hash_exists(VALUE self, VALUE key)
{
	dTHX;
	HV* hash = (HV*)valueRV(self);

	key = rb_obj_as_string(key);

	return hv_exists(hash, RSTRING_PTR(key), RSTRING_LEN(key)) ? Qtrue : Qfalse;
}

static VALUE
plrb_hash_clear(VALUE self)
{
	dTHX;
	HV* hash = (HV*)valueRV(self);

	Modify(self);

	hv_clear(hash);

	return self;
}

/* class Perl::Code */

static VALUE
plrb_call_sv(VALUE self, SV* sv, int flags, int argc, VALUE* argv)
{
	dTHX;
	dSP;

	int i;
	VALUE result;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	if(argc == 1 && TYPE(argv[0]) == T_ARRAY){
		argc = RARRAY_LEN(argv[0]);
		argv = RARRAY_PTR(argv[0]);
	}

	if(argc != 0){
		EXTEND(SP, argc);

		for(i = 0; i < argc; i++){
			PUSHs(VALUE2SV(argv[i]));
		}
	}
	if(rb_block_given_p()){
		XPUSHs(VALUE2SV(rb_block_proc()));
	}

	/* context setting */
	if(FL_TEST(self, FL_G_VOID)){
		flags |= G_VOID;
	}
	else if(FL_TEST(self, FL_G_ARRAY)){
		flags |= G_ARRAY;
	}
	else if(FL_TEST(self, FL_G_SCALAR)){
		flags |= G_SCALAR;
	}

	FL_UNSET(self, FL_G_VOID | FL_G_ARRAY | FL_G_SCALAR);

	rb_set_errinfo(Qnil);

	PUTBACK;

	i = call_sv(sv, G_EVAL | flags);

	SPAGAIN;

	if(SvTRUE(ERRSV)){
		if(!NIL_P(rb_errinfo())){
			rb_exc_raise(rb_errinfo());
		}
		else{
			rb_raise(plrb_eExc, "%" SVf, ERRSV);
		}
	}

	if(i == 0 || flags & G_VOID){
		result = Qnil;
	}
	else if(i == 1){
		result = SV2VALUE(POPs);
	}
	else{
		result = rb_ary_new2(i);
		RARRAY_LEN(result) = i;
		while(i--){
			RARRAY_PTR(result)[i] = SV2VALUE(POPs);
		}
	}

	PUTBACK;

	FREETMPS;
	LEAVE;

	return result;
}


VALUE
plrb_code_call(int argc, VALUE* argv, VALUE self)
{
	return plrb_call_sv(self, valueSV(self), 0, argc, argv);
}

static VALUE
plrb_code_arity(VALUE self)
{
	PERL_UNUSED_ARG(self);
	return INT2FIX(-1);
}

static VALUE
plrb_want(VALUE self, VALUE context)
{
	dTHX;
	ID id;
	const char* name;
	int g;

	id = rb_to_id(context);

	name = rb_id2name(id);

	if(strEQ(name, "void")){
		g = FL_G_VOID;
	}
	else if(strEQ(name, "scalar")){
		g = FL_G_SCALAR;
	}
	else if(strEQ(name, "array")){
		g = FL_G_ARRAY;
	}
	else{
		rb_raise(rb_eArgError, "Unexpected context `%s'", name);
	}

	FL_UNSET(self, FL_G_VOID|FL_G_SCALAR|FL_G_ARRAY);
	FL_SET(self, g);

	return self;
}

static VALUE
plrb_code_to_proc(VALUE self)
{
	VALUE call = ID2SYM(rb_intern("call"));
	VALUE method = rb_funcall2(self, rb_intern("method"), 1, &call);

	return rb_funcall2(method, rb_intern("to_proc"), 0, NULL);
}

/* Perl::Package, Perl::Class */


static VALUE
plrb_package_inspect(VALUE self)
{
	dTHX;
	SV* sv = valueSV(self);
	VALUE str = rb_str_new2(rb_class2name(rb_obj_class(self)));

	rb_str_cat(str, "(", 1);
	rb_str_cat(str, SvPVX(sv), (long)SvCUR(sv));
	rb_str_cat(str, ")", 1);
	return str;
}

/* function's auto-installer */
static VALUE
plrb_package_singleton_method_added(VALUE self, VALUE method)
{
	dTHX;
	SV* sv;
	VALUE name;
	CV* cv;
	ID id_m;

	if(self == plrb_top_self || sym_method_added == method){
		/* do nothing */
		return Qnil;
	}

	id_m = rb_to_id(method);

	sv = valueSV(self);

	name = rb_str_new_sv(sv);

	rb_str_cat(name, "::", 2);
	rb_str_cat2(name, rb_id2name(id_m));


	cv = newXS(RSTRING_PTR(name), XS_Ruby_function_dispatcher, __FILE__);
	CvXSUBANY(cv).any_ptr = (void*)id_m;

	return Qnil;
}

static VALUE
plrb_package_function_invoke(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	SV* pkgname = valueSV(self);
	ID meth_id;
	VALUE method;
	GV* gv;

	if(argc == 0){
		rb_raise(rb_eArgError, "No method given");
	}

	meth_id = rb_to_id(argv[0]);

	/* check rerecursive call */
	if(rb_attr_get(self, plrb_id_call_from_perl) == ID2SYM(meth_id)){
		rb_ivar_set(self, plrb_id_call_from_perl, Qnil);

		rb_raise(rb_eNoMethodError, "Undefined method %s", rb_id2name(meth_id));
	}

	method = rb_attr_get(self, meth_id); /* the cache exists? */

	if(!NIL_P(method)){
		gv = (GV*)valueSV(method);
	}
	else{
		volatile VALUE buffer  = rb_str_new_sv(pkgname);

		rb_str_buf_cat2(buffer, "::");
		rb_str_buf_cat2(buffer, rb_id2name(meth_id));

		gv = gv_fetchpv(RSTRING_PTR(buffer), TRUE, SVt_PV);

		rb_ivar_set(self, meth_id, any_new2(plrb_cAny, (SV*)gv));
	}


	if(GvCV(gv)){
		/* unshift @_ */
		argc--;
		argv++;

		return plrb_call_sv(self, (SV*)GvCV(gv), 0, argc, argv);
	}
	else{
		return rb_call_super(argc, argv);
	}
}

static VALUE
plrb_any_to_perl(VALUE self)
{
	return self;
}

/* extend Ruby's Object */

static VALUE
obj_true_p(VALUE obj)
{
	return RTEST(obj) ? Qtrue : Qfalse;
}
static VALUE
obj_false_p(VALUE obj)
{
	return RTEST(obj) ? Qfalse : Qtrue;
}

static VALUE
obj_to_perl(VALUE obj)
{
	dTHX;
	SV* sv;

	switch(TYPE(obj)){
	case T_NIL:
		sv = &PL_sv_undef;
		SvREFCNT_inc(sv);
		break;
	case T_TRUE:
		sv = &PL_sv_yes;
		SvREFCNT_inc(sv);
		break;
	case T_FALSE:
		sv = &PL_sv_no;
		SvREFCNT_inc(sv);
		break;
	case T_STRING:
		sv = newSVpvn(RSTRING_PTR(obj), RSTRLEN(obj));
		break;
	case T_FIXNUM:
		sv = newSViv((IV)FIX2INT(obj));
		break;
	case T_BIGNUM:
		obj = rb_big2str(obj, 10);
		sv = newSVpv(RSTRING_PTR(obj), RSTRLEN(obj));
		break;
	case T_FLOAT:
		sv = newSVnv(RFLOAT_VALUE(obj));
		break;
	case T_SYMBOL:
		sv = newSVpv(rb_id2name(SYM2ID(obj)), 0);
		break;
	default:
		rb_bug("Can't to_perl");
	}

	return any_new(sv);
}



static VALUE
ary_to_perl(VALUE ary)
{
	VALUE perlarray = rb_obj_alloc(plrb_cArray);

	plrb_array_push(RARRAY_LEN(ary), RARRAY_PTR(ary), perlarray);

	V2V_INFECT(ary, perlarray);

	return perlarray;
}

static int
hash_set_i(VALUE key, VALUE value, VALUE perlhash)
{
	if(key == Qundef) return ST_CONTINUE;

	plrb_hash_aset(perlhash, key, value);

	return ST_CONTINUE;
}


static VALUE
hash_to_perl(VALUE hash)
{
	VALUE perlhash = rb_obj_alloc(plrb_cHash);

	rb_hash_foreach(hash, hash_set_i, perlhash);

	V2V_INFECT(hash, perlhash);

	return perlhash;
}

#define PerlVersion (STRINGIFY(PERL_REVISION) "." STRINGIFY(PERL_VERSION) "." STRINGIFY(PERL_SUBVERSION))

void
Init_perl(pTHX)
{
	id_cmp    = rb_intern("<=>");
	id_equal  = rb_intern("==");

	sym_method_added = ID2SYM(rb_intern("singleton_method_added"));

	rb_define_method(rb_cObject,   "true?",    RUBY_METHOD_FUNC(obj_true_p),    0);
	rb_define_method(rb_cObject,   "false?",   RUBY_METHOD_FUNC(obj_false_p),   0);

	rb_define_method(rb_cNilClass,  "to_perl", RUBY_METHOD_FUNC(obj_to_perl),  0);
	rb_define_method(rb_cTrueClass, "to_perl", RUBY_METHOD_FUNC(obj_to_perl),  0);
	rb_define_method(rb_cFalseClass,"to_perl", RUBY_METHOD_FUNC(obj_to_perl),  0);
	rb_define_method(rb_cString,    "to_perl", RUBY_METHOD_FUNC(obj_to_perl),  0);
	rb_define_method(rb_cFloat,     "to_perl", RUBY_METHOD_FUNC(obj_to_perl),  0);
	rb_define_method(rb_cFixnum,    "to_perl", RUBY_METHOD_FUNC(obj_to_perl),  0);
	rb_define_method(rb_cBignum,    "to_perl", RUBY_METHOD_FUNC(obj_to_perl),  0);
	rb_define_method(rb_cSymbol,    "to_perl", RUBY_METHOD_FUNC(obj_to_perl),  0);

	rb_define_method(rb_cArray,     "to_perl", RUBY_METHOD_FUNC(ary_to_perl),  0);
	rb_define_method(rb_cHash,      "to_perl", RUBY_METHOD_FUNC(hash_to_perl), 0);


	/* module Perl */

	plrb_mPerl	= rb_define_module("Perl");

	rb_define_const(plrb_mPerl, "VERSION",
		rb_str_new(PerlVersion, sizeof(PerlVersion)-1));

	rb_define_singleton_method(plrb_mPerl, "String",    RUBY_METHOD_FUNC(plrb_perl_string),  1);
	rb_define_singleton_method(plrb_mPerl, "Integer",   RUBY_METHOD_FUNC(plrb_perl_integer), 1);
	rb_define_singleton_method(plrb_mPerl, "Float",     RUBY_METHOD_FUNC(plrb_perl_float),   1);

	rb_define_singleton_method(plrb_mPerl, "Class",     RUBY_METHOD_FUNC(plrb_perl_class),   1);
	rb_define_singleton_method(plrb_mPerl, "Package",   RUBY_METHOD_FUNC(plrb_perl_package), 1);

	rb_define_singleton_method(plrb_mPerl, "undef",     RUBY_METHOD_FUNC(plrb_perl_undef),  0);

	rb_define_singleton_method(plrb_mPerl, "[]",        RUBY_METHOD_FUNC(plrb_perl_fetch), -1);

	rb_define_singleton_method(plrb_mPerl, "eval",         RUBY_METHOD_FUNC(plrb_perl_eval),    -1);

	
	rb_define_singleton_method(plrb_mPerl, "require",      RUBY_METHOD_FUNC(plrb_perl_require), -1);
	

	/* class Perl::Exception */

	plrb_eExc	= rb_define_class_under(plrb_mPerl, "Error", rb_eStandardError);

	/* class Perl::Any */

	plrb_cAny	= rb_define_class_under(plrb_mPerl, "Any", rb_cObject);

	rb_include_module(plrb_cAny, rb_mComparable);

	rb_undef_alloc_func(plrb_cAny);

	rb_define_method(plrb_cAny, "to_perl",  RUBY_METHOD_FUNC(plrb_any_to_perl), 0);

	rb_define_method(plrb_cAny, "undef?",   RUBY_METHOD_FUNC(plrb_undef_p),     0);
	rb_define_method(plrb_cAny, "defined?", RUBY_METHOD_FUNC(plrb_defined_p),   0);
	rb_define_method(plrb_cAny, "true?",    RUBY_METHOD_FUNC(plrb_true_p),      0);
	rb_define_method(plrb_cAny, "false?",   RUBY_METHOD_FUNC(plrb_false_p),     0);

	rb_define_method(plrb_cAny, "eql?",     RUBY_METHOD_FUNC(plrb_equal),       1);
	rb_define_method(plrb_cAny, "to_ref",   RUBY_METHOD_FUNC(plrb_to_ref),      0);

	rb_define_method(plrb_cAny, "==",       RUBY_METHOD_FUNC(plrb_eq),          1);
	rb_define_method(plrb_cAny, "<=>",      RUBY_METHOD_FUNC(plrb_cmp),         1);

	rb_define_method(plrb_cAny, "inspect",  RUBY_METHOD_FUNC(plrb_inspect), 0);
	rb_define_method(plrb_cAny, "method_missing", RUBY_METHOD_FUNC(plrb_any_method_invoke), -1);

	/* class Perl::Glob */

	plrb_cGlob	= rb_define_class_under(plrb_mPerl, "Glob", plrb_cAny);

	rb_define_method(plrb_cGlob, "to_s",    RUBY_METHOD_FUNC(plrb_scalar_to_str), 0);
	rb_define_method(plrb_cGlob, "[]",      RUBY_METHOD_FUNC(plrb_glob_fetch),    1);
	rb_define_method(plrb_cGlob, "fetch",   RUBY_METHOD_FUNC(plrb_glob_fetch),    1);

	/* class Perl::Scalar */

	plrb_cScalar	= rb_define_class_under(plrb_mPerl, "Scalar", plrb_cAny);

	rb_define_alloc_func(plrb_cScalar, plrb_sv_alloc);

	rb_include_module(plrb_cScalar, rb_mEnumerable);

	rb_define_method(plrb_cScalar, "eql?",     RUBY_METHOD_FUNC(plrb_scalar_eql),      1);
	rb_define_method(plrb_cScalar, "hash",     RUBY_METHOD_FUNC(plrb_scalar_hash),     0);

	rb_define_method(plrb_cScalar, "coerce",   RUBY_METHOD_FUNC(plrb_scalar_coerce),   1);

	rb_define_method(plrb_cScalar, "to_int",   RUBY_METHOD_FUNC(plrb_scalar_to_int),   0);
	rb_define_method(plrb_cScalar, "to_float", RUBY_METHOD_FUNC(plrb_scalar_to_float), 0);
	rb_define_method(plrb_cScalar, "to_str",   RUBY_METHOD_FUNC(plrb_scalar_to_str),   0);

	rb_define_method(plrb_cScalar, "to_i",     RUBY_METHOD_FUNC(plrb_scalar_to_int),   0);
	rb_define_method(plrb_cScalar, "to_f",     RUBY_METHOD_FUNC(plrb_scalar_to_float), 0);
	rb_define_method(plrb_cScalar, "to_s",     RUBY_METHOD_FUNC(plrb_scalar_to_s),     0);

	rb_define_method(plrb_cScalar, "each_line",      RUBY_METHOD_FUNC(plrb_scalar_each_line), -1);
	rb_define_alias(plrb_cScalar, "each", "each_line");

	rb_define_method(plrb_cScalar, "concat",         RUBY_METHOD_FUNC(plrb_scalar_concat),  1);
	rb_define_method(plrb_cScalar, "set",            RUBY_METHOD_FUNC(plrb_scalar_set),     1);

	rb_define_method(plrb_cScalar, "succ",           RUBY_METHOD_FUNC(plrb_scalar_succ),    0);

	rb_define_method(plrb_cScalar, "send",           RUBY_METHOD_FUNC(plrb_scalar_send),   -1);

	rb_define_method(plrb_cScalar, "empty?",         RUBY_METHOD_FUNC(plrb_scalar_empty_p), 0);
	rb_define_method(plrb_cScalar, "size",           RUBY_METHOD_FUNC(plrb_scalar_size),    0);
	rb_define_alias(plrb_cScalar, "length", "size");

	/* class Perl::Ref */

	plrb_cRef = rb_define_class_under(plrb_mPerl, "Ref", plrb_cScalar);

	rb_define_method(plrb_cRef, "deref",    RUBY_METHOD_FUNC(plrb_ref_deref),    0);

	/* class Perl::Array */

	plrb_cArray	= rb_define_class_under(plrb_mPerl, "Array", plrb_cAny);

	rb_define_alloc_func(plrb_cArray, plrb_av_alloc);

	rb_include_module(plrb_cArray, rb_mEnumerable);

	rb_define_method(plrb_cArray, "to_ary",  RUBY_METHOD_FUNC(plrb_array_to_ary),  0);
	rb_define_method(plrb_cArray, "to_s",    RUBY_METHOD_FUNC(plrb_array_join),   -1);
	rb_define_alias(plrb_cArray, "join", "to_s");

	rb_define_method(plrb_cArray, "[]",      RUBY_METHOD_FUNC(plrb_array_aref),    1);
	rb_define_method(plrb_cArray, "[]=",     RUBY_METHOD_FUNC(plrb_array_aset),    2);
	rb_define_method(plrb_cArray, "<<",      RUBY_METHOD_FUNC(plrb_array_push),   -1);
	rb_define_method(plrb_cArray, "push",    RUBY_METHOD_FUNC(plrb_array_push),   -1);
	rb_define_method(plrb_cArray, "pop",     RUBY_METHOD_FUNC(plrb_array_pop),     0);
	rb_define_method(plrb_cArray, "shift",   RUBY_METHOD_FUNC(plrb_array_shift),   0);
	rb_define_method(plrb_cArray, "unshift", RUBY_METHOD_FUNC(plrb_array_unshift),-1);
	rb_define_method(plrb_cArray, "each",    RUBY_METHOD_FUNC(plrb_array_each),    0);
	rb_define_method(plrb_cArray, "empty?",  RUBY_METHOD_FUNC(plrb_array_empty_p), 0);
	rb_define_method(plrb_cArray, "size",    RUBY_METHOD_FUNC(plrb_array_size),    0);
	rb_define_alias(plrb_cArray, "length", "size");
	rb_define_method(plrb_cArray, "clear",   RUBY_METHOD_FUNC(plrb_array_clear),   0);

	/* class Perl::Hash */

	plrb_cHash	= rb_define_class_under(plrb_mPerl, "Hash",  plrb_cAny);

	rb_define_alloc_func(plrb_cHash, plrb_hv_alloc);

	rb_include_module(plrb_cHash, rb_mEnumerable);

	rb_define_method(plrb_cHash, "to_hash",    RUBY_METHOD_FUNC(plrb_hash_to_hash),   0);

	rb_define_method(plrb_cHash, "[]",         RUBY_METHOD_FUNC(plrb_hash_aref),      1);
	rb_define_method(plrb_cHash, "[]=",        RUBY_METHOD_FUNC(plrb_hash_aset),      2);
	rb_define_alias(plrb_cHash, "fetch", "[]");
	rb_define_alias(plrb_cHash, "store", "[]=");
	rb_define_method(plrb_cHash, "each",       RUBY_METHOD_FUNC(plrb_hash_each_pair), 0);
	rb_define_method(plrb_cHash, "each_key",   RUBY_METHOD_FUNC(plrb_hash_each_key),  0);
	rb_define_method(plrb_cHash, "each_value", RUBY_METHOD_FUNC(plrb_hash_each_value),0);
	rb_define_method(plrb_cHash, "each_pair",  RUBY_METHOD_FUNC(plrb_hash_each_pair), 0);
	rb_define_method(plrb_cHash, "delete",     RUBY_METHOD_FUNC(plrb_hash_delete),    1);
	rb_define_method(plrb_cHash, "exists",     RUBY_METHOD_FUNC(plrb_hash_exists),    1);
	rb_define_alias(plrb_cHash, "has_key?", "exists");
	rb_define_alias(plrb_cHash, "include?", "exists");
	rb_define_alias(plrb_cHash, "key?",     "exists");
	rb_define_alias(plrb_cHash, "member?",  "exists");
	rb_define_method(plrb_cHash, "clear",      RUBY_METHOD_FUNC(plrb_hash_clear),     0);

	/* class Perl::Code */

	plrb_cCode	= rb_define_class_under(plrb_mPerl, "Code",  plrb_cAny);

	rb_define_method(plrb_cCode, "call",    RUBY_METHOD_FUNC(plrb_code_call), -1);
	rb_define_method(plrb_cCode, "arity"  , RUBY_METHOD_FUNC(plrb_code_arity), 0);
	rb_define_method(plrb_cCode, "want", RUBY_METHOD_FUNC(plrb_want),    1);
	rb_define_method(plrb_cCode, "to_proc", RUBY_METHOD_FUNC(plrb_code_to_proc), 0);

	//plrb_top_self = plrb_get_package("Ruby");
	plrb_top_self = rb_eval_string("self");

	plrb_undef = any_new(&PL_sv_undef);
	rb_gc_register_address(&plrb_undef);

	packages = rb_obj_alloc(rb_cObject);
	classes  = rb_obj_alloc(rb_cObject);

	rb_gc_register_address(&packages);
	rb_gc_register_address(&classes);

	/* class Perl::Class */

	plrb_cClass = rb_define_class_under(plrb_mPerl, "Class", plrb_cAny);

	//rb_include_module(plrb_cClass, plrb_mPerl);

	rb_define_private_method(plrb_cClass, "__PACKAGE__", RUBY_METHOD_FUNC(plrb_scalar_to_str), 0);

	rb_define_method(plrb_cClass, "want", RUBY_METHOD_FUNC(plrb_want),    1);

	rb_define_method(plrb_cClass, "to_s",                RUBY_METHOD_FUNC(plrb_scalar_to_str), 0);
	rb_define_method(plrb_cClass, "inspect",             RUBY_METHOD_FUNC(plrb_package_inspect), 0);

	rb_define_method(plrb_cClass, "[]",                  RUBY_METHOD_FUNC(plrb_package_fetch), -1);

	//rb_define_singleton_method(rb_cClass, "[]", RUBY_METHOD_FUNC(plrb_package_fetch));

	/* class Perl::Package (like Module) */

	plrb_cPackage = rb_define_class_under(plrb_mPerl, "Package", plrb_cClass);

	rb_define_method(plrb_cPackage, "method_missing", RUBY_METHOD_FUNC(plrb_package_function_invoke), -1);

	rb_define_method(plrb_cPackage, "singleton_method_added", RUBY_METHOD_FUNC(plrb_package_singleton_method_added), 1);
}
