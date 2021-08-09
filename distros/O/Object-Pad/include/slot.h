#ifndef __OBJECT_PAD__SLOT_H__
#define __OBJECT_PAD__SLOT_H__

struct SlotMeta {
  SV *name;
  ClassMeta *class;
  SV *defaultsv;
  SLOTOFFSET slotix;
  AV *hooks; /* NULL, or AV of raw pointers directly to SlotHook structs */
};

void ObjectPad__boot_slots(void);

#endif
