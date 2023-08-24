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

struct Data {
  unsigned int is_weak : 1;
  SV *fieldname;
  SV *classname;
};

static int magic_set(pTHX_ SV *sv, MAGIC *mg)
{
  struct Data *data = (struct Data *)mg->mg_ptr;
  SV *savesv = mg->mg_obj;

  bool ok = sv_derived_from_sv(sv, data->classname, 0);

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

  croak("Field %" SVf " requires an object of type %" SVf,
    SVfARG(data->fieldname), SVfARG(data->classname));

  return 1;
}

static const MGVTBL vtbl = {
  .svt_set = &magic_set,
};

static bool isa_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **attrdata_ptr, void *_funcdata)
{
  struct Data *data;
  Newx(data, 1, struct Data);

  data->is_weak   = false;
  data->fieldname = SvREFCNT_inc(mop_field_get_name(fieldmeta));
  data->classname = SvREFCNT_inc(value);

  *attrdata_ptr = (SV *)data;

  return TRUE;
}

static void isa_seal(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *_funcdata)
{
  struct Data *data = (struct Data *)attrdata;

  if(mop_field_get_attribute(fieldmeta, "weak"))
    data->is_weak = true;
}

static void isa_post_makefield(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *_funcdata, SV *field)
{
  sv_magicext(field, newSV(0), PERL_MAGIC_ext, &vtbl, (char *)attrdata, 0);
}

static const struct FieldHookFuncs isa_hooks = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_MUST_VALUE,
  .permit_hintkey = "Object::Pad::FieldAttr::Isa/Isa",

  .apply          = &isa_apply,
  .seal           = &isa_seal,
  .post_makefield = &isa_post_makefield,
};

MODULE = Object::Pad::FieldAttr::Isa    PACKAGE = Object::Pad::FieldAttr::Isa

BOOT:
  register_field_attribute("Isa", &isa_hooks, NULL);
