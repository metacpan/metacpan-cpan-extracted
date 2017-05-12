#ifndef PERL_RSTATS_MAIN_H
#define PERL_RSTATS_MAIN_H

/* Fix std::isnan problem in Windows */
#ifndef _isnan
#define _isnan isnan
#endif

#include <complex>

/* Perl headers */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* suppress error - Cent OS(symbol collisions) */
#undef init_tm
#undef do_open
#undef do_close
#ifdef ENTER
#undef ENTER
#endif

/* suppress error - Mac OS X(error: declaration of 'Perl___notused' has a different language linkage) */
#ifdef __cplusplus
#  define dNOOP (void)0
#else
#  define dNOOP extern int Perl___notused(void)
#endif

namespace Rstats {
  
  // Perl helper functions
  SV* pl_new_rv(SV*);
  SV* pl_new_sv_sv(SV*);
  SV* pl_new_sv_pv(const char*);
  SV* pl_new_sv_iv(IV);
  SV* pl_new_sv_nv(NV);
  AV* pl_new_av();
  SV* pl_new_avrv();
  HV* pl_new_hv();
  SV* pl_new_hvrv();
  SV* pl_deref(SV*);
  AV* pl_av_deref(SV*);
  HV* pl_hv_deref(SV*);
  SSize_t pl_av_len (AV*);
  SSize_t pl_av_len (SV*);
  SV* pl_av_fetch(AV*, SSize_t);
  SV* pl_av_fetch(SV*, SSize_t);
  bool pl_hv_exists(HV*, char*);
  bool pl_hv_exists(SV*, char*);
  SV* pl_hv_delete(HV*, char*);
  SV* pl_hv_delete(SV*, char*);
  SV* pl_hv_fetch(HV*, const char*);
  SV* pl_hv_fetch(SV*, const char*);
  SSize_t pl_hv_key_count(HV* hv);
  SSize_t pl_hv_key_count(SV* hv_ref);
  void pl_av_store(AV*, SSize_t, SV*);
  void pl_av_store(SV*, SSize_t, SV*);
  SV* pl_av_copy(SV*);
  SV** pl_hv_store(HV*, const char*, SV*);
  SV** pl_hv_store(SV*, const char* key, SV*);
  void pl_av_push(AV*, SV*);
  void pl_av_push(SV*, SV*);
  SV* pl_av_pop(AV*);
  SV* pl_av_pop(SV*);
  void pl_av_unshift(AV*, SV*);
  void pl_av_unshift(SV*, SV*);
  SV* pl_sv_bless(SV*, const char*);
  REGEXP* pl_pregcomp (SV*, IV);
  IV pl_pregexec(SV*, REGEXP*);
  
  template <class T> T pl_object_unwrap(SV*, const char*);
  template <class T> SV* pl_object_wrap(T ptr, const char*);
  
  // Type
  namespace Type {
    enum Enum {
      LOGICAL = 0,
      INTEGER = 1 ,
      DOUBLE = 2,
      COMPLEX = 3,
      CHARACTER = 4
    };
  }

  // Rstats type
  typedef SV* Character;
  typedef std::complex<NV> Complex;
  typedef NV Double;
  typedef IV Integer;
  typedef UV Logical;// 0 or 1
  typedef UV NaPosition;
  
  // Error constant value
  const Rstats::Integer WARN_NA_INTRODUCED = 1;
  const Rstats::Integer WARN_NAN_PRODUCED = 2;
  const Rstats::Integer WARN_IMAGINARY_PART_DISCARDED = 4;

  const Rstats::Integer NaException = 1;
  const Rstats::Integer NA_POSITION_BIT_LENGTH = 8 * sizeof(Rstats::NaPosition);

  char* get_warn_message();
  void print_warn_message();
  void clear_warn();
  void add_warn(Rstats::Integer warn_id);
  Rstats::Integer get_warn();
}
# include "Rstats_Main_impl.h"

#endif
