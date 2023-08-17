/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"

#ifdef G_RETHROW
#define eval_sv_rethrow(sv, flags)  eval_sv(sv, flags|G_RETHROW)
#else
#define eval_sv_rethrow(sv, flags)  S_eval_sv_rethrow(aTHX_ sv, flags)
static void S_eval_sv_rethrow(pTHX_ SV *sv, U32 flags)
{
  /* Not a perfect emulation but good enough for our purposes */
  eval_sv(sv, flags);
  if(SvTRUE(ERRSV))
    croak_sv(ERRSV);
}
#endif

struct Data {
  unsigned int is_weak : 1;
  SV *fieldname;
  SV *checkname;
  SV *checkobj;
  CV *checkcv;
};

static int magic_set(pTHX_ SV *sv, MAGIC *mg)
{
  struct Data *data = (struct Data *)mg->mg_ptr;
  SV *savesv = mg->mg_obj;

  bool ok;
  {
    dSP;

    ENTER;
    SAVETMPS;

    EXTEND(SP, 2);
    PUSHMARK(SP);
    PUSHs(sv_mortalcopy(data->checkobj));
    PUSHs(sv); /* Yes we're pushing the SV itself */
    PUTBACK;

    call_sv((SV *)data->checkcv, G_SCALAR);

    SPAGAIN;

    ok = SvTRUEx(POPs);

    FREETMPS;
    LEAVE;
  }

  if(ok) {
    sv_setsv(savesv, sv);
    if(data->is_weak)
      sv_rvweaken(savesv);
    return 1;
  }

  /* Restore last known-good value */
  sv_setsv_nomg(sv, savesv);
  if(data->is_weak)
    sv_rvweaken(sv);

  croak("Field %" SVf " requires a value satisfying :Checked(%" SVf ")",
    SVfARG(data->fieldname), SVfARG(data->checkname));

  return 1;
}

static const MGVTBL vtbl = {
  .svt_set = &magic_set,
};

static bool checked_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **hookdata_ptr, void *_funcdata)
{
  SV *checker;

  {
    dSP;

    ENTER;
    SAVETMPS;

    eval_sv_rethrow(value, G_SCALAR);

    SPAGAIN;

    checker = SvREFCNT_inc(POPs);

    FREETMPS;
    LEAVE;
  }

  HV *stash;
  if(SvROK(checker) && SvOBJECT(SvRV(checker)))
    stash = SvSTASH(SvRV(checker));
  else if(SvPOK(checker) && (stash = gv_stashsv(checker, GV_NOADD_NOINIT)))
    ; /* checker is package name */
  else
    croak("Expected the checker expression to yield an object reference or package name");

  GV *methgv;
  if(!(methgv = gv_fetchmeth_pv(stash, "check", -1, 0)))
    croak("Expected that the checker expression can ->check");
  if(!GvCV(methgv))
    croak("Expected that methgv has a GvCV");

  struct Data *data;
  Newx(data, 1, struct Data);

  data->is_weak   = false;
  data->fieldname = SvREFCNT_inc(mop_field_get_name(fieldmeta));
  data->checkname = SvREFCNT_inc(value);
  data->checkobj  = checker;
  data->checkcv   = (CV *)SvREFCNT_inc((SV *)GvCV(methgv));

  *hookdata_ptr = (SV *)data;

  return TRUE;
}

static void checked_seal(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata)
{
  struct Data *data = (struct Data *)hookdata;

  if(mop_field_get_attribute(fieldmeta, "weak"))
    data->is_weak = true;
}

static void checked_post_initfield(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata, SV *field)
{
  sv_magicext(field, newSV(0), PERL_MAGIC_ext, &vtbl, (char *)hookdata, 0);
}

static const struct FieldHookFuncs checked_hooks = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_MUST_VALUE,
  .permit_hintkey = "Object::Pad::FieldAttr::Checked/Checked",

  .apply          = &checked_apply,
  .seal           = &checked_seal,
  .post_initfield = &checked_post_initfield,
};

MODULE = Object::Pad::FieldAttr::Checked    PACKAGE = Object::Pad::FieldAttr::Checked

BOOT:
  register_field_attribute("Checked", &checked_hooks, NULL);
