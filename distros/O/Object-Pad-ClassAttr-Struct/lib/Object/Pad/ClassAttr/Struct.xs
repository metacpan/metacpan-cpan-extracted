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

enum {
  FLAG_READONLY = (1<<0),
};

static bool struct_apply(pTHX_ ClassMeta *classmeta, SV *value, SV **attrdata_ptr, void *_funcdata)
{
  U32 flags = 0;

  if(value && SvPOK(value)) {
    const char *s = SvPVX(value), *e = s + SvCUR(value);

    while(s < e) {
      const char *comma_at = strchr(s, ',');
      if(!comma_at)
        comma_at = e;
      STRLEN len = comma_at - s;

      if(len == 8 && strnEQ(s, "readonly", len))
        flags |= FLAG_READONLY;
      else
        croak("Unrecognised :Struct() option \"%.*s\"", (int)len, s);

      s += len;
      while(*s == ',')
        s++;
    }
  }

  if(flags)
    *attrdata_ptr = newSVuv(flags);

  mop_class_apply_attribute(classmeta, "strict", sv_2mortal(newSVpvs("params")));
  return TRUE;
}

static void struct_post_add_field(pTHX_ ClassMeta *classmeta, SV *attrdata, void *_funcdata, FieldMeta *fieldmeta)
{
  if(mop_field_get_sigil(fieldmeta) != '$')
    return;

  U32 flags = attrdata ? SvUV(attrdata) : 0;

  mop_field_apply_attribute(fieldmeta, "param", NULL);

  if(flags & FLAG_READONLY)
    mop_field_apply_attribute(fieldmeta, "reader", NULL);
  else
    mop_field_apply_attribute(fieldmeta, "mutator", NULL);
}

static void struct_post_seal(pTHX_ ClassMeta *classmeta, SV *attrdata, void *_funcdata)
{
  dSP;

  ENTER;
  SAVETMPS;

  EXTEND(SP, 1);
  PUSHMARK(SP);
  PUSHs(mop_class_get_name(classmeta));
  PUTBACK;

  call_pv("Object::Pad::ClassAttr::Struct::_post_seal", G_VOID);

  FREETMPS;
  LEAVE;
}

static const struct ClassHookFuncs struct_hooks = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = 0,
  .permit_hintkey = "Object::Pad::ClassAttr::Struct/Struct",

  .apply          = &struct_apply,
  .post_add_field = &struct_post_add_field,
  .post_seal      = &struct_post_seal,
};

MODULE = Object::Pad::ClassAttr::Struct    PACKAGE = Object::Pad::ClassAttr::Struct

BOOT:
  register_class_attribute("Struct", &struct_hooks, NULL);
