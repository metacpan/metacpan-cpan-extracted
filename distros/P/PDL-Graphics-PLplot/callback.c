#include "EXTERN.h"
#include "perl.h"
#include "pdl.h"
#include "pdlcore.h"

#define PDL PDL_Graphics_PLplot
extern Core *PDL;

#include <plplot.h>
#include <plplotP.h>
#include <plevent.h>

#define MAKE_SETTABLE(label) \
  static SV* label ## _subroutine; \
  void label ## _callback_set(SV* sv, char *errmsg) { \
    if (SvTRUE(sv) && (! SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVCV)) \
      croak("%s", errmsg); \
    label ## _subroutine = sv; \
  }

MAKE_SETTABLE(pltr)

static IV pltr0_iv;
static IV pltr1_iv;
static IV pltr2_iv;
void pltr_iv_set(IV iv0, IV iv1, IV iv2) {
  pltr0_iv = iv0;
  pltr1_iv = iv1;
  pltr2_iv = iv2;
}

void pltr_callback(PLFLT x, PLFLT y, PLFLT* tx, PLFLT* ty, PLPointer pltr_data)
{
  I32 count;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVnv((double) x)));
  XPUSHs(sv_2mortal(newSVnv((double) y)));
  XPUSHs((SV*) pltr_data);
  PUTBACK;

  count = call_sv(pltr_subroutine, G_ARRAY);

  SPAGAIN;

  if (count != 2)
    croak("pltr: must return two scalars");

  *ty = (PLFLT) POPn;
  *tx = (PLFLT) POPn;

  PUTBACK;
  FREETMPS;
  LEAVE;
}

void* get_standard_pltrcb(SV* cb)
{
  if ( !SvROK(cb) ) return NULL; /* Added to prevent bug in plshades for 0 input. D. Hunt 12/18/2008 */
  IV sub = (IV) SvRV (cb);

  if (sub == pltr0_iv)
    return (void*) pltr0;
  else if (sub == pltr1_iv)
    return (void*) pltr1;
  else if (sub == pltr2_iv)
    return (void*) pltr2;
  else
    return SvTRUE(cb) ? (void*) pltr_callback : NULL;
}

MAKE_SETTABLE(defined)
PLINT defined_callback(PLFLT x, PLFLT y)
{
  I32 count, retval;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVnv((double) x)));
  XPUSHs(sv_2mortal(newSVnv((double) y)));
  PUTBACK;

  count = call_sv(defined_subroutine, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("defined: must return one scalar");

  retval = POPi;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return retval;
}

MAKE_SETTABLE(mapform)

void default_magic(pdl *p, size_t pa) { p->data = 0; }

void mapform_callback(PLINT n, PLFLT* x, PLFLT* y)
{
  pdl *x_pdl, *y_pdl;
  PLFLT *tx, *ty;
  SV *x_sv, *y_sv;
#if defined(PDL_CORE_VERSION) && PDL_CORE_VERSION >= 10
  PDL_Indx dims, i;
#else
  int dims, i;
#endif
  I32 count, ax;
  dSP;

  ENTER;
  SAVETMPS;

  dims = n;

  x_pdl = PDL->pdlnew();
  PDL->add_deletedata_magic(x_pdl, default_magic, 0);
  PDL->setdims(x_pdl, &dims, 1);
  x_pdl->datatype = PDL_D;
  x_pdl->data = x;
  x_pdl->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
  x_sv = sv_newmortal();
  PDL->SetSV_PDL(x_sv, x_pdl);

  y_pdl = PDL->pdlnew();
  PDL->add_deletedata_magic(y_pdl, default_magic, 0);
  PDL->setdims(y_pdl, &dims, 1);
  y_pdl->datatype = PDL_D;
  y_pdl->data = y;
  y_pdl->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
  y_sv = sv_newmortal();
  PDL->SetSV_PDL(y_sv, y_pdl);

  PUSHMARK(SP);
  XPUSHs(x_sv);
  XPUSHs(y_sv);
  PUTBACK;

  count = call_sv(mapform_subroutine, G_ARRAY);

  SPAGAIN;
  SP -= count ;
  ax = (SP - PL_stack_base) + 1;

  if (count != 2)
    croak("mapform: must return two ndarrays");

  tx = (PLFLT*) ((PDL->SvPDLV(ST(0)))->data);
  ty = (PLFLT*) ((PDL->SvPDLV(ST(1)))->data);

  for (i = 0; i < n; i++) {
    *(x + i) = *(tx + i);
    *(y + i) = *(ty + i);
  }

  PUTBACK;
  FREETMPS;
  LEAVE;
}

// Subroutines for adding transforms via plstransform

MAKE_SETTABLE(xform)
void
xform_callback(PLFLT x, PLFLT y, PLFLT *xt, PLFLT *yt, PLPointer data)
{
  SV *x_sv, *y_sv; // Perl scalars for the input x and y
  I32 count, ax;
  dSP;

  ENTER;
  SAVETMPS;

  x_sv = newSVnv((double)x);
  y_sv = newSVnv((double)y);

  PUSHMARK(SP);
  XPUSHs(x_sv);
  XPUSHs(y_sv);
  XPUSHs(data);
  PUTBACK;

  count = call_sv(xform_subroutine, G_ARRAY);

  SPAGAIN;
  SP -= count ;
  ax = (SP - PL_stack_base) + 1;

  if (count != 2)
    croak("xform: must return two perl scalars");

  *xt = (PLFLT) SvNV(ST(0));
  *yt = (PLFLT) SvNV(ST(1));

  PUTBACK;
  FREETMPS;
  LEAVE;
}

// Subroutines for adding label formatting via plslabelfunc
MAKE_SETTABLE(labelfunc)
void labelfunc_callback(PLINT axis, PLFLT value, char *label_text, PLINT length, void *data)
{
  SV *axis_sv, *value_sv, *length_sv; // Perl scalars for inputs
  I32 count, ax;
  dSP;

  ENTER;
  SAVETMPS;

  axis_sv   = newSViv((IV)axis);
  value_sv  = newSVnv((double)value);
  length_sv = newSViv((IV)length);

  PUSHMARK(SP);
  XPUSHs(axis_sv);
  XPUSHs(value_sv);
  XPUSHs(length_sv);
  PUTBACK;

  count = call_sv(labelfunc_subroutine, G_ARRAY);

  SPAGAIN;
  SP -= count ;
  ax = (SP - PL_stack_base) + 1;

  if (count != 1)
    croak("labelfunc: must return one perl scalar");

  // Copy label into output string
  strncpy( label_text, (char *)SvPV_nolen(ST(0)), length-1 );
  label_text[length-1] = '\0';

  PUTBACK;
  FREETMPS;
  LEAVE;
}
