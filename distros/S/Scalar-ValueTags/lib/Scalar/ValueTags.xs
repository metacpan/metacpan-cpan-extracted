#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef HAVE_DMD_HELPER
#  define WANT_DMD_API_044
#  include "DMD_helper.h"
#endif

#if defined(sv_magicv2_add)
#  define HAVE_VALUE_MAGIC
#endif

// outside of HAVE_VALUE_MAGIC, since SVTAGS_* needs to return the values
// FIXME: how should API functions behave without scalar value magic?
enum behavior_types {
    BEHAVIOR_UNIQUE_REF_ARRAY,
    BEHAVIOR_APPEND_ARRAY,
    BEHAVIOR_HASH_COUNT,
    BEHAVIOR_UNIQUE_HASH,
    MAX_BEHAVIOR
};

#ifdef HAVE_VALUE_MAGIC
#  define ENTER_DISARM_PROPAGATE \
  ENTER;  \
  SAVESPTR(PL_valuemagic_annotations); PL_valuemagic_annotations = NULL

#  define LEAVE_DISARM_PROPAGATE \
  LEAVE

typedef struct {
    struct ValueTagsSpec *vt_specs;
    struct ValueTagsSpec *final_vt_spec;
} my_cxt_t;

START_MY_CXT

/*** Structs ***/

struct ValueTagsUserStruct {
    SV *value_tags;
};

struct ValueTagsBehavior {
    SV*  (*make_tags)(pTHX);
    SV*  (*dup_tags)(pTHX_ SV *tags);
    void (*free_tags)(pTHX_ SV *sv, MAGIC *mg);   // FIXME: needed?
    void (*add_tag)(pTHX_ SV *tags, SV *tag);
    void (*remove_tag)(pTHX_ SV *tags, SV *tag);
    void (*merge_tags)(pTHX_ SV *src_tags, SV *dst_tags);
    SV*  (*make_retval)(pTHX_ MAGIC *mg);
};

struct ValueTagsSpec {
    struct ValueTagsSpec           *next;
    SV                             *vt_type;
    const struct ValueTagsBehavior *behavior;
};

#define VALUETAGS(mg) (MgUSERSTRUCT(mg, struct ValueTagsUserStruct *)->value_tags)

#define VALID_VT_TYPE_REF(ref) (SvROK(ref) && SvTYPE(SvRV(ref)) <= SVt_PVMG)
#define VALID_AV_TAGS(sv) (SvTYPE(sv) == SVt_PVAV)
#define VALID_HV_TAGS(sv) (SvTYPE(sv) == SVt_PVHV)

/*** UTILTIIES ***/

static void av_append_tag(pTHX_ AV *av, SV *tag, bool check_uniq)
{
    assert(SvOK(tag));

    if (check_uniq) {
        SV **svp = AvARRAY(av);
        Size_t count = av_count(av);
        for(U32 idx = 0; idx < count; idx++) {
            // Skip duplicates
            if(SvROK(svp[idx]) && SvRV(tag) == SvRV(svp[idx])) {
                return;
            }
        }
    }

    SV *ret = newSVsv(tag);
    av_push_simple(av, ret);
}

static void add_tag_unique_ref_array (pTHX_ SV *tags, SV *tag)
{
    assert(VALID_AV_TAGS(tags));
    assert(SvROK(tag));

    // always check_uniq
    av_append_tag(aTHX_ (AV *)tags, tag, true);
}

static void remove_tag_unique_ref_array (pTHX_ SV *tags, SV *tag)
{
    assert(VALID_AV_TAGS(tags));
    assert(SvROK(tag));

    AV *av = (AV *) tags;
    SV **svp = AvARRAY(av);
    SV **top = svp + AvFILL(av);
    for (SV **cur = svp; cur <= top; cur++) {
        if (SvROK(*cur) && SvRV(tag) == SvRV(*cur)) {
            SvREFCNT_dec_NN(*cur);
            Move(cur + 1, cur, top - cur, SV *);
            *top = NULL;
            top--;
            AvFILLp(av)--;
            break;
        }
    }
}

static void merge_tags_unique_ref_array (pTHX_ SV *src_tags, SV *dst_tags)
{
    assert(VALID_AV_TAGS(src_tags));
    assert(VALID_AV_TAGS(dst_tags));

    // no need to check uniqueness if destination has no tags
    bool check_uniq = av_count((AV *)dst_tags);

    AV *src_av = (AV *)src_tags;
    SV **svp = AvARRAY(src_av);
    Size_t count = av_count(src_av);
    for (U32 idx = 0; idx < count; idx++) {
        av_append_tag(aTHX_ (AV *)dst_tags, svp[idx], check_uniq);
    }
}

static void add_tag_append_array (pTHX_ SV *tags, SV *tag)
{
    assert(VALID_AV_TAGS(tags));
    assert(SvOK(tag));

    // never check_uniq
    av_append_tag(aTHX_ (AV *)tags, tag, false);
}

// removes all matching tags from array
static void remove_tag_append_array (pTHX_ SV *tags, SV *tag)
{
    assert(VALID_AV_TAGS(tags));
    assert(SvROK(tag));

    AV *av = (AV *) tags;
    SV **svp = AvARRAY(av);
    SV **top = svp + AvFILL(av);
    SV **cur = svp;
    while (cur <= top) {
        if (SvROK(*cur) && SvRV(tag) == SvRV(*cur)) {
            SvREFCNT_dec_NN(*cur);
            Move(cur + 1, cur, top - cur, SV *);
            *top = NULL;
            top--;
            AvFILLp(av)--;
        }
        else {
            cur++;
        }
    }
}

static void merge_tags_append_array (pTHX_ SV *src_tags, SV *dst_tags)
{
    assert(VALID_AV_TAGS(src_tags));
    assert(VALID_AV_TAGS(dst_tags));

    AV *oav = (AV *)src_tags;
    SV **svp = AvARRAY(oav);
    Size_t count = av_count(oav);
    for (U32 idx = 0; idx < count; idx++) {
        // never check_uniq; always append
        av_append_tag(aTHX_ (AV *)dst_tags, svp[idx], false);
    }
}

static void add_tag_hash_count(pTHX_ SV *tags, SV *tag)
{
    assert(VALID_HV_TAGS(tags));
    assert(tag);

    ENTER_DISARM_PROPAGATE;    // avoid PL_valuemagic_annotations copying of magic
    HV *hv = (HV *)tags;
    HE *he = hv_fetch_ent(hv, tag, TRUE, 0);
    SV *val = HeVAL(he);

    IV new_val = 1;
    if (SvOK(val))
        new_val += SvIV(val);

    sv_setiv(val, new_val);
    LEAVE_DISARM_PROPAGATE;
}

static void remove_tag_hash_count(pTHX_ SV *tags, SV *tag)
{
    assert(VALID_HV_TAGS(tags));
    assert(SvPOK(tag));

    ENTER_DISARM_PROPAGATE;
    HV *hv = (HV *)tags;
    HE *he = hv_fetch_ent(hv, tag, FALSE, 0);

    if (he) {
        SV *sv = HeVAL(he);
        IV val = SvIV(sv);
        if ( val > 1 ) {
            sv_setiv(sv, val - 1 );
        }
        else {
            hv_delete(hv, HeKEY(he), HeKLEN(he), G_DISCARD);
        }
    }
}

static void merge_tags_hash_count(pTHX_ SV *src_tags, SV *dst_tags)
{
    assert(VALID_HV_TAGS(src_tags));
    assert(VALID_HV_TAGS(dst_tags));

    HV *src_hv = (HV *)src_tags;
    HV *dst_hv = (HV *)dst_tags;

    hv_iterinit(src_hv);

    HE *src_he;
    ENTER_DISARM_PROPAGATE;    // avoid PL_valuemagic_annotations copying of magic on hash values
    while (src_he = hv_iternext(src_hv)) {
        IV new_val = SvIV(HeVAL(src_he));
        SV **dst_valp = hv_fetch(dst_hv, HeKEY(src_he), HeKLEN(src_he), TRUE);
        if (dst_valp && *dst_valp && SvIOK(*dst_valp))
            new_val += SvIV(*dst_valp);

        sv_setiv(*dst_valp, new_val);
    }
    LEAVE_DISARM_PROPAGATE;
}

static void add_tag_unique_hash(pTHX_ SV *tags, SV *tag)
{
    assert(VALID_HV_TAGS(tags));
    assert(SvPOK(tag));

    HV *hv = (HV *)tags;
    HE *he = hv_fetch_ent(hv, tag, TRUE, 0);

    SV *val = HeVAL(he);
    if (!SvOK(val))
        sv_set_true(val);
}

static void remove_tag_unique_hash(pTHX_ SV *tags, SV *tag)
{
    assert(VALID_HV_TAGS(tags));
    assert(SvPOK(tag));

    HV *hv = (HV *)tags;
    HE *he = hv_fetch_ent(hv, tag, FALSE, 0);

    if (he) {
        hv_delete(hv, HeKEY(he), HeKLEN(he), G_DISCARD);
    }
}

static void merge_tags_unique_hash(pTHX_ SV *src_tags, SV *dst_tags)
{
    assert(VALID_HV_TAGS(src_tags));
    assert(VALID_HV_TAGS(dst_tags));

    HV *src_hv = (HV *)src_tags;
    HV *dst_hv = (HV *)dst_tags;

    hv_iterinit(src_hv);

    HE *src_he;
    while (src_he = hv_iternext(src_hv)) {
        SV **dst_valp = hv_fetch(dst_hv, HeKEY(src_he), HeKLEN(src_he), TRUE);
        if (!SvOK(*dst_valp))
            sv_set_true(*dst_valp);
    }
}

/*** FORWARD DECLARATIONS FOR MAGIC HANDLING ***/
#define get_value_tags_magic(vt_type, sv)  S_get_value_tags_magic(aTHX_ vt_type, sv)
static MAGIC *S_get_value_tags_magic(pTHX_ SV *vt_type, SV *sv);

#define add_value_tags_magic(vt_type, sv, value_tags)  S_add_value_tags_magic(aTHX_ vt_type, sv, value_tags)
static MAGIC *S_add_value_tags_magic(pTHX_ SV *vt_type, SV *sv, SV *value_tags);

#define init_value_tags_magic(vt_type, sv, value_tags)  S_init_value_tags_magic(aTHX_ vt_type, sv, value_tags)
static MAGIC *S_init_value_tags_magic(pTHX_ SV *vt_type, SV *sv, SV *value_tags);

#define remove_value_tags_magic(vt_type, sv)  S_remove_value_tags_magic(aTHX_ vt_type, sv)
static MAGIC *S_remove_value_tags_magic(pTHX_ SV *vt_type, SV *sv);

#define get_vt_spec(vt_type) S_get_vt_spec(aTHX_ vt_type)
static struct ValueTagsSpec *S_get_vt_spec(pTHX_ SV *vt_type);

/*** BEHAVIORS ***/

static SV *make_array_value_tags(pTHX)
{
    return (SV *)newAV();
}

static SV *make_hash_value_tags(pTHX)
{
    return (SV *)newHV();
}

static SV *dup_array_value_tags(pTHX_ SV *value_tags)
{
    return (SV *)newAVav((AV *)value_tags);
}

static SV *dup_hash_value_tags(pTHX_ SV *value_tags)
{
    return (SV *)newHVhv((HV *)value_tags);
}

static void free_value_tags(pTHX_ SV *sv, MAGIC *mg)
{
    assert(sv);
    assert(mg);     // Just In Case
    SV *vt = VALUETAGS(mg);
    if (vt) {
        SvREFCNT_dec(vt);
        VALUETAGS(mg) = NULL;
    }
}

static SV *make_array_retval(pTHX_ MAGIC *mg)
{
    if (!mg)
        return newRV((SV *)newAV());

    SV *vt = VALUETAGS(mg);
    assert(SvTYPE(vt) == SVt_PVAV);

    AV *results = newAVav((AV *)vt);

    return newRV((SV *)results);
}

static SV *make_hash_retval(pTHX_ MAGIC *mg)
{
    if (!mg)
        return newRV((SV *)newHV());

    SV *vt = VALUETAGS(mg);
    assert(SvTYPE(vt) == SVt_PVHV);
    HV *results = newHVhv((HV *)vt);

    return newRV((SV *)results);
}

static void propagate_value_tags(pTHX_ SV *src_sv, MAGIC *src_mg, SV *dst_sv, MAGIC *dst_mg)
{
    assert(src_sv);
    assert(src_mg);
    assert(dst_sv);
    assert(!dst_mg);

    SV *src_tags = VALUETAGS(src_mg);
    if (!src_tags) {
        return;
    }

    SV *vt_type = MgAUXSV(src_mg);
    struct ValueTagsSpec *vt_spec = get_vt_spec(vt_type);

    // dst_mg is never passed in, since MGv2f_SCALARVALUE_AUTOPROPAGATE is not set
    dst_mg = get_value_tags_magic(vt_type, dst_sv);

    if (dst_mg) {
        vt_spec->behavior->merge_tags(aTHX_ src_tags, VALUETAGS(dst_mg));
    }
    else {
        SV *dst_tags = vt_spec->behavior->dup_tags(aTHX_ src_tags);
        add_value_tags_magic(vt_type, dst_sv, dst_tags);
    }
}

#ifdef DEBUG_TRACE_ANNOTATIONS
        // FIXME: handle adding trace magic somewhere
        // copying existing annotation: sv will always have debug tracing
//      if(new) {
//          sv_magicext(new, (SV *)make_traceav_copy(svp[idx]), PERL_MAGIC_ext, &vtbl_hound_debugtrace, NULL, 0);
//      }
#endif

static const struct ValueTagsBehavior behaviors[] = {
    [BEHAVIOR_UNIQUE_REF_ARRAY] = {
        .make_tags   = &make_array_value_tags,
        .dup_tags    = &dup_array_value_tags,
        .free_tags   = &free_value_tags,
        .make_retval = &make_array_retval,
        .add_tag     = &add_tag_unique_ref_array,
        .remove_tag  = &remove_tag_unique_ref_array,
        .merge_tags  = &merge_tags_unique_ref_array,
    },
    [BEHAVIOR_APPEND_ARRAY] = {
        .make_tags   = &make_array_value_tags,
        .dup_tags    = &dup_array_value_tags,
        .free_tags   = &free_value_tags,
        .make_retval = &make_array_retval,
        .add_tag     = &add_tag_append_array,
        .remove_tag  = &remove_tag_append_array,
        .merge_tags  = &merge_tags_append_array,
    },
    [BEHAVIOR_HASH_COUNT] = {
        .make_tags   = &make_hash_value_tags,
        .dup_tags    = &dup_hash_value_tags,
        .free_tags   = &free_value_tags,
        .make_retval = &make_hash_retval,
        .add_tag     = &add_tag_hash_count,
        .remove_tag  = &remove_tag_hash_count,
        .merge_tags  = &merge_tags_hash_count,
    },
    [BEHAVIOR_UNIQUE_HASH] = {
        .make_tags   = &make_hash_value_tags,
        .dup_tags    = &dup_hash_value_tags,
        .free_tags   = &free_value_tags,
        .make_retval = &make_hash_retval,
        .add_tag     = &add_tag_unique_hash,
        .remove_tag  = &remove_tag_unique_hash,
        .merge_tags  = &merge_tags_unique_hash,
    },
};

/*** VALUE-TAGS SPECIFICATIONS ***/

#define MY_CXT_KEY "Scalar::ValueTags::_registry" XS_VERSION

// FIXME - must make these thread-safe (is MY_CXT the correct pattern?)

static struct ValueTagsSpec *S_get_vt_spec(pTHX_ SV *vt_type)
{
    dMY_CXT;
    assert(vt_type);
    for (struct ValueTagsSpec *cur = MY_CXT.vt_specs; cur; cur = cur->next) {
        if (cur && (cur->vt_type == vt_type)) {
            return cur;
        }
    }
//  croak("vt_type not registered");
    return NULL;
}

#define set_vt_type_behavior(vt_type, behavior_type) S_set_vt_type_behavior(aTHX_ vt_type, behavior_type)
static void S_set_vt_type_behavior(pTHX_ SV *vt_type, SV *behavior_type)
{
    dMY_CXT;
    assert(vt_type);
    assert(behavior_type);

    const struct ValueTagsBehavior *behavior = &behaviors[SvIV(behavior_type)];

    struct ValueTagsSpec *new_vt_spec;
    Newx(new_vt_spec, 1, struct ValueTagsSpec);
    *new_vt_spec = (struct ValueTagsSpec){
        .next     = NULL,
        .vt_type  = SvREFCNT_inc(vt_type),
        .behavior = behavior,
    };

    if (MY_CXT.vt_specs) {
        MY_CXT.final_vt_spec->next = new_vt_spec;
        MY_CXT.final_vt_spec = new_vt_spec;
    }
    else {
        MY_CXT.vt_specs      = new_vt_spec;
        MY_CXT.final_vt_spec = new_vt_spec;
    }
}

/*** MAGIC ***/

static MAGIC *S_get_value_tags_magic(pTHX_ SV *vt_type, SV *sv)
{
    assert(vt_type);
    assert(sv);

    MAGIC *mg = NULL;
    if (SvTYPE(sv) >=  SVt_PVMG) {
        mg = sv_magicv2_find_by_auxsv(sv, vt_type);
    }

    return mg;
}

static const struct ScalarValueMagicFunctions magic_funcs = {
    .ver       = 2,   /* Magic v2 */
    .shape     = MGv2s_SCALARVALUE,
    .free_mg   = &free_value_tags,
    .propagate = &propagate_value_tags,
    .user_size = sizeof(struct ValueTagsUserStruct),
};

static MAGIC *S_add_value_tags_magic(pTHX_ SV *vt_type, SV *sv, SV *value_tags)
{
    assert(vt_type);
    assert(sv);
    assert(!get_value_tags_magic(vt_type, sv));

    struct ValueTagsSpec *vt_spec = get_vt_spec(vt_type);

    // FIXME - detect and handle sv_magicv2_add failure?
    MAGIC *mg = sv_magicv2_add(sv, (struct MagicFunctions *)&magic_funcs, 0, vt_type);

    // MgAUXSV refcnt is automatically decremented on mg destroy, so inc here
    SvREFCNT_inc(vt_type);

    if (!value_tags) {
        value_tags = vt_spec->behavior->make_tags(aTHX);
    }

    VALUETAGS(mg) = value_tags;

    return mg;
}

static MAGIC *S_init_value_tags_magic(pTHX_ SV *vt_type, SV *sv, SV *value_tags)
{
    assert(vt_type);
    assert(sv);

    MAGIC *mg = get_value_tags_magic(vt_type, sv);

    if (!mg) {
        mg = add_value_tags_magic(vt_type, sv, value_tags);
    }

    return mg;
}

static MAGIC *S_remove_value_tags_magic(pTHX_ SV *vt_type, SV *sv)
{
    assert(vt_type);
    assert(sv);

    MAGIC *mg = get_value_tags_magic(vt_type, sv);

    if (mg) {
        sv_magicv2_remove(sv, mg);
    }

    // API FIXME - should remove_value_tags_magic return old magic???
    return mg;
}

#endif /* HAVE_VALUE_MAGIC */

/*** API ***/

#define VALIDATE_VT_TYPE(vt_type_ref) \
    if (!VALID_VT_TYPE_REF(vt_type_ref)) croak("Invalid vt_type");

#define VALIDATE_SV_TARGET(sv_ref) \
    if (!SvROK(sv_ref) || SvTYPE(SvRV(sv_ref)) > SVt_PVMG) \
        croak("Expected a SCALAR reference for target variable");

MODULE = Scalar::ValueTags  PACKAGE = Scalar::ValueTags

int
SVTAGS_UNIQUE_REF_ARRAY()
  CODE:
    RETVAL = BEHAVIOR_UNIQUE_REF_ARRAY;
  OUTPUT:
    RETVAL

int
SVTAGS_APPEND_ARRAY()
  CODE:
    RETVAL = BEHAVIOR_APPEND_ARRAY;
  OUTPUT:
    RETVAL

int SVTAGS_HASH_COUNT()
  CODE:
    RETVAL = BEHAVIOR_HASH_COUNT;
  OUTPUT:
    RETVAL

int
SVTAGS_UNIQUE_HASH()
  CODE:
    RETVAL = BEHAVIOR_UNIQUE_HASH;
  OUTPUT:
    RETVAL

void
value_tags_enabled()
   CODE:
#ifdef HAVE_VALUE_MAGIC
    XSRETURN_YES;
#else
    XSRETURN_NO;
#endif

void
value_tags_tracing_enabled()
   CODE:
#if defined(HAVE_VALUE_MAGIC) && defined(DEBUG_TRACE_ANNOTATIONS)
    XSRETURN_YES;
#else
    XSRETURN_NO;
#endif

SV *
register_value_tags_type (SV *behavior)
  CODE:
#ifdef HAVE_VALUE_MAGIC
    if (!SvIOK(behavior))
      croak("Expected an integer for behavior");    // FIXME: need better error
    IV idx = SvIV(behavior);
    if (idx < 0 || idx >= MAX_BEHAVIOR)
      croak("Unknown behavior"); // FIXME: need better error

    SV *vt_type = newSV(0);

    set_vt_type_behavior(vt_type, behavior);

    RETVAL = newRV(vt_type);
#else
    RETVAL = NULL;
#endif
  OUTPUT:
    RETVAL

void
add_value_tag (SV *vt_type_ref, SV *sv_ref, SV *tag)
  CODE:
#ifdef HAVE_VALUE_MAGIC
    VALIDATE_VT_TYPE(vt_type_ref);
    VALIDATE_SV_TARGET(sv_ref);

    // FIXME: add tag validation to vt_spec, and validate tag here

    SV *vt_type = SvRV(vt_type_ref);
    struct ValueTagsSpec *vt_spec = get_vt_spec(vt_type);
    if (!vt_spec)
        croak("Unregistered vt_type");

    MAGIC *mg = init_value_tags_magic(vt_type, SvRV(sv_ref), NULL);

    SV *tags = VALUETAGS(mg);
    vt_spec->behavior->add_tag(aTHX_ tags, tag);
#endif


void
remove_value_tag (SV *vt_type_ref, SV *sv_ref, SV *tag)
  CODE:
#ifdef HAVE_VALUE_MAGIC
    VALIDATE_VT_TYPE(vt_type_ref);
    VALIDATE_SV_TARGET(sv_ref);

    // FIXME: add tag validation to vt_spec, and validate tag here

    SV *vt_type = SvRV(vt_type_ref);
    struct ValueTagsSpec *vt_spec = get_vt_spec(vt_type);
    if (!vt_spec)
        croak("Unregistered vt_type");

    MAGIC *mg = get_value_tags_magic(vt_type, SvRV(sv_ref));

    if (mg) {
        vt_spec->behavior->remove_tag(aTHX_ VALUETAGS(mg), tag);
    }

    // FIXME: should this return the removed tag(s)?
#endif

SV *
get_value_tags (SV *vt_type_ref, SV *sv_ref)
  CODE:
#ifdef HAVE_VALUE_MAGIC
    VALIDATE_VT_TYPE(vt_type_ref);
    VALIDATE_SV_TARGET(sv_ref);

    SV *vt_type = SvRV(vt_type_ref);
    SV *sv = SvRV(sv_ref);

    MAGIC *mg = get_value_tags_magic(vt_type, sv);

    struct ValueTagsSpec *vt_spec = get_vt_spec(vt_type);
    if (!vt_spec)
        croak("Unregistered vt_type");

    RETVAL = vt_spec->behavior->make_retval(aTHX_ mg);
#else
    RETVAL = NULL;
#endif
  OUTPUT:
    RETVAL

void
clear_value_tags (SV *vt_type_ref, SV *sv_ref)
  CODE:
#ifdef HAVE_VALUE_MAGIC
    VALIDATE_VT_TYPE(vt_type_ref);
    VALIDATE_SV_TARGET(sv_ref);

    SV *vt_type = SvRV(vt_type_ref);
    struct ValueTagsSpec *vt_spec = get_vt_spec(vt_type);
    if (!vt_spec)
        croak("Unregistered vt_type");

    SV *sv = SvRV(sv_ref);
    MAGIC *mg = get_value_tags_magic(vt_type, sv);

    if (mg) {
        remove_value_tags_magic(vt_type, sv);
    }
#endif

void
CLONE(...)
  CODE:
    MY_CXT_CLONE;

# ifdef HAVE_VALUE_MAGIC
BOOT:
{
    MY_CXT_INIT;
    MY_CXT.vt_specs = NULL;
    MY_CXT.final_vt_spec = NULL;
}
# endif
