/* ex: set sw=4 et: */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#include "ppport.h"

#ifndef AvREIFY_only
#define AvREIFY_only(av)	(AvREAL_off(av), AvREIFY_on(av))
#endif

#include "hook_op_check_entersubforcv.h"

STATIC OP * error_op (pTHX) {
    croak("panic: tail call modifier called as subroutine");
}


STATIC OP *
goto_entersub (pTHX) {
    dVAR; dSP; dMARK; dPOPss;
    GV *gv;
    CV *cv;
    AV *av;
    IV items = SP - MARK;
    IV cxix = cxstack_ix;
    PERL_CONTEXT *cx = NULL;

    while ( cxix > 0 ) {
        if ( CxTYPE(&cxstack[cxix]) == CXt_SUB ) {
            cx = &cxstack[cxix];
            break;
        } else {
            cxix--;
        }
    }
    
    if (cx == NULL)
        DIE(aTHX_ "Can't goto subroutine outside a subroutine");

    /* this first steaming hunk of cargo cult is copypasted from entersub...
     * it's pretty the original but the ENTER/LEAVE or the actual execution */

    if (!sv)
        DIE(aTHX_ "Not a CODE reference");    

    switch (SvTYPE(sv)) {
        /* This is overwhelming the most common case:  */
        case SVt_PVGV:
            if (!isGV_with_GP(sv))
                DIE(aTHX_ "Not a CODE reference");
            if (!(cv = GvCVu((const GV *)sv))) {
                HV *stash;
                cv = sv_2cv(sv, &stash, &gv, 0);
            }
            if (!cv) {
                goto try_autoload;
            }
            break;
        default:
            if (!SvROK(sv)) {
                const char *sym;
                STRLEN len;
                if (SvGMAGICAL(sv)) {
                    mg_get(sv);
                    if (SvROK(sv))
                        goto got_rv;
                    if (SvPOKp(sv)) {
                        sym = SvPVX_const(sv);
                        len = SvCUR(sv);
                    } else {
                        sym = NULL;
                        len = 0;
                    }
                }
                else {
                    sym = SvPV_const(sv, len);
                }
                if (!sym)
                    DIE(aTHX_ PL_no_usym, "a subroutine");
                if (PL_op->op_private & HINT_STRICT_REFS)
                    DIE(aTHX_ "Can't use string (\"%.32s\") as %s ref while \"strict refs\" in use",
                        sym, "a subroutine");
                cv = get_cv(sym, GV_ADD|SvUTF8(sv));
                break;
            }
got_rv:
            {
                SV * const * sp = &sv;          /* Used in tryAMAGICunDEREF macro. */
                tryAMAGICunDEREF(to_cv);
            }
            cv = (CV *)SvRV(sv);
            if (SvTYPE(cv) == SVt_PVCV)
                break;
            /* FALL THROUGH */
        case SVt_PVHV:
        case SVt_PVAV:
            DIE(aTHX_ "Not a CODE reference");
            /* This is the second most common case:  */
        case SVt_PVCV:
            cv = (CV *)sv;
            break;
    }

retry:
    if (!CvROOT(cv) && !CvXSUB(cv)) {
        GV* autogv;
        SV* sub_name;

        /* anonymous or undef'd function leaves us no recourse */
        if (CvANON(cv) || !(gv = CvGV(cv)))
            DIE(aTHX_ "Undefined subroutine called");

        /* autoloaded stub? */
        if (cv != GvCV(gv)) {
            cv = GvCV(gv);
        }
        /* should call AUTOLOAD now? */
        else {
try_autoload:
            if ((autogv = gv_autoload4(GvSTASH(gv), GvNAME(gv), GvNAMELEN(gv),
                            FALSE)))
            {
                cv = GvCV(autogv);
            }
            /* sorry */
            else {
                sub_name = sv_newmortal();
                gv_efullname3(sub_name, gv, NULL);
                DIE(aTHX_ "Undefined subroutine &%"SVf" called", SVfARG(sub_name));
            }
        }
        if (!cv)
            DIE(aTHX_ "Not a CODE reference");
        goto retry;
    }


    /* this next steaming hunk of cargo cult is the code that sets up @_ in
     * entersub. We set it up so that defgv is pointing at the pushed args as
     * set up by the entersub call, this will let pp_goto work unmodified */

#if PERL_VERSION_GE(5,23,8)
    av = MUTABLE_AV(PAD_SVl(0));
#else
    av = cx->blk_sub.argarray;
#endif

    /* abandon @_ if it got reified */
    if (AvREAL(av)) {
        SvREFCNT_dec(av);
        av = newAV();
        AvREIFY_only(av);

#if PERL_VERSION_LT(5,23,8)
        cx->blk_sub.argarray = av;
#endif
        PAD_SVl(0) = (SV *)av;
    }

    if (GvAV(PL_defgv) != av) {
	AV *olddefav = GvAV(PL_defgv);
	SvREFCNT_inc((SV*)av);
	GvAV(PL_defgv) = av;
	SvREFCNT_dec((SV*)olddefav);
    }

    /* copy items from the stack to defgv */
    ++MARK;

    av_extend(av, items-1);

    Copy(MARK,AvARRAY(av),items,SV*);
    AvFILLp(av) = items - 1;

    while (MARK <= SP) {
        if (*MARK) {
            /* if we find a lexical (PADMY) or a TEMP it's probably from
             * the scope being destroyed, so we should reify @_ to increase
             * the refcnt (this is suboptimal for tail foo($_[0]) or
             * something but that's just a minor refcounting cost */

            if ( SvTEMP(*MARK) || SvPADMY(*MARK) ) {
                I32 key;

                key = AvMAX(av) + 1;
                while (key > AvFILLp(av) + 1)
                    AvARRAY(av)[--key] = &PL_sv_undef;
                while (key) {
                    SV * const sv = AvARRAY(av)[--key];
                    assert(sv);
                    if (sv != &PL_sv_undef)
                        SvREFCNT_inc_simple_void_NN(sv);
                }
                key = AvARRAY(av) - AvALLOC(av);
                while (key)
                    AvALLOC(av)[--key] = &PL_sv_undef;
                AvREIFY_off(av);
                AvREAL_on(av);

                break;
            }
        }
        MARK++;
    }

    SP -= items;

    /* finally, execute goto. goto uses a ref to the cv, and takes the args out
     * of the context stack frame */

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_inc((SV *)cv)));
    PUTBACK;

    return PL_ppaddr[OP_GOTO](aTHX);
}

STATIC OP *
convert_to_tailcall (pTHX_ OP *o, CV *cv, void *user_data) {
    /* find the nested entersub */
    UNOP *entersub = (UNOP *)OpSIBLING(((LISTOP *)cUNOPo->op_first)->op_first);

    if ( entersub->op_type != OP_ENTERSUB )
        croak("The tail call modifier must be applied to a subroutine or method invocation");

    if ( OpHAS_SIBLING(entersub) && OpHAS_SIBLING(OpSIBLING(entersub)) )
        croak("The tail call modifier must not be given additional arguments");

    if ( entersub->op_ppaddr == error_op )
        croak("The tail call modifier cannot be applied to itself");

    if ( entersub->op_ppaddr != PL_ppaddr[OP_ENTERSUB] )
        croak("The tail call modifier can only be applied to normal subroutine calls");

    if ( !(entersub->op_flags & OPf_STACKED) ) {
        OpMORESIB_set( ((LISTOP *)cUNOPo->op_first)->op_first, OpSIBLING(entersub) );
        OpMAYBESIB_set( entersub, NULL, NULL );
        op_free(o);
        entersub->op_private &= ~(OPpENTERSUB_INARGS|OPpENTERSUB_NOPAREN);
        return newLOOPEX(OP_GOTO, (OP*)entersub);
    }

    /* change the ppaddr of the inner entersub to become a custom goto op that
     * takes its args like entersub does */
    entersub->op_ppaddr = goto_entersub;
    o->op_ppaddr = error_op;

    /* the rest is unmodified, this code will not actually be run (except for
     * the pushmark), but allows deparsing etc to work correctly */
    return o;
}

MODULE = Sub::Call::Tail        PACKAGE = Sub::Call::Tail
PROTOTYPES: disable

BOOT:
{
    hook_op_check_entersubforcv(get_cv("Sub::Call::Tail::tail", TRUE), convert_to_tailcall, NULL);
}

