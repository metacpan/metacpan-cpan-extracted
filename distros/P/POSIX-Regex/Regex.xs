#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <regex.h>

#include "const-c.inc"

#ifndef REG_NOERROR
 #define REG_NOERROR 0
#endif

#define regpk     "__reg_pointer"
#define regpk_len 13

MODULE = POSIX::Regex   PACKAGE = POSIX::Regex		

PROTOTYPES: DISABLE
INCLUDE: const-xs.inc

void
regcomp(self,regular,opts)
    SV   *self
    char *regular
    int  opts

    PREINIT:
    regex_t *r = (regex_t *) malloc(sizeof(regex_t));
    int err;
    char *errmsg[256];
    HV* me;

    CODE:
    if( r == NULL )
        croak("error allocating memory for regular expression\n");

    if( !sv_isobject(self) ) {
        free(r);
        croak("error trying to compile regular expression in an unblessed reference\n");
    }

    me = (HV*) SvRV(self); // de-reference us

    if( SvTYPE(me) != SVt_PVHV ) {
        free(r);
        croak("error trying to compile regular expression in a blessed reference that isn't a hash reference\n");
    }

    // NOTE: using PTR2UV instead of a cast to (unsigned int) is all thanks to Prof_vincent/vincent @ #perl on freenode

    // SV**  hv_store(HV*, const char* key, U32 klen, SV* val, U32 hash); // U32 hash is the pre-computed key (if you like)
    // Store first, so if regcomp fails normal cleanup happens in cleanup_memory
    hv_store(me, regpk, regpk_len, newSVuv(PTR2UV(r)), 0);

    // warn("regcomp r=%d", PTR2UV(r));

    if( (err = regcomp(r, regular, opts)) != REG_NOERROR ) {
        regerror(err, r, (char *)errmsg, 250); // 255 or 256?  screw it, 250
	
        croak("error compiling regular expression, %s\n", errmsg);
    }


void
cleanup_memory(self)
    SV *self

    PREINIT:
    regex_t *r;
    HV* me;
    SV** rptr;

    CODE:
    if( !sv_isobject(self) )
        croak("error trying to cleanup regular in an unblessed reference\n");

    me = (HV*) SvRV(self); // de-reference us
    if( SvTYPE(me) != SVt_PVHV )
        croak("error trying to cleanup regular in a blessed reference that isn't a hash reference\n");

    // NOTE: using INT2PTR(p,u) instead of a cast to (regex_t *) by hand is all thanks to Prof_vincent/vincent @ #perl on freenode

    // SV**  hv_fetch(HV*, const char* key, U32 klen, I32 lval); lval indicates whether this is part of a store operation also
    rptr = hv_fetch(me, regpk, regpk_len, 0);

    if (rptr) {
        r = INT2PTR(regex_t *, SvUV(*rptr));

        // warn("DESTROY r=%d", PTR2UV(r));
        regfree(r); free(r);
    }

int
regexec(self,string,opts)
    SV *self
    char *string
    int opts;

	PREINIT:
    regex_t *r;
    HV* me;
    int err;
    char *errmsg[256];

    CODE:
    if( !sv_isobject(self) )
        croak("error trying to execute regular expression in an unblessed reference\n");

    me = (HV*) SvRV(self); // de-reference us
    if( SvTYPE(me) != SVt_PVHV )
        croak("error trying to execute regular expression in a blessed reference that isn't a hash reference\n");

    // SV**  hv_fetch(HV*, const char* key, U32 klen, I32 lval); lval indicates whether this is part of a store operation also
    r = INT2PTR(regex_t *, SvUV(*(hv_fetch(me, regpk, regpk_len, 0))) );

    err = regexec(r, string, 0, (regmatch_t *) NULL, opts); // | REG_NOSUB); // TODO: can't NOSUB here, that goes to regcomp!!

    if( err == REG_NOMATCH ) {
        RETVAL = 0;

    } else if( err ) {
        regerror(err, r, (char *)errmsg, 250); // 255 or 256?  screw it, 250
        croak("error executing regular expression, %s\n", errmsg);

    } else {
        RETVAL = 1;
    }

    OUTPUT:
    RETVAL

AV*
regexec_wa(self,tomatch,opts)
    SV *self
    char *tomatch
    int opts;

	PREINIT:
    regex_t *r;
    HV* me;
    int err;
    char *errmsg[256];
    regmatch_t mat[10];
    int i,e,s;
    AV* retav = newAV();

    CODE:
    if( !sv_isobject(self) )
        croak("error trying to execute regular expression in an unblessed reference\n");

    me = (HV*) SvRV(self); // de-reference us
    if( SvTYPE(me) != SVt_PVHV )
        croak("error trying to execute regular expression in a blessed reference that isn't a hash reference\n");

    RETVAL = retav;

    // SV**  hv_fetch(HV*, const char* key, U32 klen, I32 lval); lval indicates whether this is part of a store operation also
    r = INT2PTR(regex_t *, SvUV(*(hv_fetch(me, regpk, regpk_len, 0))) );

    err = regexec(r, tomatch, 10, mat, opts);

    if( err == REG_NOMATCH ) {
        // twiddle baby

    } else if( err ) {
        regerror(err, r, (char *)errmsg, 250); // 255 or 256?  screw it, 250
        croak("error executing regular expression, %s", errmsg);

    } else {
        // find substrings and push them into retav
        for(i=0; i<10; i++) {
            s = mat[i].rm_so;
            e = mat[i].rm_eo;

            if( s==-1 || e==-1 ) {
                break;

            } else {
                av_push(retav, newSVpvn(tomatch+s, e-s));
            }
        }
    }

    OUTPUT:
    RETVAL

SV*
re_nsub(self)
    SV   *self
    PREINIT:
    regex_t *r;
    HV* me;

    CODE:
    if( !sv_isobject(self) )
        croak("error trying to execute regular expression in an unblessed reference");

    me = (HV*) SvRV(self); // de-reference us
    if( SvTYPE(me) != SVt_PVHV )
        croak("error trying to execute regular expression in a blessed reference that isn't a hash reference");

    r = INT2PTR(regex_t *, SvUV(*(hv_fetch(me, regpk, regpk_len, 0))) );

    ST(0) = sv_newmortal();
    sv_setnv( ST(0), r->re_nsub );

