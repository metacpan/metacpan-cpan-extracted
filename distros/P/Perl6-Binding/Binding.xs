#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Stolen from Devel::LexAlias and Devel::Caller */
/* $Id: Binding.xs,v 1.0 2004/05/23 01:12:28 kevin Exp $ */

MODULE = Perl6::Binding		PACKAGE = Perl6::Binding		

void
_lexalias(SV* cv_ref, char *name, SV* new_rv)
  CODE:
{
    CV *cv   = SvROK(cv_ref) ? (CV*) SvRV(cv_ref) : NULL;
    AV* padn = cv ? (AV*) AvARRAY(CvPADLIST(cv))[0] : PL_comppad_name;
    AV* padv = cv ? (AV*) AvARRAY(CvPADLIST(cv))[CvDEPTH(cv)] : PL_comppad;
    SV* new_sv;
    I32 i;

    if (!SvROK(new_rv)) croak("ref is not a reference");
    new_sv = SvRV(new_rv);

    for (i = 0; i <= av_len(padn); ++i) {
        SV** name_ptr = av_fetch(padn, i, 0);
        if (name_ptr) {
            SV* name_sv = *name_ptr;
            
            if (SvPOKp(name_sv)) {
                char *name_str = SvPVX(name_sv);

                if (!strcmp(name, name_str)) {
                    SV* old_sv = (SV*) av_fetch(padv, i, 0);
                    av_store(padv, i, new_sv);
                    SvREFCNT_inc(new_sv);
                }
            }
        }
    }
}

SV*
_context_cv(context)
SV* context;
  CODE:
    PERL_CONTEXT *cx = (PERL_CONTEXT*) SvIV(context);
    CV *cur_cv;

    if (cx->cx_type != CXt_SUB)
        croak("cx_type is %d not CXt_SUB\n", cx->cx_type);

    cur_cv = cx->blk_sub.cv;
    if (!cur_cv)
        croak("Context has no CV!\n");

    RETVAL = (SV*) newRV_inc( (SV*) cur_cv );
  OUTPUT:
    RETVAL
