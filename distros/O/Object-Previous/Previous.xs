#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef CxHASARGS
 #define CxHASARGS(cx) (cx->blk_sub.hasargs)
#endif

// Almost all the code from this .xs is ripped from perl5.8.8/pp_ctl.c
// It's slimmed down a bit, but that's where it all comes from.
// -Paul

I32 my_dopoptosub(const PERL_CONTEXT *cxstk, I32 startingblock) {
    I32 i;
    for(i=startingblock; i>=0; i--) {
        const PERL_CONTEXT * const cx = &cxstk[i];

        switch (CxTYPE(cx)) {
            case CXt_EVAL:
            case CXt_SUB:
            case CXt_FORMAT:
            return i;
        }
    }

    return i;
}

MODULE = Object::Previous PACKAGE = Object::Previous

SV*
previous_object_xs()

    PREINIT:
    register I32 cxix = my_dopoptosub(cxstack, cxstack_ix);
    register const PERL_CONTEXT *cx;
    register const PERL_CONTEXT *ccstack = cxstack;
    const PERL_SI *top_si = PL_curstackinfo;
    int count = 1; // this corresponds to the caller(2) from the previous_object_perl 

	CODE:
    RETVAL = newSV(0); // just return undef by default

    for (;;) {
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
            top_si = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = my_dopoptosub(ccstack, top_si->si_cxix);
        }

        if (cxix < 0)
            break;

        if (!count--)
            break;

        cxix = my_dopoptosub(ccstack, cxix - 1);
    }

    if( cxix >= 0 ) {
        char *stashname = CopSTASHPV(ccstack[cxix+1].blk_oldcop);
        cx = &ccstack[cxix];

        if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
            if( CxHASARGS(cx) ) {
                AV *ary = cx->blk_sub.argarray;
                int off = AvARRAY(ary) - AvALLOC(ary);
                AV *tmp = newAV();
                SV **obj;

                sv_2mortal((SV*)tmp);
                AvREAL_off(tmp);

                if (AvMAX(tmp) < AvFILLp(ary) + off)
                    av_extend(tmp, AvFILLp(ary) + off);

                Copy(AvALLOC(ary), AvARRAY(tmp), AvFILLp(ary) + 1 + off, SV*);
                AvFILLp(tmp) = AvFILLp(ary) + off;

                // TODO: I literally don't understand why we can't just
                // av_fetch(ary,0,0) and return that...  Sadly, the av_len(ary)
                // is -1, and you have to Copy() it to the tmp AV* in order to
                // get the real size of 1.  The offset is usually 2 I think...
                // perhaps that has something to do with it?  Beyond my skill
                // level...

                // warn("\e[31ml1=%d l2=%d off=%d\e[m", av_len(ary), av_len(tmp), off);

                if( obj = av_fetch(tmp, 0, 0) )
                    if( sv_isa(*obj, stashname) )
                        RETVAL = SvREFCNT_inc(*obj);
            }
        }
    }

    OUTPUT:
    RETVAL
