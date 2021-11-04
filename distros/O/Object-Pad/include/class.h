#ifndef __OBJECT_PAD__CLASS_H__
#define __OBJECT_PAD__CLASS_H__

#include "suspended_compcv.h"

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

  /* In the following, "MERGED" means the item includes elements merged from a
   * superclass if present, and any applied roles
   * "direct" means only the things added directly to this exact class/role
   */

  SV *name;
  HV *stash;
  AV *pending_submeta; /* NULL, or AV containing raw ClassMeta pointers to subclasses pending seal */
  AV *hooks;           /* NULL, or AV of raw pointers directly to ClassHook structs */
  AV *direct_slots;    /* each elem is a raw pointer directly to a SlotMeta */
  AV *direct_methods;  /* each elem is a raw pointer directly to a MethodMeta */
  HV *parammap;        /* NULL, or each elem is a raw pointer directly at a ParamMeta (MERGED) */
  AV *requiremethods;  /* each elem is an SVt_PV giving a name */
  CV *initslots;       /* the INITSLOTS method body */
  AV *buildblocks;     /* the BUILD {} phaser blocks; each elem is a CV* directly (MERGED) */
  AV *adjustblocks;    /* the ADJUST {} phaser blocks; each elem is a AdjustBlock* (MERGED) */

  AV *slothooks_postslots; /* NULL, or AV of struct SlotHook, all of whose ->funcs->post_initslot exist (MERGED) */
  AV *slothooks_construct; /* NULL, or AV of struct SlotHook, all of whose ->funcs->post_construct exist (MERGED) */

  COP *tmpcop;         /* a COP to use during generated constructor */
  CV *methodscope;     /* a temporary CV used just during compilation of a `method` */

  SuspendedCompCVBuffer initslots_compcv; /* temporary PL_compcv + associated state during initslots */

  union {
    /* Things that only true classes have */
    struct {
      ClassMeta *supermeta; /* superclass */
      CV *foreign_new;      /* superclass is not Object::Pad, here is the constructor */
      CV *foreign_does;     /* superclass is not Object::Pad, here is SUPER::DOES (which could be UNIVERSAL::DOES) */
      AV *direct_roles;     /* each elem is a raw pointer directly to a RoleEmbedding for roles directly applied to this class */
      AV *embedded_roles;   /* each elem is a raw pointer directly to a RoleEmbedding for all roles embedded (MERGED) */
    } cls; /* not 'class' or C++ compilers get upset */

    /* Things that only roles have */
    struct {
      AV *superroles;      /* each elem is a raw pointer directly to a ClassMeta whose type == METATYPE_ROLE */
      HV *applied_classes; /* keyed by class name each elem is a raw pointer directly to a RoleEmbedding */
    } role;
  };
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

#define mop_class_get_direct_roles(class, embeddings)  ObjectPad_mop_class_get_direct_roles(aTHX_ class, embeddings)
RoleEmbedding **ObjectPad_mop_class_get_direct_roles(pTHX_ const ClassMeta *meta, U32 *nroles);

#define mop_class_get_all_roles(class, embeddings)  ObjectPad_mop_class_get_all_roles(aTHX_ class, embeddings)
RoleEmbedding **ObjectPad_mop_class_get_all_roles(pTHX_ const ClassMeta *meta, U32 *nroles);

void ObjectPad__boot_classes(void);

#endif
