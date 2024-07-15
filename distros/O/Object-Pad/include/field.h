#ifndef __OBJECT_PAD__FIELD_H__
#define __OBJECT_PAD__FIELD_H__

#include "linnet.h"

#define LINNET_VAL_FIELDMETA  0x4F50464D  /* "OPFM" */
#define MUST_FIELDMETA(ptr)   LINNET_CHECK_CAST(ptr, FieldMeta *, LINNET_VAL_FIELDMETA)
struct FieldMeta {
  LINNET_FIELD
  /* Flags first */
  unsigned int is_direct : 1;
  unsigned int def_if_undef : 1;
  unsigned int def_if_false : 1;
  unsigned int is_inheritable : 1;

  SV *name;
  ClassMeta *class;
  OP *defaultexpr;
  FIELDOFFSET fieldix;
  SV *paramname;
  AV *hooks; /* NULL, or AV of raw pointers directly to FieldHook structs */
};

#define MOP_FIELD_RUN_HOOKS_NOARGS(fieldmeta, func)                                       \
  {                                                                                       \
    U32 hooki;                                                                            \
    for(hooki = 0; fieldmeta->hooks && hooki < av_count(fieldmeta->hooks); hooki++) {     \
      struct FieldHook *h = (struct FieldHook *)AvARRAY(fieldmeta->hooks)[hooki];         \
      if(*h->funcs->func)                                                                 \
        (*h->funcs->func)(aTHX_ fieldmeta, h->attrdata, h->funcdata);                     \
    }                                                                                     \
  }

#define MOP_FIELD_RUN_HOOKS(fieldmeta, func, ...)                                         \
  {                                                                                       \
    U32 hooki;                                                                            \
    for(hooki = 0; fieldmeta->hooks && hooki < av_count(fieldmeta->hooks); hooki++) {     \
      struct FieldHook *h = (struct FieldHook *)AvARRAY(fieldmeta->hooks)[hooki];         \
      if(*h->funcs->func)                                                                 \
        (*h->funcs->func)(aTHX_ fieldmeta, h->attrdata, h->funcdata, __VA_ARGS__);        \
    }                                                                                     \
  }

void ObjectPad__boot_fields(pTHX);

#endif
