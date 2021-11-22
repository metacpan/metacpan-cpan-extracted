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

static bool struct_apply(pTHX_ ClassMeta *classmeta, SV *hookdata, SV **hookdata_ptr, void *_funcdata)
{
  mop_class_apply_attribute(classmeta, "strict", sv_2mortal(newSVpvs("params")));
  return TRUE;
}

static void struct_post_add_slot(pTHX_ ClassMeta *classmeta, SV *hookdata, void *_funcdata, SlotMeta *slotmeta)
{
  if(mop_slot_get_sigil(slotmeta) != '$')
    return;

  mop_slot_apply_attribute(slotmeta, "param", NULL);
  mop_slot_apply_attribute(slotmeta, "mutator", NULL);
}

static const struct ClassHookFuncs struct_hooks = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_NO_VALUE,
  .permit_hintkey = "Object::Pad::ClassAttr::Struct/Struct",

  .apply         = &struct_apply,
  .post_add_slot = &struct_post_add_slot,
};

MODULE = Object::Pad::ClassAttr::Struct    PACKAGE = Object::Pad::ClassAttr::Struct

BOOT:
  register_class_attribute("Struct", &struct_hooks, NULL);
