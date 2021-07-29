#ifndef __OBJECT_PAD__TYPES_H__
#define __OBJECT_PAD__TYPES_H__

typedef void AttributeHandler(pTHX_ void *target, const char *value, void *data);

struct AttributeDefinition {
  char *attrname;
  /* TODO: int flags */
  AttributeHandler *apply;
  void *applydata;
};

/* A SLOTOFFSET is an offset within the AV of an object instance */
typedef IV SLOTOFFSET;

typedef struct ClassMeta ClassMeta;
typedef struct SlotMeta SlotMeta;

enum AccessorType {
  ACCESSOR,
  ACCESSOR_READER,
  ACCESSOR_WRITER,
  ACCESSOR_LVALUE_MUTATOR,
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

struct SlotHookFuncs {
  U32 flags;
  const char *permit_hintkey;

  /* called immediately at apply time; return TRUE means it did its thing immediately */
  bool (*apply)(pTHX_ SlotMeta *slotmeta, SV *value);

  /* called as part of accessor generation */
  void (*gen_accessor_ops)(pTHX_ SlotMeta *slotmeta, SV *hookdata, enum AccessorType type,
          struct AccessorGenerationCtx *ctx);

  void (*post_initslot)(pTHX_ SlotMeta *slotmeta, SV *hookdata, SV *slot); /* called by constructor */
};

struct SlotHook {
  const struct SlotHookFuncs *funcs;
  SV *hookdata;
};

struct SlotMeta {
  SV *name;
  ClassMeta *class;
  SV *defaultsv;
  SLOTOFFSET slotix;
  SV *readername, *writername, *mutatorname; /* accessor method names */
  AV *hooks; /* NULL, or AV of raw pointers directly to SlotHook structs */
};

typedef struct MethodMeta {
  SV *name;
  ClassMeta *class;
  ClassMeta *role;   /* set if inherited from a role */
  /* We don't store the method body CV; leave that in the class stash */
} MethodMeta;

typedef struct ParamMeta {
  SV *name;
  SlotMeta *slot;
  SLOTOFFSET slotix;
} ParamMeta;

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

/* Metadata about a class or role */
struct ClassMeta {
  enum MetaType type : 8;
  enum ReprType repr : 8;

  unsigned int sealed : 1;
  unsigned int role_is_invokable : 1;
  unsigned int strict_params : 1;

  SLOTOFFSET start_slotix; /* first slot index of this partial within its instance */
  SLOTOFFSET next_slotix;  /* 1 + final slot index of this partial within its instance; includes slots in roles */

  SV *name;
  HV *stash;
  ClassMeta *supermeta;
  AV *pending_submeta; /* NULL, or AV containing raw ClassMeta pointers to subclasses pending seal */
  AV *roles;           /* each elem is a raw pointer directly to a RoleEmbedding whose type == METATYPE_ROLE */
  AV *slots;           /* each elem is a raw pointer directly to a SlotMeta */
  AV *methods;         /* each elem is a raw pointer directly to a MethodMeta */
  HV *parammap;        /* NULL, or each elem is a raw pointer directly at a ParamMeta */
  SV *requireslots;    /* NULL, or the PV is a bitmap of which slots are required params */
  AV *requiremethods;  /* each elem is an SVt_PV giving a name */
  CV *foreign_new;     /* superclass is not Object::Pad, here is the constructor */
  CV *foreign_does;    /* superclass is not Object::Pad, here is SUPER::DOES (which could be UNIVERSAL::DOES) */
  CV *initslots;       /* the INITSLOTS method body */
  AV *buildblocks;     /* the BUILD {} phaser blocks; each elem is a CV* directly */
  AV *adjustblocks;    /* the ADJUST {} phaser blocks; each elem is a CV* directly */

  COP *tmpcop;         /* a COP to use during generated constructor */
  CV *methodscope;     /* a temporary CV used just during compilation of a `method` */
};

/* Metadata about the embedding of a role into a class */
typedef struct RoleEmbedding {
  SV *embeddingsv;
  struct ClassMeta *rolemeta;
  struct ClassMeta *classmeta;
  PADOFFSET offset;
} RoleEmbedding;

/* Special pad indexes within `method` CVs */
enum {
  PADIX_SELF = 1,
  PADIX_SLOTS = 2,

  /* for role methods */
  PADIX_EMBEDDING = 3,
};

/* Function prototypes */

#define extend_pad_vars(meta)  ObjectPad_extend_pad_vars(aTHX_ meta)
void ObjectPad_extend_pad_vars(pTHX_ const ClassMeta *meta);

#define newMETHSTARTOP(flags, private)  ObjectPad_newMETHSTARTOP(flags, private)
OP *ObjectPad_newMETHSTARTOP(I32 flags, U8 private);

OP *ObjectPad_newSVOP(SV *sv);

#define get_obj_slotsav(self, repr, create)  ObjectPad_obj_get_slotsav(aTHX_ self, repr, create)
SV *ObjectPad_obj_get_slotsav(pTHX_ SV *self, enum ReprType repr, bool create);

/* Class API */
#define mop_create_class(type, name, super)  ObjectPad_mop_create_class(aTHX_ type, name, super)
ClassMeta *ObjectPad_mop_create_class(pTHX_ enum MetaType type, SV *name, SV *superclassname);

#define mop_class_seal(meta)  ObjectPad_mop_class_seal(aTHX_ meta)
void ObjectPad_mop_class_seal(pTHX_ ClassMeta *meta);

#define mop_class_add_method(class, methodname)  ObjectPad_mop_class_add_method(aTHX_ class, methodname)
MethodMeta *ObjectPad_mop_class_add_method(pTHX_ ClassMeta *meta, SV *methodname);

#define mop_class_add_slot(class, slotname)  ObjectPad_mop_class_add_slot(aTHX_ class, slotname)
SlotMeta *ObjectPad_mop_class_add_slot(pTHX_ ClassMeta *meta, SV *slotname);

#define mop_class_add_BUILD(class, cv)  ObjectPad_mop_class_add_BUILD(aTHX_ class, cv)
void ObjectPad_mop_class_add_BUILD(pTHX_ ClassMeta *meta, CV *cv);

#define mop_class_add_ADJUST(class, cv)  ObjectPad_mop_class_add_ADJUST(aTHX_ class, cv)
void ObjectPad_mop_class_add_ADJUST(pTHX_ ClassMeta *meta, CV *cv);

#define mop_class_compose_role(class, role)  ObjectPad_mop_class_compose_role(aTHX_ class, role)
void ObjectPad_mop_class_compose_role(pTHX_ ClassMeta *classmeta, ClassMeta *rolemeta);

#define mop_class_apply_role(embedding)  ObjectPad_mop_class_apply_role(aTHX_ embedding)

/* Slot API */
#define mop_create_slot(slotname, classmeta)  ObjectPad_mop_create_slot(aTHX_ slotname, classmeta)
SlotMeta *ObjectPad_mop_create_slot(pTHX_ SV *slotname, ClassMeta *classmeta);

#define mop_slot_set_param(slotmeta, paramname)  ObjectPad_mop_slot_set_param(aTHX_ slotmeta, paramname)
void ObjectPad_mop_slot_set_param(pTHX_ SlotMeta *slotmeta, const char *paramname);

#define mop_slot_apply_attribute(slotmeta, name, value)  ObjectPad_mop_slot_apply_attribute(aTHX_ slotmeta, name, value)
void ObjectPad_mop_slot_apply_attribute(pTHX_ SlotMeta *slotmeta, const char *name, SV *value);

#define MOP_SLOT_RUN_HOOKS(slotmeta, func, ...)                                           \
  {                                                                                       \
    U32 hooki;                                                                            \
    for(hooki = 0; slotmeta->hooks && hooki < av_count(slotmeta->hooks); hooki++) {       \
      struct SlotHook *h = (struct SlotHook *)AvARRAY(slotmeta->hooks)[hooki];            \
      if(*h->funcs->func)                                                                 \
        (*h->funcs->func)(aTHX_ slotmeta, h->hookdata, __VA_ARGS__);                      \
    }                                                                                     \
  }

#define register_slot_attribute(name, funcs)  ObjectPad_register_slot_attribute(aTHX_ name, funcs)
void ObjectPad_register_slot_attribute(pTHX_ const char *name, const struct SlotHookFuncs *funcs);

/* internal API - not for user use */

void ObjectPad__boot_slots(void);

#endif
