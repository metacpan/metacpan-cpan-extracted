#include "Rstats_Main.h"

// Rstats
namespace Rstats {

  static Rstats::Integer WARN = 0;

  REGEXP* pl_pregcomp (SV* sv_re, IV flag) {
    return (REGEXP*)sv_2mortal((SV*)pregcomp(sv_re, flag));
  }

  SV* pl_new_rv(SV* sv) {
    return sv_2mortal(newRV_inc(sv));
  }

  SV* pl_new_sv_sv(SV* sv) {
    return sv_2mortal(newSVsv(sv));
  }

  SV* pl_new_sv_pv(const char* pv) {
    return sv_2mortal(newSVpvn(pv, strlen(pv)));
  }
      
  SV* pl_new_sv_iv(IV iv) {
    return sv_2mortal(newSViv(iv));
  }
  
  SV* pl_new_sv_nv(NV nv) {
    return sv_2mortal(newSVnv(nv));
  }

  AV* pl_new_av() {
    return (AV*)sv_2mortal((SV*)newAV());
  }

  SV* pl_new_avrv() {
    return sv_2mortal(newRV_inc((SV*)pl_new_av()));
  }

  HV* pl_new_hv() {
    return (HV*)sv_2mortal((SV*)newHV());
  }

  SV* pl_new_hvrv() {
    return sv_2mortal(newRV_inc((SV*)pl_new_hv()));
  }

  SV* pl_deref(SV* ref) {
    if (SvROK(ref)) {
      return SvRV(ref);
    }
    else {
      croak("Can't derefernce");
    }
  }

  AV* pl_av_deref(SV* ref) {
    return (AV*)pl_deref(ref);
  }

  HV* pl_hv_deref(SV* ref) {
    return (HV*)pl_deref(ref);
  }

  SSize_t pl_av_len (AV* av) {
    return av_len(av) + 1;
  }

  SSize_t pl_av_len (SV* av_ref) {
    return av_len((AV*)pl_deref(av_ref)) + 1;
  }

  SV* pl_av_fetch(AV* av, SSize_t pos) {
    SV** const element_ptr = av_fetch(av, pos, FALSE);
    SV* const element = element_ptr ? *element_ptr : &PL_sv_undef;
    
    return element;
  }

  SV* pl_av_fetch(SV* av_ref, SSize_t pos) {
    AV* av = (AV*)pl_deref(av_ref);
    return pl_av_fetch(av, pos);
  }

  bool pl_hv_exists(HV* hv_hash, char* key) {
    return hv_exists(hv_hash, key, strlen(key));
  }

  bool pl_hv_exists(SV* sv_hash_ref, char* key) {
    return hv_exists(pl_hv_deref(sv_hash_ref), key, strlen(key));
  }

  SV* pl_hv_delete(HV* hv_hash, char* key) {
    return hv_delete(hv_hash, key, strlen(key), 0);
  }

  SV* pl_hv_delete(SV* sv_hash_ref, char* key) {
    return hv_delete(pl_hv_deref(sv_hash_ref), key, strlen(key), 0);
  }

  SV* pl_hv_fetch(HV* hv, const char* key) {
    SV** const element_ptr = hv_fetch(hv, key, strlen(key), FALSE);
    SV* const element = element_ptr ? *element_ptr : &PL_sv_undef;
    
    return element;
  }

  SV* pl_hv_fetch(SV* hv_ref, const char* key) {
    HV* hv = pl_hv_deref(hv_ref);
    return pl_hv_fetch(hv, key);
  }

  void pl_av_store(AV* av, SSize_t pos, SV* element) {
    av_store(av, pos, SvREFCNT_inc(element));
  }

  void pl_av_store(SV* av_ref, SSize_t pos, SV* element) {
    AV* av = pl_av_deref(av_ref);
    pl_av_store(av, pos, element);
  }

  SV* pl_av_copy(SV* sv_av_ref) {
    SV* sv_new_av_ref = pl_new_avrv();
    
    for (SSize_t i = 0; i < pl_av_len(sv_av_ref); i++) {
      pl_av_store(sv_new_av_ref, i, pl_new_sv_sv(pl_av_fetch(sv_av_ref, i)));
    }
    
    return sv_new_av_ref;
  }

  SV** pl_hv_store(HV* hv, const char* key, SV* element) {
    SV** ret = hv_store(hv, key, strlen(key), SvREFCNT_inc(element), FALSE);
    if (ret == NULL) {
      SvREFCNT_dec(element);
    }
    return ret;
  }

  SV** pl_hv_store(SV* hv_ref, const char* key, SV* element) {
    HV* hv = pl_hv_deref(hv_ref);
    return pl_hv_store(hv, key, element);
  }

  SSize_t pl_hv_key_count(HV* hv) {
    hv_iterinit(hv);
    
    SSize_t count = 0;
    while (1) {
      HE* he_iter = hv_iternext(hv);
      if (he_iter == NULL) {
        break;
      }
      else {
        count++;
      }
    }
    
    return count;
  }

  SSize_t pl_hv_key_count(SV* hv_ref) {
    HV* hv = pl_hv_deref(hv_ref);
    return pl_hv_key_count(hv);
  }

  void pl_av_push(AV* av, SV* sv) {
    av_push(av, SvREFCNT_inc(sv));
  }

  void pl_av_push(SV* av_ref, SV* sv) {
    return pl_av_push(pl_av_deref(av_ref), sv);
  }

  SV* pl_av_pop(AV* av_array) {
    return av_pop(av_array);
  }

  SV* pl_av_pop(SV* sv_array_ref) {
    return av_pop(pl_av_deref(sv_array_ref));
  }

  void pl_av_unshift(AV* av, SV* sv) {
    av_unshift(av, 1);
    pl_av_store(av, (IV)0, SvREFCNT_inc(sv));
  }

  void pl_av_unshift(SV* av_ref, SV* sv) {
    av_unshift((AV*)pl_deref(av_ref), 1);
    pl_av_store((AV*)pl_deref(av_ref), 0, SvREFCNT_inc(sv));
  }

  SV* pl_sv_bless(SV* sv_data, const char* class_name) {
    return sv_bless(sv_data, gv_stashpv(class_name, 1));
  }

  IV pl_pregexec(SV* sv_str, REGEXP* sv_re) {
    char* str = SvPV_nolen(sv_str);
    
    IV ret = pregexec(
      sv_re,
      str,
      str + strlen(str),
      str,
      0,
      sv_str,
      1
    );
    
    return ret;
  }

  void clear_warn() {
    WARN = 0;
  }
  void add_warn(Rstats::Integer warn_id) {
    WARN |= warn_id;
  }
  
  Rstats::Integer get_warn() {
    return WARN;
  }
  
  char* get_warn_message() {
    if (Rstats::get_warn()) {
      SV* sv_warn = Rstats::pl_new_sv_pv("Warning message:\n");
      if (WARN & Rstats::WARN_NAN_PRODUCED) {
        sv_catpv(sv_warn, "NaNs produced\n");
      }
      if (WARN & Rstats::WARN_IMAGINARY_PART_DISCARDED) {
        sv_catpv(sv_warn, "imaginary parts discarded in coercion\n");
      }
      if (WARN & Rstats::WARN_NA_INTRODUCED) {
        sv_catpv(sv_warn, "NAs introduced by coercion\n");
      }        
      return SvPV_nolen(sv_warn);
    }
    else {
      return "Unexpected warning";
    }
  }
  
  void print_warn_message() {
    warn(Rstats::get_warn_message());
  }
}
