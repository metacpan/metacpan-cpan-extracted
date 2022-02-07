/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"

static SV *unassigned_val;

#ifndef mg_freeext
#  define mg_freeext(sv, how, vtbl)  S_mg_freeext(aTHX_ sv, how, vtbl)
static void S_mg_freeext(pTHX_ SV *sv, int how, const MGVTBL *vtbl)
{
  MAGIC *mg, *prevmg, *moremg;

  assert(how == PERL_MAGIC_ext);

  for(prevmg = NULL, mg = SvMAGIC(sv); mg; prevmg = mg, mg = moremg) {
    moremg = mg->mg_moremagic;
    if(mg->mg_type == how && mg->mg_virtual == vtbl) {
      if(prevmg) {
        prevmg->mg_moremagic = moremg;
      }
      else {
        SvMAGIC_set(sv, moremg);
      }

      /* mg_free_struct(sv, mg) */
      if(vtbl->svt_free)
        vtbl->svt_free(aTHX_ sv, mg);
      if(mg->mg_ptr) {
        if(mg->mg_len > 0)
          Safefree(mg->mg_ptr);
        else if(mg->mg_len == HEf_SVKEY)
          SvREFCNT_dec(MUTABLE_SV(mg->mg_ptr));
      }
      if(mg->mg_flags & MGf_REFCOUNTED)
        SvREFCNT_dec(mg->mg_obj);
    }
  }
}
#endif

static int magic_get(pTHX_ SV *sv, MAGIC *mg);
static int magic_set(pTHX_ SV *sv, MAGIC *mg);

static const MGVTBL vtbl = {
  .svt_get = &magic_get,
  .svt_set = &magic_set,
};

static int magic_get(pTHX_ SV *sv, MAGIC *mg)
{
  SV *self       = mg->mg_obj;
  SV *methodname = (SV *)mg->mg_ptr;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(self);
  PUTBACK;

  call_method(SvPV_nolen(methodname), G_SCALAR);

  SPAGAIN;

  SV *value = POPs;

  sv_setsv_nomg(sv, value);

  FREETMPS;
  LEAVE;

  /* Now disarm the magic so it won't run again */
  mg_freeext(sv, PERL_MAGIC_ext, &vtbl);

  return 1;
}

static int magic_set(pTHX_ SV *sv, MAGIC *mg)
{
  if(SvROK(sv) && SvRV(sv) == unassigned_val)
    /* This is just the constructor applying the default unassigned value;
     * don't disarm the magic yet
     */
    return 1;

  /* Now disarm the magic so it won't run again */
  mg_freeext(sv, PERL_MAGIC_ext, &vtbl);

  return 1;
}

static bool lazyinit_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **hookdata_ptr, void *_funcdata)
{
  mop_field_set_default_sv(fieldmeta, newRV_inc(unassigned_val));

  return TRUE;
}

static void lazyinit_post_initfield(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata, SV *field)
{
  SV *weakself = newSVsv(PAD_SVl(PADIX_SELF));
  sv_rvweaken(weakself);

  sv_magicext(field, weakself, PERL_MAGIC_ext, &vtbl, (char *)hookdata, HEf_SVKEY);

  SvREFCNT_dec(weakself);
}

static const struct FieldHookFuncs lazyinit_hooks = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_MUST_VALUE,
  .permit_hintkey = "Object::Pad::FieldAttr::LazyInit/LazyInit",
  .apply          = &lazyinit_apply,
  .post_initfield = &lazyinit_post_initfield,
};

MODULE = Object::Pad::FieldAttr::LazyInit    PACKAGE = Object::Pad::FieldAttr::LazyInit

BOOT:
  register_field_attribute("LazyInit", &lazyinit_hooks, NULL);

  unassigned_val = newSV(0);
