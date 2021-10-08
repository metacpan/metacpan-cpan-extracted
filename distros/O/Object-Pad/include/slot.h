#ifndef __OBJECT_PAD__SLOT_H__
#define __OBJECT_PAD__SLOT_H__

struct SlotMeta {
  SV *name;
  ClassMeta *class;
  SV *defaultsv;
  OP *defaultexpr; /* at most one of defaultsv or defaultexpr should be set */
  SLOTOFFSET slotix;
  SV *paramname;
  AV *hooks; /* NULL, or AV of raw pointers directly to SlotHook structs */
};

#define MOP_SLOT_RUN_HOOKS_NOARGS(slotmeta, func)                                         \
  {                                                                                       \
    U32 hooki;                                                                            \
    for(hooki = 0; slotmeta->hooks && hooki < av_count(slotmeta->hooks); hooki++) {       \
      struct SlotHook *h = (struct SlotHook *)AvARRAY(slotmeta->hooks)[hooki];            \
      if(*h->funcs->func)                                                                 \
        (*h->funcs->func)(aTHX_ slotmeta, h->hookdata);                                   \
    }                                                                                     \
  }

#define MOP_SLOT_RUN_HOOKS(slotmeta, func, ...)                                           \
  {                                                                                       \
    U32 hooki;                                                                            \
    for(hooki = 0; slotmeta->hooks && hooki < av_count(slotmeta->hooks); hooki++) {       \
      struct SlotHook *h = (struct SlotHook *)AvARRAY(slotmeta->hooks)[hooki];            \
      if(*h->funcs->func)                                                                 \
        (*h->funcs->func)(aTHX_ slotmeta, h->hookdata, __VA_ARGS__);                      \
    }                                                                                     \
  }

void ObjectPad__boot_slots(pTHX);

#endif
