/*
	$Id: plrb.h,v 1.5 2004/04/11 05:04:46 jigoro Exp $
*/

#ifndef PERL_RUBY_PM_H
#define PERL_RUBY_PM_H

#define getuid  _ruby_getuid
#define getgid  _ruby_getgid
#define geteuid _ruby_geteuid
#define getegid _ruby_getegid
#define setuid  _ruby_setuid
#define setgid  _ruby_setgid
#define kill    _ruby_kill
#define chown   _ruby_chown
#define tms     _ruby_tms

#if MY_RUBY_VERSION_INT >= 190
#include <ruby/ruby.h>
#else
#include <ruby.h>
#include "rbport.h"
#endif


#undef getuid
#undef getgid
#undef geteuid
#undef getegid
#undef setuid
#undef setgid
#undef kill
#undef chown
#undef tms


#undef yyparse
#undef yylex
#undef yyerror
#undef yylval


#undef isnan
#undef getenv
#undef fclose
#undef fputc
#undef close
#undef mktemp
#undef read
#undef rename
#undef stat
#undef umask
#undef unlink
#undef utime
#undef write
#undef sleep
#undef times
#undef getpid
#undef accept
#undef bind
#undef connect
#undef gethostbyaddr
#undef gethostbyname
#undef gethostname
#undef getpeername
#undef getprotobyname
#undef getprotobynumber
#undef getservbyname
#undef getservbyport
#undef getsockname
#undef getsockopt
#undef listen
#undef recv
#undef recvfrom
#undef select
#undef send
#undef sendto
#undef setsockopt
#undef shutdown
#undef socket
#undef mkdir
#undef rmdir
#undef isatty
#undef execv

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"


#include "inspect.h"


/* -------------------------------------- */


extern VALUE plrb_top_self;

void plrb_initialize(pTHX);
void plrb_finalize(pTHX);


typedef VALUE (*plrb_func_t)(VALUE);

bool plrb_is_value(pTHX_ SV*);

SV*   plrb_value2sv(pTHX_ VALUE);

SV*   plrb_sv_set_value(pTHX_ SV* sv, VALUE value);
SV*   plrb_sv_set_value_direct(pTHX_ SV* sv, VALUE value, const char* pkg);

SV*   plrb_new_sv_value(pTHX_ VALUE, const char* pkg);

SV*   plrb_newSVvalue(pTHX_ VALUE);
void  plrb_delSVvalue(pTHX_ SV*);

const char* plrb_value_pv(volatile VALUE* vp, STRLEN* lenp);

VALUE plrb_name2class(pTHX_ const char* name);
VALUE plrb_ruby_class(pTHX_ const char* name, int check);
VALUE plrb_ruby_self (pTHX_ SV* sv);

void plrb_exc_raise(VALUE exc);
void plrb_raise(VALUE etype, const char* format, ...);

VALUE plrb_eval(pTHX_ SV* source, SV* pkg, const char* file, const int line);

void plrb_install_class(pTHX_ const char* pkg, VALUE klass);

VALUE plrb_errinfo(void);
void  plrb_set_errinfo(VALUE e);

VALUE plrb_funcall_protect(pTHX_ VALUE recv, ID method, int argc, SV** argv);
#define Funcall(recv, method, argc, argv) plrb_funcall_protect(aTHX_ recv, method, argc, argv)

VALUE plrb_protect0(plrb_func_t);
VALUE plrb_protect1(plrb_func_t, VALUE arg1);
VALUE plrb_protect(plrb_func_t, int argc, ...);

XS(XS_Ruby_VALUE_new);
XS(XS_Ruby_function_dispatcher);
XS(XS_Ruby_method_dispatcher);
XS(XS_Ruby_class_holder);

extern ID plrb_id_call_from_perl;


/* macros for SV */

#define isVALUE(sv) plrb_is_value(aTHX_ sv)
#define SvVALUE(sv)  ((VALUE)SvIVX(SvRV(sv)))

#define SV2VALUE(sv) plrb_sv2value(aTHX_ sv)

/* macros for VALUE */

#define new_sv_value(value, pkg) sv_set_value_direct(newSV(0),  value, pkg)

#define newSVvalue(value) plrb_newSVvalue(aTHX_ value)
#define delSVvalue(value) plrb_delSVvalue(aTHX_ value)

#define sv_set_value_direct(sv, value, pkg)  plrb_sv_set_value_direct(aTHX_ sv, value, pkg)
#define sv_set_value(sv, value)              plrb_sv_set_value(aTHX_ sv, value)

#define isSV(value) (TYPE(value) == T_DATA && rb_obj_is_kind_of(value, plrb_cAny))
#define valueSV(value) ((SV*)DATA_PTR(value))
#define valueRV(value) SvRV(valueSV(value))

#define VALUE2SV(value) plrb_value2sv(aTHX_ value)

#define ValuePV(value, len)  plrb_value_pv(&value, &len)
#define ValuePV_nolen(value) plrb_value_pv(&value, &PL_na)

#define rb_inspect_cstr(v) RSTRING(rb_inspect(v))->ptr

#define ruby_self(sv) plrb_ruby_self(aTHX_ sv)

#define name2class(name) plrb_name2class(aTHX_ name)

#define RSTRLEN(s) ((STRLEN)RSTRING_LEN(s))

/* taint infecting */

#define V2V_INFECT(from, to) OBJ_INFECT(to, from)
#define S2S_INFECT(from, to) do{ if(  SvTAINTED(from))   SvTAINT(to); }while(0)

#define S2V_INFECT(from, to) do{ if(  SvTAINTED(from)) OBJ_TAINT(to); } while(0)
#define V2S_INFECT(from, to) do{ if(OBJ_TAINTED(from))   SvTAINT(to); } while(0)

#define S_V2V_INFECT(s, v, to_v) do{ S2V_INFECT(s, to_v); V2V_INFECT(v, to_v); } while(0)
#define V_S2S_INFECT(v, s, to_s) do{ V2S_INFECT(v, to_s); S2S_INFECT(s, to_s); } while(0)

#define V2S_V_INFECT(v, to_s, to_v) do{ V2S_INFECT(v, to_s); V2V_INFECT(v, to_v); } while(0)
#define S2V_S_INFECT(s, to_v, to_s) do{ S2V_INFECT(s, to_v); S2S_INFECT(s, to_s); } while(0)

/* module Perl */

extern VALUE plrb_mPerl;
extern VALUE plrb_cAny;
extern VALUE plrb_cGlob;
extern VALUE plrb_cScalar;
extern VALUE plrb_cRef;
extern VALUE plrb_cArray;
extern VALUE plrb_cHash;
extern VALUE plrb_cCode;
extern VALUE plrb_eExc;

void  Init_perl(pTHX);

VALUE plrb_any_new_noinc(pTHX_ SV*);
VALUE plrb_any_new2_noinc(pTHX_ VALUE, SV*);
VALUE plrb_sv2value(pTHX_ SV*);

#define any_new_noinc(a) plrb_any_new_noinc(aTHX_ a)
#define any_new_inc(a)   plrb_any_new_noinc(aTHX_ SvREFCNT_inc(a))
#define any_new(a)       any_new_inc(a)

#define any_new2_noinc(k,a)  plrb_any_new2_noinc(aTHX_ k, a)
#define any_new2_inc(k,a)    plrb_any_new2_noinc(aTHX_ k, SvREFCNT_inc(a))
#define any_new2(k,a)        any_new2_inc(k,a)

VALUE plrb_get_package(const char* name);
VALUE plrb_get_class(const char* name);

const char* plrb_sv_to_s(pTHX_ SV*, STRLEN* len);
#define sv_to_s(sv, len) plrb_sv_to_s(aTHX_ sv, &len)

VALUE plrb_code_call(int, VALUE*, VALUE);

/* perlio.c */

void Init_perlio(pTHX);

extern VALUE plrb_cPerlIO;

VALUE plrb_pio_gv2pio_noinc(pTHX_ GV* gv);
VALUE plrb_pio_io2pio(pTHX_ IO* io);

SV* IO_Handle_inspect(pTHX_ GV* gv);

#define gv2pio(gv) gv2pio_inc(gv)
#define gv2pio_noinc(gv) plrb_pio_gv2pio_noinc(aTHX_ gv)
#define gv2pio_inc(gv)   plrb_pio_gv2pio_noinc(aTHX_ (GV*)SvREFCNT_inc((SV*)gv))

#define io2pio(io) plrb_pio_io2pio(aTHX_ io)

/* utility.c */

typedef VALUE (*defaultf_t)(void);

VALUE rb_ivar_get_defaultv(VALUE obj, ID key, VALUE defaultv);

VALUE rb_ivar_get_defaultf(VALUE obj, ID key, defaultf_t defaultf);

#define rb_str_new_sv(sv) plrb_str_new_sv(aTHX_ sv)
VALUE plrb_str_new_sv(pTHX_ SV*);

#endif /* PERL_RUBY_PM_H */
