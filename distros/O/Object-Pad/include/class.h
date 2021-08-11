#ifndef __OBJECT_PAD__CLASS_H__
#define __OBJECT_PAD__CLASS_H__

typedef struct AdjustBlock {
  unsigned int is_adjustparams : 1;
  CV *cv;
} AdjustBlock;

/* Metadata about a class or role */
struct ClassMeta {
  enum MetaType type : 8;
  enum ReprType repr : 8;

  unsigned int sealed : 1;
  unsigned int role_is_invokable : 1;
  unsigned int strict_params : 1;
  unsigned int has_adjustparams : 1; /* has at least one ADJUSTPARAMS block */

  SLOTOFFSET start_slotix; /* first slot index of this partial within its instance */
  SLOTOFFSET next_slotix;  /* 1 + final slot index of this partial within its instance; includes slots in roles */

  SV *name;
  HV *stash;
  ClassMeta *supermeta;
  AV *pending_submeta; /* NULL, or AV containing raw ClassMeta pointers to subclasses pending seal */
  AV *hooks;           /* NULL, or AV of raw pointers directly to ClassHook structs */
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
  AV *adjustblocks;    /* the ADJUST {} phaser blocks; each elem is a AdjustBlock* */

  AV *slothooks_postslots; /* NULL, or AV of struct SlotHook, all of whose ->funcs->post_initslot exist */
  AV *slothooks_construct; /* NULL, or AV of struct SlotHook, all of whose ->funcs->post_construct exist */

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

struct MethodMeta {
  SV *name;
  ClassMeta *class;
  ClassMeta *role;   /* set if inherited from a role */
  /* We don't store the method body CV; leave that in the class stash */
};

typedef struct ParamMeta {
  SV *name;
  SlotMeta *slot;
  SLOTOFFSET slotix;
} ParamMeta;

#define MOP_CLASS_RUN_HOOKS(classmeta, func, ...)                                         \
  {                                                                                       \
    U32 hooki;                                                                            \
    for(hooki = 0; classmeta->hooks && hooki < av_count(classmeta->hooks); hooki++) {     \
      struct ClassHook *h = (struct ClassHook *)AvARRAY(classmeta->hooks)[hooki];         \
      if(*h->funcs->func)                                                                 \
        (*h->funcs->func)(aTHX_ classmeta, h->hookdata, __VA_ARGS__);                     \
    }                                                                                     \
  }

void ObjectPad__boot_classes(void);

#endif
