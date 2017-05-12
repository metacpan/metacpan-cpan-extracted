#include "xshelper.h"

static void
setup_sigset(pTHX_ sigset_t* const sigmask, SV* const arg) {
    SvGETMAGIC(arg);
#if PERL_BCDVERSION > 0x5015002
    if( sv_isobject(arg) && sv_derived_from(arg, "POSIX::SigSet") && SvPOK(SvRV(arg)) ) {
        *sigmask = *(sigset_t*)SvPV_nolen(SvRV(arg));
#else
    if( sv_isobject(arg) && sv_derived_from(arg, "POSIX::SigSet") && SvIOK(SvRV(arg)) ) {
        *sigmask = *(sigset_t*)SvIV( SvRV(arg) );
#endif
    }
    else if(SvOK(arg)) {
        if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
            AV* const av  = (AV*)SvRV(arg);
            I32 const len = av_len(av) + 1;
            I32 i;

            sigemptyset(sigmask);

            for(i = 0; i < len; i++) {
                SV** const svp = av_fetch(av, i, FALSE);
                if(svp) {
                    if(looks_like_number(*svp)) {
                        sigaddset(sigmask, (int)SvIV(*svp));
                    }
                    else {
                        int signum;
                        STRLEN len;
                        const char* name = SvPV_const(*svp, len);
                        if(len > 3 && strncmp(name, "SIG", 3) == 0) {
                            name += 3;
                        }
                        signum = whichsig( (char*)name);
                        if(signum < 0) {
                            if(ckWARN( packWARN(WARN_MISC) )) {
                                warner(packWARN(WARN_MISC),
                                    "POSIX::pselect: unrecognized signal name \"%s\"", name);
                            }
                        }
                        else {
                            sigaddset(sigmask, signum);
                        }
                    }
                }
            }
        }
        else {
            croak("POSIX::pselect: sigset must be an ARRAY reference or POSIX::SigSet object");
        }
    }
}

/* stolen from pp_sselect() at pp_sys.c */
static
XS(XS_POSIX__pselect)
{
    dVAR; dXSARGS; dXSTARG;
    I32 i;
    I32 j;
    char *s;
    SV *sv;
    NV value;
    I32 maxlen = 0;
    I32 nfound;
    struct timespec timebuf;
    struct timespec *tbuf = &timebuf;
    sigset_t sigmask;
    I32 growsize;
    char *fd_sets[4];
#if BYTEORDER != 0x1234 && BYTEORDER != 0x12345678
    I32 masksize;
    I32 offset;
    I32 k;

#   if BYTEORDER & 0xf0000
#        define ORDERBYTE (0x88888888 - BYTEORDER)
#   else
#        define ORDERBYTE (0x4444 - BYTEORDER)
#   endif

#endif

    if (items != 5)
       croak("Usage: pselect(rfdset, wfdset, efdset, timeout, sigmask)");

    SP -= 5; /* r, w, e, timeout, sigset */
    for (i = 1; i <= 3; i++) {
        SV * const sv = SP[i];
        if (!SvOK(sv))
            continue;
        if (SvREADONLY(sv)) {
            if (SvIsCOW(sv))
                sv_force_normal_flags(sv, 0);
            if (SvREADONLY(sv) && !(SvPOK(sv) && SvCUR(sv) == 0))
                croak("%s", PL_no_modify);
        }
        if (!SvPOK(sv)) {
            if(ckWARN( packWARN(WARN_MISC) )) {
                warner(packWARN(WARN_MISC),
                    "POSIX::pselect: Non-string passed as bitmask");
            }
            SvPV_force_nolen(sv);        /* force string conversion */
        }
        j = SvCUR(sv);
        if (maxlen < j)
            maxlen = j;
    }

/* little endians can use vecs directly */
#if BYTEORDER != 0x1234 && BYTEORDER != 0x12345678
#  ifdef NFDBITS

#    ifndef NBBY
#     define NBBY 8
#    endif

    masksize = NFDBITS / NBBY;
#  else
    masksize = sizeof(long);        /* documented int, everyone seems to use long */
#  endif
    Zero(&fd_sets[0], 4, char*);
#endif

#  if SELECT_MIN_BITS == 1
    growsize = sizeof(fd_set);
#  else
#   if defined(__GLIBC__) && defined(__FD_SETSIZE)
#      undef SELECT_MIN_BITS
#      define SELECT_MIN_BITS __FD_SETSIZE
#   endif
    /* If SELECT_MIN_BITS is greater than one we most probably will want
     * to align the sizes with SELECT_MIN_BITS/8 because for example
     * in many little-endian (Intel, Alpha) systems (Linux, OS/2, Digital
     * UNIX, Solaris, NeXT, Darwin) the smallest quantum select() operates
     * on (sets/tests/clears bits) is 32 bits.  */
    growsize = maxlen + (SELECT_MIN_BITS/8 - (maxlen % (SELECT_MIN_BITS/8)));
#  endif

    sv = SP[4];
    if (SvOK(sv)) {
        value = SvNV(sv);
        if (value < 0.0)
            value = 0.0;
        timebuf.tv_sec = (long)value;
        value -= (NV)timebuf.tv_sec;
        timebuf.tv_nsec = (long)(value * 1000000000.0);
        //timebuf.tv_usec = (long)(value * 1000000.0);
    }
    else
        tbuf = NULL;

    setup_sigset(aTHX_ &sigmask, SP[5]);

    for (i = 1; i <= 3; i++) {
        sv = SP[i];
        if (!SvOK(sv) || SvCUR(sv) == 0) {
            fd_sets[i] = 0;
            continue;
        }
        assert(SvPOK(sv));
        j = SvLEN(sv);
        if (j < growsize) {
            Sv_Grow(sv, growsize);
        }
        j = SvCUR(sv);
        s = SvPVX(sv) + j;
        while (++j <= growsize) {
            *s++ = '\0';
        }

#if BYTEORDER != 0x1234 && BYTEORDER != 0x12345678
        s = SvPVX(sv);
        Newx(fd_sets[i], growsize, char);
        for (offset = 0; offset < growsize; offset += masksize) {
            for (j = 0, k=ORDERBYTE; j < masksize; j++, (k >>= 4))
                fd_sets[i][j+offset] = s[(k % masksize) + offset];
        }
#else
        fd_sets[i] = SvPVX(sv);
#endif
    }

    nfound = pselect(
        maxlen * 8,
        (fd_set*) fd_sets[1],
        (fd_set*) fd_sets[2],
        (fd_set*) fd_sets[3],
        tbuf, &sigmask);

    for (i = 1; i <= 3; i++) {
        if (fd_sets[i]) {
            sv = SP[i];
#if BYTEORDER != 0x1234 && BYTEORDER != 0x12345678
            s = SvPVX(sv);
            for (offset = 0; offset < growsize; offset += masksize) {
                for (j = 0, k=ORDERBYTE; j < masksize; j++, (k >>= 4))
                    s[(k % masksize) + offset] = fd_sets[i][j+offset];
            }
            Safefree(fd_sets[i]);
#endif
            SvSETMAGIC(sv);
        }
    }

    PUSHi(nfound);
    if (GIMME == G_ARRAY && tbuf) {
        value = (NV)(timebuf.tv_sec) +
                (NV)(timebuf.tv_nsec) / 1000000000.0;
        mPUSHn(value);
    }
    PUTBACK;
}


MODULE = POSIX::pselect    PACKAGE = POSIX::pselect

PROTOTYPES: DISABLE

BOOT:
{
        newXS("POSIX::pselect::pselect",
            XS_POSIX__pselect, (char*)__FILE__);
}

