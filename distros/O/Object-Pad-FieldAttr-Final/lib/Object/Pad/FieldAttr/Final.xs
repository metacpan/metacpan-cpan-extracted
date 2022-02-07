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

static void final_post_construct(pTHX_ FieldMeta *fieldmeta, SV *_hookdata, void *_funcdata, SV *field)
{
  SvREADONLY_on(field);
}

static void final_seal(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata)
{
  if(mop_field_get_attribute(fieldmeta, "writer"))
    warn("Applying :Final attribute to field %" SVf " which already has :writer", SVfARG(mop_field_get_name(fieldmeta)));
}

static const struct FieldHookFuncs final_hooks = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_NO_VALUE,
  .permit_hintkey = "Object::Pad::FieldAttr::Final/Final",

  .seal           = &final_seal,
  .post_construct = &final_post_construct,
};

MODULE = Object::Pad::FieldAttr::Final    PACKAGE = Object::Pad::FieldAttr::Final

BOOT:
  register_field_attribute("Final", &final_hooks, NULL);
