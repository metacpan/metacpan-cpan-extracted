#ifndef __OBJECT_PAD__TYPES_H__
#define __OBJECT_PAD__TYPES_H__

#define OBJECTPAD_ABIVERSION_MINOR 51
#define OBJECTPAD_ABIVERSION_MAJOR 0

#define OBJECTPAD_ABIVERSION  ((OBJECTPAD_ABIVERSION_MAJOR << 16) | (OBJECTPAD_ABIVERSION_MINOR))

/* A SLOTOFFSET is an offset within the AV of an object instance */
typedef IV SLOTOFFSET;

typedef struct ClassMeta ClassMeta;
typedef struct SlotMeta SlotMeta;
typedef struct MethodMeta MethodMeta;

enum AccessorType {
  ACCESSOR,
  ACCESSOR_READER,
  ACCESSOR_WRITER,
  ACCESSOR_LVALUE_MUTATOR,
  ACCESSOR_COMBINED,
};

struct AccessorGenerationCtx {
  PADOFFSET padix;
  OP *bodyop;       /* OP_SASSIGN for :writer, empty for :reader, :mutator */
  OP *post_bodyops;
  OP *retop;        /* OP_RETURN */
};

enum {
  OBJECTPAD_FLAG_ATTR_NO_VALUE = (1<<0),
  OBJECTPAD_FLAG_ATTR_MUST_VALUE = (1<<1),
};

struct ClassHookFuncs {
  U32 ver;  /* caller must initialise to OBJECTPAD_VERSION */
  U32 flags;
  const char *permit_hintkey;

  /* called immediately at apply time; return FALSE means it did its thing immediately, so don't store it */
  bool (*apply)(pTHX_ ClassMeta *classmeta, SV *value, SV **hookdata_ptr);

  /* called by mop_class_add_slot() */
  void (*post_add_slot)(pTHX_ ClassMeta *classmeta, SV *hookdata, SlotMeta *slotmeta);
};

struct ClassHook {
  const struct ClassHookFuncs *funcs;
  SV *hookdata;
};

struct SlotHookFuncs {
  U32 ver;   /* caller must initialise to OBJECTPAD_VERSION */
  U32 flags;
  const char *permit_hintkey;

  /* called immediately at apply time; return FALSE means it did its thing immediately, so don't store it */
  bool (*apply)(pTHX_ SlotMeta *slotmeta, SV *value, SV **hookdata_ptr);

  /* called at the end of `has` statement compiletime */
  void (*seal_slot)(pTHX_ SlotMeta *slotmeta, SV *hookdata);

  /* called as part of accessor generation */
  void (*gen_accessor_ops)(pTHX_ SlotMeta *slotmeta, SV *hookdata, enum AccessorType type,
          struct AccessorGenerationCtx *ctx);

  /* called by constructor */
  void (*post_initslot)(pTHX_ SlotMeta *slotmeta, SV *hookdata, SV *slot);
  void (*post_construct)(pTHX_ SlotMeta *slotmeta, SV *hookdata, SV *slot);
};

struct SlotHook {
  SLOTOFFSET slotix; /* unused when in SlotMeta->hooks; used by ClassMeta->slothooks_* */
  SlotMeta *slotmeta;
  const struct SlotHookFuncs *funcs;
  SV *hookdata;
};

enum MetaType {
  METATYPE_CLASS,
  METATYPE_ROLE,
};

enum ReprType {
  REPR_NATIVE,       /* instances are in native format - blessed AV as slots */
  REPR_HASH,         /* instances are blessed HASHes; our slots live in $self->{"Object::Pad/slots"} */
  REPR_MAGIC,        /* instances store slot AV via magic; superconstructor must be foreign */

  REPR_AUTOSELECT,   /* pick one of the above depending on foreign_new and SvTYPE()==SVt_PVHV */
};

/* Special pad indexes within `method` CVs */
enum {
  PADIX_SELF = 1,
  PADIX_SLOTS = 2,

  /* for role methods */
  PADIX_EMBEDDING = 3,

  /* during initslots */
  PADIX_INITSLOTS_PARAMS = 4,
};

/* Function prototypes */

#define extend_pad_vars(meta)  ObjectPad_extend_pad_vars(aTHX_ meta)
void ObjectPad_extend_pad_vars(pTHX_ const ClassMeta *meta);

#define newMETHSTARTOP(flags)  ObjectPad_newMETHSTARTOP(aTHX_ flags)
OP *ObjectPad_newMETHSTARTOP(pTHX_ U32 flags);

/* op_private flags on SLOTPAD ops */
enum {
  OPpSLOTPAD_SV,  /* has $x */
  OPpSLOTPAD_AV,  /* has @y */
  OPpSLOTPAD_HV,  /* has %z */
};

#define newSLOTPADOP(flags, padix, slotix)  ObjectPad_newSLOTPADOP(aTHX_ flags, padix, slotix)
OP *ObjectPad_newSLOTPADOP(pTHX_ U32 flags, PADOFFSET padix, SLOTOFFSET slotix);

#define get_obj_slotsav(self, repr, create)  ObjectPad_get_obj_slotsav(aTHX_ self, repr, create)
SV *ObjectPad_get_obj_slotsav(pTHX_ SV *self, enum ReprType repr, bool create);

/* Class API */
#define mop_create_class(type, name, super)  ObjectPad_mop_create_class(aTHX_ type, name, super)
ClassMeta *ObjectPad_mop_create_class(pTHX_ enum MetaType type, SV *name, SV *superclassname);

#define mop_class_seal(meta)  ObjectPad_mop_class_seal(aTHX_ meta)
void ObjectPad_mop_class_seal(pTHX_ ClassMeta *meta);

#define mop_class_add_role(class, role)  ObjectPad_mop_class_add_role(aTHX_ class, role)
void ObjectPad_mop_class_add_role(pTHX_ ClassMeta *class, ClassMeta *role);

#define mop_class_add_method(class, methodname)  ObjectPad_mop_class_add_method(aTHX_ class, methodname)
MethodMeta *ObjectPad_mop_class_add_method(pTHX_ ClassMeta *meta, SV *methodname);

#define mop_class_add_slot(class, slotname)  ObjectPad_mop_class_add_slot(aTHX_ class, slotname)
SlotMeta *ObjectPad_mop_class_add_slot(pTHX_ ClassMeta *meta, SV *slotname);

#define mop_class_add_BUILD(class, cv)  ObjectPad_mop_class_add_BUILD(aTHX_ class, cv)
void ObjectPad_mop_class_add_BUILD(pTHX_ ClassMeta *meta, CV *cv);

#define mop_class_add_ADJUST(class, cv)  ObjectPad_mop_class_add_ADJUST(aTHX_ class, cv)
void ObjectPad_mop_class_add_ADJUST(pTHX_ ClassMeta *meta, CV *cv);

#define mop_class_add_ADJUSTPARAMS(class, cv)  ObjectPad_mop_class_add_ADJUSTPARAMS(aTHX_ class, cv)
void ObjectPad_mop_class_add_ADJUSTPARAMS(pTHX_ ClassMeta *meta, CV *cv);

#define mop_class_apply_attribute(classmeta, name, value)  ObjectPad_mop_class_apply_attribute(aTHX_ classmeta, name, value)
void ObjectPad_mop_class_apply_attribute(pTHX_ ClassMeta *classmeta, const char *name, SV *value);

#define register_class_attribute(name, funcs)  ObjectPad_register_class_attribute(aTHX_ name, funcs)
void ObjectPad_register_class_attribute(pTHX_ const char *name, const struct ClassHookFuncs *funcs);

/* Slot API */
#define mop_create_slot(slotname, classmeta)  ObjectPad_mop_create_slot(aTHX_ slotname, classmeta)
SlotMeta *ObjectPad_mop_create_slot(pTHX_ SV *slotname, ClassMeta *classmeta);

#define mop_slot_seal(slotmeta)  ObjectPad_mop_slot_seal(aTHX_ slotmeta)
void ObjectPad_mop_slot_seal(pTHX_ SlotMeta *slotmeta);

#define mop_slot_get_name(slotmeta)  ObjectPad_mop_slot_get_name(aTHX_ slotmeta)
SV *ObjectPad_mop_slot_get_name(pTHX_ SlotMeta *slotmeta);

#define mop_slot_get_sigil(slotmeta)  ObjectPad_mop_slot_get_sigil(aTHX_ slotmeta)
char ObjectPad_mop_slot_get_sigil(pTHX_ SlotMeta *slotmeta);

#define mop_slot_apply_attribute(slotmeta, name, value)  ObjectPad_mop_slot_apply_attribute(aTHX_ slotmeta, name, value)
void ObjectPad_mop_slot_apply_attribute(pTHX_ SlotMeta *slotmeta, const char *name, SV *value);

#define mop_slot_get_attribute(slotmeta, name)  ObjectPad_mop_slot_get_attribute(aTHX_ slotmeta, name)
struct SlotHook *ObjectPad_mop_slot_get_attribute(pTHX_ SlotMeta *slotmeta, const char *name);

#define register_slot_attribute(name, funcs)  ObjectPad_register_slot_attribute(aTHX_ name, funcs)
void ObjectPad_register_slot_attribute(pTHX_ const char *name, const struct SlotHookFuncs *funcs);

#endif
