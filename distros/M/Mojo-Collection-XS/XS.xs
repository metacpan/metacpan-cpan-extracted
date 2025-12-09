#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef CVf_HAS_SIGNATURES
#  define CVf_HAS_SIGNATURES 0
#endif

MODULE = Mojo::Collection::XS    PACKAGE = Mojo::Collection::XS

SV *
while_fast(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("while_fast: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("while_fast: callback must be a CODE ref");

    AV     *av   = (AV *)SvRV(self);
    SSize_t max  = AvFILL(av);

    if (max >= 0) {
      dSP;

      CV  *cv    = (CV *)SvRV(cb);   /* hoisted */
      SV **items = AvARRAY(av);

      ENTER;
      SAVETMPS;
      SAVE_DEFSV;                     /* alias $_ */

      SV *idx_sv = sv_newmortal();

      for (SSize_t i = 0, num = 1; i <= max; i++, num++) {
        SV *e = items[i];
        if (!e) continue;

        DEFSV = e;                    /* $_ alias */
        sv_setiv(idx_sv, num);

        PUSHMARK(SP);
        XPUSHs(e);
        XPUSHs(idx_sv);
        PUTBACK;

        call_sv((SV *)cv, G_VOID | G_DISCARD);
        SPAGAIN;
      }

      FREETMPS;
      LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
  }
  OUTPUT: RETVAL

SV *
while_ultra(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("while_ultra: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("while_ultra: callback must be a CODE ref");

    AV     *av   = (AV *)SvRV(self);
    SSize_t max  = AvFILL(av);

    if (max >= 0) {
      dSP;

      CV  *cv    = (CV *)SvRV(cb);    /* hoist */
      SV **items = AvARRAY(av);

      ENTER;
      SAVETMPS;

      SV *idx_sv = sv_newmortal();

      for (SSize_t i = 0, num = 1; i <= max; i++, num++) {
        SV *e = items[i];
        if (!e) continue;

        sv_setiv(idx_sv, num);

        PUSHMARK(SP);
        XPUSHs(e);
        XPUSHs(idx_sv);
        PUTBACK;

        call_sv((SV *)cv, G_VOID | G_DISCARD);
        SPAGAIN;
      }

      FREETMPS;
      LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
  }
  OUTPUT: RETVAL

SV *
each_fast(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("Mojo::Collection::XS->each_fast: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("Mojo::Collection::XS->each_fast: callback must be a CODE ref");

    AV *av      = (AV *)SvRV(self);
    SSize_t max = AvFILL(av);

    if (max >= 0) {
      dSP;

      CV  *cv    = (CV *)SvRV(cb);   /* hoist sekali */
      SV **items = AvARRAY(av);

      ENTER;
      SAVETMPS;
      SAVE_DEFSV;

      SV *num_sv = sv_2mortal(newSViv(0)); /* reusable index SV */

      for (SSize_t idx = 0, num = 1; idx <= max; idx++, num++) {
        SV *item = items[idx];
        if (!item) continue;

        DEFSV = item;            /* alias to element */
        sv_setiv(num_sv, num);

        PUSHMARK(SP);
        XPUSHs(item);
        XPUSHs(num_sv);
        PUTBACK;

        call_sv((SV *)cv, G_VOID | G_DISCARD);
        SPAGAIN;
      }

      FREETMPS;
      LEAVE;
    }

    RETVAL = SvREFCNT_inc(self);
  }
  OUTPUT:
    RETVAL

SV *
map_ultra(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("map_ultra: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("map_ultra: callback must be a CODE ref");

    AV *av = (AV *)SvRV(self);
    SSize_t max = AvFILL(av);

    AV *out    = newAV();
    SV *out_rv = newRV_noinc((SV *)out);
    sv_bless(out_rv, SvSTASH(SvRV(self)));

    if (max >= 0) {
      dSP;

      CV  *cv    = (CV *)SvRV(cb);
      SV **items = AvARRAY(av);

      ENTER;
      SAVETMPS;
      av_extend(out, max);

      for (SSize_t i = 0; i <= max; i++) {
        SV *item = items[i];
        if (!item) continue;

        PUSHMARK(SP);
        XPUSHs(item);
        PUTBACK;

        I32 count = call_sv((SV *)cv, G_SCALAR);
        SPAGAIN;

        if (count > 0) {
          SV *ret = POPs;
          if (ret && ret != &PL_sv_undef) {
            av_push(out, SvTEMP(ret) ? newSVsv(ret) : SvREFCNT_inc(ret));
          }
          if (count > 1) SP -= (count - 1);
        }
      }

      FREETMPS;
      LEAVE;
    }

    RETVAL = out_rv;
  }
  OUTPUT:
    RETVAL

SV *
map_fast(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("Mojo::Collection::XS->map_fast: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("Mojo::Collection::XS->map_fast: callback must be a CODE ref");

    AV *av      = (AV *)SvRV(self);
    SSize_t max = AvFILL(av);

    AV *out_av = newAV();
    SV *ret_rv = newRV_noinc((SV *)out_av);
    sv_bless(ret_rv, SvSTASH(SvRV(self)));

    if (max >= 0) {
      dSP;

      CV  *cv    = (CV *)SvRV(cb);   /* hoist sekali */
      SV **items = AvARRAY(av);

      ENTER;
      SAVETMPS;
      SAVE_DEFSV;
      av_extend(out_av, max);

      for (SSize_t idx = 0; idx <= max; idx++) {
        SV *item = items[idx];
        if (!item) continue;

        DEFSV = item;            /* alias to element */

        PUSHMARK(SP);
        XPUSHs(item);
        PUTBACK;

        I32 count = call_sv((SV *)cv, G_ARRAY);
        SPAGAIN;

        if (count > 0) {
          SV **results = SP - count + 1; /* start of returned values */
          for (I32 i = 0; i < count; i++) {
            av_push(out_av, newSVsv(results[i]));
          }
          SP -= count;
        }
      }

      FREETMPS;
      LEAVE;
    }

    RETVAL = ret_rv;
  }
  OUTPUT:
    RETVAL

SV *
grep_fast(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("Mojo::Collection::XS->grep_fast: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("Mojo::Collection::XS->grep_fast: callback must be a CODE ref");

    AV *av      = (AV *)SvRV(self);
    SSize_t max = AvFILL(av);

    AV *out_av = newAV();
    SV *ret_rv = newRV_noinc((SV *)out_av);
    sv_bless(ret_rv, SvSTASH(SvRV(self)));

    if (max >= 0) {
      dSP;

      CV  *cv    = (CV *)SvRV(cb);
      SV **items = AvARRAY(av);

      ENTER;
      SAVETMPS;
      SAVE_DEFSV;                      /* karena kita set $_ */

      for (SSize_t idx = 0; idx <= max; idx++) {
        SV *item = items[idx];
        if (!item) continue;

        DEFSV = item;                 /* $_ = item */

        PUSHMARK(SP);
        XPUSHs(item);
        PUTBACK;

        I32 count = call_sv((SV *)cv, G_SCALAR);
        SPAGAIN;

        SV *decision = count > 0 ? POPs : &PL_sv_undef;
        if (count > 1) SP -= (count - 1);

        if (decision && SvTRUE(decision)) {
          /* tidak clone: persis referensi aslinya */
          av_push(out_av, SvREFCNT_inc(item));
        }
      }

      FREETMPS;
      LEAVE;
    }

    RETVAL = ret_rv;
  }
  OUTPUT:
    RETVAL
