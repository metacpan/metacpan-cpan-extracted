#ifndef __SUSPENDED_COMPCV_H__
#define __SUSPENDED_COMPCV_H__

typedef struct {
  CV *compcv;
  STRLEN padix;
#ifdef PL_constpadix
  STRLEN constpadix;
#endif
  STRLEN comppad_name_fill, min_intro_pending, max_intro_pending;
  bool cv_has_eval, pad_reset_pending;
} SuspendedCompCVBuffer;

/* perl 5.37.9 defined a set of these but they will collide with ours. we
 * should keep ours separate for now
 */
#undef suspend_compcv
#undef resume_compcv
#undef resume_compcv_and_save

#define suspend_compcv(buffer)  MY_suspend_compcv(aTHX_ buffer)
void MY_suspend_compcv(pTHX_ SuspendedCompCVBuffer *buffer);

#define resume_compcv(buffer)  MY_resume_compcv(aTHX_ buffer, FALSE)
#define resume_compcv_and_save(buffer)  MY_resume_compcv(aTHX_ buffer, TRUE)
void MY_resume_compcv(pTHX_ SuspendedCompCVBuffer *buffer, bool save);

#endif
