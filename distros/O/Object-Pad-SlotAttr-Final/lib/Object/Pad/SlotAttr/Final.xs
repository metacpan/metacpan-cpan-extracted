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

static void final_post_construct(pTHX_ SlotMeta *slotmeta, SV *_hookdata, void *_funcdata, SV *slot)
{
  SvREADONLY_on(slot);
}

static void final_seal(pTHX_ SlotMeta *slotmeta, SV *hookdata, void *_funcdata)
{
  if(mop_slot_get_attribute(slotmeta, "writer"))
    warn("Applying :Final attribute to slot %" SVf " which already has :writer", SVfARG(mop_slot_get_name(slotmeta)));
}

static const struct SlotHookFuncs final_hooks = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_NO_VALUE,
  .permit_hintkey = "Object::Pad::SlotAttr::Final/Final",

  .seal_slot      = &final_seal,
  .post_construct = &final_post_construct,
};

MODULE = Object::Pad::SlotAttr::Final    PACKAGE = Object::Pad::SlotAttr::Final

BOOT:
  register_slot_attribute("Final", &final_hooks, NULL);
