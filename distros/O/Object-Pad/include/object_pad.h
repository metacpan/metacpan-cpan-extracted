#ifndef __OBJECT_PAD__TYPES_H__
#define __OBJECT_PAD__TYPES_H__

#define OBJECTPAD_ABIVERSION_MINOR 57
#define OBJECTPAD_ABIVERSION_MAJOR 0

#define OBJECTPAD_ABIVERSION  ((OBJECTPAD_ABIVERSION_MAJOR << 16) | (OBJECTPAD_ABIVERSION_MINOR))

/* A FIELDOFFSET is an offset within the AV of an object instance */
typedef IV FIELDOFFSET;

typedef struct ClassMeta ClassMeta;
typedef struct FieldMeta FieldMeta;
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
  bool (*apply)(pTHX_ ClassMeta *classmeta, SV *value, SV **hookdata_ptr, void *funcdata);

  /* called by mop_class_add_field() */
  void (*post_add_field)(pTHX_ ClassMeta *classmeta, SV *hookdata, void *funcdata, FieldMeta *fieldmeta);
};

struct ClassHook {
  const struct ClassHookFuncs *funcs;
  void *funcdata;
  SV *hookdata;
};

struct FieldHookFuncs {
  U32 ver;   /* caller must initialise to OBJECTPAD_VERSION */
  U32 flags;
  const char *permit_hintkey;

  /* called immediately at apply time; return FALSE means it did its thing immediately, so don't store it */
  bool (*apply)(pTHX_ FieldMeta *fieldmeta, SV *value, SV **hookdata_ptr, void *funcdata);

  /* called at the end of `has` statement compiletime */
  void (*seal)(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *funcdata);

  /* called as part of accessor generation */
  void (*gen_accessor_ops)(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *funcdata,
          enum AccessorType type, struct AccessorGenerationCtx *ctx);

  /* called by constructor */
  void (*post_initfield)(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *funcdata, SV *field);
  void (*post_construct)(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *funcdata, SV *field);
};

struct FieldHook {
  FIELDOFFSET fieldix; /* unused when in FieldMeta->hooks; used by ClassMeta->fieldhooks_* */
  FieldMeta *fieldmeta;
  const struct FieldHookFuncs *funcs;
  void *funcdata;
  SV *hookdata;
};

enum MetaType {
  METATYPE_CLASS,
  METATYPE_ROLE,
};

enum ReprType {
  REPR_NATIVE,       /* instances are in native format - blessed AV as backing */
  REPR_HASH,         /* instances are blessed HASHes; our backing lives in $self->{"Object::Pad/slots"} */
  REPR_MAGIC,        /* instances store backing AV via magic; superconstructor must be foreign */

  REPR_AUTOSELECT,   /* pick one of the above depending on foreign_new and SvTYPE()==SVt_PVHV */
};

/* Special pad indexes within `method` CVs */
enum {
  PADIX_SELF = 1,
  PADIX_SLOTS = 2,

  /* for role methods */
  PADIX_EMBEDDING = 3,

  /* during initfields */
  PADIX_INITFIELDS_PARAMS = 4,
};

/* Function prototypes */

#define extend_pad_vars(meta)  ObjectPad_extend_pad_vars(aTHX_ meta)
void ObjectPad_extend_pad_vars(pTHX_ const ClassMeta *meta);

#define newMETHSTARTOP(flags)  ObjectPad_newMETHSTARTOP(aTHX_ flags)
OP *ObjectPad_newMETHSTARTOP(pTHX_ U32 flags);

#define newCOMMONMETHSTARTOP(flags)  ObjectPad_newCOMMONMETHSTARTOP(aTHX_ flags)
OP *ObjectPad_newCOMMONMETHSTARTOP(pTHX_ U32 flags);

/* op_private flags on FIELDPAD ops */
enum {
  OPpFIELDPAD_SV,  /* has $x */
  OPpFIELDPAD_AV,  /* has @y */
  OPpFIELDPAD_HV,  /* has %z */
};

#define newFIELDPADOP(flags, padix, fieldix)  ObjectPad_newFIELDPADOP(aTHX_ flags, padix, fieldix)
OP *ObjectPad_newFIELDPADOP(pTHX_ U32 flags, PADOFFSET padix, FIELDOFFSET fieldix);

#define get_obj_backingav(self, repr, create)  ObjectPad_get_obj_backingav(aTHX_ self, repr, create)
SV *ObjectPad_get_obj_backingav(pTHX_ SV *self, enum ReprType repr, bool create);

/* Class API */
#define mop_create_class(type, name)  ObjectPad_mop_create_class(aTHX_ type, name)
ClassMeta *ObjectPad_mop_create_class(pTHX_ enum MetaType type, SV *name);

#define mop_get_class_for_stash(stash)  ObjectPad_mop_get_class_for_stash(aTHX_ stash)
ClassMeta *ObjectPad_mop_get_class_for_stash(pTHX_ HV *stash);

#define mop_class_set_superclass(class, super)  ObjectPad_mop_class_set_superclass(aTHX_ class, super)
void ObjectPad_mop_class_set_superclass(pTHX_ ClassMeta *class, SV *superclassname);

#define mop_class_begin(meta)  ObjectPad_mop_class_begin(aTHX_ meta)
void ObjectPad_mop_class_begin(pTHX_ ClassMeta *meta);

#define mop_class_seal(meta)  ObjectPad_mop_class_seal(aTHX_ meta)
void ObjectPad_mop_class_seal(pTHX_ ClassMeta *meta);

#define mop_class_load_and_add_role(class, rolename, rolever)  ObjectPad_mop_class_load_and_add_role(aTHX_ class, rolename, rolever)
void ObjectPad_mop_class_load_and_add_role(pTHX_ ClassMeta *class, SV *rolename, SV *rolever);

#define mop_class_add_role(class, role)  ObjectPad_mop_class_add_role(aTHX_ class, role)
void ObjectPad_mop_class_add_role(pTHX_ ClassMeta *class, ClassMeta *role);

#define mop_class_add_method(class, methodname)  ObjectPad_mop_class_add_method(aTHX_ class, methodname)
MethodMeta *ObjectPad_mop_class_add_method(pTHX_ ClassMeta *meta, SV *methodname);

#define mop_class_add_field(class, fieldname)  ObjectPad_mop_class_add_field(aTHX_ class, fieldname)
FieldMeta *ObjectPad_mop_class_add_field(pTHX_ ClassMeta *meta, SV *fieldname);

#define mop_class_add_BUILD(class, cv)  ObjectPad_mop_class_add_BUILD(aTHX_ class, cv)
void ObjectPad_mop_class_add_BUILD(pTHX_ ClassMeta *meta, CV *cv);

#define mop_class_add_ADJUST(class, cv)  ObjectPad_mop_class_add_ADJUST(aTHX_ class, cv)
void ObjectPad_mop_class_add_ADJUST(pTHX_ ClassMeta *meta, CV *cv);

#define mop_class_add_required_method(class, methodname)  ObjectPad_mop_class_add_required_method(aTHX_ class, methodname)
void ObjectPad_mop_class_add_required_method(pTHX_ ClassMeta *meta, SV *methodname);

#define mop_class_apply_attribute(classmeta, name, value)  ObjectPad_mop_class_apply_attribute(aTHX_ classmeta, name, value)
void ObjectPad_mop_class_apply_attribute(pTHX_ ClassMeta *classmeta, const char *name, SV *value);

#define register_class_attribute(name, funcs, funcdata)  ObjectPad_register_class_attribute(aTHX_ name, funcs, funcdata)
void ObjectPad_register_class_attribute(pTHX_ const char *name, const struct ClassHookFuncs *funcs, void *funcdata);

/* Field API */
#define mop_create_field(fieldname, classmeta)  ObjectPad_mop_create_field(aTHX_ fieldname, classmeta)
FieldMeta *ObjectPad_mop_create_field(pTHX_ SV *fieldname, ClassMeta *classmeta);

#define mop_field_seal(fieldmeta)  ObjectPad_mop_field_seal(aTHX_ fieldmeta)
void ObjectPad_mop_field_seal(pTHX_ FieldMeta *fieldmeta);

#define mop_field_get_name(fieldmeta)  ObjectPad_mop_field_get_name(aTHX_ fieldmeta)
SV *ObjectPad_mop_field_get_name(pTHX_ FieldMeta *fieldmeta);

#define mop_field_get_sigil(fieldmeta)  ObjectPad_mop_field_get_sigil(aTHX_ fieldmeta)
char ObjectPad_mop_field_get_sigil(pTHX_ FieldMeta *fieldmeta);

#define mop_field_apply_attribute(fieldmeta, name, value)  ObjectPad_mop_field_apply_attribute(aTHX_ fieldmeta, name, value)
void ObjectPad_mop_field_apply_attribute(pTHX_ FieldMeta *fieldmeta, const char *name, SV *value);

#define mop_field_get_attribute(fieldmeta, name)  ObjectPad_mop_field_get_attribute(aTHX_ fieldmeta, name)
struct FieldHook *ObjectPad_mop_field_get_attribute(pTHX_ FieldMeta *fieldmeta, const char *name);

#define mop_field_get_attribute_values(fieldmeta, name)  ObjectPad_mop_field_get_attribute_values(aTHX_ fieldmeta, name)
AV *ObjectPad_mop_field_get_attribute_values(pTHX_ FieldMeta *fieldmeta, const char *name);

#define mop_field_get_default_sv(fieldmeta)  ObjectPad_mop_field_get_default_sv(aTHX_ fieldmeta)
SV *ObjectPad_mop_field_get_default_sv(pTHX_ FieldMeta *fieldmeta);

#define mop_field_set_default_sv(fieldmeta, sv)  ObjectPad_mop_field_set_default_sv(aTHX_ fieldmeta, sv)
void ObjectPad_mop_field_set_default_sv(pTHX_ FieldMeta *fieldmeta, SV *sv);

#define register_field_attribute(name, funcs, funcdata)  ObjectPad_register_field_attribute(aTHX_ name, funcs, funcdata)
void ObjectPad_register_field_attribute(pTHX_ const char *name, const struct FieldHookFuncs *funcs, void *funcdata);


#endif
