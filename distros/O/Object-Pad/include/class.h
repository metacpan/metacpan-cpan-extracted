#ifndef __OBJECT_PAD__CLASS_H__
#define __OBJECT_PAD__CLASS_H__

#include "suspended_compcv.h"

#include "linnet.h"

/* Metadata about a class or role */
#define LINNET_VAL_CLASSMETA  0x4F50434D     /* "OPCM" */
#define MUST_CLASSMETA(ptr)   LINNET_CHECK_CAST(ptr, ClassMeta *, LINNET_VAL_CLASSMETA)
struct ClassMeta {
  LINNET_FIELD
  enum MetaType type : 8;
  enum ReprType repr : 8;

  unsigned int begun : 1;
  unsigned int sealed : 1;
  unsigned int role_is_invokable : 1;
  unsigned int strict_params : 1;
  unsigned int has_adjust : 1; /* has at least one ADJUST(PARAMS) block */
  unsigned int composed_adjust : 1; /* all ADJUST blocks are true blocks, composed into initfields */
  unsigned int has_superclass : 1;
  unsigned int has_buildargs : 1;

  FIELDOFFSET start_fieldix; /* first field index of this partial within its instance */
  FIELDOFFSET next_fieldix;  /* 1 + final field index of this partial within its instance; includes fields in roles */

  /* In the following, "MERGED" means the item includes elements merged from a
   * superclass if present, and any applied roles
   * "direct" means only the things added directly to this exact class/role
   */

  SV *name;
  HV *stash;
  AV *isa;             /* cached pointer to the @ISA array for the stash */
  AV *pending_submeta; /* NULL, or AV containing raw ClassMeta pointers to subclasses pending seal */
  AV *hooks;           /* NULL, or AV of raw pointers directly to ClassHook structs */
  AV *fields;          /* each elem is a raw pointer directly to a FieldMeta */
  AV *direct_methods;  /* each elem is a raw pointer directly to a MethodMeta */
  HV *parammap;        /* NULL, or each elem is a raw pointer directly at a ParamMeta (MERGED) */
  AV *requiremethods;  /* each elem is an SVt_PV giving a name */
  CV *initfields;      /* the INITFIELDS method body */
  AV *buildcvs;        /* the BUILD {} phaser blocks; each elem is a CV* directly (MERGED) */
  AV *adjustcvs;       /* the ADJUST {} phaser blocks; each elem is a CV* directly (MERGED) */

  AV *fieldhooks_makefield; /* NULL, or AV of struct FieldHook, all of whose ->funcs->post_makefield exist (MERGED) */
  AV *fieldhooks_construct; /* NULL, or AV of struct FieldHook, all of whose ->funcs->post_construct exist (MERGED) */

  COP *tmpcop;         /* a COP to use during generated constructor */
  CV *methodscope;     /* a temporary CV used just during compilation of a `method` */
  U32 methodscope_seq; /* PL_cop_seqmax at the time methodscope was created */

  SuspendedCompCVBuffer initfields_compcv; /* temporary PL_compcv + associated state during initfields */
  OP *initfields_lines;                    /* temporary OP_LINESEQ to contain the initfield ops */
  U32 next_field_for_initfields;           /* how many fields have we seen so far? (offset into direct_fields, !NOT! fieldix) */

  SuspendedCompCVBuffer adjust_compcv; /* temporary PL_compcv + associated state during true-block ADJUSTs */
  CV *adjust_methodscope;              /* temporary CV used during compilation of ADJUST blocks */
  AV *adjust_params;                   /* temporary AV of the params used by true-block ADJUST :params */
  OP *adjust_lines;                    /* temporary OP_LINESEQ to contain true-block ADJUSTs */
  U32 next_field_for_adjust;           /* how many fields have we seen so far? (offset into direct_fields; !NOT! fieldix) */

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
#define LINNET_VAL_ROLEEMBEDDING  0x4F505245  /* "OPRE" */
#define MUST_ROLEEMBEDDING(ptr)   LINNET_CHECK_CAST(ptr, RoleEmbedding *, LINNET_VAL_ROLEEMBEDDING)
typedef struct RoleEmbedding {
  LINNET_FIELD
  SV *embeddingsv;
  struct ClassMeta *rolemeta;
  struct ClassMeta *classmeta;
  PADOFFSET offset;
} RoleEmbedding;

#define LINNET_VAL_METHODMETA  0x4F504D4D  /* "OPMM" */
#define MUST_METHODMETA(ptr)   LINNET_CHECK_CAST(ptr, MethodMeta *, LINNET_VAL_METHODMETA)
struct MethodMeta {
  LINNET_FIELD
  SV *name;
  ClassMeta *class;
  ClassMeta *role;   /* set if inherited from a role */
  /* We don't store the method body CV; leave that in the class stash */
  unsigned int is_common : 1;
};

#define LINNET_VAL_PARAMMETA  0x4F50504D  /* "OPPM" */
#define MUST_PARAMMETA(ptr)   LINNET_CHECK_CAST(ptr, ParamMeta *, LINNET_VAL_PARAMMETA)
typedef struct ParamMeta {
  LINNET_FIELD
  SV *name;
  ClassMeta *class;
  enum {
    PARAM_FIELD,
    PARAM_ADJUST,
  } type;
  union {
    struct {
      FieldMeta *fieldmeta;
      FIELDOFFSET fieldix;
    } field;
    struct {
      /* TODO: store the block itself sometime?? */
      PADOFFSET padix;
      OP *defexpr;
      unsigned int def_if_undef : 1;
      unsigned int def_if_false : 1;
    } adjust;
  };
} ParamMeta;

#define MOP_CLASS_RUN_HOOKS_NOARGS(classmeta, func)                                       \
  {                                                                                       \
    U32 hooki;                                                                            \
    for(hooki = 0; classmeta->hooks && hooki < av_count(classmeta->hooks); hooki++) {     \
      struct ClassHook *h = (struct ClassHook *)AvARRAY(classmeta->hooks)[hooki];         \
      if(*h->funcs->func)                                                                 \
        (*h->funcs->func)(aTHX_ classmeta, h->attrdata, h->funcdata);                     \
    }                                                                                     \
  }

#define MOP_CLASS_RUN_HOOKS(classmeta, func, ...)                                         \
  {                                                                                       \
    U32 hooki;                                                                            \
    for(hooki = 0; classmeta->hooks && hooki < av_count(classmeta->hooks); hooki++) {     \
      struct ClassHook *h = (struct ClassHook *)AvARRAY(classmeta->hooks)[hooki];         \
      if(*h->funcs->func)                                                                 \
        (*h->funcs->func)(aTHX_ classmeta, h->attrdata, h->funcdata, __VA_ARGS__);        \
    }                                                                                     \
  }

#define mop_class_get_direct_roles(class, embeddings)  ObjectPad_mop_class_get_direct_roles(aTHX_ class, embeddings)
RoleEmbedding **ObjectPad_mop_class_get_direct_roles(pTHX_ const ClassMeta *meta, U32 *nroles);

#define mop_class_get_all_roles(class, embeddings)  ObjectPad_mop_class_get_all_roles(aTHX_ class, embeddings)
RoleEmbedding **ObjectPad_mop_class_get_all_roles(pTHX_ const ClassMeta *meta, U32 *nroles);

#define prepare_method_parse(meta)  ObjectPad__prepare_method_parse(aTHX_ meta)
void ObjectPad__prepare_method_parse(pTHX_ ClassMeta *meta);

#define add_fields_to_pad(meta, since_field)  ObjectPad__add_fields_to_pad(aTHX_ meta, since_field)
void ObjectPad__add_fields_to_pad(pTHX_ ClassMeta *meta, U32 since_field);

#define start_method_parse(meta, is_common)  ObjectPad__start_method_parse(aTHX_ meta, is_common)
void ObjectPad__start_method_parse(pTHX_ ClassMeta *meta, bool is_common);

#define finish_method_parse(meta, is_common, body)  ObjectPad__finish_method_parse(aTHX_ meta, is_common, body)
OP *ObjectPad__finish_method_parse(pTHX_ ClassMeta *meta, bool is_common, OP *body);

#define prepare_adjust_params(meta)  ObjectPad__prepare_adjust_params(aTHX_ meta)
void ObjectPad__prepare_adjust_params(pTHX_ ClassMeta *meta);

#define parse_adjust_params(meta, params)  ObjectPad__parse_adjust_params(aTHX_ meta, params)
void ObjectPad__parse_adjust_params(pTHX_ ClassMeta *meta, AV *params);

#define finish_adjust_params(meta, params, body)  ObjectPad__finish_adjust_params(aTHX_ meta, params, body)
OP *ObjectPad__finish_adjust_params(pTHX_ ClassMeta *meta, AV *params, OP *body);

#define newop_croak_from_constructor(message)  ObjectPad__newop_croak_from_constructor(aTHX_ message)
OP *ObjectPad__newop_croak_from_constructor(pTHX_ SV *message);

#define check_colliding_param(classmeta, paramname)  ObjectPad__check_colliding_param(aTHX_ classmeta, paramname)
void ObjectPad__check_colliding_param(pTHX_ ClassMeta *classmeta, SV *paramname);

#define get_embedding_from_pad()  ObjectPad__get_embedding_from_pad(aTHX)
RoleEmbedding *ObjectPad__get_embedding_from_pad(pTHX);

void ObjectPad__boot_classes(pTHX);

/* Empty role embedding that is applied to all invokable role methods */
extern struct RoleEmbedding ObjectPad__embedding_standalone;

#ifdef HAVE_UNOP_AUX
#  define METHSTART_CONTAINS_FIELD_BINDINGS

/* We'll reserve the top two bits of a UV for storing the `type` value for a
 * fieldpad operation; the remainder stores the fieldix itself */
#  define UVBITS (UVSIZE*8)
#  define FIELDIX_TYPE_SHIFT  (UVBITS-2)
#  define FIELDIX_MASK        ((1LL<<FIELDIX_TYPE_SHIFT)-1)
#endif

#if HAVE_PERL_VERSION(5, 38, 0)
#  define HAVE_SVt_PVOBJ

#  define fieldstore_fields(fs)   \
      ((SvTYPE(fs) == SVt_PVOBJ) ? ObjectFIELDS(fs) : AvARRAY(fs))
#  define fieldstore_maxfield(fs) \
      ((SvTYPE(fs) == SVt_PVOBJ) ? ObjectMAXFIELD(fs) : AvFILLp(fs))
#else
#  define fieldstore_fields(fs)   \
      AvARRAY(fs)
#  define fieldstore_maxfield(fs) \
      AvFILLp(fs)
#endif

#endif
