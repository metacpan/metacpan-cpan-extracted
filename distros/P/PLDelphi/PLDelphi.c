/*******************************************************************************
## Name:        PLDelphi.c
## Purpose:     Embed Perl into Delphi
## Author:      Graciliano M. P.
## Modified by:
## Created:     04/07/2004
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
*******************************************************************************/

// #define PERL_NO_GET_CONTEXT


#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <embed.h>

#include <windows.h>

#define PLDELPHI_API __declspec(dllexport)

/* expletive */
#undef malloc
#undef free

#ifdef WIN32
#define snprintf _snprintf
#endif


#ifdef __GNUC__

/* Mingw32 defaults to globing command line 
 * This is inconsistent with other Win32 ports and 
 * seems to cause trouble with passing -DXSVERSION=\"1.6\" 
 * So we turn it off like this:
 */
int _CRT_glob = 0;

#endif

///////////////////////////////////////////////////////////

char* retval ;

static PerlInterpreter *my_perl;

static void xs_init( pTHX );
EXTERN_C void boot_DynaLoader( pTHX_ CV* cv );

PLDELPHI_API int
PLDelphi_start() {
    int exitstatus;
    int my_argc = 3 ;
    char** my_argv = (char**) malloc( ( my_argc + 1 ) * sizeof(char**) );

    my_argv[0] = strdup( "PLDelphi" );
    my_argv[1] = strdup( "-e" );
    my_argv[2] = strdup( " use PLDelphi " );
    my_argv[3] = strdup( "--" );
    my_argv[ my_argc + 1 ] = NULL;
       
#if defined(USE_ITHREADS)
    PTHREAD_ATFORK(Perl_atfork_lock,
                   Perl_atfork_unlock,
                   Perl_atfork_unlock);
#endif

    my_perl = perl_alloc();
    PERL_SET_CONTEXT(my_perl);
     
    perl_construct(my_perl);
	PL_perl_destruct_level = 0;
    
    exitstatus = perl_parse(my_perl, xs_init, my_argc, my_argv, (char **)NULL) ;
    exitstatus = perl_run(my_perl);
    
    free(my_argv) ;
    
    return exitstatus ;
}

PLDELPHI_API char*
PLDelphi_call( char* code ) {
  dTHX ;
  dSP ;
  
  STRLEN len ;
  char *tmp ;
  SV* ret ;
  
  PERL_SET_CONTEXT(PL_curinterp) ;

  ENTER ;
  SAVETMPS ;
  PUSHMARK(SP);
  
    call_pv(code , G_SCALAR);

    SPAGAIN ;
    
    ret = POPs ;
    tmp = SvPV(ret , len) ;
    free(retval);
    retval = malloc(sizeof(char) * (len+1)) ;
    Copy(tmp, retval, len, char);
    retval[len] = '\0';

  PUTBACK ;
  FREETMPS ;
  LEAVE ;

  return retval  ;
}


PLDELPHI_API char*
PLDelphi_call_args( char* code , char* args ) {
  dTHX ;
  dSP ;
  
  STRLEN len;
  char *tmp ;
  int i ;
  AV* ar ;
  SV* ret ;
  SV* sv ;
  
  PERL_SET_CONTEXT(PL_curinterp) ;

  ENTER ;
  SAVETMPS ;

    PUSHMARK(SP) ;
      sv = sv_2mortal(newSVpvf("[%s]", args)) ;
      sv = eval_pv( SvPV(sv , SvLEN(sv) ) , 0 ) ;
      ar = (AV*) SvRV(sv) ;
    
      for (i = 0 ; i <= av_len(ar) ; ++i) {
        sv = *av_fetch(ar, i ,0) ;
        XPUSHs( sv );
      }
    PUTBACK ;
  
    call_pv(code , G_SCALAR);

    SPAGAIN ;

    ret = POPs ;
    tmp = SvPV(ret , len) ;
    free(retval);
    retval = malloc(sizeof(char) * (len+1)) ;
    Copy(tmp, retval, len, char);
    retval[len] = '\0';

  PUTBACK ;
  FREETMPS ;
  LEAVE ;

  return retval  ;
}

PLDELPHI_API char*
PLDelphi_eval( char* code ) {
  dTHX ;
  dSP ;
  
  STRLEN len;
  char *retval ;
  SV* ret ;
  SV* svcode ;
  
  PERL_SET_CONTEXT(PL_curinterp) ;

  svcode = get_sv("PLDelphi::SVCODE", 1) ;
  sv_setpv(svcode, code) ;

  ENTER ;
  SAVETMPS ;
  PUSHMARK(SP) ;

    call_pv("PLDelphi::STR_eval" , G_SCALAR);
    sv_setpv(svcode, "") ;
      
    SPAGAIN ;
    POPs ;
  PUTBACK ;
  FREETMPS ;
  LEAVE ;
  
  ret = get_sv("PLDelphi::CALLRET", 1) ;
  retval = SvPV(ret , len) ;

  return retval ;
}


PLDELPHI_API char*
PLDelphi_eval_sv(char* code) {
  dTHX ;
  dSP ;
  
  STRLEN len;
  char *retval ;
  SV* ret ;
  SV* svcode ;
  
  PERL_SET_CONTEXT(PL_curinterp) ;

  svcode = get_sv("PLDelphi::SVCODE", 1) ;
  sv_setpv(svcode, code) ;

  ENTER ;
  SAVETMPS ;
  PUSHMARK(SP) ;

    call_pv("PLDelphi::SV_eval" , G_SCALAR);
    sv_setpv(svcode, "") ;
      
    SPAGAIN ;
    POPs ;
  PUTBACK ;
  FREETMPS ;
  LEAVE ;
  
  ret = get_sv("PLDelphi::CALLRET", 1) ;
  retval = SvPV(ret , len) ;

  return retval ;
}


PLDELPHI_API char*
PLDelphi_error() {
  dTHX ;
  PERL_SET_CONTEXT(PL_curinterp);
  return SvPV( ERRSV , SvLEN(ERRSV) )  ;
}

PLDELPHI_API void
PLDelphi_stop() {
  dTHX ;
  PERL_SET_CONTEXT(PL_curinterp);
  
  eval_pv( "exit" , 0 ) ;

  perl_destruct(my_perl);
  perl_free(my_perl);
}

XS(XS_PLDelphi_weaken);
XS(XS_PLDelphi_weaken)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: PLDelphi::weaken(sv)");
    {
	SV *	sv = ST(0);
#ifdef SvWEAKREF
	sv_rvweaken(sv);
#else
	croak("weak references are not implemented in this release of perl");
#endif
    }
    XSRETURN_EMPTY;
}

XS(XS_PLDelphi_is_SvBlessed)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: PLDelphi::is_SvBlessed(sv)");
    {
	SV *	sv = ST(0);
	bool	RETVAL;
    RETVAL = sv_isobject(sv) ;
	ST(0) = boolSV(RETVAL);
	sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

EXTERN_C void
xs_init(pTHX) {
    char *file = __FILE__;

    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);

    newXSproto("PLDelphi::weaken", XS_PLDelphi_weaken, file, "$");
    newXS("PLDelphi::is_SvBlessed", XS_PLDelphi_is_SvBlessed, file);
}


