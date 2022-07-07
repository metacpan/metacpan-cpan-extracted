#ifndef __OBJECT_PAD__FIELD_H__
#define __OBJECT_PAD__FIELD_H__

struct FieldMeta {
  SV *name;
  ClassMeta *class;
  SV *defaultsv;
  OP *defaultexpr; /* at most one of defaultsv or defaultexpr should be set */
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
        (*h->funcs->func)(aTHX_ fieldmeta, h->hookdata, h->funcdata);                     \
    }                                                                                     \
  }

#define MOP_FIELD_RUN_HOOKS(fieldmeta, func, ...)                                         \
  {                                                                                       \
    U32 hooki;                                                                            \
    for(hooki = 0; fieldmeta->hooks && hooki < av_count(fieldmeta->hooks); hooki++) {     \
      struct FieldHook *h = (struct FieldHook *)AvARRAY(fieldmeta->hooks)[hooki];         \
      if(*h->funcs->func)                                                                 \
        (*h->funcs->func)(aTHX_ fieldmeta, h->hookdata, h->funcdata, __VA_ARGS__);        \
    }                                                                                     \
  }

void ObjectPad__boot_fields(pTHX);

#endif
