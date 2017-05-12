/*
	$Id: plrb.c,v 1.6 2004/04/11 05:04:46 jigoro Exp $
*/

#include "ruby_pm.h"


VALUE plrb_root;  /* object register */
#define InitRegister() do{ plrb_root = rb_hash_new(); rb_gc_register_address(&plrb_root); } while(0)
#define GetRegister(k)    rb_hash_aref(plrb_root, k)
#define AddRegister(k,v)  rb_hash_aset(plrb_root, k, v)
#define RemoveRegister(k) rb_hash_delete(plrb_root, k)

#define NewRegEnt(reg, val, refcnt) (reg = rb_assoc_new(val, refcnt))
#define RegEntValue(reg)  (RARRAY_PTR(reg)[0])
#define RegEntRefcnt(reg) (RARRAY_PTR(reg)[1])

#define RegEntRefcnt_op(reg, op) (RegEntRefcnt(reg) = INT2FIX( FIX2INT(RegEntRefcnt(reg)) op) )
#define RegEntRefcnt_inc(reg)    (RegEntRefcnt_op(reg, +1))
#define RegEntRefcnt_dec(reg)    (RegEntRefcnt_op(reg, -1))

#define CheckError(e) do{ if(e){\
		if(!NIL_P(rb_errinfo())) plrb_exc_raise(rb_errinfo());\
		else                     plrb_local_jump_error(e);\
	} } while(0)


static VALUE name2class;

static void
plrb_local_jump_error(int e);

void
plrb_initialize(pTHX)
{
	VALUE rbversion;
	SV* rbversion_sv = get_sv("Ruby::Version", GV_ADDMULTI);
	CV* cv;

	static char my_argv_buffer[10];
	static char my_argv_elem_buffer[10][100];

	static char* my_argv_tmpl[] = { NULL, "-e", "", NULL, NULL, NULL };
	int my_argc = 3;
	char** my_argv = (char**)my_argv_buffer;
	int i;

	my_argv_tmpl[0] = PL_origfilename;

	if(PL_tainting){ /* perl -T */
		my_argv_tmpl[my_argc++] = "-T";
	}
	if(PL_dowarn & (G_WARN_ON|G_WARN_ALL_ON)){ /* perl -w */
		my_argv_tmpl[my_argc++] = "-w";
	}
	if(PL_perldb & PERLDB_ALL){ /* perl -d */
		my_argv_tmpl[my_argc++] = "-d";
	}

	/* build char** argv */
	
	for(i = 0; i < my_argc; i++){
		my_argv[i] = my_argv_elem_buffer[i];

		assert( strlen(my_argv_tmpl[i]) < sizeof(my_argv_elem_buffer[i]) );
		memcpy(my_argv[i], my_argv_tmpl[i], strlen(my_argv_tmpl[i])+1);
	}

#if MY_RUBY_VERSION_INT >= 190
	ruby_sysinit(&my_argc, &my_argv);
#endif
	ruby_init();

	ruby_options(my_argc, my_argv);

//	ruby_exec();

	ruby_script(PL_origfilename);

	/* initialize name2class cache */
	name2class = rb_obj_alloc(rb_cObject);
	rb_gc_register_address(&name2class);

	/* initialize object register */
	InitRegister();

	/* check ruby version */
	rbversion = rb_obj_as_string(rb_const_get(rb_cObject, rb_intern("RUBY_VERSION")));
	if(!strEQ(RSTRING_PTR(rbversion), STRINGIFY(MY_RUBY_VERSION))){
		croak("libruby version %s does not match Ruby.pm object version %s",
			RSTRING_PTR(rbversion), STRINGIFY(MY_RUBY_VERSION));
	}
	sv_setpvn(rbversion_sv, RSTRING_PTR(rbversion), RSTRLEN(rbversion));

	/* setup baseclass */
	cv = newXS("Ruby::Object::__CLASS__", XS_Ruby_class_holder, __FILE__);
	CvXSUBANY(cv).any_ptr = (void*)rb_cObject;

	Init_perl(aTHX);    /* Perl::*  in perlobject.c */
	Init_perlio(aTHX);  /* Perl::IO in perlio.c */

	/* install rb_argv */
#if 0
	{
		AV* argv = GvAV(PL_argvgv);
		int i;
		int size = av_len(argv)+1;
		for(i = 0; i < size; i++){
			SV* sv = *av_fetch(argv, i, TRUE);
			STRLEN len;
			const char* str = SvPV(sv, len);
			VALUE v = rb_tainted_str_new(str, (long)len);
			OBJ_FREEZE(v);
			rb_ary_push(rb_argv, v);
		}
	}
#endif

}

void
plrb_finalize(pTHX)
{

	plrb_root = Qfalse;
	ruby_cleanup(0);

}

bool
plrb_is_value(pTHX_ SV* sv)
{
	GV* gv;
	HV* stash;
	const char* hv_name;

	if(!sv) return FALSE;

	SvGETMAGIC(sv);

	if(!SvROK(sv)) return FALSE;

	sv = SvRV(sv);

	/* check flags: SvOBJECT && SvIOK && SvREADONLY */
	if((SvFLAGS(sv) & (SVs_OBJECT|SVf_READONLY|SVf_IOK)) != (SVs_OBJECT|SVf_READONLY|SVf_IOK)) return FALSE;

	stash = SvSTASH(sv);
	hv_name = HvNAME(stash);
	assert(hv_name != NULL);

	if(strEQ(hv_name, "Ruby::Object")) return TRUE; /* the base class? */

	/* installed? */
	gv = gv_fetchmethod_autoload(stash, "__CLASS__", FALSE /* no autoloading */);

	return (bool)(gv && CvXSUB(GvCV(gv)) == XS_Ruby_class_holder);
}



VALUE
plrb_sv2value(pTHX_ SV* sv)
{
	if(!sv) return Qnil;

	if(isVALUE(sv)) return SvVALUE(sv);

	return any_new(sv);
}

SV*
plrb_value2sv(pTHX_ VALUE value)
{
	if(isSV(value)){
		return valueSV(value);
	}
	return sv_2mortal(new_sv_value(value, NULL));
}
SV*
plrb_sv_set_value(pTHX_ SV* sv, VALUE value)
{
	if(isSV(value)){
		sv_setsv(sv, valueSV(value));
	}
	else{
		sv_set_value_direct(sv, value, NULL);
	}

	return sv;
}

SV*
plrb_sv_set_value_direct(pTHX_ SV* sv, VALUE value, const char* pkg)
{
	VALUE reg;
	VALUE obj_id;

	if(!plrb_root){
		warn("panic: Ruby already finalized");
		return &PL_sv_undef;
	}

	if(!pkg){
		pkg = "Ruby::Object";
	}

	if(!isVALUE(sv)){
		sv_setref_iv(sv, pkg, (IV)value); /* upgrade sv to SVt_RV */

	}
	else{
		if(SvVALUE(sv) == value) return sv;

		delSVvalue(sv);

		SvREADONLY_off(SvRV(sv));

		SvIVX(SvRV(sv)) = (IV)value;
	}

	SvREADONLY_on(SvRV(sv));

	if(!SPECIAL_CONST_P(value)){ /* value is pointer */
		obj_id = rb_obj_id(value);

		reg = GetRegister(obj_id);

		if(NIL_P(reg)){
			NewRegEnt(reg, value, INT2FIX(1));

			AddRegister(obj_id, reg);
		}
		else{
			RegEntRefcnt_inc(reg);
		}
	}

	V2S_INFECT(value, sv);

	return sv;
}

SV*
plrb_newSVvalue(pTHX_ VALUE value)
{
	if(isSV(value)){
		return newSVsv(valueSV(value));
	}
	return new_sv_value(value, NULL);
}

void
plrb_delSVvalue(pTHX_ SV* sv){
	VALUE reg;
	VALUE obj_id;
	VALUE value;

	if(!plrb_root){ /* finalized or uninitialized */
		return;
	}

	if(!isVALUE(sv)){ /* illigal object */
		return;
	}

	value = SvVALUE(sv);
	
	if(!SPECIAL_CONST_P(value)){ /* value is pointer */
		obj_id = rb_obj_id(value);
		reg = GetRegister(obj_id);

		if(NIL_P(reg)){
			warn("Attempt to free destroied VALUE");
			return;
		}

		if(RegEntRefcnt(reg) == INT2FIX(1)){
			RemoveRegister(obj_id);
		}
		else{
			RegEntRefcnt_dec(reg);
		}
	}
}

const char*
plrb_value_pv(volatile VALUE* vp, STRLEN* lenp)
{
	if(NIL_P(*vp)){
		*lenp = 3;
		return "nil";
	}

	*vp = plrb_protect1((plrb_func_t)rb_obj_as_string, *vp);

	*lenp = RSTRLEN(*vp);

	return RSTRING_PTR(*vp);
}

VALUE
plrb_name2class(pTHX_ const char* name)
{
	VALUE klass;
	ID key = rb_intern(name);

	klass = rb_attr_get(name2class, key);

	if(NIL_P(klass)){
		klass = plrb_protect1((plrb_func_t)rb_path2class, (VALUE)name);

		rb_ivar_set(name2class, key, klass);
	}

	return klass;
}

VALUE
plrb_ruby_class(pTHX_ const char* name, int check)
{
	HV* stash;
	GV* gv;

	stash = gv_stashpv(name, FALSE);

	if(!stash) goto error;

	gv = gv_fetchmethod_autoload(stash, "__CLASS__", FALSE);

	if(!gv) goto error;

	if(CvXSUB(GvCV(gv)) != XS_Ruby_class_holder)
		goto fatal;

	return (VALUE)CvXSUBANY(GvCV(gv)).any_ptr;

	error:

	if(check){
		fatal:
		croak("Can't call method on non-ruby class \"%s\"", name);
	}


	return Qfalse;
}
VALUE
plrb_ruby_self(pTHX_ SV* sv)
{
	VALUE k = Qfalse;

	if(isVALUE(sv)){
		return SvVALUE(sv);
	}
	if(SvPOK(sv)){
		k = plrb_ruby_class(aTHX_ SvPVX(sv), FALSE);
	}

	return k ? k : any_new(sv);
}

/* copied from eval.c (1.8.6) */
#define TAG_RETURN	0x1
#define TAG_BREAK	0x2
#define TAG_NEXT	0x3
#define TAG_RETRY	0x4
#define TAG_REDO	0x5
#define TAG_RAISE	0x6
#define TAG_THROW	0x7
#define TAG_FATAL	0x8
#define TAG_MASK	0xf

/* cf. localjump_error() in eval.c */
#define JUMPERR_MSG "Ruby.pm: unexpected "
static void
plrb_local_jump_error(int e)
{
	VALUE exc = Qnil;
	VALUE e_local_jump_error = rb_const_get(rb_cObject, rb_intern("LocalJumpError"));
	const char* why;
	const char msg[sizeof(JUMPERR_MSG "return")];

	switch(e){
	case TAG_RETURN:
		why = "return";
		break;
	case TAG_BREAK:
		why = "break";
		break;
	case TAG_NEXT:
		why = "next";
		break;
	case TAG_RETRY:
		why = "retry";
		break;
	case TAG_REDO:
		why = "redo";
		break;
	case TAG_RAISE:
		why = "raise";
		break;
	case TAG_THROW:
		why = "throw";
		break;
	case TAG_FATAL:
		why = "fatal";
		break;
	default:
		why = "jump";
	}
	Copy(JUMPERR_MSG, msg, sizeof(JUMPERR_MSG)-1, char);
	Copy(why, msg+sizeof(JUMPERR_MSG)-1, strlen(why)+1, char);
	exc = rb_exc_new2(e_local_jump_error, msg);

	rb_iv_set(exc, "@exit_value", INT2FIX(e));
	rb_iv_set(exc, "@reason", ID2SYM(rb_intern(why)));

	plrb_exc_raise(exc);
}

void
plrb_exc_raise(VALUE exc)
{
	dTHX;
	VALUE message;
	/*int e = 0;*/

	rb_set_errinfo(exc);

	message = rb_obj_as_string(exc);

	if(RSTRING_PTR(message)[RSTRLEN(message)-1] == '\n'){
		rb_str_cat2(message, "\t...");
	}

	/*
	croak("%s (%s) at %s line %d\n", RSTRING_PTR(message), rb_obj_classname(exc),
		ruby_sourcefile, ruby_sourceline);
	*/
	croak("%s (%s)", RSTRING_PTR(message), rb_obj_classname(exc));
}

void
plrb_raise(VALUE etype, const char* format, ...)
{
	dTHX;
	SV* esv = ERRSV;
	VALUE exc;

	va_list args;

	va_start(args, format);
	sv_vsetpvf_mg(esv, format, &args);
	va_end(args);

	exc = rb_exc_new(etype, SvPVX(esv), (long)SvCUR(esv));

	plrb_exc_raise(exc);
}



typedef struct plrb_protect_arg{
	plrb_func_t func;
	int   argc;
	VALUE argv[3];
} plrb_protect_arg;

static VALUE
plrb_protect_helper(plrb_protect_arg* arg)
{
	typedef VALUE (*f0)(void);
	typedef VALUE (*f1)(VALUE);
	typedef VALUE (*f2)(VALUE, VALUE);
	typedef VALUE (*f3)(VALUE, VALUE, VALUE);

	plrb_func_t func = arg->func;
	VALUE* argv = arg->argv;

	switch(arg->argc){
	case 0:
		return ((f0)func)();
	case 1:
		return ((f1)func)(argv[0]);
	case 2:
		return ((f2)func)(argv[0], argv[1]);
	case 3:
		return ((f3)func)(argv[0], argv[1], argv[2]);
	}
	assert(arg->argc <= 3);
	return Qnil; /* not reached */
}



VALUE
plrb_protect(plrb_func_t func, int argc, ...)
{
	plrb_protect_arg arg;
	int i;
	int e = 0;
	VALUE result;
	va_list args;

	if(argc > 3){
		rb_bug("Too meny arguments for %s", "plrb_protect()");
	}

	arg.func = func;
	arg.argc = argc;

	va_start(args, argc);

	for(i = 0; i < argc; i++){
		arg.argv[i] = va_arg(args, VALUE);
	}

	va_end(args);

	result = rb_protect((plrb_func_t)plrb_protect_helper, (VALUE)&arg, &e);

	CheckError(e);

	return result;
}

VALUE
plrb_protect0(plrb_func_t func)
{
	int e = 0;
	VALUE result;

	result = rb_protect(func, Qnil, &e);
	CheckError(e);
	return result;
}
VALUE
plrb_protect1(plrb_func_t func, VALUE arg1)
{
	int e = 0;
	VALUE result;

	result = rb_protect(func, arg1, &e);
	CheckError(e);
	return result;
}

typedef struct {
	VALUE   recv;
	ID      method;
	int     argc;
	VALUE*  argv;
} funcall_arg;

static VALUE
plrb_funcaller(funcall_arg* arg)
{
	return rb_funcall2(arg->recv, arg->method, arg->argc, arg->argv);
}

static VALUE
plrb_yield(VALUE arg, VALUE code)
{
	return plrb_code_call(1, &arg, code);
}

static VALUE
plrb_iterate(funcall_arg* arg)
{
	VALUE code = arg->argv[--(arg->argc)]; /* pop */
	return rb_iterate((plrb_func_t)plrb_funcaller, (VALUE)arg, plrb_yield, code);
}

static inline VALUE
do_funcall_protect(pTHX_ VALUE recv, ID method, int argc, VALUE* argv, int has_proc)
{
	volatile funcall_arg arg = { recv, method, argc, argv };
	VALUE result;
	int e = 0;

	result = rb_protect((plrb_func_t)(has_proc ? plrb_iterate : plrb_funcaller), (VALUE)&arg, &e);

	CheckError(e);

	return result;
}

VALUE
plrb_funcall_protect(pTHX_ VALUE recv, ID method, int argc, SV** argv)
{
	volatile VALUE argbuf;
	VALUE smallbuf[4];
	VALUE* args;
	int idx;
	int has_proc;

	if( ((size_t)argc) > (sizeof(smallbuf) / sizeof(VALUE))){
		argbuf = rb_ary_new2(argc);

		RARRAY_LEN(argbuf)= argc;
		args = RARRAY_PTR(argbuf);
	}
	else{
		args = smallbuf;
	}

	for(idx = 0; idx < argc; idx++){
		args[idx] = SV2VALUE(argv[idx]);
	}

	has_proc = (argc && SvROK(argv[argc-1]) && SvTYPE(SvRV(argv[argc-1])) == SVt_PVCV);

	return do_funcall_protect(aTHX_ recv, method, argc, args, has_proc);
}


void
plrb_install_class(pTHX_ const char* pkg, VALUE klass)
{
	VALUE k;

	k = plrb_ruby_class(aTHX_ pkg, FALSE);

	if(k){
		if(k == klass){
			/* already installed */
		}
		else{
			croak("Class %s redefined", pkg);
		}
	}
	else{
		SV* sv = newSV(0);

		CV* cv;
		AV* isa;

		sv_setpvf(sv, "%s::__CLASS__", pkg);
		cv = newXS(SvPVX(sv), XS_Ruby_class_holder, __FILE__);
		CvXSUBANY(cv).any_ptr = (void*)klass;

		sv_setpvf(sv, "%s::ISA", pkg);
		isa = get_av(SvPVX(sv), TRUE);
		sv_setpvs(sv, "Ruby::Object");
		av_push(isa, sv);
	}
}

VALUE
plrb_eval(pTHX_ SV* source, SV* pkg, const char* filename, const int line)
{
	const char* pkgname = NULL;

	STRLEN len;
	const char* s = SvPV(source, len);
	VALUE src  = rb_str_new(s, (long)len);
	VALUE file = rb_str_new2(filename);

	VALUE argv[4];
	VALUE result;

	S2V_INFECT(source, src);

	if(SvOK(pkg)){
		if(!(isVALUE(pkg) && NIL_P(SvVALUE(pkg)))){
			pkgname = SvPV_nolen_const(pkg);
		}
	}

	if(!pkgname){
		/* eval(source, binding, file, line) */
		argv[0] = src; 
		argv[1] = Qnil;
		argv[2] = file;
		argv[3] = INT2NUM(line);

		result = do_funcall_protect(aTHX_ plrb_top_self, rb_intern("eval"), 3, argv, FALSE);
	}
	else{
		volatile VALUE self = plrb_get_package(pkgname);
		volatile VALUE constants;

		/* instance_eval(source, file, line) */
		argv[0] = src;
		argv[1] = file;
		argv[2] = INT2NUM(line); 

		/* rb_instance_eval(argc, argv, self) */
		result = plrb_protect((plrb_func_t)rb_obj_instance_eval, 3, (VALUE)3, (VALUE)argv, (VALUE)self);


		/* export classes */
		constants = rb_const_list( rb_mod_const_at(CLASS_OF(self), NULL) );
		if(RARRAY_LEN(constants) > 0){
			volatile VALUE vpkg = rb_str_new2(pkgname);
			int pkglen = RSTRLEN(vpkg);
			int i;
			for(i = 0; i < RARRAY_LEN(constants); i++){
				VALUE name = RARRAY_PTR(constants)[i];
				VALUE klass = rb_const_get_at(CLASS_OF(self), rb_intern(RSTRING_PTR(name)));

				if(TYPE(klass) == T_CLASS || TYPE(klass) == T_MODULE){
					rb_str_resize(vpkg, pkglen);

					rb_str_cat(vpkg, "::", 2);
					rb_str_cat(vpkg, RSTRING_PTR(name), RSTRING_LEN(name));

					plrb_install_class(aTHX_ RSTRING_PTR(vpkg), klass);
				}
			}
		}
	}
	return result;
}

/* utilities */

VALUE
rb_ivar_get_defaultv(VALUE obj, ID key, VALUE defaultvalue)
{
	VALUE val = rb_attr_get(obj, key);

	if(NIL_P(val)){
		val = defaultvalue;
		rb_ivar_set(obj, key, val);
	}
	return val;
}

VALUE
rb_ivar_get_defaultf(VALUE obj, ID key, defaultf_t defaultfunc)
{
	VALUE val = rb_attr_get(obj, key);
	if(NIL_P(val)){
		val = defaultfunc();
		rb_ivar_set(obj, key, val);
	}
	return val;
}

VALUE
plrb_str_new_sv(pTHX_ SV* sv)
{
	STRLEN len;
	const char* pv = SvPV(sv, len);
	VALUE result =  rb_str_new(pv, (long)len);
	S2V_INFECT(sv, result);
	return result;
}

