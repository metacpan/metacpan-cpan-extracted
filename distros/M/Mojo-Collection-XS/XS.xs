#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Mojo::Collection::XS    PACKAGE = Mojo::Collection::XS

SV *
while_fast(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("Mojo::Collection::XS->while_fast: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("Mojo::Collection::XS->while_fast: callback must be a CODE ref");

    AV *av     = (AV *)SvRV(self);
    SSize_t max = AvFILL(av); /* -1 if empty */

    if (max >= 0) {
      dSP;

      ENTER;
      SAVETMPS;
      SAVE_DEFSV;

      SV *num_sv = sv_2mortal(newSViv(0)); /* reusable index SV */
      SV **items = AvARRAY(av);

      for (SSize_t idx = 0, num = 1; idx <= max; idx++, num++) {
        SV *item = items[idx];
        if (!item) continue;

        DEFSV = item;            /* alias to element */
        sv_setiv(num_sv, num);

        PUSHMARK(SP);
        XPUSHs(item);
        XPUSHs(num_sv);
        PUTBACK;

        call_sv(SvRV(cb), G_VOID | G_DISCARD);
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
while_pure_fast(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("Mojo::Collection::XS->while_pure_fast: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("Mojo::Collection::XS->while_pure_fast: callback must be a CODE ref");

    AV *av     = (AV *)SvRV(self);
    SSize_t max = AvFILL(av);

    if (max >= 0) {
      dSP;

      ENTER;
      SAVETMPS;

      SV *num_sv = sv_2mortal(newSViv(0)); /* reusable index SV */
      SV **items = AvARRAY(av);

      for (SSize_t idx = 0, num = 1; idx <= max; idx++, num++) {
        SV *item = items[idx];
        if (!item) continue;

        sv_setiv(num_sv, num);

        PUSHMARK(SP);
        XPUSHs(item);
        XPUSHs(num_sv);
        PUTBACK;

        call_sv(SvRV(cb), G_VOID | G_DISCARD);
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
each_fast(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("Mojo::Collection::XS->each_fast: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("Mojo::Collection::XS->each_fast: callback must be a CODE ref");

    AV *av     = (AV *)SvRV(self);
    SSize_t max = AvFILL(av);

    if (max >= 0) {
      dSP;

      ENTER;
      SAVETMPS;
      SAVE_DEFSV;

      SV *num_sv = sv_2mortal(newSViv(0)); /* reusable index SV */
      SV **items = AvARRAY(av);

      for (SSize_t idx = 0, num = 1; idx <= max; idx++, num++) {
        SV *item = items[idx];
        if (!item) continue;

        DEFSV = item;            /* alias to element */
        sv_setiv(num_sv, num);

        PUSHMARK(SP);
        XPUSHs(item);
        XPUSHs(num_sv);
        PUTBACK;

        call_sv(SvRV(cb), G_VOID | G_DISCARD);
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
map_pure_fast(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("Mojo::Collection::XS->map_pure_fast: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("Mojo::Collection::XS->map_pure_fast: callback must be a CODE ref");

    AV *av     = (AV *)SvRV(self);
    SSize_t max = AvFILL(av);

    AV *out_av = newAV();
    SV *ret_rv = newRV_noinc((SV *)out_av);
    sv_bless(ret_rv, SvSTASH(SvRV(self)));

    if (max >= 0) {
      dSP;

      ENTER;
      SAVETMPS;

      SV *num_sv = sv_2mortal(newSViv(0)); /* reusable index SV */
      SV **items = AvARRAY(av);

      for (SSize_t idx = 0, num = 1; idx <= max; idx++, num++) {
        SV *item = items[idx];
        if (!item) continue;

        sv_setiv(num_sv, num);

        PUSHMARK(SP);
        XPUSHs(item);
        XPUSHs(num_sv);
        PUTBACK;

        I32 count = call_sv(SvRV(cb), G_SCALAR);
        SPAGAIN;

        if (count > 0) {
          SV *ret = POPs;
          if (ret)
            av_push(out_av, newSVsv(ret));
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
map_fast(self, cb)
    SV *self
    SV *cb
  CODE:
  {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
      croak("Mojo::Collection::XS->map_fast: self is not an arrayref");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
      croak("Mojo::Collection::XS->map_fast: callback must be a CODE ref");

    AV *av     = (AV *)SvRV(self);
    SSize_t max = AvFILL(av);

    AV *out_av = newAV();
    SV *ret_rv = newRV_noinc((SV *)out_av);
    sv_bless(ret_rv, SvSTASH(SvRV(self)));

    if (max >= 0) {
      dSP;

      ENTER;
      SAVETMPS;
      SAVE_DEFSV;

      SV *num_sv = sv_2mortal(newSViv(0)); /* reusable index SV */
      SV **items = AvARRAY(av);

      for (SSize_t idx = 0, num = 1; idx <= max; idx++, num++) {
        SV *item = items[idx];
        if (!item) continue;

        DEFSV = item;            /* alias to element */
        sv_setiv(num_sv, num);

        PUSHMARK(SP);
        XPUSHs(item);
        XPUSHs(num_sv);
        PUTBACK;

        I32 count = call_sv(SvRV(cb), G_ARRAY);
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

    AV *av     = (AV *)SvRV(self);
    SSize_t max = AvFILL(av);

    AV *out_av = newAV();
    SV *ret_rv = newRV_noinc((SV *)out_av);
    sv_bless(ret_rv, SvSTASH(SvRV(self)));

    if (max >= 0) {
      dSP;

      ENTER;
      SAVETMPS;
      SAVE_DEFSV;

      SV *num_sv = sv_2mortal(newSViv(0)); /* reusable index SV */
      SV **items = AvARRAY(av);

      for (SSize_t idx = 0, num = 1; idx <= max; idx++, num++) {
        SV *item = items[idx];
        if (!item) continue;

        DEFSV = item;            /* alias to element */
        sv_setiv(num_sv, num);

        PUSHMARK(SP);
        XPUSHs(item);
        XPUSHs(num_sv);
        PUTBACK;

        I32 count = call_sv(SvRV(cb), G_SCALAR);
        SPAGAIN;

        SV *decision = (count > 0) ? POPs : NULL;
        if (decision && SvTRUE(decision)) {
          av_push(out_av, newSVsv(item));
        }
      }

      FREETMPS;
      LEAVE;
    }

    RETVAL = ret_rv;
  }
  OUTPUT:
    RETVAL
