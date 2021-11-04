/* vi: set ft=xs : */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "suspended_compcv.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#ifndef SAVESTRLEN
#  if HAVE_PERL_VERSION(5,26,0)
#    define SAVESTRLEN(i)  Perl_save_strlen(aTHX_ (STRLEN *)&(i))
#  else
     /* perls before 5.26.0 had no STRLEN and used simply I32 here */
#    define SAVESTRLEN(i)  SAVEI32(i)
#  endif
#endif

void MY_suspend_compcv(pTHX_ SuspendedCompCVBuffer *buffer)
{
  buffer->compcv = PL_compcv;

  buffer->padix             = PL_padix;
#ifdef PL_constpadix
  buffer->constpadix        = PL_constpadix;
#endif
  buffer->comppad_name_fill = PL_comppad_name_fill;
  buffer->min_intro_pending = PL_min_intro_pending;
  buffer->max_intro_pending = PL_max_intro_pending;

  buffer->cv_has_eval       = PL_cv_has_eval;
  buffer->pad_reset_pending = PL_pad_reset_pending;
}

void MY_resume_compcv(pTHX_ SuspendedCompCVBuffer *buffer, bool save)
{
  SAVESPTR(PL_compcv);
  PL_compcv = buffer->compcv;
  PAD_SET_CUR(CvPADLIST(PL_compcv), 1);

  SAVESPTR(PL_comppad_name);
  PL_comppad_name = PadlistNAMES(CvPADLIST(PL_compcv));

  SAVESTRLEN(PL_padix);             PL_padix             = buffer->padix;
#ifdef PL_constpadix
  SAVESTRLEN(PL_constpadix);        PL_constpadix        = buffer->constpadix;
#endif
  SAVESTRLEN(PL_comppad_name_fill); PL_comppad_name_fill = buffer->comppad_name_fill;
  SAVESTRLEN(PL_min_intro_pending); PL_min_intro_pending = buffer->min_intro_pending;
  SAVESTRLEN(PL_max_intro_pending); PL_max_intro_pending = buffer->max_intro_pending;

  SAVEBOOL(PL_cv_has_eval);
  PL_cv_has_eval = buffer->cv_has_eval;

  SAVEBOOL(PL_pad_reset_pending);
  PL_pad_reset_pending = buffer->pad_reset_pending;

  if(save)
    SAVEDESTRUCTOR_X(&MY_suspend_compcv, buffer);
}
