#ifndef __OBJECT_PAD__TYPES_H__
#define __OBJECT_PAD__TYPES_H__

#define OBJECTPAD_ABIVERSION_MINOR 810
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
  bool (*apply)(pTHX_ ClassMeta *classmeta, SV *value, SV **attrdata_ptr, void *funcdata);

  /* called immediately before class seal */
  void (*pre_seal)(pTHX_ ClassMeta *classmeta, SV *attrdata, void *funcdata);
  /* called immediately after class seal */
  void (*post_seal)(pTHX_ ClassMeta *classmeta, SV *attrdata, void *funcdata);

  /* called by mop_class_add_field() */
  void (*post_add_field)(pTHX_ ClassMeta *classmeta, SV *attrdata, void *funcdata, FieldMeta *fieldmeta);
};

struct ClassHook {
  const struct ClassHookFuncs *funcs;
  void *funcdata;
  SV *attrdata; /* used to be called 'hookdata' */
};

struct FieldHookFuncs {
  U32 ver;   /* caller must initialise to OBJECTPAD_VERSION */
  U32 flags;
  const char *permit_hintkey;

  /* optional; called when parsing `:ATTRNAME(ATTRVALUE)` source code */
  SV *(*parse)(pTHX_ FieldMeta *fieldmeta, SV *valuesrc, void *funcdata);

  /* called immediately at apply time; return FALSE means it did its thing immediately, so don't store it */
  bool (*apply)(pTHX_ FieldMeta *fieldmeta, SV *value, SV **attrdata_ptr, void *funcdata);

  /* called at the end of `has` statement compiletime */
  void (*seal)(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *funcdata);

  /* called as part of accessor generation */
  void (*gen_accessor_ops)(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *funcdata,
          enum AccessorType type, struct AccessorGenerationCtx *ctx);

  /* called by constructor */
  union {
    void (*post_makefield)(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *funcdata, SV *field);

    // This used to be called post_initfield but was badly named because it 
    // actually ran *before* initfields
    void (*post_initfield)(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *funcdata, SV *field);
  };
  void (*post_construct)(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *funcdata, SV *field);

  /* called as part of constructor generation
   * TODO: Not yet used by accessors, but maybe a future version will add a
   * flag to do this.
   */
  OP *(*gen_valueassert_op)(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *funcdata, OP *valueop);
};

struct FieldHook {
  FIELDOFFSET fieldix; /* unused when in FieldMeta->hooks; used by ClassMeta->fieldhooks_* */
  FieldMeta *fieldmeta;
  const struct FieldHookFuncs *funcs;
  void *funcdata;
  SV *attrdata; /* used to be called 'hookdata' */
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

  REPR_KEYS,         /* instances are blessed HASHes, each field lives in an individually-named key */

  REPR_PVOBJ,        /* instances are SVt_PVOBJ on perl 5.38+ */
};

/* Special pad indexes within `method` CVs */
enum {
  PADIX_SELF = 1,
  PADIX_FIELDS = 2,

  /* for role methods */
  PADIX_EMBEDDING = 3,

  /* during initfields */
  PADIX_PARAMS = 4,
};

/* Function prototypes */

#define get_compclassmeta()  ObjectPad_get_compclassmeta(aTHX)
ClassMeta *ObjectPad_get_compclassmeta(pTHX);

#define extend_pad_vars(meta)  ObjectPad_extend_pad_vars(aTHX_ meta)
void ObjectPad_extend_pad_vars(pTHX_ const ClassMeta *meta);

#define get_field_for_padix(padix)  ObjectPad_get_field_for_padix(aTHX_ padix)
FieldMeta *ObjectPad_get_field_for_padix(pTHX_ PADOFFSET padix);

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

/* Deprecated */
#define get_obj_backingav(self, repr, create)  ObjectPad_get_obj_backingav(aTHX_ self, repr, create)
SV *ObjectPad_get_obj_backingav(pTHX_ SV *self, enum ReprType repr, bool create);

#define get_obj_fieldstore(self, repr, create)  ObjectPad_get_obj_fieldstore(aTHX_ self, repr, create)
SV *ObjectPad_get_obj_fieldstore(pTHX_ SV *self, enum ReprType repr, bool create);

#define get_obj_fieldsv(self, fieldmeta)  ObjectPad_get_obj_fieldsv(aTHX_ self, fieldmeta)
SV *ObjectPad_get_obj_fieldsv(pTHX_ SV *self, FieldMeta *fieldmeta);

/* Class API */
#define mop_create_class(type, name)  ObjectPad_mop_create_class(aTHX_ type, name)
ClassMeta *ObjectPad_mop_create_class(pTHX_ enum MetaType type, SV *name);

#define mop_get_class_for_stash(stash)  ObjectPad_mop_get_class_for_stash(aTHX_ stash)
ClassMeta *ObjectPad_mop_get_class_for_stash(pTHX_ HV *stash);

#define mop_class_get_name(class)  ObjectPad_mop_class_get_name(aTHX_ class)
SV *ObjectPad_mop_class_get_name(pTHX_ ClassMeta *class);

#define mop_class_load_and_set_superclass(class, supername, superver)  ObjectPad_mop_class_load_and_set_superclass(aTHX_ class, supername, superver)
void ObjectPad_mop_class_load_and_set_superclass(pTHX_ ClassMeta *class, SV *supername, SV *superver);

#define mop_class_set_superclass(class, super)  ObjectPad_mop_class_set_superclass(aTHX_ class, super)
void ObjectPad_mop_class_set_superclass(pTHX_ ClassMeta *class, SV *superclassname);

#define mop_class_inherit_from_superclass(class, args, nargs)  ObjectPad_mop_class_inherit_from_superclass(aTHX_ class, args, nargs)
void ObjectPad_mop_class_inherit_from_superclass(pTHX_ ClassMeta *class, SV **args, size_t nargs);

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

#define mop_class_add_method_cv(class, methodname, cv)  ObjectPad_mop_class_add_method_cv(aTHX_ class, methodname, cv)
MethodMeta *ObjectPad_mop_class_add_method_cv(pTHX_ ClassMeta *meta, SV *methodname, CV *cv);

#define mop_class_add_field(class, fieldname)  ObjectPad_mop_class_add_field(aTHX_ class, fieldname)
FieldMeta *ObjectPad_mop_class_add_field(pTHX_ ClassMeta *meta, SV *fieldname);

enum {
  FIND_FIELD_ONLY_DIRECT      = (1<<0),
  FIND_FIELD_ONLY_INHERITABLE = (1<<1),
};

#define mop_class_find_field(class, fieldname, flags)  ObjectPad_mop_class_find_field(aTHX_ class, fieldname, flags)
FieldMeta *ObjectPad_mop_class_find_field(pTHX_ ClassMeta *meta, SV *fieldname, U32 flags);

#define mop_class_add_BUILD(class, cv)  ObjectPad_mop_class_add_BUILD(aTHX_ class, cv)
void ObjectPad_mop_class_add_BUILD(pTHX_ ClassMeta *meta, CV *cv);

#define mop_class_add_ADJUST(class, cv)  ObjectPad_mop_class_add_ADJUST(aTHX_ class, cv)
void ObjectPad_mop_class_add_ADJUST(pTHX_ ClassMeta *meta, CV *cv);

#define mop_class_add_required_method(class, methodname)  ObjectPad_mop_class_add_required_method(aTHX_ class, methodname)
void ObjectPad_mop_class_add_required_method(pTHX_ ClassMeta *meta, SV *methodname);

#define mop_class_apply_attribute(classmeta, name, value)  ObjectPad_mop_class_apply_attribute(aTHX_ classmeta, name, value)
void ObjectPad_mop_class_apply_attribute(pTHX_ ClassMeta *classmeta, const char *name, SV *value);

#define mop_class_get_attribute(classmeta, name)  ObjectPad_mop_class_get_attribute(aTHX_ classmeta, name)
struct ClassHook *ObjectPad_mop_class_get_attribute(pTHX_ ClassMeta *classmeta, const char *name);

#define mop_class_get_attribute_values(classmeta, name)  ObjectPad_mop_class_get_attribute_values(aTHX_ classmeta, name)
AV *ObjectPad_mop_class_get_attribute_values(pTHX_ ClassMeta *classmeta, const char *name);

#define register_class_attribute(name, funcs, funcdata)  ObjectPad_register_class_attribute(aTHX_ name, funcs, funcdata)
void ObjectPad_register_class_attribute(pTHX_ const char *name, const struct ClassHookFuncs *funcs, void *funcdata);

/* Field API */
#define mop_create_field(fieldname, fieldix, classmeta)  ObjectPad_mop_create_field(aTHX_ fieldname, fieldix, classmeta)
FieldMeta *ObjectPad_mop_create_field(pTHX_ SV *fieldname, FIELDOFFSET fieldix, ClassMeta *classmeta);

#define mop_field_seal(fieldmeta)  ObjectPad_mop_field_seal(aTHX_ fieldmeta)
void ObjectPad_mop_field_seal(pTHX_ FieldMeta *fieldmeta);

#define mop_field_get_class(fieldmeta)  ObjectPad_mop_field_get_class(aTHX_ fieldmeta)
ClassMeta *ObjectPad_mop_field_get_class(pTHX_ FieldMeta *fieldmeta);

#define mop_field_get_name(fieldmeta)  ObjectPad_mop_field_get_name(aTHX_ fieldmeta)
SV *ObjectPad_mop_field_get_name(pTHX_ FieldMeta *fieldmeta);

#define mop_field_get_sigil(fieldmeta)  ObjectPad_mop_field_get_sigil(aTHX_ fieldmeta)
char ObjectPad_mop_field_get_sigil(pTHX_ FieldMeta *fieldmeta);

#define mop_field_apply_attribute(fieldmeta, name, value)  ObjectPad_mop_field_apply_attribute(aTHX_ fieldmeta, name, value)
void ObjectPad_mop_field_apply_attribute(pTHX_ FieldMeta *fieldmeta, const char *name, SV *value);

#define mop_field_parse_and_apply_attribute(fieldmeta, name, value)  ObjectPad_mop_field_parse_and_apply_attribute(aTHX_ fieldmeta, name, value)
void ObjectPad_mop_field_parse_and_apply_attribute(pTHX_ FieldMeta *fieldmeta, const char *name, SV *value);

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

/* Integration with XS::Parse::Keyword v0.30
 *   To enable this you must #include "XSParseKeyword.h" before this file
 */
#ifdef XPK_STAGED_ANONSUB
  /* These are not really API functions but we need to see them to let these call it */
  void ObjectPad__prepare_method_parse(pTHX_ ClassMeta *meta);
  void ObjectPad__start_method_parse(pTHX_ ClassMeta *meta, bool is_common);
  OP *ObjectPad__finish_method_parse(pTHX_ ClassMeta *meta, bool is_common, OP *body);

  static void opxpk_anonsub_prepare(pTHX_ void *hookdata)
  {
    ObjectPad__prepare_method_parse(aTHX_ get_compclassmeta());
  }

  static void opxpk_anonsub_start(pTHX_ void *hookdata)
  {
    ObjectPad__start_method_parse(aTHX_ get_compclassmeta(), FALSE);
  }

  static OP *opxpk_anonsub_wrap(pTHX_ OP *o, void *hookdata)
  {
    return ObjectPad__finish_method_parse(aTHX_ get_compclassmeta(), FALSE, o);
  }

  /* OPXPK_ANONMETHOD is like XPK_ANONSUB but constructs an anonymous method
   * CV in the currently compiling class. As usual it will have $self and all
   * the field lexicals visible inside it
   */
#define OPXPK_ANONMETHOD_PREPARE   XPK_ANONSUB_PREPARE(&opxpk_anonsub_prepare)
#define OPXPK_ANONMETHOD_START     XPK_ANONSUB_START  (&opxpk_anonsub_start)
#define OPXPK_ANONMETHOD_WRAP      XPK_ANONSUB_WRAP   (&opxpk_anonsub_wrap)

#define OPXPK_ANONMETHOD \
  XPK_STAGED_ANONSUB(         \
    OPXPK_ANONMETHOD_PREPARE, \
    OPXPK_ANONMETHOD_START,   \
    OPXPK_ANONMETHOD_WRAP     \
  )
#endif

#endif
