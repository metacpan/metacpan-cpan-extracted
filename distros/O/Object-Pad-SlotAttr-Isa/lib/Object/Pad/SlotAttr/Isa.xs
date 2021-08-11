/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"

struct Data {
  unsigned int is_weak : 1;
  SV *slotname;
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

  croak("Slot %" SVf " requires an object of type %" SVf,
    SVfARG(data->slotname), SVfARG(data->classname));

  return 1;
}

static MGVTBL vtbl = {
  .svt_set = &magic_set,
};

static bool isa_apply(pTHX_ SlotMeta *slotmeta, SV *value, SV **hookdata_ptr)
{
  struct Data *data;
  Newx(data, 1, struct Data);

  data->is_weak   = false;
  data->slotname  = SvREFCNT_inc(mop_slot_get_name(slotmeta));
  data->classname = SvREFCNT_inc(value);

  *hookdata_ptr = (SV *)data;

  return TRUE;
}

static void isa_seal(pTHX_ SlotMeta *slotmeta, SV *hookdata)
{
  struct Data *data = (struct Data *)hookdata;

  if(mop_slot_get_attribute(slotmeta, "weak"))
    data->is_weak = true;
}

static void isa_post_initslot(pTHX_ SlotMeta *slotmeta, SV *hookdata, SV *slot)
{
  sv_magicext(slot, newSV(0), PERL_MAGIC_ext, &vtbl, (char *)hookdata, 0);
}

static const struct SlotHookFuncs isa_hooks = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_MUST_VALUE,
  .permit_hintkey = "Object::Pad::SlotAttr::Isa/Isa",

  .apply         = &isa_apply,
  .seal_slot     = &isa_seal,
  .post_initslot = &isa_post_initslot,
};

MODULE = Object::Pad::SlotAttr::Isa    PACKAGE = Object::Pad::SlotAttr::Isa

BOOT:
  register_slot_attribute("Isa", &isa_hooks);
