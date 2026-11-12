#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "include/object_compat.h"

/* Object flags - stored in mg_private */
#define OBJ_FLAG_LOCKED  0x01
#define OBJ_FLAG_FROZEN  0x02

/* Built-in type IDs for inline checks */
typedef enum {
    TYPE_NONE = 0,
    TYPE_ANY,
    TYPE_DEFINED,
    TYPE_STR,
    TYPE_INT,
    TYPE_NUM,
    TYPE_BOOL,
    TYPE_ARRAYREF,
    TYPE_HASHREF,
    TYPE_CODEREF,
    TYPE_OBJECT,
    TYPE_REF,
    TYPE_SCALARREF,
    TYPE_REGEXPREF,
    TYPE_GLOBREF,
    TYPE_FILEHANDLE,
    TYPE_CLASSNAME,
    TYPE_POSITIVEINT,
    TYPE_NEGATIVEINT,
    TYPE_NONEMPTYSTR,
    TYPE_UNDEF,
    TYPE_CUSTOM       /* Uses registered or callback check */
} BuiltinTypeID;

/* Type check/coerce function signatures for external plugins */
typedef bool (*ObjectTypeCheckFunc)(pTHX_ SV *val);
typedef SV*  (*ObjectTypeCoerceFunc)(pTHX_ SV *val);
typedef bool (*ObjectTypeCheckFuncEx)(pTHX_ SV *val, void *data);
typedef SV*  (*ObjectTypeCoerceFuncEx)(pTHX_ SV *val, void *data);

/* Registered type entry (for plugins) */
typedef struct {
    char *name;
    ObjectTypeCheckFunc check;      /* C function for type check */
    ObjectTypeCoerceFunc coerce;    /* C function for coercion */
    SV *perl_check;                 /* Fallback Perl callback */
    SV *perl_coerce;                /* Fallback Perl coercion */
    ObjectTypeCheckFuncEx check_ex;   /* C function with user-data */
    ObjectTypeCoerceFuncEx coerce_ex; /* C coerce with user-data */
    void *data;                     /* Opaque user-data for _ex functions */
} RegisteredType;

/* handles(...): how a slot's value is delegated to, decided by its type */
typedef enum {
    HK_METHOD = 0,   /* Object: call the method on it */
    HK_CODE,         /* CodeRef: call it */
    HK_ARRAY,        /* ArrayRef: a native array op */
    HK_HASH          /* HashRef: a native hash op */
} HandleKind;

/* CodeRef modes */
#define HANDLE_CODE_CALL   0   /* $code->(@args) */
#define HANDLE_CODE_METHOD 1   /* $code->($self, @args) */

/* One delegator, resolved against the slot's final type */
typedef struct {
    SV *local;       /* method installed in the class */
    SV *remote;      /* method called on the delegate, or the native op, or call/method */
    U8  kind;        /* HandleKind */
    U8  op;          /* index in the kind's op table, or HANDLE_CODE_* */
} ResolvedHandle;

/* Per-slot specification - parsed from "name:Type:default(val)" */
typedef struct {
    char *name;
    BuiltinTypeID type_id;          /* Built-in type or TYPE_CUSTOM */
    RegisteredType *registered;     /* For external XS types */
    SV *default_sv;                 /* Default value (immutable, refcnt'd) */
    SV *trigger_cb;                 /* Trigger callback */
    SV *coerce_cb;                  /* Coercion callback (Perl) */
    SV *builder_name;               /* Builder method name for lazy attrs */
    U8 is_required;                 /* Croak if not provided in new() */
    U8 is_readonly;                 /* Croak if set after new() */
    U8 is_lazy;                     /* Build on first access, not at new() */
    U8 has_default;
    U8 has_trigger;
    U8 has_coerce;
    U8 has_type;
    U8 has_builder;                 /* Has builder method */
    U8 has_clearer;                 /* Generate clear_X method */
    U8 has_predicate;               /* Generate has_X method */
    U8 is_weak;                     /* Weaken references when stored */
    U8 is_private;                  /* Accessor only callable from the owning package */
    U8 has_checks;                  /* is_readonly | is_required | has_coerce | TYPE_CUSTOM — skip block when 0 */
    SV *clearer_name;               /* Custom clearer method name */
    SV *predicate_name;             /* Custom predicate method name */
    SV *reader_name;                /* Custom reader method name (get_X style) */
    SV *writer_name;                /* Custom writer method name (set_X style) */
    SV *init_arg;                   /* Alternate constructor argument name */
    char *private_owner;            /* Package that declared the attribute: the only caller of a :private one */
    char *private_also;             /* A role attribute's consuming class, which may call it too; NULL otherwise */
    AV *handles;                    /* handles(...) as written: local, remote pairs; local undef for role:Name,
                                       remote undef for a bare name. Never changed once parsed, so clones share it */
    ResolvedHandle *resolved;       /* handles resolved when the slot joins a class */
    IV resolved_count;
    U8 has_handles;
    U8 default_implicit;            /* default [] or {} added by handles, not written by the user */
    U8 inherited;                   /* copied unchanged from a parent: a method of the child's own
                                       overrides its delegators rather than clashing with them */
} SlotSpec;

/* Custom op definitions */
static XOP object_get_xop;
static XOP object_set_xop;
static XOP object_set_typed_xop;

/* Per-class metadata */
typedef struct ClassMeta_s ClassMeta;  /* Forward declaration */

/* Method modifier chain - linked list for each type */
typedef struct MethodModifier_s {
    SV *callback;
    struct MethodModifier_s *next;
} MethodModifier;

/* Modified method wrapper */
typedef struct {
    CV *original_cv;
    MethodModifier *before_chain;
    MethodModifier *after_chain;
    MethodModifier *around_chain;
} ModifiedMethod;

/* Role metadata */
typedef struct {
    char *role_name;
    char **required_methods;   /* Methods consuming class MUST have */
    IV required_count;
    SlotSpec **slots;          /* Slots the role provides */
    IV slot_count;
    HV *stash;                 /* Role's stash for provided methods */
} RoleMeta;

/* Per-class metadata */
struct ClassMeta_s {
    char *class_name;
    HV *prop_to_idx;      /* property name -> slot index */
    HV *arg_to_idx;       /* constructor argument name -> slot index (init_arg or property name) */
    char **idx_to_prop;   /* slot index -> property name */
    IV slot_count;
    HV *stash;            /* cached stash pointer */
    /* Type system extensions */
    SlotSpec **slots;     /* Per-slot specifications, NULL if no specs */
    U8 has_any_types;     /* Quick check: any slot has type checking? */
    U8 has_any_defaults;  /* Quick check: any slot has defaults? */
    U8 has_any_triggers;  /* Quick check: any slot has triggers? */
    U8 has_any_required;  /* Quick check: any slot is required? */
    U8 has_any_lazy;      /* Quick check: any slot is lazy? */
    U8 has_any_builders;  /* Quick check: any slot has builders? */
    U8 has_any_weak;      /* Quick check: any slot has weak refs? */
    /* Singleton support */
    SV *singleton_instance;  /* Cached singleton instance, NULL if not a singleton */
    U8 is_singleton;         /* Flag: class is a singleton */
    /* DEMOLISH support - only set if class has DEMOLISH method */
    CV *demolish_cv;         /* Cached DEMOLISH method, NULL if none */
    /* BUILD support - called after new() */
    CV *build_cv;            /* Cached BUILD method, NULL if none */
    U8 has_build;            /* Flag: class has BUILD method */
    /* Role support */
    RoleMeta **consumed_roles;  /* Array of consumed roles, NULL if none */
    IV role_count;
    /* Method modifier registry - only allocated if modifiers are used */
    HV *modified_methods;    /* method name -> ModifiedMethod*, NULL if none */
    /* Inheritance support */
    char **parent_classes;               /* Array of parent class names, NULL if no parents */
    struct ClassMeta_s **parent_metas;   /* Array of parent ClassMeta pointers */
    IV parent_count;                     /* Number of parent classes */
};

/* Global class registry */
static HV *g_class_registry = NULL;  /* class name -> ClassMeta* */

/* Global type registry for external plugins */
static HV *g_type_registry = NULL;   /* type name -> RegisteredType* */

/* Global role registry */
static HV *g_role_registry = NULL;   /* role name -> RoleMeta* */

/* handles(...) lookups, built at boot from the tables beside parse_handles */
static HV *g_reserved_methods = NULL;   /* names a delegator may never take */
static HV *g_array_op_index = NULL;     /* ArrayRef op name -> index in array_ops, aliases resolved */
static HV *g_hash_op_index = NULL;      /* HashRef op name -> index in hash_ops */

/* Forward declaration for FuncAccessorData */
typedef struct FuncAccessorData_s FuncAccessorData;

/* Global registry for function accessor data (to avoid storing pointers in op_targ) */
static FuncAccessorData **g_func_accessor_registry = NULL;
static IV g_func_accessor_count = 0;
static IV g_func_accessor_capacity = 0;

/* Forward declarations */
static ClassMeta* get_class_meta(pTHX_ const char *class_name, STRLEN len);
static void install_constructor(pTHX_ const char *class_name, ClassMeta *meta);
static void install_accessor(pTHX_ const char *class_name, const char *prop_name, IV idx);
static void install_accessor_typed(pTHX_ const char *class_name, const char *prop_name, IV idx, ClassMeta *meta);
static void install_clearer(pTHX_ const char *class_name, const char *prop_name, IV idx, ClassMeta *meta, SV *custom_name);
static void install_predicate(pTHX_ const char *class_name, const char *prop_name, IV idx, ClassMeta *meta, SV *custom_name);
static void install_destroy_wrapper(pTHX_ const char *class_name, ClassMeta *meta);
static RoleMeta* get_role_meta(pTHX_ const char *role_name, STRLEN len);
static void object_check_private(pTHX_ SlotSpec *spec, ClassMeta *meta);
static void install_class_delegators(pTHX_ ClassMeta *meta);
static void check_role_slot_against_delegators(pTHX_ ClassMeta *meta, SlotSpec *slot, RoleMeta *role);
XS_INTERNAL(xs_prototype);

/* What every generated method checks on each call: one flag, with the caller
 * looked at only for a private attribute */
OBJECT_INLINE void check_private(pTHX_ SlotSpec *spec, ClassMeta *meta) {
    if (spec->is_private) object_check_private(aTHX_ spec, meta);
}
XS_INTERNAL(xs_set_prototype);

/* ============================================
   Built-in type checking (inline)
   ============================================ */

OBJECT_INLINE BuiltinTypeID parse_builtin_type(const char *type_str, STRLEN len) {
    if (len == 3 && strEQ(type_str, "Str")) return TYPE_STR;
    if (len == 3 && strEQ(type_str, "Int")) return TYPE_INT;
    if (len == 3 && strEQ(type_str, "Num")) return TYPE_NUM;
    if (len == 3 && strEQ(type_str, "Any")) return TYPE_ANY;
    if (len == 3 && strEQ(type_str, "Ref")) return TYPE_REF;
    if (len == 4 && strEQ(type_str, "Bool")) return TYPE_BOOL;
    if (len == 5 && strEQ(type_str, "Undef")) return TYPE_UNDEF;
    if (len == 6 && strEQ(type_str, "Object")) return TYPE_OBJECT;
    if (len == 7 && strEQ(type_str, "Defined")) return TYPE_DEFINED;
    if (len == 7 && strEQ(type_str, "CodeRef")) return TYPE_CODEREF;
    if (len == 7 && strEQ(type_str, "HashRef")) return TYPE_HASHREF;
    if (len == 7 && strEQ(type_str, "GlobRef")) return TYPE_GLOBREF;
    if (len == 8 && strEQ(type_str, "ArrayRef")) return TYPE_ARRAYREF;
    if (len == 9 && strEQ(type_str, "ScalarRef")) return TYPE_SCALARREF;
    if (len == 9 && strEQ(type_str, "RegexpRef")) return TYPE_REGEXPREF;
    if (len == 9 && strEQ(type_str, "ClassName")) return TYPE_CLASSNAME;
    if (len == 10 && strEQ(type_str, "FileHandle")) return TYPE_FILEHANDLE;
    if (len == 11 && strEQ(type_str, "PositiveInt")) return TYPE_POSITIVEINT;
    if (len == 11 && strEQ(type_str, "NegativeInt")) return TYPE_NEGATIVEINT;
    if (len == 11 && strEQ(type_str, "NonEmptyStr")) return TYPE_NONEMPTYSTR;
    return TYPE_NONE;  /* Unknown - could be custom */
}

/* ScalarRef: a reference that ref() calls SCALAR or REF, blessed or not */
static bool check_scalarref(pTHX_ SV *val) {
    SV *rv;
    if (!SvROK(val)) return false;
    rv = SvRV(val);
    if (SvTYPE(rv) <= SVt_PVMG) {
#if !PERL_VERSION_GE(5,11,0)
        if (SvRXOK(val)) return false;    /* before 5.11 a regexp is a PVMG */
#endif
        return !SvVOK(rv);                /* ref() calls a v-string VSTRING */
    }
    /* A tied element is an lvalue that ref() calls SCALAR, or REF once it
     * has fetched a reference; substr, vec and pos lvalues are LVALUE. */
    if (SvTYPE(rv) == SVt_PVLV) {
        const char *kind = sv_reftype(rv, 0);
        return strEQ(kind, "SCALAR") || strEQ(kind, "REF");
    }
    return false;
}

/* FileHandle: an open handle - a glob (including one held in an lvalue),
 * glob ref or IO ref whose IO is open or tied, as Scalar::Util::openhandle
 * decides it - or an object that isa IO::Handle, which covers handle objects
 * that are not open yet. */
static bool check_filehandle(pTHX_ SV *val) {
    SV *sv = SvROK(val) ? SvRV(val) : val;
    IO *io = NULL;

    /* isGV_with_GP is flag && (PVGV || PVLV). The GP flag is only set on a
     * PVGV or a PVLV, so PVGV false only ever falls to PVLV true, and PVLV
     * is never false: neither decides the result with its false outcome.
     # uncoverable condition right count:2
     # uncoverable condition right count:3 */
    if (isGV_with_GP(sv))
        io = GvIOp((GV *)sv);
    else if (SvTYPE(sv) == SVt_PVIO)
        io = (IO *)sv;

    /* A tied handle has no PerlIO of its own */
    if (io && (IoIFP(io) || mg_find((SV *)io, PERL_MAGIC_tiedscalar)))
        return true;

    return SvROK(val) && SvOBJECT(SvRV(val)) && sv_derived_from(val, "IO::Handle");
}

/* Int, and the sign of its value: -1, 0 or 1, or INT_SIGN_NONE when val
 * is not an Int. A UV is only flagged when it is above IV_MAX, where SvIV
 * would wrap it negative. A numeric string is signed by strtoll, which on a
 * 32-bit perl reads past the IV range. */
#define INT_SIGN_NONE 2
OBJECT_INLINE int int_sign(pTHX_ SV *val) {
    if (SvIOK(val)) {
        if (SvIsUV(val)) return 1;
        return SvIVX(val) > 0 ? 1 : SvIVX(val) < 0 ? -1 : 0;
    }
    if (SvPOK(val)) {
        /* Use strtoll for fast integer parsing */
        STRLEN len;
        const char *pv = SvPV(val, len);
        char *endp;
        long long n;
        if (len == 0) return INT_SIGN_NONE;
        errno = 0;
        n = strtoll(pv, &endp, 10);
        if (errno == 0 && endp == pv + len && *pv != '\0') /* # uncoverable condition right count:3 */
            return n > 0 ? 1 : n < 0 ? -1 : 0;
    }
    return INT_SIGN_NONE;
}

/* The GV a stash holds under name, or NULL. An entry that is not a GV is a
 * constant or a sub stub placeholder. */
static GV *stash_gv(pTHX_ HV *stash, const char *name, I32 len) {
    SV **svp = hv_fetch(stash, name, len, 0);
    return svp && SvTYPE(*svp) == SVt_PVGV ? (GV *)*svp : NULL;
}

/* ClassName: a non-empty string naming a loaded package - one with a
 * defined $VERSION, a non-empty @ISA or at least one sub, as Class::Load
 * decides it. The stash is looked up, never created, and walked bucket by
 * bucket so the check does not reset an each() the caller has under way. */
static bool check_classname(pTHX_ SV *val) {
    HV *stash;
    GV *gv;
    HE **buckets;
    STRLEN i;

    if (!SvOK(val) || SvROK(val)) return false;
    if (SvPOK(val) && SvCUR(val) == 0) return false;   /* "" would be main */
    stash = gv_stashsv(val, 0);
    if (!stash) return false;

    gv = stash_gv(aTHX_ stash, "VERSION", 7);
    if (gv && GvSV(gv) && SvOK(GvSV(gv))) return true;
    gv = stash_gv(aTHX_ stash, "ISA", 3);
    if (gv && GvAV(gv) && AvFILLp(GvAV(gv)) >= 0) return true;

    buckets = HvARRAY(stash);
    if (buckets) {
        for (i = 0; i <= HvMAX(stash); i++) {
            HE *he;
            for (he = buckets[i]; he; he = HeNEXT(he)) {
                SV *entry = HeVAL(he);
                if (SvTYPE(entry) != SVt_PVGV || GvCV((GV *)entry))
                    return true;
            }
        }
    }
    return false;
}

/* Inline type check - returns true if value passes check */
OBJECT_INLINE bool check_builtin_type(pTHX_ SV *val, BuiltinTypeID type_id) {
    switch (type_id) { /* # uncoverable branch true count:21 */
        case TYPE_ANY:
            return true;
        case TYPE_DEFINED:
            /* Be defensive: SvOK may not catch all defined values in older Perls */
            /*
             # uncoverable condition left count:2
             # uncoverable condition left count:3
             # uncoverable condition left count:4 */
            return SvOK(val) || SvIOK(val) || SvNOK(val) || SvPOK(val);
        case TYPE_STR:
            return SvOK(val) && !SvROK(val);  /* defined non-ref */
        case TYPE_INT:
            return int_sign(aTHX_ val) != INT_SIGN_NONE;
        case TYPE_NUM:
            if (SvNIOK(val)) return true;
            if (SvPOK(val)) {
                /* Use strtod for fast number parsing */
                STRLEN len;
                const char *pv = SvPV(val, len);
                char *endp;
                if (len == 0) return false;
                errno = 0;
                (void)strtod(pv, &endp);
                return errno == 0 && endp == pv + len && *pv != '\0'; /* # uncoverable condition right count:3 */
            }
            return false;
        case TYPE_BOOL:
            /* Accept 0, 1, "", or boolean SVs */
            if (SvIOK(val)) {
                IV iv = SvIV(val);
                return iv == 0 || iv == 1;
            }
            return SvTRUE(val) || !SvOK(val) || (SvPOK(val) && SvCUR(val) == 0);
        case TYPE_ARRAYREF:
            return SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV;
        case TYPE_HASHREF:
            return SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV;
        case TYPE_CODEREF:
            return SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV;
        case TYPE_OBJECT:
            return SvROK(val) && sv_isobject(val);
        case TYPE_REF:
            return SvROK(val);
        case TYPE_SCALARREF:
            return check_scalarref(aTHX_ val);
        case TYPE_REGEXPREF:
#if PERL_VERSION_GE(5,11,0)
            return SvROK(val) && SvTYPE(SvRV(val)) == SVt_REGEXP;
#else
            return SvROK(val) && SvRXOK(val);    /* a regexp is a PVMG before 5.11 */
#endif
        case TYPE_GLOBREF:
            /* What ref() calls GLOB. A ref to a glob held in an lvalue
             * vivifies it into a real glob, so the referent is a PVGV.
             # uncoverable condition right count:3
             # uncoverable condition left count:4
             # uncoverable condition right count:4 */
            return SvROK(val) && isGV_with_GP(SvRV(val));
        case TYPE_FILEHANDLE:
            return check_filehandle(aTHX_ val);
        case TYPE_CLASSNAME:
            return check_classname(aTHX_ val);
        case TYPE_POSITIVEINT:
            return int_sign(aTHX_ val) == 1;
        case TYPE_NEGATIVEINT:
            return int_sign(aTHX_ val) == -1;
        case TYPE_NONEMPTYSTR:
            /* a number always stringifies to something: only a string is empty */
            return SvOK(val) && !SvROK(val) && (!SvPOK(val) || SvCUR(val) > 0);
        case TYPE_UNDEF:
            return !SvOK(val);
        default: /* # uncoverable statement */
            return true;  /* No check or unknown */ /* # uncoverable statement */
    }
}

/* Get type name for error messages */
static const char* type_id_to_name(BuiltinTypeID type_id) {
    /*
     # uncoverable branch true count:21
     # uncoverable branch true count:22 */
    switch (type_id) {
        case TYPE_ANY: return "Any";
        case TYPE_DEFINED: return "Defined";
        case TYPE_STR: return "Str";
        case TYPE_INT: return "Int";
        case TYPE_NUM: return "Num";
        case TYPE_BOOL: return "Bool";
        case TYPE_ARRAYREF: return "ArrayRef";
        case TYPE_HASHREF: return "HashRef";
        case TYPE_CODEREF: return "CodeRef";
        case TYPE_OBJECT: return "Object";
        case TYPE_REF: return "Ref";
        case TYPE_SCALARREF: return "ScalarRef";
        case TYPE_REGEXPREF: return "RegexpRef";
        case TYPE_GLOBREF: return "GlobRef";
        case TYPE_FILEHANDLE: return "FileHandle";
        case TYPE_CLASSNAME: return "ClassName";
        case TYPE_POSITIVEINT: return "PositiveInt";
        case TYPE_NEGATIVEINT: return "NegativeInt";
        case TYPE_NONEMPTYSTR: return "NonEmptyStr";
        case TYPE_UNDEF: return "Undef";
        case TYPE_CUSTOM: return "custom"; /* # uncoverable statement */
        default: return "unknown"; /* # uncoverable statement */
    }
}

/* Apply coercion to a value for a slot (slot-level, C-level, and Perl-registered) */
static SV* apply_slot_coercion(pTHX_ SV *val, SlotSpec *spec) {
    /* Slot-level coerce(callback) */
    if (spec->has_coerce && spec->coerce_cb) {
        dSP;
        PUSHMARK(SP);
        XPUSHs(val);
        PUTBACK;
        call_sv(spec->coerce_cb, G_SCALAR);
        SPAGAIN;
        val = POPs;
        PUTBACK;
    }
    /* C-registered type coercion with user-data (fast path) */
    if (spec->type_id == TYPE_CUSTOM && spec->registered && spec->registered->coerce_ex) { /* # uncoverable condition right count:2 */
        val = spec->registered->coerce_ex(aTHX_ val, spec->registered->data);
    }
    /* C-registered type coercion (fast path) */
    if (spec->type_id == TYPE_CUSTOM && spec->registered && spec->registered->coerce) { /* # uncoverable condition right count:2 */
        val = spec->registered->coerce(aTHX_ val);
    }
    /* Perl-registered type coercion (from register_type) */
    if (spec->type_id == TYPE_CUSTOM && spec->registered && spec->registered->perl_coerce) { /* # uncoverable condition right count:2 */
        dSP;
        PUSHMARK(SP);
        XPUSHs(val);
        PUTBACK;
        call_sv(spec->registered->perl_coerce, G_SCALAR);
        SPAGAIN;
        val = POPs;
        PUTBACK;
    }
    return val;
}

/* Check a value against a slot's type constraint (handles both C and Perl callbacks) */
static bool check_slot_type(pTHX_ SV *val, SlotSpec *spec) {
    /*
     # uncoverable branch true
     # uncoverable condition left count:1
     # uncoverable condition left count:2 */
    if (!spec || !spec->has_type) return true;
    
    if (spec->type_id != TYPE_CUSTOM) {
        return check_builtin_type(aTHX_ val, spec->type_id);
    }
    
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!spec->registered) return true;
    
    /* Try C function with user-data first (fast path - ~5 cycles) */
    if (spec->registered->check_ex) {
        return spec->registered->check_ex(aTHX_ val, spec->registered->data);
    }

    /* Try C function next (fast path - ~5 cycles) */
    if (spec->registered->check) {
        return spec->registered->check(aTHX_ val);
    }
    
    /* Fall back to Perl callback (~100 cycles) */
    if (spec->registered->perl_check) {
        dSP;
        int count;
        bool result = false;
        SV *result_sv;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(val);
        PUTBACK;
        count = call_sv(spec->registered->perl_check, G_SCALAR);
        SPAGAIN;
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 */
        if (count > 0) {
            result_sv = POPs;
            result = SvTRUE(result_sv);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        return result;
    }
    
    return true;
}

/* ============================================
   Slot spec parser: "name:Type:default(val)"
   ============================================ */

/* ============================================
   handles(...) - tables and parsing
   ============================================ */

/* The slot types handles supports and the kind of delegation each gets,
 * indexed by handle_kind_of */
static const struct {
    U8 kind;
    const char *name;
} handle_kinds[] = {
    { HK_METHOD, "Object"   },
    { HK_CODE,   "CodeRef"  },
    { HK_ARRAY,  "ArrayRef" },
    { HK_HASH,   "HashRef"  }
};

/* The handle_kinds row for a slot type, or -1 when handles does not support it */
static IV handle_kind_of(BuiltinTypeID type) {
    switch (type) {
        case TYPE_OBJECT:   return 0;
        case TYPE_CODEREF:  return 1;
        case TYPE_ARRAYREF: return 2;
        case TYPE_HASHREF:  return 3;
        default:            return -1;
    }
}

/* A native array or hash method. min_args and max_args count the arguments
 * after the invocant, max_args -1 for no limit. */
typedef struct {
    const char *name;
    I8 min_args;
    I8 max_args;
    U8 mutates;           /* changes the container: refused on a readonly slot,
                             croaks on a frozen object, fires the trigger */
    U8 pairs;             /* arguments are key/value pairs */
    const char *alias_of; /* another name for that op */
} NativeOp;

static const NativeOp array_ops[] = {
    { "push",     1, -1, 1, 0, NULL   },
    { "pop",      0,  0, 1, 0, NULL   },
    { "shift",    0,  0, 1, 0, NULL   },
    { "unshift",  1, -1, 1, 0, NULL   },
    { "list",     0,  0, 0, 0, NULL   },
    { "count",    0,  0, 0, 0, NULL   },
    { "is_empty", 0,  0, 0, 0, NULL   },
    { "get",      1,  1, 0, 0, NULL   },
    { "set",      2,  2, 1, 0, NULL   },
    { "clear",    0,  0, 1, 0, NULL   },
    { "elements", 0,  0, 0, 0, "list" },
    { NULL,       0,  0, 0, 0, NULL   }
};

/* Indices into array_ops, in its order */
enum { AOP_PUSH = 0, AOP_POP, AOP_SHIFT, AOP_UNSHIFT, AOP_LIST, AOP_COUNT,
       AOP_IS_EMPTY, AOP_GET, AOP_SET, AOP_CLEAR };

static const NativeOp hash_ops[] = {
    { "get",      1, -1, 0, 0, NULL },
    { "set",      2, -1, 1, 1, NULL },
    { "exists",   1,  1, 0, 0, NULL },
    { "defined",  1,  1, 0, 0, NULL },
    { "delete",   1, -1, 1, 0, NULL },
    { "keys",     0,  0, 0, 0, NULL },
    { "values",   0,  0, 0, 0, NULL },
    { "kv",       0,  0, 0, 0, NULL },
    { "count",    0,  0, 0, 0, NULL },
    { "is_empty", 0,  0, 0, 0, NULL },
    { "clear",    0,  0, 1, 0, NULL },
    { NULL,       0,  0, 0, 0, NULL }
};

/* Indices into hash_ops, in its order */
enum { HOP_GET = 0, HOP_SET, HOP_EXISTS, HOP_DEFINED, HOP_DELETE, HOP_KEYS,
       HOP_VALUES, HOP_KV, HOP_COUNT, HOP_IS_EMPTY, HOP_CLEAR };

/* Method names a delegator may never take: Object::Proto's own, perl's
 * special blocks and the methods of UNIVERSAL */
static const char *const reserved_methods[] = {
    "new", "prototype", "set_prototype", "instance", "BUILD", "DEMOLISH", "DESTROY",
    "AUTOLOAD", "import", "unimport", "isa", "can", "DOES", "VERSION",
    "BEGIN", "END", "INIT", "CHECK", "UNITCHECK", NULL
};

/* Whether name is reserved: one hash lookup. hash may be a hash already
 * computed for name, as a stash entry has, or 0. */
static bool is_reserved_method(pTHX_ const char *name, STRLEN len, U32 hash) {
    return hv_common_key_len(g_reserved_methods, name, (I32)len, HV_FETCH_ISEXISTS, NULL, hash) != NULL;
}

/* Name -> index lookup for a table of native ops, an alias mapped straight to
 * the op it stands for (which the table lists before it) */
static HV *build_op_index(pTHX_ const NativeOp *ops) {
    HV *index = newHV();
    IV i;
    for (i = 0; ops[i].name; i++) {
        IV op = ops[i].alias_of
              ? SvIV(*hv_fetch(index, ops[i].alias_of, strlen(ops[i].alias_of), 0))
              : i;
        (void)hv_store(index, ops[i].name, strlen(ops[i].name), newSViv(op), 0);
    }
    return index;
}

/* The index of the native op called name, or -1: one hash lookup */
static IV find_native_op(pTHX_ HV *index, SV *name) {
    HE *he = hv_fetch_ent(index, name, 0, 0);
    return he ? SvIV(HeVAL(he)) : -1;
}

/* Strip leading and trailing white space from [*p, *p + *len) */
static void handles_trim(const char **p, STRLEN *len) {
    while (*len && isSPACE_A(**p)) { (*p)++; (*len)--; }
    while (*len && isSPACE_A((*p)[*len - 1])) (*len)--;
}

/* A method name: [A-Za-z_]\w* */
static bool handles_name_ok(const char *p, STRLEN len) {
    STRLEN i;
    if (len == 0 || !isIDFIRST_A(*p)) return false;
    for (i = 1; i < len; i++) {
        if (!isWORDCHAR_A(p[i])) return false;
    }
    return true;
}

/* A package name: [A-Za-z_]\w*(::\w+)* */
static bool handles_role_ok(const char *p, STRLEN len) {
    STRLEN i;
    if (len == 0 || !isIDFIRST_A(*p)) return false;
    for (i = 1; i < len; i++) {
        if (p[i] == ':') {
            if (i + 2 >= len || p[i + 1] != ':' || !isWORDCHAR_A(p[i + 2])) return false;
            i += 2;
        } else if (!isWORDCHAR_A(p[i])) {
            return false;
        }
    }
    return true;
}

/* The method names (the locals) among local, remote pairs, as a mortal hash
 * for O(1) lookups; NULL pairs give an empty one */
static HV *handles_locals(pTHX_ AV *pairs) {
    HV *locals = (HV*)sv_2mortal((SV*)newHV());
    SSize_t i;
    for (i = 0; pairs && i < av_len(pairs); i += 2) {
        SV *local = AvARRAY(pairs)[i];
        if (SvOK(local)) (void)hv_store_ent(locals, local, &PL_sv_yes, 0);
    }
    return locals;
}

/* Parse the argument of handles(...) - "a, b=>c, role:Some::Role" - into
 * the spec's local, remote pairs. A second handles(...) in the same spec adds
 * to the first. Only the names are checked here; what they mean depends on
 * the slot's type, which is final only when the slot joins a class. */
static void parse_handles(pTHX_ SlotSpec *spec, const char *arg, STRLEN arg_len) {
    AV *pairs = (AV*)sv_2mortal((SV*)newAV());
    HV *seen;     /* the names so far, an earlier handles(...) in this spec's too */
    const char *p = arg;
    const char *end = arg + arg_len;
    SSize_t i;

    {
        const char *all = arg;
        STRLEN all_len = arg_len;
        handles_trim(&all, &all_len);
        if (all_len == 0)
            croak("handles() needs at least one method for slot '%s'", spec->name);
    }
    seen = handles_locals(aTHX_ spec->handles);

    for (;;) {
        const char *comma = (const char *)memchr(p, ',', end - p);
        const char *entry = p;
        STRLEN len = (comma ? comma : end) - p;

        handles_trim(&entry, &len);
        if (len >= 5 && memEQ(entry, "role:", 5)) {
            const char *role = entry + 5;
            STRLEN role_len = len - 5;
            handles_trim(&role, &role_len);
            if (!handles_role_ok(role, role_len))
                croak("Invalid role name '%.*s' in handles for slot '%s'",
                      (int)role_len, role, spec->name);
            av_push(pairs, newSV(0));
            av_push(pairs, newSVpvn(role, role_len));
        } else {
            const char *local = entry;
            STRLEN local_len = len;
            const char *arrow = ninstr(entry, entry + len, "=>", "=>" + 2);
            const char *remote = NULL;
            STRLEN remote_len = 0;

            if (arrow) {
                local_len = arrow - entry;
                remote = arrow + 2;
                remote_len = entry + len - remote;
                handles_trim(&local, &local_len);
                handles_trim(&remote, &remote_len);
            }
            if (!handles_name_ok(local, local_len))
                croak("Invalid method name '%.*s' in handles for slot '%s'",
                      (int)local_len, local, spec->name);
            if (arrow && !handles_name_ok(remote, remote_len))
                croak("Invalid method name '%.*s' in handles for slot '%s'",
                      (int)remote_len, remote, spec->name);
            if (hv_exists(seen, local, local_len))
                croak("Method '%.*s' appears twice in handles for slot '%s'",
                      (int)local_len, local, spec->name);
            (void)hv_store(seen, local, local_len, &PL_sv_yes, 0);
            av_push(pairs, newSVpvn(local, local_len));
            av_push(pairs, arrow ? newSVpvn(remote, remote_len) : newSV(0));
        }

        if (!comma) break;
        p = comma + 1;
    }

    if (!spec->handles) spec->handles = newAV();
    for (i = 0; i <= av_len(pairs); i++) {
        av_push(spec->handles, SvREFCNT_inc(AvARRAY(pairs)[i]));
    }
    spec->has_handles = 1;
}

/* Croak when a function-style modifier's '(' is never closed, before anything
 * is allocated. The scan follows parse_slot_spec: past the name, a '(' opens
 * an argument and parentheses nest inside it, while a ')' outside any argument
 * is just part of a modifier's name. Once this passes, every argument scan in
 * parse_slot_spec finds its closing ')'. */
static void check_spec_parens(pTHX_ const char *spec_str, STRLEN len) {
    const char *p = spec_str;
    const char *end = spec_str + len;
    IV depth = 0;

    while (p < end && *p != ':') p++;
    for (; p < end; p++) {
        if (*p == '(') depth++;
        else if (*p == ')' && depth > 0) depth--;
    }
    if (depth > 0)
        croak("Unterminated '(' in slot spec '%.*s'", (int)len, spec_str);
}

static SlotSpec* parse_slot_spec(pTHX_ const char *spec_str, STRLEN len) {
    SlotSpec *spec;
    const char *p = spec_str;
    const char *end = spec_str + len;
    const char *name_start, *name_end;
    STRLEN name_len;

    check_spec_parens(aTHX_ spec_str, len);
    Newxz(spec, 1, SlotSpec);

    /* Parse property name (before first ':') */
    name_start = p;
    while (p < end && *p != ':') p++;
    name_end = p;

    name_len = name_end - name_start;
    Newx(spec->name, name_len + 1, char);
    Copy(name_start, spec->name, name_len, char);
    spec->name[name_len] = '\0';
    
    /* Parse modifiers after name */
    while (p < end) {
        const char *mod_start;
        const char *arg_start;
        const char *arg_end;
        STRLEN mod_len;
        STRLEN arg_len;
        int paren_depth;

        /*
         # uncoverable branch false
         # uncoverable condition right count:1 */
        if (*p == ':') p++;  /* Skip separator */
        if (p >= end) break;

        mod_start = p;

        /* Check for function-style modifiers: default(...), trigger(...) */
        while (p < end && *p != ':' && *p != '(') p++;

        mod_len = p - mod_start;

        if (p < end && *p == '(') {
            /* Function-style: default(value) or trigger(&callback) */
            p++;
            arg_start = p;
            paren_depth = 1;
            /* check_spec_parens has made sure the closing ')' is there */
            while (paren_depth > 0) {
                if (*p == '(') paren_depth++;
                else if (*p == ')') paren_depth--;
                p++;
            }
            arg_end = p - 1;  /* Before closing paren */
            arg_len = arg_end - arg_start;
            
            if (mod_len == 7 && strncmp(mod_start, "default", 7) == 0) {
                /* Parse default value */
                spec->has_default = 1;
                /* Simple default: copy as string and eval at runtime */
                /* For now, support literal numbers and strings */
                if (arg_len > 0) {
                    char *arg_copy;
                    Newx(arg_copy, arg_len + 1, char);
                    Copy(arg_start, arg_copy, arg_len, char);
                    arg_copy[arg_len] = '\0';
                    
                    /* Try to parse as number */
                    if (arg_copy[0] >= '0' && arg_copy[0] <= '9') {
                        if (strchr(arg_copy, '.')) {
                            spec->default_sv = newSVnv(atof(arg_copy));
                        } else {
                            spec->default_sv = newSViv(atoi(arg_copy));
                        }
                    } else if (arg_copy[0] == '-' && arg_len > 1) {
                        if (strchr(arg_copy, '.')) {
                            spec->default_sv = newSVnv(atof(arg_copy));
                        } else {
                            spec->default_sv = newSViv(atoi(arg_copy));
                        }
                    } else if (arg_copy[0] == '\'' || arg_copy[0] == '"') {
                        /* String literal - strip quotes */
                        if (arg_len >= 2) {
                            spec->default_sv = newSVpvn(arg_copy + 1, arg_len - 2);
                        } else {
                            spec->default_sv = newSVpvn("", 0);
                        }
                    } else if (strncmp(arg_copy, "undef", 5) == 0) {
                        spec->default_sv = newSV(0);
                    } else if (strncmp(arg_copy, "[]", 2) == 0) {
                        spec->default_sv = newRV_noinc((SV*)newAV());
                    } else if (strncmp(arg_copy, "{}", 2) == 0) {
                        spec->default_sv = newRV_noinc((SV*)newHV());
                    } else {
                        /* Default to string */
                        spec->default_sv = newSVpvn(arg_copy, arg_len);
                    }
                    Safefree(arg_copy);
                }
            } else if (mod_len == 7 && strncmp(mod_start, "trigger", 7) == 0) {
                /* trigger(&callback) - store callback name for later resolution */
                spec->has_trigger = 1;
                /* Note: callback resolution happens at runtime in Perl layer */
                /* For now, store as string - will be resolved in object.pm */
                if (arg_len > 0) {
                    char *cb_copy;
                    Newx(cb_copy, arg_len + 1, char);
                    Copy(arg_start, cb_copy, arg_len, char);
                    cb_copy[arg_len] = '\0';
                    /* Store as SV for later resolution */
                    spec->trigger_cb = newSVpvn(cb_copy, arg_len);
                    Safefree(cb_copy);
                }
            } else if (mod_len == 6 && strncmp(mod_start, "coerce", 6) == 0) {
                /* coerce(&callback) */
                spec->has_coerce = 1;
                if (arg_len > 0) {
                    char *cb_copy;
                    Newx(cb_copy, arg_len + 1, char);
                    Copy(arg_start, cb_copy, arg_len, char);
                    cb_copy[arg_len] = '\0';
                    spec->coerce_cb = newSVpvn(cb_copy, arg_len);
                    Safefree(cb_copy);
                }
            } else if (mod_len == 7 && strncmp(mod_start, "builder", 7) == 0) {
                /* builder(method_name) - builder method, called at new() unless :lazy */
                spec->has_builder = 1;
                if (arg_len > 0) {
                    char *cb_copy;
                    Newx(cb_copy, arg_len + 1, char);
                    Copy(arg_start, cb_copy, arg_len, char);
                    cb_copy[arg_len] = '\0';
                    spec->builder_name = newSVpvn(cb_copy, arg_len);
                    Safefree(cb_copy);
                } else {
                    /* Default builder name: _build_<property> */
                    char build_name[256];
                    snprintf(build_name, sizeof(build_name), "_build_%s", spec->name);
                    spec->builder_name = newSVpv(build_name, 0);
                }
            } else if (mod_len == 7 && strncmp(mod_start, "clearer", 7) == 0) {
                /* clearer(method_name) - custom clearer method name */
                spec->has_clearer = 1;
                if (arg_len > 0) {
                    char *name_copy;
                    Newx(name_copy, arg_len + 1, char);
                    Copy(arg_start, name_copy, arg_len, char);
                    name_copy[arg_len] = '\0';
                    spec->clearer_name = newSVpvn(name_copy, arg_len);
                    Safefree(name_copy);
                }
            } else if (mod_len == 9 && strncmp(mod_start, "predicate", 9) == 0) {
                /* predicate(method_name) - custom predicate method name */
                spec->has_predicate = 1;
                if (arg_len > 0) {
                    char *name_copy;
                    Newx(name_copy, arg_len + 1, char);
                    Copy(arg_start, name_copy, arg_len, char);
                    name_copy[arg_len] = '\0';
                    spec->predicate_name = newSVpvn(name_copy, arg_len);
                    Safefree(name_copy);
                }
            } else if (mod_len == 6 && strncmp(mod_start, "reader", 6) == 0) {
                /* reader(method_name) - custom getter method name */
                if (arg_len > 0) {
                    char *name_copy;
                    Newx(name_copy, arg_len + 1, char);
                    Copy(arg_start, name_copy, arg_len, char);
                    name_copy[arg_len] = '\0';
                    spec->reader_name = newSVpvn(name_copy, arg_len);
                    Safefree(name_copy);
                }
            } else if (mod_len == 6 && strncmp(mod_start, "writer", 6) == 0) {
                /* writer(method_name) - custom setter method name */
                if (arg_len > 0) {
                    char *name_copy;
                    Newx(name_copy, arg_len + 1, char);
                    Copy(arg_start, name_copy, arg_len, char);
                    name_copy[arg_len] = '\0';
                    spec->writer_name = newSVpvn(name_copy, arg_len);
                    Safefree(name_copy);
                }
            } else if (mod_len == 7 && strncmp(mod_start, "handles", 7) == 0) {
                parse_handles(aTHX_ spec, arg_start, arg_len);
            } else if (mod_len == 3 && strncmp(mod_start, "arg", 3) == 0) {
                /* arg(init_arg_name) - alternate constructor argument name */
                if (arg_len > 0) {
                    char *name_copy;
                    Newx(name_copy, arg_len + 1, char);
                    Copy(arg_start, name_copy, arg_len, char);
                    name_copy[arg_len] = '\0';
                    spec->init_arg = newSVpvn(name_copy, arg_len);
                    Safefree(name_copy);
                }
            }
        } else {
            /* Simple modifier: type name or flag */
            if (mod_len == 8 && strncmp(mod_start, "required", 8) == 0) {
                spec->is_required = 1;
            } else if (mod_len == 8 && strncmp(mod_start, "readonly", 8) == 0) {
                spec->is_readonly = 1;
            } else if (mod_len == 4 && strncmp(mod_start, "lazy", 4) == 0) {
                spec->is_lazy = 1;
            } else if (mod_len == 4 && strncmp(mod_start, "weak", 4) == 0) {
                spec->is_weak = 1;
            } else if (mod_len == 7 && strncmp(mod_start, "private", 7) == 0) {
                spec->is_private = 1;
            } else if (mod_len == 7 && strncmp(mod_start, "clearer", 7) == 0) {
                spec->has_clearer = 1;
                /* Default clearer name: clear_<property> */
            } else if (mod_len == 9 && strncmp(mod_start, "predicate", 9) == 0) {
                spec->has_predicate = 1;
                /* Default predicate name: has_<property> */
            } else {
                /* Try as type name. A registered type takes precedence over
                 * a built-in of the same name, so a type a user registered
                 * keeps its meaning when a built-in of that name is added. */
                char *type_copy;
                SV **svp = NULL;

                Newx(type_copy, mod_len + 1, char);
                Copy(mod_start, type_copy, mod_len, char);
                type_copy[mod_len] = '\0';

                /*
                 # uncoverable branch false
                 # uncoverable condition right count:1 */
                if (g_type_registry) {
                    svp = hv_fetch(g_type_registry, type_copy, mod_len, 0);
                }
                if (svp) {
                    spec->registered = INT2PTR(RegisteredType*, SvIV(*svp));
                    spec->type_id = TYPE_CUSTOM;
                    spec->has_type = 1;
                } else {
                    BuiltinTypeID type_id = parse_builtin_type(type_copy, mod_len);
                    if (type_id != TYPE_NONE) {
                        spec->type_id = type_id;
                        spec->has_type = 1;
                    }
                }
                Safefree(type_copy);
            }
        }
    }
    
    spec->has_checks = spec->is_readonly | spec->is_required | spec->has_coerce
                     | (spec->type_id == TYPE_CUSTOM ? 1 : 0);

    return spec;
}

/* Magic vtable for object flags */
static MGVTBL object_magic_vtbl = {
    NULL,  /* get */
    NULL,  /* set */
    NULL,  /* len */
    NULL,  /* clear */
    NULL,  /* free */
    NULL,  /* copy */
    NULL,  /* dup */
    NULL   /* local */
};

/* Validate that an SV is a blessed array-backed object */
#define VALIDATE_OBJECT(sv, funcname) \
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV || !SvOBJECT(SvRV(sv))) \
        croak("%s: argument is not an Object::Proto object", funcname)

/* Get object magic (for flags) */
static MAGIC* get_object_magic(pTHX_ SV *obj) {
    MAGIC *mg;
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!SvROK(obj)) return NULL;
    mg = mg_find(SvRV(obj), PERL_MAGIC_ext);
    while (mg) {
        if (mg->mg_virtual == &object_magic_vtbl) return mg;
        mg = mg->mg_moremagic;
    }
    return NULL;
}

/* A slot holding the shared undef is empty: before perl 5.20 av_fill put
   &PL_sv_undef in new slots rather than NULL, and it is read-only. */
static int slot_is_writable(SV *slot) {
    return slot && slot != &PL_sv_undef; /* # uncoverable condition right count:2 */
}

/* Add object magic */
static MAGIC* add_object_magic(pTHX_ SV *obj) {
    MAGIC *mg;
    SV *rv = SvRV(obj);
    mg = sv_magicext(rv, NULL, PERL_MAGIC_ext, &object_magic_vtbl, NULL, 0);
    mg->mg_private = 0;  /* flags */
    return mg;
}

/* ============================================
   Class definition and registration
   ============================================ */

/* Clone a SlotSpec (deep copy for inheritance) */
static SlotSpec* clone_slot_spec(pTHX_ const SlotSpec *src) {
    SlotSpec *dst;
    STRLEN name_len;

    Newxz(dst, 1, SlotSpec);

    name_len = strlen(src->name);
    Newx(dst->name, name_len + 1, char);
    Copy(src->name, dst->name, name_len + 1, char);

    dst->type_id     = src->type_id;
    dst->registered  = src->registered;
    dst->is_required = src->is_required;
    dst->is_readonly = src->is_readonly;
    dst->is_lazy     = src->is_lazy;
    dst->is_weak     = src->is_weak;
    dst->is_private  = src->is_private;
    dst->has_default  = src->has_default;
    dst->has_trigger  = src->has_trigger;
    dst->has_coerce   = src->has_coerce;
    dst->has_type     = src->has_type;
    dst->has_builder  = src->has_builder;
    dst->has_clearer  = src->has_clearer;
    dst->has_predicate = src->has_predicate;
    dst->has_checks   = src->has_checks;   /* the inlined typed setter skips readonly/required/coerce without it */

    if (src->default_sv)  dst->default_sv  = SvREFCNT_inc(src->default_sv);
    if (src->trigger_cb)  dst->trigger_cb  = SvREFCNT_inc(src->trigger_cb);
    if (src->coerce_cb)   dst->coerce_cb   = SvREFCNT_inc(src->coerce_cb);
    if (src->builder_name) dst->builder_name = SvREFCNT_inc(src->builder_name);
    if (src->clearer_name) dst->clearer_name = SvREFCNT_inc(src->clearer_name);
    if (src->predicate_name) dst->predicate_name = SvREFCNT_inc(src->predicate_name);
    if (src->reader_name) dst->reader_name = SvREFCNT_inc(src->reader_name);
    if (src->writer_name) dst->writer_name = SvREFCNT_inc(src->writer_name);
    if (src->init_arg) dst->init_arg = SvREFCNT_inc(src->init_arg);
    /* An inherited attribute stays private to the package that declared it */
    dst->private_owner = savepv(src->private_owner);   /* savepv(NULL) is NULL */
    dst->private_also  = savepv(src->private_also);

    /* handles as written are shared; what they resolve to, and the default
     * they add, are worked out again for the clone's own final spec - a
     * +attr may give it a builder that an inherited implicit [] would mask */
    dst->handles     = (AV*)SvREFCNT_inc((SV*)src->handles);
    dst->has_handles = src->has_handles;
    if (src->default_implicit) {
        dst->has_default = 0;
        SvREFCNT_dec(dst->default_sv);
        dst->default_sv = NULL;
    }

    return dst;
}

/* The parent's handles with the override's added: an override entry with the
 * same method name replaces the parent's. Returns a new array. */
static AV* merge_handles(pTHX_ AV *parent, AV *override) {
    AV *merged = newAV();
    HV *replaced = handles_locals(aTHX_ override);
    SSize_t i;
    for (i = 0; parent && i < av_len(parent); i += 2) {   /* the parent may have none */
        SV *local = AvARRAY(parent)[i];
        if (SvOK(local) && hv_exists_ent(replaced, local, 0)) continue;
        av_push(merged, SvREFCNT_inc(local));
        av_push(merged, SvREFCNT_inc(AvARRAY(parent)[i + 1]));
    }
    for (i = 0; i <= av_len(override); i++) {
        av_push(merged, SvREFCNT_inc(AvARRAY(override)[i]));
    }
    return merged;
}

/* Merge child override modifiers onto a clone of parent spec.
 * Only fields that are explicitly set in override are applied.
 * This enables Moo/Moose-style '+attr' syntax for inheritance.
 * Called at define-time only - zero runtime overhead. */
static SlotSpec* merge_slot_spec(pTHX_ const SlotSpec *parent, const SlotSpec *override) {
    SlotSpec *merged = clone_slot_spec(aTHX_ parent);
    
    /* Override type if specified */
    if (override->has_type) {
        merged->type_id = override->type_id;
        merged->registered = override->registered;
        merged->has_type = 1;
    }
    
    /* Override default if specified */
    if (override->has_default) {
        if (merged->default_sv) SvREFCNT_dec(merged->default_sv);
        merged->default_sv = override->default_sv ? SvREFCNT_inc(override->default_sv) : NULL;
        merged->has_default = 1;
    }
    
    /* Override trigger if specified */
    if (override->has_trigger) {
        if (merged->trigger_cb) SvREFCNT_dec(merged->trigger_cb);
        merged->trigger_cb = override->trigger_cb ? SvREFCNT_inc(override->trigger_cb) : NULL;
        merged->has_trigger = 1;
    }
    
    /* Override coerce if specified */
    if (override->has_coerce) {
        if (merged->coerce_cb) SvREFCNT_dec(merged->coerce_cb);
        merged->coerce_cb = override->coerce_cb ? SvREFCNT_inc(override->coerce_cb) : NULL;
        merged->has_coerce = 1;
    }
    
    /* Override builder if specified */
    if (override->has_builder) {
        if (merged->builder_name) SvREFCNT_dec(merged->builder_name);
        merged->builder_name = override->builder_name ? SvREFCNT_inc(override->builder_name) : NULL; /* # uncoverable condition right count:1 */
        merged->has_builder = 1;
    }
    
    /* Boolean flags - only set if explicitly enabled in override */
    if (override->is_required) merged->is_required = 1;
    if (override->is_readonly) merged->is_readonly = 1;
    if (override->is_lazy)     merged->is_lazy = 1;
    if (override->is_weak)     merged->is_weak = 1;
    if (override->is_private) {
        /* Made private by the child, so the child is the one package that may call it */
        merged->is_private = 1;
        Safefree(merged->private_owner);
        Safefree(merged->private_also);
        merged->private_owner = savepv(override->private_owner);
        merged->private_also  = NULL;
    }
    
    /* Clearer/predicate */
    if (override->has_clearer) {
        merged->has_clearer = 1;
        if (override->clearer_name) {
            if (merged->clearer_name) SvREFCNT_dec(merged->clearer_name);
            merged->clearer_name = SvREFCNT_inc(override->clearer_name);
        }
    }
    if (override->has_predicate) {
        merged->has_predicate = 1;
        if (override->predicate_name) {
            if (merged->predicate_name) SvREFCNT_dec(merged->predicate_name);
            merged->predicate_name = SvREFCNT_inc(override->predicate_name);
        }
    }
    
    /* Reader/writer/init_arg */
    if (override->reader_name) {
        if (merged->reader_name) SvREFCNT_dec(merged->reader_name);
        merged->reader_name = SvREFCNT_inc(override->reader_name);
    }
    if (override->writer_name) {
        if (merged->writer_name) SvREFCNT_dec(merged->writer_name);
        merged->writer_name = SvREFCNT_inc(override->writer_name);
    }
    if (override->init_arg) {
        if (merged->init_arg) SvREFCNT_dec(merged->init_arg);
        merged->init_arg = SvREFCNT_inc(override->init_arg);
    }
    
    /* handles: the union, the override winning for a method name */
    if (override->has_handles) {
        AV *was = merged->handles;
        merged->handles = merge_handles(aTHX_ was, override->handles);
        merged->has_handles = 1;
        SvREFCNT_dec((SV*)was);
    }

    /* Recompute has_checks flag */
    merged->has_checks = merged->is_readonly | merged->is_required | merged->has_coerce
                       | (merged->type_id == TYPE_CUSTOM ? 1 : 0);
    
    return merged;
}

/* ============================================
   handles(...) - resolving against the slot's final type
   ============================================ */

/* A slot type's name, for messages */
static const char *slot_type_name(const SlotSpec *spec) {
    return spec->type_id == TYPE_CUSTOM ? spec->registered->name : type_id_to_name(spec->type_id);
}

/* Add one delegator to out (local, remote, op triples) */
static void handles_push(pTHX_ AV *out, HV *seen, SV *local, SV *remote, IV op) {
    (void)hv_store_ent(seen, local, &PL_sv_yes, 0);
    av_push(out, SvREFCNT_inc(local));
    av_push(out, SvREFCNT_inc(remote));
    av_push(out, newSViv(op));
}

/* A method the role brings, delegated under its own name unless a method
 * given explicitly already has that name. Counted either way. */
static void handles_push_role_method(pTHX_ AV *out, HV *seen, SV *name, IV *found) {
    (*found)++;
    if (hv_exists_ent(seen, name, 0)) return;
    handles_push(aTHX_ out, seen, name, name, 0);
}

/* Push onto names every method a slot gives a class: its accessor, and its
 * reader, writer, clearer and predicate when it has them */
static void slot_method_names(pTHX_ const SlotSpec *spec, AV *names) {
    av_push(names, newSVpv(spec->name, 0));
    if (spec->reader_name) av_push(names, newSVsv(spec->reader_name));
    if (spec->writer_name) av_push(names, newSVsv(spec->writer_name));
    if (spec->has_clearer) {
        av_push(names, spec->clearer_name ? newSVsv(spec->clearer_name)
                                          : newSVpvf("clear_%s", spec->name));
    }
    if (spec->has_predicate) {
        av_push(names, spec->predicate_name ? newSVsv(spec->predicate_name)
                                            : newSVpvf("has_%s", spec->name));
    }
}

/* Every method within a role (D8): the methods it requires, the subs defined
 * in its package - not imported ones, not constants, not _private ones nor
 * reserved names - in sorted order, and the methods its slots give a class
 * that composes it, except for private slots, whose methods the delegating
 * class could not call. The role is loaded if it is not defined yet, as with()
 * does, and read as it is now. */
static void handles_expand_role(pTHX_ SlotSpec *spec, SV *role_sv, AV *out, HV *seen) {
    STRLEN role_len;
    const char *role_pv = SvPV(role_sv, role_len);
    RoleMeta *role = get_role_meta(aTHX_ role_pv, role_len);
    AV *subs = (AV*)sv_2mortal((SV*)newAV());
    IV found = 0;
    IV i;

    if (!role) {
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvn(role_pv, role_len), NULL);
        role = get_role_meta(aTHX_ role_pv, role_len);
        if (!role)
            croak("Role '%s' in handles for slot '%s' is not defined", role_pv, spec->name);
    }

    for (i = 0; i < role->required_count; i++) {
        handles_push_role_method(aTHX_ out, seen,
            sv_2mortal(newSVpv(role->required_methods[i], 0)), &found);
    }

    /* The role's package is walked bucket by bucket so that its iterator is
     * left alone. A package with keys has its buckets; an empty one may not. */
    if (HvTOTALKEYS(role->stash)) {
        HE **buckets = HvARRAY(role->stash);
        STRLEN b;
        for (b = 0; b <= HvMAX(role->stash); b++) {
            HE *he;
            for (he = buckets[b]; he; he = HeNEXT(he)) {
                SV *entry = HeVAL(he);
                const char *name;
                CV *cv;
                /* Not a glob: a constant or a declaration without a body */
                if (SvTYPE(entry) != SVt_PVGV) continue;
                cv = GvCV((GV*)entry);
                /* No sub, or one not compiled in the role's package: an
                 * imported one, or a constant, which belongs to no package */
                if (!cv || CvSTASH(cv) != role->stash) continue;
                name = HeKEY(he);
                if (*name == '_' || is_reserved_method(aTHX_ name, HeKLEN(he), HeHASH(he))) continue;
                av_push(subs, newSVhek(HeKEY_hek(he)));    /* keeps a UTF-8 name's flag */
            }
        }
    }
    sortsv(AvARRAY(subs), av_len(subs) + 1, Perl_sv_cmp);
    for (i = 0; i <= av_len(subs); i++) {
        handles_push_role_method(aTHX_ out, seen, AvARRAY(subs)[i], &found);
    }

    for (i = 0; i < role->slot_count; i++) {
        AV *names;
        IV n;
        if (role->slots[i]->is_private) continue;
        names = (AV*)sv_2mortal((SV*)newAV());
        slot_method_names(aTHX_ role->slots[i], names);
        for (n = 0; n <= av_len(names); n++) {
            handles_push_role_method(aTHX_ out, seen, AvARRAY(names)[n], &found);
        }
    }

    if (!found)
        croak("Role '%s' in handles for slot '%s' has no methods", role_pv, spec->name);
}

/* Add a delegator given by name: what the name maps to depends on the kind */
static void handles_push_named(pTHX_ SlotSpec *spec, U8 kind, const char *kind_name,
                               AV *out, HV *seen, SV *local, SV *remote) {
    SV *target = remote ? remote : local;    /* a bare name maps to itself */
    const NativeOp *ops = kind == HK_ARRAY ? array_ops : hash_ops;
    HV *index = kind == HK_ARRAY ? g_array_op_index : g_hash_op_index;
    IV op;

    switch (kind) {
        case HK_METHOD:
            handles_push(aTHX_ out, seen, local, target, 0);
            return;
        case HK_CODE:
            /* A bare name calls the code; =>call does too, =>method passes $self */
            if (!remote || strEQ(SvPV_nolen(remote), "call")) {
                op = HANDLE_CODE_CALL;
            } else if (strEQ(SvPV_nolen(remote), "method")) {
                op = HANDLE_CODE_METHOD;
            } else {
                croak("CodeRef handles for slot '%s' must map to call or method, not '%s'",
                      spec->name, SvPV_nolen(remote));
            }
            handles_push(aTHX_ out, seen, local,
                         sv_2mortal(newSVpv(op == HANDLE_CODE_METHOD ? "method" : "call", 0)), op);
            return;
        default:    /* HK_ARRAY, HK_HASH */
            op = find_native_op(aTHX_ index, target);
            if (op < 0) {
                SV *valid = sv_2mortal(newSVpvs(""));
                IV i;
                for (i = 0; ops[i].name; i++) {
                    if (ops[i].alias_of) continue;
                    sv_catpvf(valid, "%s%s", i ? ", " : "", ops[i].name);
                }
                croak("Unknown %s method '%s' in handles for slot '%s' (valid: %s)",
                      kind_name, SvPV_nolen(target), spec->name, SvPV_nolen(valid));
            }
            if (ops[op].mutates && spec->is_readonly) {
                croak("Cannot delegate %s=>%s on readonly slot '%s'",
                      SvPV_nolen(local), ops[op].name, spec->name);
            }
            handles_push(aTHX_ out, seen, local, sv_2mortal(newSVpv(ops[op].name, 0)), op);
            return;
    }
}

/* Resolve a slot's handles against its final type, once it is about to join a
 * class, and check them: the type must support handles (D1, D18), a weak slot
 * only method delegation (D14), a native method must exist (D15) and not change
 * a readonly slot (D5), a CodeRef maps to call or method (D9), a role brings
 * every method within it (D8). An ArrayRef or HashRef slot with no default,
 * builder or required gets an implicit [] or {} (D3). Croaks before the class
 * is touched, so a caught error leaves it as it was. */
static void resolve_handles(pTHX_ SlotSpec *spec) {
    AV *out;
    HV *seen;
    U8 kind;
    IV k, i, n;

    if (!spec->has_handles) return;

    if (!spec->has_type)
        croak("handles is not supported on an untyped slot '%s'", spec->name);
    k = handle_kind_of(spec->type_id);
    if (k < 0) {
        const char *type = slot_type_name(spec);
        croak("handles is not supported on %s %s slot '%s'",
              strchr("AEIOU", *type) ? "an" : "a", type, spec->name);
    }
    kind = handle_kinds[k].kind;

    if (spec->is_weak && kind != HK_METHOD)
        croak("weak slot '%s' cannot have %s handles", spec->name, handle_kinds[k].name);

    if (kind == HK_ARRAY || kind == HK_HASH) {
        svtype want = kind == HK_ARRAY ? SVt_PVAV : SVt_PVHV;
        if (spec->has_default) {
            if (!spec->default_sv || !SvROK(spec->default_sv) || SvTYPE(SvRV(spec->default_sv)) != want)
                croak("The default of %s slot '%s' must be %s for handles",
                      handle_kinds[k].name, spec->name, kind == HK_ARRAY ? "[]" : "{}");
        } else if (!spec->has_builder && !spec->is_required) {
            /* Not marked in has_any_defaults (note_slot_flags), which would
             * change how new() reads positional arguments */
            spec->has_default = 1;
            spec->default_implicit = 1;
            spec->default_sv = newRV_noinc(kind == HK_ARRAY ? (SV*)newAV() : (SV*)newHV());
        }
    }

    out  = (AV*)sv_2mortal((SV*)newAV());
    seen = (HV*)sv_2mortal((SV*)newHV());
    n = av_len(spec->handles) + 1;

    /* Named entries first, so that a name given explicitly wins over the same
     * name brought by a role */
    for (i = 0; i < n; i += 2) {
        SV *local  = AvARRAY(spec->handles)[i];
        SV *remote = AvARRAY(spec->handles)[i + 1];
        if (!SvOK(local)) continue;
        handles_push_named(aTHX_ spec, kind, handle_kinds[k].name, out, seen,
                           local, SvOK(remote) ? remote : NULL);
    }
    for (i = 0; i < n; i += 2) {
        if (SvOK(AvARRAY(spec->handles)[i])) continue;
        if (kind != HK_METHOD)
            croak("handles(role:...) needs an Object slot, '%s' is %s",
                  spec->name, handle_kinds[k].name);
        handles_expand_role(aTHX_ spec, AvARRAY(spec->handles)[i + 1], out, seen);
    }

    n = (av_len(out) + 1) / 3;
    Newxz(spec->resolved, n, ResolvedHandle);
    for (i = 0; i < n; i++) {
        ResolvedHandle *h = &spec->resolved[i];
        SV *remote = AvARRAY(out)[i * 3 + 1];
        h->local  = SvREFCNT_inc(AvARRAY(out)[i * 3]);
        /* A method name is made a shared hash key once here, so that each call
         * looks the method up without hashing or copying the name */
        if (kind == HK_METHOD) {
            STRLEN len;
            const char *pv = SvPV(remote, len);
            h->remote = newSVpvn_share(pv, SvUTF8(remote) ? -(I32)len : (I32)len, 0);
        } else {
            h->remote = SvREFCNT_inc(remote);
        }
        h->kind   = kind;
        h->op     = (U8)SvIV(AvARRAY(out)[i * 3 + 2]);
    }
    spec->resolved_count = n;
}

static ClassMeta* create_class_meta(pTHX_ const char *class_name, STRLEN len) {
    ClassMeta *meta;
    Newxz(meta, 1, ClassMeta);
    Newxz(meta->class_name, len + 1, char);
    Copy(class_name, meta->class_name, len, char);
    meta->class_name[len] = '\0';
    meta->prop_to_idx = newHV();
    meta->arg_to_idx = newHV();
    meta->idx_to_prop = NULL;
    meta->slot_count = 1;  /* slot 0 reserved for prototype */
    meta->stash = gv_stashpvn(class_name, len, GV_ADD);
    return meta;
}

static ClassMeta* get_class_meta(pTHX_ const char *class_name, STRLEN len) {
    SV **svp;
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!g_class_registry) return NULL;
    svp = hv_fetch(g_class_registry, class_name, len, 0);
    if (svp && SvIOK(*svp)) { /* # uncoverable condition right count:2 */
        return INT2PTR(ClassMeta*, SvIV(*svp));
    }
    return NULL;
}

static void register_class_meta(pTHX_ const char *class_name, STRLEN len, ClassMeta *meta) {
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!g_class_registry) {
        g_class_registry = newHV(); /* # uncoverable statement */
    }
    hv_store(g_class_registry, class_name, len, newSViv(PTR2IV(meta)), 0);
}

/* ============================================
   Prototype chain resolution
   ============================================ */

#define MAX_PROTOTYPE_DEPTH 100

/* Resolve a property through the full prototype chain.
 * Returns the value if found, or &PL_sv_undef if not.
 * Detects circular references using depth limit and pointer tracking.
 */
static SV* resolve_property_chain(pTHX_ AV *av, IV idx) {
    int depth = 0;
    AV *visited[MAX_PROTOTYPE_DEPTH];  /* Simple stack-based cycle detection */
    int i;

    while (av && depth < MAX_PROTOTYPE_DEPTH) { /* # uncoverable condition right count:1 */
        /* Check for circular reference */
        for (i = 0; i < depth; i++) {
            if (visited[i] == av) {
                warn("Circular prototype reference detected");
                return &PL_sv_undef;
            }
        }
        visited[depth] = av;

        /* Try to fetch the property at this level */
        if (idx <= AvFILLp(av)) {
            SV *slot = AvARRAY(av)[idx];
            if (slot && SvOK(slot)) return slot;
        }

        /* Follow prototype chain (slot 0) */
        if (AvFILLp(av) < 0) break;
        {
            SV *proto_sv = AvARRAY(av)[0];
            /*
             # uncoverable branch true count:1 class:ignore_covered_err
             # uncoverable condition left count:1 */
            if (!proto_sv || !SvROK(proto_sv) || SvTYPE(SvRV(proto_sv)) != SVt_PVAV) break;
            av = (AV*)SvRV(proto_sv);
        }
        depth++;
    }

    if (depth >= MAX_PROTOTYPE_DEPTH) {
        warn("Prototype chain too deep (max %d levels)", MAX_PROTOTYPE_DEPTH);
    }

    return &PL_sv_undef;
}

/* ============================================
   Custom OP: property accessor (get)
   ============================================ */

static OP* pp_object_get(pTHX) {
    dSP;
    SV *obj = TOPs;
    IV idx = PL_op->op_targ;
    AV *av;
    SV *sv;

    if (!SvROK(obj) || SvTYPE(SvRV(obj)) != SVt_PVAV) {
        croak("Not an object");
    }

    av = (AV*)SvRV(obj);

    /* Fast path: direct slot access (common case - no prototype chain) */
    if (idx <= AvFILLp(av)) {
        sv = AvARRAY(av)[idx];
        if (sv && SvOK(sv)) {
            SETs(sv);
            RETURN;
        }
    }

    /* Slow path: check prototype chain only if prototype exists.
       Slot 0 is always allocated - use direct access instead of av_fetch(). */
    {
        SV *proto_sv = AvARRAY(av)[0];
        if (proto_sv && SvROK(proto_sv) && SvTYPE(SvRV(proto_sv)) == SVt_PVAV) { /* # uncoverable condition right count:1 */
            SV *result = resolve_property_chain(aTHX_ av, idx);
            SETs(result);
            RETURN;
        }
    }

    SETs(&PL_sv_undef);
    RETURN;
}

/* ============================================
   Custom OP: property accessor (set)
   ============================================ */

static OP* pp_object_set(pTHX) {
    dSP;
    SV *val = POPs;
    SV *obj = TOPs;
    IV idx = PL_op->op_targ;
    SV *rv;
    AV *av;

    rv = SvRV(obj);
    if (!SvROK(obj) || SvTYPE(rv) != SVt_PVAV) {
        croak("Not an object");
    }

    av = (AV*)rv;

    /* Only check magic if object has any (lazy magic - most objects don't) */
    if (SvMAGICAL(rv)) {
        MAGIC *mg = get_object_magic(aTHX_ obj);
        if (mg && (mg->mg_private & OBJ_FLAG_FROZEN)) {
            croak("Cannot modify frozen object");
        }
    }

    /* In-place update if slot already has an SV (avoids alloc/dealloc) */
    if (idx <= AvFILLp(av)) {
        SV *slot = AvARRAY(av)[idx];
        if (slot_is_writable(slot)) {
            sv_setsv(slot, val);
            SETs(val);
            RETURN;
        }
    }

    av_store(av, idx, newSVsv(val));
    SETs(val);
    RETURN;
}

/* ============================================
   Custom OP: property accessor (set) with type check
   Uses op_private to store type ID for inline check
   ============================================ */

/* Helper struct to pass both idx and meta through op */
typedef struct {
    IV slot_idx;
    ClassMeta *meta;
} SlotOpData;

/* Helper struct for function-style accessors (cross-class support) */
struct FuncAccessorData_s {
    IV slot_idx;
    ClassMeta *expected_class;  /* Class this accessor expects */
    SlotSpec *spec;             /* Slot spec (for lazy support), may be NULL */
    IV registry_id;             /* ID in g_func_accessor_registry */
    ClassMeta *meta;            /* Class imported from: its current spec decides :private */
};

/* Register a FuncAccessorData and return its ID */
static IV register_func_accessor_data(pTHX_ FuncAccessorData *data) {
    if (g_func_accessor_count >= g_func_accessor_capacity) {
        IV new_capacity = g_func_accessor_capacity ? g_func_accessor_capacity * 2 : 64;
        Renew(g_func_accessor_registry, new_capacity, FuncAccessorData*);
        g_func_accessor_capacity = new_capacity;
    }
    data->registry_id = g_func_accessor_count;
    g_func_accessor_registry[g_func_accessor_count] = data;
    return g_func_accessor_count++;
}

/* Look up FuncAccessorData by ID — inlined for hot path performance */
OBJECT_INLINE FuncAccessorData* get_func_accessor_data(IV id) {
    return g_func_accessor_registry[id];
}

static OP* pp_object_set_typed(pTHX) {
    dSP;
    SV *val = POPs;
    SV *obj = TOPs;
    SlotOpData *data = INT2PTR(SlotOpData*, PL_op->op_targ);
    IV idx = data->slot_idx;
    ClassMeta *meta = data->meta;
    SlotSpec *spec = meta->slots[idx];
    AV *av;

    if (!SvROK(obj) || SvTYPE(SvRV(obj)) != SVt_PVAV) {
        croak("Not an object");
    }

    av = (AV*)SvRV(obj);

    /* Check frozen/locked — only walk magic list if object has magic */
    if (SvMAGICAL(av)) {
        MAGIC *mg = get_object_magic(aTHX_ obj);
        if (mg && (mg->mg_private & OBJ_FLAG_FROZEN)) {
            croak("Cannot modify frozen object");
        }
    }

    /* Fast-skip readonly/required/coerce when none apply */
    if (spec->has_checks) {
        if (spec->is_readonly) {
            croak("Cannot modify readonly slot '%s'", spec->name);
        }
        if (spec->is_required && !SvOK(val)) {
            croak("Cannot set required slot '%s' to undef", spec->name);
        }
        if (spec->has_coerce || spec->type_id == TYPE_CUSTOM) {
            val = apply_slot_coercion(aTHX_ val, spec);
        }
    }

    /* Type check using helper (handles both C and Perl callbacks) */
    if (spec->has_type) {
        if (!check_slot_type(aTHX_ val, spec)) {
            const char *type_name = (spec->type_id == TYPE_CUSTOM && spec->registered)
                ? spec->registered->name
                : type_id_to_name(spec->type_id);
            croak("Type constraint failed for '%s': expected %s",
                  spec->name, type_name);
        }
    }

    /* Trigger callback ($self, $new_value) */
    if (spec->has_trigger && spec->trigger_cb) {
        dSP;
        PUSHMARK(SP);
        XPUSHs(obj);
        XPUSHs(val);
        PUTBACK;
        call_method(SvPV_nolen(spec->trigger_cb), G_DISCARD);
    }

    if (!spec->is_weak) {
        /* In-place update avoids newSVsv allocation (common case) */
        if (idx <= AvFILLp(av)) {
            SV *slot = AvARRAY(av)[idx];
            if (slot_is_writable(slot)) {
                sv_setsv(slot, val);
                SETs(val);
                RETURN;
            }
        }
        av_store(av, idx, newSVsv(val));
    } else {
        SV *stored = newSVsv(val);
        av_store(av, idx, stored);
        if (SvROK(stored)) sv_rvweaken(stored);
    }
    SETs(val);
    RETURN;
}

/* ============================================
   Call checker for accessor
   ============================================ */

static OP* accessor_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    IV idx = SvIV(ckobj);
    OP *pushop, *cvop, *selfop, *argop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    pushop = cUNOPx(entersubop)->op_first;
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    selfop = OpSIBLING(pushop);
    cvop = selfop;
    argop = selfop;
    while (OpHAS_SIBLING(cvop)) {
        argop = cvop;
        cvop = OpSIBLING(cvop);
    }

    /* Check if there's an argument after self (setter call) */
    if (argop != selfop) {
        /* Setter: $obj->name($value) */
        OP *valop = OpSIBLING(selfop);
        
        /* Detach self and val */
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(valop, NULL);
        OpLASTSIB_set(selfop, NULL);
        
        /* Create binop with self and val - use OP_NULL to avoid assertion
         * failures on debugging Perls (5.14-5.20), then set OP_CUSTOM */
        newop = newBINOP(OP_NULL, 0, selfop, valop);
        newop->op_type = OP_CUSTOM;
        newop->op_ppaddr = pp_object_set;
        newop->op_targ = idx;
        
        op_free(entersubop);
        return newop;
    } else {
        /* Getter: $obj->name */
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(selfop, NULL);
        
        /* Use OP_NULL to avoid assertion failures on debugging Perls
         * (5.14-5.20), then set OP_CUSTOM */
        newop = newUNOP(OP_NULL, 0, selfop);
        newop->op_type = OP_CUSTOM;
        newop->op_ppaddr = pp_object_get;
        newop->op_targ = idx;
        
        op_free(entersubop);
        return newop;
    }
}

/* ============================================
   XS Fallback functions
   ============================================ */

/* XS fallback for new (when call checker can't optimize) */
XS_INTERNAL(xs_object_new_fallback) {
    dXSARGS;
    ClassMeta *meta = INT2PTR(ClassMeta*, CvXSUBANY(cv).any_iv);
    AV *obj_av;
    SV *obj_sv;
    SV **ary;
    IV i;
    IV start_arg = 0;
    IV arg_count;
    IV slot_count = meta->slot_count;
    int is_named = 0;

    /* Skip class name if passed as invocant (Cat->new or new Cat).
     * Fast path: compare stash pointer instead of string compare. */
    if (items > 0 && SvPOK(ST(0)) && !SvROK(ST(0))) { /* # uncoverable condition right count:3 */
        /* The class name is always the first arg for Cat->new() or new Cat() style */
        start_arg = 1;
    }

    arg_count = items - start_arg;

    /* Detect named pairs: even count and first arg is a known property/init_arg name,
       OR the class has defaults (unknown keys are dropped, defaults applied). */
    if (arg_count > 0 && (arg_count % 2) == 0 && SvPOK(ST(start_arg))) {
        STRLEN len;
        const char *pv = SvPV(ST(start_arg), len);
        if (hv_exists(meta->prop_to_idx, pv, len) || hv_exists(meta->arg_to_idx, pv, len)
            || meta->has_any_defaults) {
            is_named = 1;
        }
    }

    /* Create array with pre-extended size and get direct pointer */
    obj_av = newAV();
    av_extend(obj_av, slot_count - 1);
    /* Fill array length so AvARRAY access is safe */
    AvFILLp(obj_av) = slot_count - 1;
    ary = AvARRAY(obj_av);

    /* Slot 0 = prototype (initially undef - read-only is fine, never written via setter) */
    ary[0] = &PL_sv_undef;

    /* Fill slots with defaults or writable undef in a single pass */
    for (i = 1; i < slot_count; i++) {
        SlotSpec *spec = meta->slots[i];
        if (spec && spec->has_default && spec->default_sv) { /* # uncoverable condition right count:1 */
            if (SvROK(spec->default_sv)) {
                if (SvTYPE(SvRV(spec->default_sv)) == SVt_PVAV) {
                    ary[i] = newRV_noinc((SV*)newAV());
                /*
                 # uncoverable branch false
                 # uncoverable condition right count:1 */
                } else if (SvTYPE(SvRV(spec->default_sv)) == SVt_PVHV) {
                    ary[i] = newRV_noinc((SV*)newHV());
                } else {
                    ary[i] = newSVsv(spec->default_sv); /* # uncoverable statement */
                }
            } else {
                ary[i] = newSVsv(spec->default_sv);
            }
        } else {
            ary[i] = newSV(0);
        }
    }

    /* Create blessed reference NOW so triggers can do method dispatch */
    obj_sv = newRV_noinc((SV*)obj_av);
    sv_bless(obj_sv, meta->stash);

    if (is_named) {
        /* Named arguments */
        for (i = start_arg; i < items; i += 2) {
            SV *key_sv = ST(i);
            SV *val_sv = (i + 1 < items) ? ST(i + 1) : &PL_sv_undef; /* # uncoverable condition right count:1 */
            STRLEN key_len;
            const char *key = SvPV(key_sv, key_len);
            SV **idx_svp = hv_fetch(meta->arg_to_idx, key, key_len, 0);
            if (idx_svp) {
                IV idx = SvIVX(*idx_svp);
                SlotSpec *spec = meta->slots[idx];
                
                /* Coerce + type check */
                if (spec && spec->has_type) { /* # uncoverable condition right count:1 */
                    if (spec->has_coerce || spec->type_id == TYPE_CUSTOM)
                        val_sv = apply_slot_coercion(aTHX_ val_sv, spec);
                    if (!check_slot_type(aTHX_ val_sv, spec)) {
                        const char *type_name = (spec->type_id == TYPE_CUSTOM && spec->registered) 
                            ? spec->registered->name 
                            : type_id_to_name(spec->type_id);
                        croak("Type constraint failed for '%s' in new(): expected %s",
                              spec->name, type_name);
                    }
                }
                
                /* Trigger callback */
                if (spec && spec->has_trigger && spec->trigger_cb) { /* # uncoverable condition right count:1 */
                    dSP;
                    PUSHMARK(SP);
                    XPUSHs(obj_sv);
                    XPUSHs(val_sv);
                    PUTBACK;
                    call_method(SvPV_nolen(spec->trigger_cb), G_DISCARD);
                }
                
                sv_setsv(ary[idx], val_sv);
            }
        }
    } else {
        /* Positional arguments */
        IV provided = items - start_arg;
        if (provided > slot_count - 1) provided = slot_count - 1;

        for (i = 0; i < provided; i++) {
            IV idx = i + 1;
            SV *val_sv = ST(start_arg + i);
            SlotSpec *spec = meta->slots[idx];
            
            /* Coerce + type check */
            if (spec && spec->has_type) { /* # uncoverable condition right count:1 */
                if (spec->has_coerce || spec->type_id == TYPE_CUSTOM)
                    val_sv = apply_slot_coercion(aTHX_ val_sv, spec);
                if (!check_slot_type(aTHX_ val_sv, spec)) {
                    const char *type_name = (spec->type_id == TYPE_CUSTOM && spec->registered) 
                        ? spec->registered->name 
                        : type_id_to_name(spec->type_id);
                    croak("Type constraint failed for '%s' in new(): expected %s",
                          spec->name, type_name);
                }
            }
            
            /* Trigger callback */
            if (spec && spec->has_trigger && spec->trigger_cb) { /* # uncoverable condition right count:1 */
                dSP;
                PUSHMARK(SP);
                XPUSHs(obj_sv);
                XPUSHs(val_sv);
                PUTBACK;
                call_method(SvPV_nolen(spec->trigger_cb), G_DISCARD);
            }
            
            sv_setsv(ary[idx], val_sv);
        }
    }

    /* Call builders for non-lazy builder slots that weren't set */
    if (meta->has_any_builders) {
        for (i = 1; i < slot_count; i++) {
            SlotSpec *spec = meta->slots[i];
            if (spec && spec->has_builder && !spec->is_lazy && !SvOK(ary[i])) { /* # uncoverable condition right count:1 */
                /* Call builder method */
                dSP;
                IV count;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(obj_sv);
                PUTBACK;
                count = call_method(SvPV_nolen(spec->builder_name), G_SCALAR);
                SPAGAIN;
                /*
                 # uncoverable branch false
                 # uncoverable condition right count:1 */
                if (count > 0) {
                    SV *built_val = POPs;
                    
                    /* Coerce + type check the built value */
                    if (spec->has_type) {
                        if (spec->has_coerce || spec->type_id == TYPE_CUSTOM)
                            built_val = apply_slot_coercion(aTHX_ built_val, spec);
                        if (!check_slot_type(aTHX_ built_val, spec)) {
                            const char *type_name = (spec->type_id == TYPE_CUSTOM && spec->registered) 
                                ? spec->registered->name 
                                : type_id_to_name(spec->type_id);
                            croak("Type constraint failed for '%s' in builder: expected %s",
                                  spec->name, type_name);
                        }
                    }
                    
                    sv_setsv(ary[i], built_val);
                }
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        }
    }

    /* Check required slots */
    if (meta->has_any_required) {
        for (i = 1; i < slot_count; i++) {
            SlotSpec *spec = meta->slots[i];
            if (spec && spec->is_required && !SvOK(ary[i])) { /* # uncoverable condition right count:1 */
                croak("Required slot '%s' not provided in new()", spec->name);
            }
        }
    }

    /* Weaken references if any slots have is_weak */
    if (meta->has_any_weak) {
        for (i = 1; i < slot_count; i++) {
            SlotSpec *spec = meta->slots[i];
            if (spec && spec->is_weak && SvROK(ary[i])) { /* # uncoverable condition right count:1 */
                sv_rvweaken(ary[i]);
            }
        }
    }

    /* Call BUILD if defined. Use tri-state: 0=unchecked, 1=has BUILD, 2=no BUILD.
       Avoids gv_fetchmeth on every construction once checked. */
    if (meta->has_build == 0) {
        GV *gv = gv_fetchmeth(meta->stash, "BUILD", 5, 0);
        if (gv && GvCV(gv)) { /* # uncoverable condition right count:2 */
            meta->has_build = 1;
            meta->build_cv = GvCV(gv);
        } else {
            meta->has_build = 2;
        }
    }
    if (meta->has_build == 1) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(obj_sv);
        PUTBACK;
        call_method("BUILD", G_VOID | G_DISCARD);
        FREETMPS;
        LEAVE;
    }

    ST(0) = sv_2mortal(obj_sv);
    XSRETURN(1);
}

/* XS fallback accessor */
XS_INTERNAL(xs_accessor_fallback) {
    dXSARGS;
    IV idx = CvXSUBANY(cv).any_iv;
    SV *self = ST(0);
    AV *av;
    SV *rv;

    rv = SvRV(self);
    if (!SvROK(self) || SvTYPE(rv) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)rv;

    if (items > 1) {
        /* Setter */
        if (SvMAGICAL(rv)) {
            MAGIC *mg = get_object_magic(aTHX_ self);
            if (mg && (mg->mg_private & OBJ_FLAG_FROZEN)) {
                croak("Cannot modify frozen object");
            }
        }
        /* In-place update if slot already has an SV */
        if (idx <= AvFILLp(av)) {
            SV *slot = AvARRAY(av)[idx];
            if (slot_is_writable(slot)) {
                sv_setsv(slot, ST(1));
                ST(0) = ST(1);
                XSRETURN(1);
            }
        }
        av_store(av, idx, newSVsv(ST(1)));
        ST(0) = ST(1);
        XSRETURN(1);
    } else {
        /* Getter - fast path: direct slot access */
        if (idx <= AvFILLp(av)) {
            SV *sv = AvARRAY(av)[idx];
            if (sv && SvOK(sv)) {
                ST(0) = sv;
                XSRETURN(1);
            }
        }
        /* Slow path: check prototype chain */
        {
            SV **proto = av_fetch(av, 0, 0);
            if (proto && SvROK(*proto) && SvTYPE(SvRV(*proto)) == SVt_PVAV) {
                SV *result = resolve_property_chain(aTHX_ av, idx);
                ST(0) = result;
                XSRETURN(1);
            }
        }
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }
}

/* ============================================
   Install constructor into class
   ============================================ */

static void install_constructor(pTHX_ const char *class_name, ClassMeta *meta) {
    char full_name[256];
    CV *cv;

    snprintf(full_name, sizeof(full_name), "%s::new", class_name);
    
    /* Create a minimal CV that will be replaced by call checker */
    cv = newXS(full_name, xs_object_new_fallback, __FILE__);
    CvXSUBANY(cv).any_iv = PTR2IV(meta);
}

/* ============================================
   Custom OP: fast function-style getter
   op_targ = registry ID, reads object from stack
   ============================================ */
static XOP object_func_get_xop;
static XOP object_func_set_xop;

static OP* pp_object_func_get(pTHX) {
    dSP;
    SV *obj = TOPs;  /* peek, don't pop */
    FuncAccessorData *data = get_func_accessor_data(PL_op->op_targ);
    IV idx = data->slot_idx;
    SV *rv;
    AV *av;
    SV *sv;

    if (!SvROK(obj)) croak("Not an object");
    rv = SvRV(obj);
    if (SvTYPE(rv) != SVt_PVAV) croak("Not an object");
    av = (AV*)rv;

    /* Validate object is of expected class (stash pointer comparison) */
    /*
     # uncoverable branch true
     # uncoverable condition left count:1
     # uncoverable condition left count:2
     # uncoverable condition right count:2 */
    if (data->expected_class && SvSTASH(rv) != data->expected_class->stash) {
        croak("Expected object of class '%s', got '%s'", /* # uncoverable statement */
              data->expected_class->class_name, /* # uncoverable statement */
              HvNAME(SvSTASH(rv))); /* # uncoverable statement */
    }

    /* Direct array access — no SvOK needed (func path has no prototype chain) */
    sv = NULL;
    if (idx <= AvFILLp(av)) {
        sv = AvARRAY(av)[idx];
        if (sv && SvOK(sv)) {
            SETs(sv);
            RETURN;
        }
    }

    /* Lazy initialization for func accessors */
    if (data->spec && data->spec->is_lazy) { /* # uncoverable condition right count:1 */
        SlotSpec *spec = data->spec;
        SV *built_val = NULL;
        if (spec->has_builder && spec->builder_name) { /* # uncoverable condition right count:2 */
            const char *builder = SvPV_nolen(spec->builder_name);
            int count;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(obj);
            PUTBACK;
            count = call_method(builder, G_SCALAR);
            SPAGAIN;
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            if (count > 0) built_val = newSVsv(POPs);
            else built_val = newSV(0); /* # uncoverable statement */
            PUTBACK; FREETMPS; LEAVE;
        } else if (spec->has_default && spec->default_sv) {
            if (SvROK(spec->default_sv)) {
                SV *inner = SvRV(spec->default_sv);
                if (SvTYPE(inner) == SVt_PVAV) built_val = newRV_noinc((SV*)newAV());
                /*
                 # uncoverable branch false
                 # uncoverable condition right count:1 */
                else if (SvTYPE(inner) == SVt_PVHV) built_val = newRV_noinc((SV*)newHV());
                else built_val = newSVsv(spec->default_sv); /* # uncoverable statement */
            } else {
                built_val = newSVsv(spec->default_sv);
            }
        }
        if (built_val) {
            av_store(av, idx, built_val);
            SETs(built_val);
            RETURN;
        }
    }

    SETs(&PL_sv_undef);
    RETURN;
}

static OP* pp_object_func_set(pTHX) {
    dSP;
    SV *val = POPs;  /* Pop value first */
    SV *obj = TOPs;  /* Object left on stack */
    FuncAccessorData *data = get_func_accessor_data(PL_op->op_targ);
    IV idx = data->slot_idx;
    SV *rv;
    AV *av;

    if (!SvROK(obj)) croak("Not an object");
    rv = SvRV(obj);
    if (SvTYPE(rv) != SVt_PVAV) croak("Not an object");
    av = (AV*)rv;

    /* Validate object is of expected class (stash pointer comparison) */
    /*
     # uncoverable branch true
     # uncoverable condition left count:1
     # uncoverable condition left count:2
     # uncoverable condition right count:2 */
    if (data->expected_class && SvSTASH(rv) != data->expected_class->stash) {
        croak("Expected object of class '%s', got '%s'", /* # uncoverable statement */
              data->expected_class->class_name, /* # uncoverable statement */
              HvNAME(SvSTASH(rv))); /* # uncoverable statement */
    }

    /* In-place update if slot already has an SV (avoids alloc/dealloc) */
    if (idx <= AvFILLp(av)) {
        SV *slot = AvARRAY(av)[idx];
        if (slot_is_writable(slot)) {
            sv_setsv(slot, val);
            SETs(val);
            RETURN;
        }
    }

    av_store(av, idx, newSVsv(val));
    SETs(val);  /* Replace object with value */
    RETURN;
}

/* Custom ops from other modules that are safe to use as an accessor operand:
 * side-effect free, and leaving exactly one value on the stack. Matched by the
 * name the op was registered under, so neither dist needs to know how to build
 * against the other. Seeded with Confold's `<:`, whose whole purpose is to mark
 * a value as constant. */
#define OBJECT_MAX_SIMPLE_CUSTOM 8
static const char *g_simple_custom_ops[OBJECT_MAX_SIMPLE_CUSTOM] = { "confold" };
static int g_simple_custom_op_count = 1;

OBJECT_INLINE bool is_simple_custom_op(pTHX_ OP *op) {
    const char *name;
    int i;

    name = XopENTRYCUSTOM(op, xop_name);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!name) return false;

    for (i = 0; i < g_simple_custom_op_count; i++) {
        /*
         # uncoverable branch true class:ignore_covered_err
         # uncoverable condition left count:1 class:ignore_covered_err */
        if (strEQ(name, g_simple_custom_ops[i])) return true;
    }
    return false;
}

/* Check if an op is "simple" (can be safely used in optimized accessor) */
OBJECT_INLINE bool is_simple_op(pTHX_ OP *op) {
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!op) return false;
    /* Simple ops: pad variables, constants, global variables */
    switch (op->op_type) {
        case OP_CUSTOM:
            return is_simple_custom_op(aTHX_ op);
        case OP_PADSV:    /* $lexical */
        case OP_CONST:    /* literal value */
        case OP_GV:       /* *glob */
        case OP_GVSV:     /* $global */
        case OP_AELEMFAST:/* $array[const] */
#if defined(OP_AELEMFAST_LEX) && OP_AELEMFAST_LEX != OP_AELEMFAST
        case OP_AELEMFAST_LEX:
#endif
        case OP_NULL:     /* Often wraps simple ops */
            return true;
        default:
            return false;
    }
}

/* Call checker for function-style accessor: name($obj) or name($obj, $val) */
static OP* func_accessor_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    IV registry_id = SvIV(ckobj);
    FuncAccessorData *data = get_func_accessor_data(registry_id);
    OP *pushop, *cvop, *objop, *argop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!data) {
        return entersubop;  /* Fallback if data not found */ /* # uncoverable statement */
    }

    /* A private attribute keeps the XSUB, which checks the caller, rather
     * than becoming a custom op that would not. The spec is looked up in the
     * class, which a redefinition keeps current. */
    if (data->meta->slots[data->slot_idx]->is_private) return entersubop;

    pushop = cUNOPx(entersubop)->op_first;
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    /* Walk the op tree like the method-style accessor checker */
    objop = OpSIBLING(pushop);
    cvop = objop;
    argop = objop;
    while (OpHAS_SIBLING(cvop)) {
        argop = cvop;
        cvop = OpSIBLING(cvop);
    }

    /* Check if there's an argument after obj (setter call) */
    if (argop != objop) {
        /* Setter: name($obj, $val) - optimize to custom binop */
        OP *valop = OpSIBLING(objop);

        /* Only optimize if exactly 2 args and both are simple ops */
        if (valop && OpSIBLING(valop) == cvop && /* # uncoverable condition right count:1 */
            is_simple_op(aTHX_ objop) && is_simple_op(aTHX_ valop)) {
            OpMORESIB_set(pushop, cvop);
            OpLASTSIB_set(valop, NULL);
            OpLASTSIB_set(objop, NULL);

            /* Use OP_NULL first, then set op_type to OP_CUSTOM.
             * This avoids assertion failures in newBINOP on older
             * debugging Perls (5.14-5.20) which check op class masks. */
            newop = newBINOP(OP_NULL, 0, objop, valop);
            newop->op_type = OP_CUSTOM;
            newop->op_ppaddr = pp_object_func_set;
            newop->op_targ = data->registry_id;

            op_free(entersubop);
            return newop;
        }

        /* Complex args - fall back to XS */
        return op_contextualize(entersubop, G_SCALAR);
    }

    /* Getter: name($obj) - optimize only if objop is simple */
    if (!is_simple_op(aTHX_ objop)) {
        return entersubop;
    }

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(objop, NULL);

    /* Use OP_NULL first, then set op_type to OP_CUSTOM.
     * This avoids assertion failures in newUNOP on older
     * debugging Perls (5.14-5.20) which check op class masks. */
    newop = newUNOP(OP_NULL, 0, objop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = pp_object_func_get;
    newop->op_targ = data->registry_id;

    op_free(entersubop);
    return newop;
}

/* XS fallback for function-style accessor */
XS_INTERNAL(xs_func_accessor_fallback) {
    dXSARGS;
    FuncAccessorData *data = INT2PTR(FuncAccessorData*, CvXSUBANY(cv).any_iv);
    IV idx = data->slot_idx;
    SV *obj = ST(0);
    AV *av;

    check_private(aTHX_ data->meta->slots[idx], data->meta);

    if (!SvROK(obj) || SvTYPE(SvRV(obj)) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)SvRV(obj);

    /* Validate object is of expected class */
    /*
     # uncoverable branch true
     # uncoverable condition left count:1
     # uncoverable condition left count:2
     # uncoverable condition right count:2 */
    if (data->expected_class && SvSTASH(SvRV(obj)) != data->expected_class->stash) {
        croak("Expected object of class '%s', got '%s'", /* # uncoverable statement */
              data->expected_class->class_name, /* # uncoverable statement */
              HvNAME(SvSTASH(SvRV(obj)))); /* # uncoverable statement */
    }

    if (items > 1) {
        /* In-place update if slot already has an SV */
        if (idx <= AvFILLp(av)) {
            SV *slot = AvARRAY(av)[idx];
            if (slot_is_writable(slot)) {
                sv_setsv(slot, ST(1));
                ST(0) = ST(1);
                XSRETURN(1);
            }
        }
        av_store(av, idx, newSVsv(ST(1)));
        ST(0) = ST(1);
    } else {
        /* Direct array access */
        SV *sv = NULL;
        if (idx <= AvFILLp(av)) {
            sv = AvARRAY(av)[idx];
        }
        if ((!sv || !SvOK(sv)) && data->spec && data->spec->is_lazy) { /* # uncoverable condition right count:3 */
            /* Lazy initialization */
            SlotSpec *spec = data->spec;
            SV *built_val = NULL;
            if (spec->has_builder && spec->builder_name) { /* # uncoverable condition right count:2 */
                dSP;
                const char *builder = SvPV_nolen(spec->builder_name);
                int count;
                ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(ST(0));
                PUTBACK;
                count = call_method(builder, G_SCALAR);
                SPAGAIN;
                /*
                 # uncoverable branch false
                 # uncoverable condition right count:1 */
                if (count > 0) built_val = newSVsv(POPs);
                else built_val = newSV(0); /* # uncoverable statement */
                PUTBACK; FREETMPS; LEAVE;
            } else if (spec->has_default && spec->default_sv) {
                if (SvROK(spec->default_sv)) {
                    SV *inner = SvRV(spec->default_sv);
                    if (SvTYPE(inner) == SVt_PVAV) built_val = newRV_noinc((SV*)newAV());
                    /*
                     # uncoverable branch false
                     # uncoverable condition right count:1 */
                    else if (SvTYPE(inner) == SVt_PVHV) built_val = newRV_noinc((SV*)newHV());
                    else built_val = newSVsv(spec->default_sv); /* # uncoverable statement */
                } else {
                    built_val = newSVsv(spec->default_sv);
                }
            }
            if (built_val) {
                av_store(av, idx, built_val);
                ST(0) = built_val;
            } else {
                ST(0) = &PL_sv_undef;
            }
        } else {
            ST(0) = (sv && SvOK(sv)) ? sv : &PL_sv_undef;
        }
    }
    XSRETURN(1);
}

/* Install function-style accessor in caller's namespace */
static void install_func_accessor(pTHX_ const char *pkg, const char *prop_name, IV idx, ClassMeta *expected_class, int force, SlotSpec *spec, ClassMeta *meta) {
    char full_name[256];
    CV *cv;
    SV *ckobj;
    FuncAccessorData *data;
    IV registry_id;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, prop_name);

    /* Check if this accessor already exists */
    cv = get_cvn_flags(full_name, strlen(full_name), 0);
    if (cv) {
        /*
         # uncoverable branch true
         # uncoverable condition left count:1 */
        if (!force) {
            return;  /* Not forced: skip to preserve user-defined subs */ /* # uncoverable statement */
        }
        /* Forced (import_accessors/import_accessor): delete existing
         * to avoid "Subroutine redefined" warning from newXS. */
        {
            HV *stash = gv_stashpvn(pkg, strlen(pkg), 0);
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            if (stash) {
                (void)hv_delete(stash, prop_name, strlen(prop_name), G_DISCARD);
            }
        }
    }

    /* Allocate data for this accessor and register it */
    Newx(data, 1, FuncAccessorData);
    data->slot_idx = idx;
    data->expected_class = expected_class;  /* NULL for same-class, set for cross-class */
    data->spec = spec;                      /* NULL if no spec, used for lazy support */
    data->meta = meta;
    registry_id = register_func_accessor_data(aTHX_ data);

    cv = newXS(full_name, xs_func_accessor_fallback, __FILE__);
    CvXSUBANY(cv).any_iv = PTR2IV(data);  /* XS fallback still uses pointer directly */

    ckobj = newSViv(registry_id);
    cv_set_call_checker(cv, func_accessor_call_checker, ckobj);
}

/* Object::Proto::import_accessors("Class", "targetpkg") - import fast accessors */
XS_INTERNAL(xs_import_accessors) {
    dXSARGS;
    STRLEN class_len, pkg_len, prefix_len;
    const char *class_pv, *pkg_pv, *prefix_pv;
    ClassMeta *meta;
    IV i;

    if (items < 1) croak("Usage: Object::Proto::import_accessors($class [, $prefix [, $package]])");

    class_pv = SvPV(ST(0), class_len);

    /* Optional prefix (alias prepended to accessor names) */
    prefix_pv = NULL;
    prefix_len = 0;
    if (items > 1 && SvOK(ST(1))) {
        prefix_pv = SvPV(ST(1), prefix_len);
        if (prefix_len == 0) prefix_pv = NULL;
    }

    if (items > 2 && SvOK(ST(2))) {
        pkg_pv = SvPV(ST(2), pkg_len);
    } else {
        /* Default to caller's package, an undef package too */
        pkg_pv = CopSTASHPV(PL_curcop);
        pkg_len = strlen(pkg_pv);
    }

    meta = get_class_meta(aTHX_ class_pv, class_len);
    if (!meta) {
        croak("Class '%s' not defined with Object::Proto::define", class_pv);
    }

    /* Install function-style accessors for each property */
    for (i = 1; i < meta->slot_count; i++) {
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 */
        if (meta->idx_to_prop[i]) {
            const char *install_name;
            char prefixed_name[256];
            if (prefix_pv) {
                snprintf(prefixed_name, sizeof(prefixed_name), "%s%s",
                         prefix_pv, meta->idx_to_prop[i]);
                install_name = prefixed_name;
            } else {
                install_name = meta->idx_to_prop[i];
            }
            /* Pass NULL for same-class (skip validation), meta for cross-class */
            install_func_accessor(aTHX_ pkg_pv, install_name, i,
                                  NULL, 1,
                                  /*
                                   # uncoverable condition right count:1
                                   # uncoverable condition right count:2 */
                                  (meta->slots && i < meta->slot_count) ? meta->slots[i] : NULL,
                                  meta);
        }
    }

    XSRETURN_EMPTY;
}

/* Object::Proto::import_accessor("Class", "prop", "alias") - import single accessor with alias */
XS_INTERNAL(xs_import_accessor) {
    dXSARGS;
    STRLEN class_len, prop_len, alias_len, pkg_len;
    const char *class_pv, *prop_pv, *alias_pv, *pkg_pv;
    ClassMeta *meta;
    SV **idx_svp;
    IV idx;

    if (items < 2) croak("Usage: Object::Proto::import_accessor($class, $prop [, $alias [, $package]])");

    class_pv = SvPV(ST(0), class_len);
    prop_pv = SvPV(ST(1), prop_len);

    /* Alias defaults to property name */
    if (items > 2 && SvOK(ST(2))) {
        alias_pv = SvPV(ST(2), alias_len);
    } else {
        alias_pv = prop_pv;
    }

    /* Package defaults to caller */
    if (items > 3) {
        pkg_pv = SvPV(ST(3), pkg_len);
    } else {
        pkg_pv = CopSTASHPV(PL_curcop);
        pkg_len = strlen(pkg_pv);
    }

    meta = get_class_meta(aTHX_ class_pv, class_len);
    if (!meta) {
        croak("Class '%s' not defined with Object::Proto::define", class_pv);
    }

    /* Look up property index */
    idx_svp = hv_fetch(meta->prop_to_idx, prop_pv, prop_len, 0);
    if (!idx_svp) {
        croak("Property '%s' not defined in class '%s'", prop_pv, class_pv);
    }
    idx = SvIV(*idx_svp);

    /* Install with alias name — no class check, work with any compatible object */
    install_func_accessor(aTHX_ pkg_pv, alias_pv, idx,
                          NULL, 1,
                          /*
                           # uncoverable condition right count:1
                           # uncoverable condition right count:2 */
                          (meta->slots && idx < meta->slot_count) ? meta->slots[idx] : NULL,
                          meta);

    XSRETURN_EMPTY;
}

/* Object::Proto::import() - export 'object' to caller's namespace */
XS_INTERNAL(xs_import) {
    dXSARGS;
    const char *caller_pkg;
    SV *full_name;
    CV *define_cv, *before_cv, *after_cv, *around_cv;
    GV *gv;

    PERL_UNUSED_VAR(items);

    /* Get caller's package */
    caller_pkg = CopSTASHPV(PL_curcop);

    /* Get Object::Proto::define */
    define_cv = get_cv("Object::Proto::define", 0);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!define_cv) croak("Object::Proto::define not found");

    /* Create fully qualified name: caller::object */
    full_name = newSVpvf("%s::object", caller_pkg);

    /* Export: create alias in caller's namespace */
    gv = gv_fetchsv(full_name, GV_ADD, SVt_PVCV);
    if (GvCV(gv) == NULL) {
        GvCV_set(gv, (CV*)SvREFCNT_inc((SV*)define_cv));
        GvIMPORTED_CV_on(gv);
    }
    GvMULTI_on(gv);
    SvREFCNT_dec(full_name);

    /* Export before/after/around modifiers */
    before_cv = get_cv("Object::Proto::before", 0);
    after_cv = get_cv("Object::Proto::after", 0);
    around_cv = get_cv("Object::Proto::around", 0);

    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (before_cv) {
        full_name = newSVpvf("%s::before", caller_pkg);
        gv = gv_fetchsv(full_name, GV_ADD, SVt_PVCV);
        if (GvCV(gv) == NULL) {
            GvCV_set(gv, (CV*)SvREFCNT_inc((SV*)before_cv));
            GvIMPORTED_CV_on(gv);
        }
        GvMULTI_on(gv);
        SvREFCNT_dec(full_name);
    }

    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (after_cv) {
        full_name = newSVpvf("%s::after", caller_pkg);
        gv = gv_fetchsv(full_name, GV_ADD, SVt_PVCV);
        if (GvCV(gv) == NULL) {
            GvCV_set(gv, (CV*)SvREFCNT_inc((SV*)after_cv));
            GvIMPORTED_CV_on(gv);
        }
        GvMULTI_on(gv);
        SvREFCNT_dec(full_name);
    }

    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (around_cv) {
        full_name = newSVpvf("%s::around", caller_pkg);
        gv = gv_fetchsv(full_name, GV_ADD, SVt_PVCV);
        if (GvCV(gv) == NULL) {
            GvCV_set(gv, (CV*)SvREFCNT_inc((SV*)around_cv));
            GvIMPORTED_CV_on(gv);
        }
        GvMULTI_on(gv);
        SvREFCNT_dec(full_name);
    }

    /* Export role/requires/with */
    {
        static const char *names[] = { "role", "requires", "with" };
        int i;
        for (i = 0; i < 3; i++) {
            CV *cv = get_cvn_flags(
                Perl_form(aTHX_ "Object::Proto::%s", names[i]),
                strlen("Object::Proto::") + strlen(names[i]), 0);
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            if (cv) {
                full_name = newSVpvf("%s::%s", caller_pkg, names[i]);
                gv = gv_fetchsv(full_name, GV_ADD, SVt_PVCV);
                if (GvCV(gv) == NULL) {
                    GvCV_set(gv, (CV*)SvREFCNT_inc((SV*)cv));
                    GvIMPORTED_CV_on(gv);
                }
                GvMULTI_on(gv);
                SvREFCNT_dec(full_name);
            }
        }
    }

    XSRETURN_EMPTY;
}

/* ============================================
   Install accessor into class
   ============================================ */

static void install_accessor(pTHX_ const char *class_name, const char *prop_name, IV idx) {
    char full_name[256];
    CV *cv;
    SV *ckobj;

    snprintf(full_name, sizeof(full_name), "%s::%s", class_name, prop_name);

    /* Check if accessor already exists to avoid redefinition warnings */
    cv = get_cvn_flags(full_name, strlen(full_name), 0);
    if (cv) {
        return;  /* Already defined, skip */
    }

    cv = newXS(full_name, xs_accessor_fallback, __FILE__);
    CvXSUBANY(cv).any_iv = idx;

    ckobj = newSViv(idx);
    cv_set_call_checker(cv, accessor_call_checker, ckobj);
}

/* Enforce a :private attribute. Every method Object::Proto generates for the
 * attribute - accessor, reader, writer, clearer, predicate and function-style
 * accessor - may only be called from code compiled in the package that
 * declared it: the class for its own attributes, the parent that declared an
 * inherited one, and for a role's attribute the role or the class that
 * composed it. In an XSUB PL_curcop is the caller's cop, so its stash names
 * the calling package. meta is the class the method was installed in, named
 * in the error. Reached through check_private, only for a private attribute.
 * Packages are compared by name, not stash pointer: a thread has its own copy
 * of each stash. */
static void object_check_private(pTHX_ SlotSpec *spec, ClassMeta *meta) {
    HV *stash;
    const char *name;
    const char *caller;
    stash  = PL_curcop ? CopSTASH(PL_curcop) : NULL; /* # uncoverable condition right count:1 */
    /*
     # uncoverable condition right count:1
     # uncoverable condition left count:2 */
    name   = stash ? HvNAME(stash) : NULL;
    caller = name ? name : ""; /* # uncoverable condition right count:1 */
    if (strEQ(caller, spec->private_owner)) return;
    if (spec->private_also && strEQ(caller, spec->private_also)) return;
    croak("cannot call private attribute %s on %s from %s",
          spec->name, meta->class_name, caller);
}

/* Build a lazy slot on first access: the builder's value, or a fresh copy
 * of the default (a new empty array or hash for [] and {}). A defined value
 * is type checked, then stored in the slot. Returns what was stored, or NULL
 * when the slot has neither a builder nor a default. */
static SV *slot_build_lazy(pTHX_ SV *self, AV *av, IV idx, SlotSpec *spec) {
    SV *built_val = NULL;

    if (spec->has_builder && spec->builder_name) { /* # uncoverable condition right count:2 */
        /* Call builder method */
        dSP;
        const char *builder = SvPV_nolen(spec->builder_name);
        int count;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;

        count = call_method(builder, G_SCALAR);

        SPAGAIN;
        /*
         # uncoverable branch false
         # uncoverable condition right count:1 */
        if (count > 0) {
            /* Copy the value BEFORE FREETMPS to avoid freed scalar issue */
            built_val = newSVsv(POPs);
        } else {
            built_val = newSV(0);  /* undef */ /* # uncoverable statement */
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    } else if (spec->has_default && spec->default_sv) {
        /* Use default value for lazy default */
        if (SvROK(spec->default_sv)) {
            /* Clone reference types (arrays, hashes) */
            SV *inner = SvRV(spec->default_sv);
            if (SvTYPE(inner) == SVt_PVAV) {
                built_val = newRV_noinc((SV*)newAV());
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            } else if (SvTYPE(inner) == SVt_PVHV) {
                built_val = newRV_noinc((SV*)newHV());
            } else {
                built_val = newSVsv(spec->default_sv); /* # uncoverable statement */
            }
        } else {
            built_val = newSVsv(spec->default_sv);
        }
    }

    if (!built_val) return NULL;

    /* Type check the built value */
    if (spec->has_type && SvOK(built_val)) {
        if (!check_slot_type(aTHX_ built_val, spec)) {
            const char *type_name = (spec->type_id == TYPE_CUSTOM && spec->registered)
                ? spec->registered->name
                : type_id_to_name(spec->type_id);
            SvREFCNT_dec(built_val);
            croak("Type constraint failed for lazy '%s': expected %s",
                  spec->name, type_name);
        }
    }

    /* Store the built value - built_val already has correct refcount from newSVsv */
    av_store(av, idx, built_val);
    return built_val;
}

XS_INTERNAL(xs_accessor_typed_fallback) {
    dXSARGS;
    SlotOpData *data = INT2PTR(SlotOpData*, CvXSUBANY(cv).any_iv);
    IV idx = data->slot_idx;
    ClassMeta *meta = data->meta;
    SlotSpec *spec = meta->slots[idx];
    SV *self = ST(0);
    AV *av;

    check_private(aTHX_ spec, meta);

    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)SvRV(self);

    if (items > 1) {
        /* Setter with type check */
        SV *val = ST(1);
        MAGIC *mg = get_object_magic(aTHX_ self);
        if (mg && (mg->mg_private & OBJ_FLAG_FROZEN)) {
            croak("Cannot modify frozen object");
        }
        
        if (spec->is_readonly) {
            croak("Cannot modify readonly slot '%s'", spec->name);
        }
        
        /* Required fields cannot be set to undef */
        if (spec->is_required && !SvOK(val)) {
            croak("Cannot set required slot '%s' to undef", spec->name);
        }
        
        /* Coercion */
        if (spec->has_coerce || spec->type_id == TYPE_CUSTOM)
            val = apply_slot_coercion(aTHX_ val, spec);

        /* Type check */
        if (spec->has_type) {
            if (!check_slot_type(aTHX_ val, spec)) {
                const char *type_name = (spec->type_id == TYPE_CUSTOM && spec->registered)
                    ? spec->registered->name
                    : type_id_to_name(spec->type_id);
                croak("Type constraint failed for '%s': expected %s",
                      spec->name, type_name);
            }
        }

        /* Trigger callback ($self, $new_value) */
        if (spec->has_trigger && spec->trigger_cb) {
            dSP;
            PUSHMARK(SP);
            XPUSHs(self);
            XPUSHs(val);
            PUTBACK;
            call_method(SvPV_nolen(spec->trigger_cb), G_DISCARD);
        }
        
        {
            SV *stored = newSVsv(val);
            av_store(av, idx, stored);
            /* Weaken reference if is_weak flag is set */
            if (spec->is_weak && SvROK(stored)) {
                sv_rvweaken(stored);
            }
        }
        ST(0) = val;
        XSRETURN(1);
    } else {
        /* Getter - use prototype chain resolution, handle lazy */
        SV *result = resolve_property_chain(aTHX_ av, idx);
        
        /* Lazy initialization: if undef and is_lazy, build/default on first access */
        if (spec->is_lazy && !SvOK(result)) {
            SV *built_val = slot_build_lazy(aTHX_ self, av, idx, spec);
            if (built_val) result = built_val;
        }
        
        ST(0) = result;
        XSRETURN(1);
    }
}

/* Call checker for typed accessor */
static OP* accessor_typed_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    SlotOpData *data = INT2PTR(SlotOpData*, SvIV(ckobj));
    IV idx = data->slot_idx;
    OP *pushop, *cvop, *selfop, *argop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    /* Private slots keep the XSUB (which enforces the caller check) rather than
     * being inlined to a custom op that would bypass it. */
    if (data->meta->slots[idx]->is_private) return entersubop;

    pushop = cUNOPx(entersubop)->op_first;
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    selfop = OpSIBLING(pushop);
    cvop = selfop;
    argop = selfop;
    while (OpHAS_SIBLING(cvop)) {
        argop = cvop;
        cvop = OpSIBLING(cvop);
    }

    /* Check if there's an argument after self (setter call) */
    if (argop != selfop) {
        /* Setter: $obj->name($value) - use typed setter */
        OP *valop = OpSIBLING(selfop);
        SlotSpec *spec = data->meta->slots[idx];

        /* When the value is already known at compile time, the type check can
         * be settled here instead of on every call. That is only equivalent if
         * a type check is the sole thing the typed setter would have done:
         * pp_object_set handles the frozen check and the store, but not
         * readonly, required, coercion, triggers or weak refs. A value that
         * fails falls through to the runtime path, so a type error is still
         * reported where it always was. */
        if (valop->op_type == OP_CONST
            && spec->has_type
            && !spec->has_checks
            && !spec->has_trigger
            && !spec->is_weak
            && check_slot_type(aTHX_ cSVOPx_sv(valop), spec))
        {
            OpMORESIB_set(pushop, cvop);
            OpLASTSIB_set(valop, NULL);
            OpLASTSIB_set(selfop, NULL);

            newop = newBINOP(OP_NULL, 0, selfop, valop);
            newop->op_type = OP_CUSTOM;
            newop->op_ppaddr = pp_object_set;
            newop->op_targ = idx;

            op_free(entersubop);
            return newop;
        }

        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(valop, NULL);
        OpLASTSIB_set(selfop, NULL);
        
        /* Use OP_NULL to avoid assertion failures on debugging Perls
         * (5.14-5.20), then set OP_CUSTOM */
        newop = newBINOP(OP_NULL, 0, selfop, valop);
        newop->op_type = OP_CUSTOM;
        newop->op_ppaddr = pp_object_set_typed;
        newop->op_targ = PTR2IV(data);
        
        op_free(entersubop);
        return newop;
    } else {
        /* Getter: $obj->name - plain getter (no type check needed) */
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(selfop, NULL);
        
        /* Use OP_NULL to avoid assertion failures on debugging Perls
         * (5.14-5.20), then set OP_CUSTOM */
        newop = newUNOP(OP_NULL, 0, selfop);
        newop->op_type = OP_CUSTOM;
        newop->op_ppaddr = pp_object_get;
        newop->op_targ = idx;
        
        op_free(entersubop);
        return newop;
    }
}

/* XS fallback for reader-only accessor (get_X style) */
XS_INTERNAL(xs_reader_fallback) {
    dXSARGS;
    SlotOpData *data = INT2PTR(SlotOpData*, CvXSUBANY(cv).any_iv);
    IV idx = data->slot_idx;
    ClassMeta *meta = data->meta;
    SlotSpec *spec = meta->slots[idx];
    SV *self = ST(0);
    AV *av;

    PERL_UNUSED_ARG(items);

    check_private(aTHX_ spec, meta);

    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)SvRV(self);

    /* Handle lazy builder */
    /*
     # uncoverable condition right count:1
     # uncoverable condition right count:4 */
    if (spec && spec->is_lazy && spec->has_builder && spec->builder_name) {
        if (idx <= AvFILLp(av)) {
            SV *slot = AvARRAY(av)[idx];
            if (!slot || !SvOK(slot)) {
                /* Call builder method */
                dSP;
                IV count;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(self);
                PUTBACK;
                count = call_method(SvPV_nolen(spec->builder_name), G_SCALAR);
                SPAGAIN;
                /*
                 # uncoverable branch false
                 # uncoverable condition right count:1 */
                if (count > 0) {
                    SV *built_val = POPs;
                    
                    /* Type check the built value */
                    if (spec->has_type) {
                        if (spec->has_coerce || spec->type_id == TYPE_CUSTOM)
                            built_val = apply_slot_coercion(aTHX_ built_val, spec);
                        if (!check_slot_type(aTHX_ built_val, spec)) {
                            const char *type_name = (spec->type_id == TYPE_CUSTOM && spec->registered) 
                                ? spec->registered->name 
                                : type_id_to_name(spec->type_id);
                            croak("Type constraint failed for '%s' in builder: expected %s",
                                  spec->name, type_name);
                        }
                    }
                    
                    if (slot_is_writable(slot)) {
                        sv_setsv(slot, built_val);
                    }
                    else {
                        av_store(av, idx, newSVsv(built_val));
                    }
                }
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        }
    }

    /* Getter - fast path: direct slot access */
    if (idx <= AvFILLp(av)) {
        SV *sv = AvARRAY(av)[idx];
        if (sv && SvOK(sv)) {
            ST(0) = sv;
            XSRETURN(1);
        }
    }
    /* Slow path: check prototype chain */
    {
        SV **proto = av_fetch(av, 0, 0);
        if (proto && SvROK(*proto) && SvTYPE(SvRV(*proto)) == SVt_PVAV) {
            SV *result = resolve_property_chain(aTHX_ av, idx);
            ST(0) = result;
            XSRETURN(1);
        }
    }
    ST(0) = &PL_sv_undef;
    XSRETURN(1);
}

/* XS fallback for writer-only accessor (set_X style) */
XS_INTERNAL(xs_writer_fallback) {
    dXSARGS;
    SlotOpData *data = INT2PTR(SlotOpData*, CvXSUBANY(cv).any_iv);
    IV idx = data->slot_idx;
    ClassMeta *meta = data->meta;
    SlotSpec *spec = meta->slots[idx];
    SV *self = ST(0);
    AV *av;
    MAGIC *mg;

    check_private(aTHX_ spec, meta);

    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)SvRV(self);

    if (items < 2) {
        croak("Writer method requires a value argument");
    }

    /* Check frozen */
    mg = get_object_magic(aTHX_ self);
    if (mg && (mg->mg_private & OBJ_FLAG_FROZEN)) {
        croak("Cannot modify frozen object");
    }

    /* Check readonly */
    if (spec && spec->is_readonly) { /* # uncoverable condition right count:1 */
        croak("Cannot modify readonly slot '%s'", spec->name);
    }

    {
        SV *val = ST(1);
        
        /* Required fields cannot be set to undef */
        if (spec && spec->is_required && !SvOK(val)) { /* # uncoverable condition right count:1 */
            croak("Cannot set required slot '%s' to undef", spec->name);
        }
        
        /* Coerce + type check */
        if (spec && spec->has_type) { /* # uncoverable condition right count:1 */
            if (spec->has_coerce || spec->type_id == TYPE_CUSTOM)
                val = apply_slot_coercion(aTHX_ val, spec);
            if (!check_slot_type(aTHX_ val, spec)) {
                const char *type_name = (spec->type_id == TYPE_CUSTOM && spec->registered) 
                    ? spec->registered->name 
                    : type_id_to_name(spec->type_id);
                croak("Type constraint failed for '%s': expected %s",
                      spec->name, type_name);
            }
        }
        
        /* Trigger callback ($self, $new_value) */
        if (spec && spec->has_trigger && spec->trigger_cb) { /* # uncoverable condition right count:1 */
            dSP;
            PUSHMARK(SP);
            XPUSHs(self);
            XPUSHs(val);
            PUTBACK;
            call_method(SvPV_nolen(spec->trigger_cb), G_DISCARD);
        }
        
        /* In-place update */
        if (idx <= AvFILLp(av)) {
            SV *slot = AvARRAY(av)[idx];
            if (slot_is_writable(slot)) {
                sv_setsv(slot, val);
                /* Weaken reference if is_weak flag is set */
                if (spec && spec->is_weak && SvROK(slot)) { /* # uncoverable condition right count:1 */
                    sv_rvweaken(slot);
                }
                ST(0) = val;
                XSRETURN(1);
            }
        }
        {
            SV *stored = newSVsv(val);
            av_store(av, idx, stored);
            /* Weaken reference if is_weak flag is set */
            if (spec && spec->is_weak && SvROK(stored)) { /* # uncoverable condition right count:1 */
                sv_rvweaken(stored);
            }
        }
        ST(0) = val;
        XSRETURN(1);
    }
}

/* Install reader-only accessor (get_X style) */
static void install_reader(pTHX_ const char *class_name, const char *method_name, IV idx, ClassMeta *meta) {
    char full_name[256];
    CV *cv;
    SlotOpData *data;

    snprintf(full_name, sizeof(full_name), "%s::%s", class_name, method_name);

    /* Check if method already exists */
    cv = get_cvn_flags(full_name, strlen(full_name), 0);
    if (cv) {
        return;
    }

    Newx(data, 1, SlotOpData);
    data->slot_idx = idx;
    data->meta = meta;

    cv = newXS(full_name, xs_reader_fallback, __FILE__);
    CvXSUBANY(cv).any_iv = PTR2IV(data);
}

/* Install writer-only accessor (set_X style) */
static void install_writer(pTHX_ const char *class_name, const char *method_name, IV idx, ClassMeta *meta) {
    char full_name[256];
    CV *cv;
    SlotOpData *data;

    snprintf(full_name, sizeof(full_name), "%s::%s", class_name, method_name);

    /* Check if method already exists */
    cv = get_cvn_flags(full_name, strlen(full_name), 0);
    if (cv) {
        return;
    }

    Newx(data, 1, SlotOpData);
    data->slot_idx = idx;
    data->meta = meta;

    cv = newXS(full_name, xs_writer_fallback, __FILE__);
    CvXSUBANY(cv).any_iv = PTR2IV(data);
}

/* Install typed accessor (with type check, triggers, etc.) */
static void install_accessor_typed(pTHX_ const char *class_name, const char *prop_name, IV idx, ClassMeta *meta) {
    char full_name[256];
    CV *cv;
    SV *ckobj;
    SlotOpData *data;

    snprintf(full_name, sizeof(full_name), "%s::%s", class_name, prop_name);

    /* An accessor may already be there: a typed one from an earlier
     * definition keeps its CV and takes the new slot data, a plain one
     * (the attribute had no type until this +attr or redefinition) is
     * replaced, and a sub of the user's own is left alone. */
    cv = get_cvn_flags(full_name, strlen(full_name), 0);
    if (cv) {
        if (CvISXSUB(cv) && CvXSUB(cv) == xs_accessor_typed_fallback) {
            data = INT2PTR(SlotOpData*, CvXSUBANY(cv).any_iv);
            data->slot_idx = idx;
            data->meta = meta;
            return;
        }
        if (!CvISXSUB(cv) || CvXSUB(cv) != xs_accessor_fallback) {
            return;
        }
        {
            HV *stash = gv_stashpv(class_name, 0);
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            if (stash) {
                (void)hv_delete(stash, prop_name, strlen(prop_name), G_DISCARD);
            }
        }
    }

    /* Allocate persistent data for this slot */
    Newx(data, 1, SlotOpData);
    data->slot_idx = idx;
    data->meta = meta;

    cv = newXS(full_name, xs_accessor_typed_fallback, __FILE__);
    CvXSUBANY(cv).any_iv = PTR2IV(data);

    ckobj = newSViv(PTR2IV(data));
    cv_set_call_checker(cv, accessor_typed_call_checker, ckobj);
}

/* XS fallback for clearer method (clear_X) */
XS_INTERNAL(xs_clearer_fallback) {
    dXSARGS;
    SlotOpData *data = INT2PTR(SlotOpData*, CvXSUBANY(cv).any_iv);
    IV idx = data->slot_idx;
    SV *self = ST(0);
    AV *av;
    MAGIC *mg;

    PERL_UNUSED_ARG(items);

    check_private(aTHX_ data->meta->slots[idx], data->meta);

    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)SvRV(self);

    /* Check frozen */
    mg = get_object_magic(aTHX_ self);
    if (mg && (mg->mg_private & OBJ_FLAG_FROZEN)) {
        croak("Cannot modify frozen object");
    }

    /* Clear the slot by setting to undef */
    av_store(av, idx, newSV(0));
    
    ST(0) = self;  /* Return self for chaining */
    XSRETURN(1);
}

/* Install clearer method (clear_X or custom name) */
static void install_clearer(pTHX_ const char *class_name, const char *prop_name, IV idx, ClassMeta *meta, SV *custom_name) {
    char full_name[256];
    CV *cv;
    SlotOpData *data;

    if (custom_name && SvOK(custom_name)) { /* # uncoverable condition right count:2 */
        snprintf(full_name, sizeof(full_name), "%s::%s", class_name, SvPV_nolen(custom_name));
    } else {
        snprintf(full_name, sizeof(full_name), "%s::clear_%s", class_name, prop_name);
    }

    /* Check if method already exists */
    cv = get_cvn_flags(full_name, strlen(full_name), 0);
    if (cv) {
        return;
    }

    Newx(data, 1, SlotOpData);
    data->slot_idx = idx;
    data->meta = meta;

    cv = newXS(full_name, xs_clearer_fallback, __FILE__);
    CvXSUBANY(cv).any_iv = PTR2IV(data);
}

/* XS fallback for predicate method (has_X) */
XS_INTERNAL(xs_predicate_fallback) {
    dXSARGS;
    SlotOpData *data = INT2PTR(SlotOpData*, CvXSUBANY(cv).any_iv);
    IV idx = data->slot_idx;
    SV *self = ST(0);
    AV *av;
    SV **svp;

    PERL_UNUSED_ARG(items);

    check_private(aTHX_ data->meta->slots[idx], data->meta);

    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)SvRV(self);

    /* Check if slot has a defined value */
    svp = av_fetch(av, idx, 0);
    if (svp && SvOK(*svp)) {
        ST(0) = &PL_sv_yes;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

/* Install predicate method (has_X or custom name) */
static void install_predicate(pTHX_ const char *class_name, const char *prop_name, IV idx, ClassMeta *meta, SV *custom_name) {
    char full_name[256];
    CV *cv;
    SlotOpData *data;

    if (custom_name && SvOK(custom_name)) { /* # uncoverable condition right count:2 */
        snprintf(full_name, sizeof(full_name), "%s::%s", class_name, SvPV_nolen(custom_name));
    } else {
        snprintf(full_name, sizeof(full_name), "%s::has_%s", class_name, prop_name);
    }

    /* Check if method already exists */
    cv = get_cvn_flags(full_name, strlen(full_name), 0);
    if (cv) {
        return;
    }

    Newx(data, 1, SlotOpData);
    data->slot_idx = idx;
    data->meta = meta;

    cv = newXS(full_name, xs_predicate_fallback, __FILE__);
    CvXSUBANY(cv).any_iv = PTR2IV(data);
}

/* ============================================
   DEMOLISH Support (zero overhead if not used)
   ============================================ */

/* XS DESTROY wrapper that calls DEMOLISH */
XS_INTERNAL(xs_destroy_wrapper) {
    dXSARGS;
    ClassMeta *meta = INT2PTR(ClassMeta*, CvXSUBANY(cv).any_iv);
    SV *self = ST(0);
    
    PERL_UNUSED_VAR(items);
    
    /*
     # uncoverable branch false
     # uncoverable condition right count:1
     # uncoverable condition right count:2 */
    if (meta && meta->demolish_cv) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        call_sv((SV*)meta->demolish_cv, G_DISCARD | G_EVAL);
        SPAGAIN;
        /* Ignore errors in DEMOLISH - don't die during destruction */
        if (SvTRUE(ERRSV)) { /* # uncoverable condition right count:1 */
            warn("Error in DEMOLISH: %s", SvPV_nolen(ERRSV));
        }
        FREETMPS;
        LEAVE;
    }
    
    XSRETURN_EMPTY;
}

/* Install DESTROY wrapper - only called if DEMOLISH exists */
static void install_destroy_wrapper(pTHX_ const char *class_name, ClassMeta *meta) {
    char full_name[256];
    CV *cv;
    
    snprintf(full_name, sizeof(full_name), "%s::DESTROY", class_name);
    
    /* Check if DESTROY already exists - don't override user's DESTROY */
    cv = get_cvn_flags(full_name, strlen(full_name), 0);
    if (cv) {
        return;  /* User has their own DESTROY, don't interfere */
    }
    
    cv = newXS(full_name, xs_destroy_wrapper, __FILE__);
    CvXSUBANY(cv).any_iv = PTR2IV(meta);
}

/* ============================================
   Slot registration - one path for a class's own slots, the slots it
   inherits and the slots a role gives it
   ============================================ */

/* Class-level fast-path flags for one slot */
static void note_slot_flags(ClassMeta *meta, const SlotSpec *spec) {
    if (spec->has_type)    meta->has_any_types = 1;
    /* An implicit default from handles is left out: new() reads its
     * arguments as named pairs when the class has any default */
    if (spec->has_default && !spec->default_implicit) meta->has_any_defaults = 1;
    if (spec->has_trigger) meta->has_any_triggers = 1;
    if (spec->is_required) meta->has_any_required = 1;
    if (spec->is_lazy)     meta->has_any_lazy = 1;
    if (spec->has_builder) meta->has_any_builders = 1;
    if (spec->is_weak)     meta->has_any_weak = 1;
}

/* Install every method the slot's spec asks for */
static void install_slot_methods(pTHX_ const char *class_pv, ClassMeta *meta, IV idx, SlotSpec *spec) {
    /* The typed accessor carries the checks, the :private one among them,
     * that the plain accessor leaves out */
    if (spec->has_type || spec->has_trigger || spec->has_coerce || spec->is_readonly
        || spec->is_lazy || spec->is_required || spec->is_weak || spec->is_private) {
        install_accessor_typed(aTHX_ class_pv, spec->name, idx, meta);
    } else {
        install_accessor(aTHX_ class_pv, spec->name, idx);
    }
    if (spec->has_clearer) {
        install_clearer(aTHX_ class_pv, spec->name, idx, meta, spec->clearer_name);
    }
    if (spec->has_predicate) {
        install_predicate(aTHX_ class_pv, spec->name, idx, meta, spec->predicate_name);
    }
    if (spec->reader_name) {
        install_reader(aTHX_ class_pv, SvPV_nolen(spec->reader_name), idx, meta);
    }
    if (spec->writer_name) {
        install_writer(aTHX_ class_pv, SvPV_nolen(spec->writer_name), idx, meta);
    }
    /* A slot's handles(...) delegators are installed by
     * install_class_delegators, in a pass after every slot of the class is
     * in, so that a delegator can never take a name an accessor still has to
     * claim. */
}

/* Put a slot into a class at idx: the property and constructor-argument
 * lookups, the fast-path flags and the slot's methods */
static void register_slot(pTHX_ const char *class_pv, ClassMeta *meta, IV idx, SlotSpec *spec) {
    meta->slots[idx] = spec;
    note_slot_flags(meta, spec);
    hv_store(meta->prop_to_idx, spec->name, strlen(spec->name), newSViv(idx), 0);
    /* The constructor takes the init_arg if there is one, else the property name */
    if (spec->init_arg) {
        STRLEN arg_len;
        const char *arg_name = SvPV(spec->init_arg, arg_len);
        hv_store(meta->arg_to_idx, arg_name, arg_len, newSViv(idx), 0);
    } else {
        hv_store(meta->arg_to_idx, spec->name, strlen(spec->name), newSViv(idx), 0);
    }
    meta->idx_to_prop[idx] = spec->name;
    install_slot_methods(aTHX_ class_pv, meta, idx, spec);
}

/* ============================================
   Role Support (zero overhead if not used)
   ============================================ */

static RoleMeta* get_role_meta(pTHX_ const char *role_name, STRLEN len) {
    SV **svp;
    if (!g_role_registry) return NULL;
    svp = hv_fetch(g_role_registry, role_name, len, 0);
    if (svp && SvIOK(*svp)) { /* # uncoverable condition right count:2 */
        return INT2PTR(RoleMeta*, SvIV(*svp));
    }
    return NULL;
}

static void register_role_meta(pTHX_ const char *role_name, STRLEN len, RoleMeta *meta) {
    if (!g_role_registry) {
        g_role_registry = newHV();
    }
    hv_store(g_role_registry, role_name, len, newSViv(PTR2IV(meta)), 0);
}

/* Copy a method from role stash to class stash */
static void copy_method(pTHX_ HV *from_stash, HV *to_stash, const char *method_name) {
    GV *from_gv;
    CV *cv;
    char full_name[512];
    GV *to_gv;
    
    from_gv = gv_fetchmeth(from_stash, method_name, strlen(method_name), 0);
    if (!from_gv || !(cv = GvCV(from_gv))) { /* # uncoverable condition left count:2 */
        return;  /* No such method in role */
    }
    
    /* Check if target already has this method */
    to_gv = gv_fetchmeth(to_stash, method_name, strlen(method_name), 0);
    if (to_gv && GvCV(to_gv)) { /* # uncoverable condition right count:2 */
        return;  /* Target already has method, don't override */
    }
    
    /* Install the CV in target stash */
    snprintf(full_name, sizeof(full_name), "%s::%s", HvNAME(to_stash), method_name);
    to_gv = gv_fetchpv(full_name, GV_ADD, SVt_PVCV);
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (to_gv) {
        /* Share the CV between role and class */
        GvCV_set(to_gv, (CV*)SvREFCNT_inc((SV*)cv));
        GvCVGEN(to_gv) = 0;  /* Clear cache */
    }
}

/* Apply a role to a class */
static void apply_role_to_class(pTHX_ ClassMeta *class_meta, RoleMeta *role_meta) {
    IV i;
    HE *entry;
    
    /* Check required methods */
    for (i = 0; i < role_meta->required_count; i++) {
        const char *required = role_meta->required_methods[i];
        GV *gv = gv_fetchmeth(class_meta->stash, required, strlen(required), 0);
        if (!gv || !GvCV(gv)) { /* # uncoverable condition left count:2 */
            croak("Class '%s' does not implement required method '%s' from role '%s'",
                  class_meta->class_name, required, role_meta->role_name);
        }
    }
    
    /* Copy role's slots to class */
    for (i = 0; i < role_meta->slot_count; i++) {
        SlotSpec *role_slot = role_meta->slots[i];
        SlotSpec *slot;
        IV new_idx;
        SV **existing;
        
        /* Check for slot name conflict */
        existing = hv_fetch(class_meta->prop_to_idx, role_slot->name, strlen(role_slot->name), 0);
        if (existing) {
            croak("Slot conflict: '%s' already exists in class '%s' (from role '%s')",
                  role_slot->name, class_meta->class_name, role_meta->role_name);
        }
        
        /* The class gets its own copy of the role's slot: it records the
         * class as the other package that may call a :private attribute,
         * and a +attr redefining the slot later frees this copy, not the
         * role's spec that other classes use too. Its handles are resolved
         * before the class grows, so that a croak leaves it as it was. */
        check_role_slot_against_delegators(aTHX_ class_meta, role_slot, role_meta);
        slot = clone_slot_spec(aTHX_ role_slot);
        slot->private_also = savepv(class_meta->class_name);
        resolve_handles(aTHX_ slot);

        /* Add slot to class */
        new_idx = class_meta->slot_count++;
        Renew(class_meta->slots, class_meta->slot_count, SlotSpec*);
        Renew(class_meta->idx_to_prop, class_meta->slot_count, char*);
        register_slot(aTHX_ class_meta->class_name, class_meta, new_idx, slot);
    }

    /* handles(...) of the role's slots, now that their methods are in */
    install_class_delegators(aTHX_ class_meta);
    
    /* Copy role's methods to class. xs_role made the role's stash with
     * GV_ADD, so it is always there. */
    hv_iterinit(role_meta->stash);
    while ((entry = hv_iternext(role_meta->stash))) {
        const char *name = HePV(entry, PL_na);
        /* Skip special entries and slots (already handled) */
        if (name[0] != '_' || strncmp(name, "_build_", 7) == 0) {
            copy_method(aTHX_ role_meta->stash, class_meta->stash, name);
        }
    }
    
    /* Track consumed role */
    Renew(class_meta->consumed_roles, class_meta->role_count + 1, RoleMeta*);
    class_meta->consumed_roles[class_meta->role_count++] = role_meta;
}

/* ============================================
   Method Modifiers (zero overhead if not used)
   ============================================ */

/* Get or create modified method entry */
static ModifiedMethod* get_or_create_modified_method(pTHX_ ClassMeta *meta, const char *method_name) {
    SV **svp;
    ModifiedMethod *mod;
    STRLEN name_len = strlen(method_name);
    
    if (!meta->modified_methods) {
        meta->modified_methods = newHV();
    }
    
    svp = hv_fetch(meta->modified_methods, method_name, name_len, 0);
    if (svp && SvIOK(*svp)) { /* # uncoverable condition right count:2 */
        return INT2PTR(ModifiedMethod*, SvIV(*svp));
    }
    
    /* Create new modified method entry */
    Newxz(mod, 1, ModifiedMethod);
    
    /* Get the original CV */
    {
        GV *gv = gv_fetchmeth(meta->stash, method_name, name_len, 0);
        if (gv && GvCV(gv)) { /* # uncoverable condition right count:2 */
            mod->original_cv = GvCV(gv);
            SvREFCNT_inc((SV*)mod->original_cv);
        }
    }
    
    hv_store(meta->modified_methods, method_name, name_len, newSViv(PTR2IV(mod)), 0);
    return mod;
}

/* XS wrapper for modified methods */
XS_INTERNAL(xs_modified_method_wrapper) {
    dXSARGS;
    ModifiedMethod *mod = INT2PTR(ModifiedMethod*, CvXSUBANY(cv).any_iv);
    MethodModifier *m;
    int count = 0;
    I32 gimme = GIMME_V;
    AV *saved_args;
    AV *saved_results;
    int i;
    
    /* Save original arguments for before/after chains */
    saved_args = newAV();
    sv_2mortal((SV*)saved_args);
    for (i = 0; i < items; i++) {
        av_push(saved_args, SvREFCNT_inc(ST(i)));
    }
    
    /* Call before chain (in stack order - most recent first) */
    for (m = mod->before_chain; m; m = m->next) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        for (i = 0; i <= av_len(saved_args); i++) {
            SV **svp = av_fetch(saved_args, i, 0);
            /*
             # uncoverable condition left count:1
             # uncoverable condition right count:2 */
            XPUSHs(svp ? *svp : &PL_sv_undef);
        }
        PUTBACK;
        call_sv(m->callback, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
    
    /* Save results from original/around call */
    saved_results = newAV();
    sv_2mortal((SV*)saved_results);
    
    /* Call around chain (or original if no around) */
    if (mod->around_chain) {
        /* For around, we pass ($orig, $self, @args) */
        m = mod->around_chain;
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newRV_inc((SV*)mod->original_cv)));
            for (i = 0; i <= av_len(saved_args); i++) {
                SV **svp = av_fetch(saved_args, i, 0);
                /*
                 # uncoverable condition left count:1
                 # uncoverable condition right count:2 */
                XPUSHs(svp ? *svp : &PL_sv_undef);
            }
            PUTBACK;
            count = call_sv(m->callback, gimme == G_ARRAY ? G_LIST : G_SCALAR);
            SPAGAIN;
            /* Save results before LEAVE destroys them - they're on stack in reverse */
            for (i = 0; i < count; i++) {
                av_push(saved_results, newSVsv(POPs));
            }
            FREETMPS;
            LEAVE;
        }
    } else if (mod->original_cv) {
        /* Call original method */
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        for (i = 0; i <= av_len(saved_args); i++) {
            SV **svp = av_fetch(saved_args, i, 0);
            /*
             # uncoverable condition left count:1
             # uncoverable condition right count:2 */
            XPUSHs(svp ? *svp : &PL_sv_undef);
        }
        PUTBACK;
        count = call_sv((SV*)mod->original_cv, gimme == G_ARRAY ? G_LIST : G_SCALAR);
        SPAGAIN;
        /* Save results before LEAVE destroys them */
        for (i = 0; i < count; i++) {
            av_push(saved_results, newSVsv(POPs));
        }
        FREETMPS;
        LEAVE;
    }
    
    /* Call after chain (in order of registration) */
    for (m = mod->after_chain; m; m = m->next) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        for (i = 0; i <= av_len(saved_args); i++) {
            SV **svp = av_fetch(saved_args, i, 0);
            /*
             # uncoverable condition left count:1
             # uncoverable condition right count:2 */
            XPUSHs(svp ? *svp : &PL_sv_undef);
        }
        PUTBACK;
        call_sv(m->callback, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
    
    /* Put saved results back on stack (they were saved in reverse order) */
    {
        count = av_len(saved_results) + 1;
        for (i = count - 1; i >= 0; i--) {
            SV **svp = av_fetch(saved_results, i, 0);
            /* Use sv_mortalcopy to put a mortal copy on stack */
            ST(count - 1 - i) = sv_mortalcopy(svp ? *svp : &PL_sv_undef); /* # uncoverable condition right count:1 */
        }
    }
    
    XSRETURN(count);
}

/* Install the wrapper if not already done */
static void install_modifier_wrapper(pTHX_ ClassMeta *meta, const char *method_name, ModifiedMethod *mod) {
    char full_name[256];
    CV *existing_cv;
    
    snprintf(full_name, sizeof(full_name), "%s::%s", meta->class_name, method_name);
    
    existing_cv = get_cvn_flags(full_name, strlen(full_name), 0);
    
    /* Only install wrapper once - check if it's already our wrapper */
    if (existing_cv && CvXSUB(existing_cv) == xs_modified_method_wrapper) {
        return;  /* Already wrapped */
    }
    
    /* Install wrapper without "Subroutine redefined" warning */
    {
        GV *gv = gv_fetchpv(full_name, GV_ADD, SVt_PVCV);
        CV *cv = newXS_flags(NULL, xs_modified_method_wrapper, __FILE__, NULL, 0);
        CvXSUBANY(cv).any_iv = PTR2IV(mod);
        /* Silently replace the CV in the GV */
        if (GvCV(gv)) {
            SvREFCNT_dec(GvCV(gv));
        }
        GvCV_set(gv, cv);
    }
}

/* Add a modifier to a method */
static void add_modifier(pTHX_ ClassMeta *meta, const char *method_name, SV *callback, int type) {
    ModifiedMethod *mod;
    MethodModifier *new_mod;
    
    mod = get_or_create_modified_method(aTHX_ meta, method_name);
    
    Newx(new_mod, 1, MethodModifier);
    new_mod->callback = newSVsv(callback);
    new_mod->next = NULL;
    
    /* Add to appropriate chain */
    switch (type) { /* # uncoverable branch true count:4 */
        case 0:  /* before */
            new_mod->next = mod->before_chain;
            mod->before_chain = new_mod;
            break;
        case 1:  /* after */
            /* Add to end of after chain */
            if (!mod->after_chain) {
                mod->after_chain = new_mod;
            } else {
                MethodModifier *last = mod->after_chain;
                while (last->next) last = last->next;
                last->next = new_mod;
            }
            break;
        case 2:  /* around */
            /* around wraps previous around/original */
            new_mod->next = mod->around_chain;
            mod->around_chain = new_mod;
            break;
    }
    
    install_modifier_wrapper(aTHX_ meta, method_name, mod);
}

/* ============================================
   handles(...) - the delegating methods
   ============================================ */

/* How a method is called on the delegate: from perl 5.19.2 as $obj->name is,
 * through the shared name's cached hash */
#ifdef G_METHOD_NAMED
#  define G_DELEGATE_METHOD G_METHOD_NAMED
#else
#  define G_DELEGATE_METHOD G_METHOD
#endif

/* What a delegating method knows: its class, the slot it delegates to and
 * the resolved handle. Kept in CvXSUBANY, like the other generated methods. */
typedef struct {
    ClassMeta      *meta;
    IV              slot_idx;
    SlotSpec       *spec;
    ResolvedHandle *h;
} DelegateData;

/* The invocant of a delegating method, which must be an object */
OBJECT_INLINE AV *delegator_self(pTHX_ I32 items, SV *self) {
    if (items < 1 || !SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV) croak("Not an object");
    return (AV*)SvRV(self);
}

/* The delegate: the slot's value, found the way the slot's getter finds it -
 * the object's own slot, then its prototype chain, then a lazy build.
 * Croaks when there is none (D3). av is the object's array. */
OBJECT_INLINE SV *delegate_target(pTHX_ SV *self, AV *av, DelegateData *d) {
    IV idx = d->slot_idx;
    SV *target;

    /* The common case: the object's own slot holds it */
    if (idx <= AvFILLp(av)) {
        target = AvARRAY(av)[idx];
        if (target && SvOK(target)) return target;
    }
    target = resolve_property_chain(aTHX_ av, idx);
    if (!SvOK(target) && d->spec->is_lazy) {
        SV *built = slot_build_lazy(aTHX_ self, av, idx, d->spec);
        if (built) target = built;
    }
    if (!SvOK(target)) {
        croak("Cannot delegate %" SVf " to %s: %s is not set",
              SVfARG(d->h->local), d->spec->name, d->spec->name);
    }
    return target;
}

/* $self->local(@args) is $self->slot->remote(@args). The call reuses this
 * XSUB's own frame: the delegate replaces $self as ST(0), the arguments stay
 * where they are, the caller's context passes through, and the results are
 * left where ours go. Nothing is copied. */
XS_INTERNAL(xs_delegate_method) {
    dXSARGS;
    DelegateData *d = INT2PTR(DelegateData*, CvXSUBANY(cv).any_iv);
    AV *av = delegator_self(aTHX_ items, ST(0));
    I32 count;

    ST(0) = delegate_target(aTHX_ ST(0), av, d);
    /* From PL_stack_base, not a saved pointer: a lazy builder may have grown the stack */
    PUSHMARK(PL_stack_base + ax - 1);
    count = call_sv(d->h->remote, GIMME_V | G_DELEGATE_METHOD);
    XSRETURN(count);
}

/* The delegate of a CodeRef, ArrayRef or HashRef slot, found as a method
 * delegate is, and a reference to type, as the slot's type makes it. A value
 * that is not - from a prototype of another class, or written into the
 * object's array directly - croaks: call_sv would call a string as the name
 * of a sub, and the native ops would take it for a container. what is "a
 * CODE", "an ARRAY" or "a HASH". */
OBJECT_INLINE SV *delegate_ref(pTHX_ SV *self, AV *av, DelegateData *d, svtype type, const char *what) {
    SV *target = delegate_target(aTHX_ self, av, d);
    if (!SvROK(target) || SvTYPE(SvRV(target)) != type) {
        croak("Cannot delegate %" SVf " to %s: %s is not %s reference",
              SVfARG(d->h->local), d->spec->name, d->spec->name, what);
    }
    return target;
}

/* $self->local(@args) is $self->slot->(@args). $self is left out by marking
 * the stack after it, so the arguments are passed where they are; the
 * results land one place up, and move down to where ours go. */
XS_INTERNAL(xs_delegate_code_call) {
    dXSARGS;
    DelegateData *d = INT2PTR(DelegateData*, CvXSUBANY(cv).any_iv);
    AV *av = delegator_self(aTHX_ items, ST(0));
    SV *code = delegate_ref(aTHX_ ST(0), av, d, SVt_PVCV, "a CODE");
    I32 count, i;

    PUSHMARK(PL_stack_base + ax);
    count = call_sv(code, GIMME_V);
    /* ST() is from PL_stack_base, so this holds if the call grew the stack */
    for (i = 0; i < count; i++) ST(i) = ST(i + 1);
    XSRETURN(count);
}

/* $self->local(@args) is $self->slot->($self, @args): this XSUB's own
 * arguments, $self first, are passed as they are */
XS_INTERNAL(xs_delegate_code_method) {
    dXSARGS;
    DelegateData *d = INT2PTR(DelegateData*, CvXSUBANY(cv).any_iv);
    AV *av = delegator_self(aTHX_ items, ST(0));
    SV *code = delegate_ref(aTHX_ ST(0), av, d, SVt_PVCV, "a CODE");
    I32 count;

    PUSHMARK(PL_stack_base + ax - 1);
    count = call_sv(code, GIMME_V);
    XSRETURN(count);
}

/* What a native delegator checks before it runs anything: the number of
 * arguments, and, for an op that changes the container, that the object is
 * not frozen (D4, D12). So a call that croaks has done nothing, not even a
 * lazy build. */
OBJECT_INLINE void native_precheck(pTHX_ DelegateData *d, const NativeOp *op, I32 nargs, SV *self, AV *self_av) {
    if (nargs < op->min_args || (op->max_args >= 0 && nargs > op->max_args) || (op->pairs && nargs % 2)) {
        if (op->pairs) {
            croak("Wrong number of arguments to %" SVf " (%s takes key/value pairs)",
                  SVfARG(d->h->local), op->name);
        }
        if (op->max_args < 0) {
            croak("Wrong number of arguments to %" SVf " (%s takes at least %d)",
                  SVfARG(d->h->local), op->name, (int)op->min_args);
        }
        croak("Wrong number of arguments to %" SVf " (%s takes %d)",
              SVfARG(d->h->local), op->name, (int)op->min_args);
    }
    if (op->mutates && SvMAGICAL(self_av)) {
        MAGIC *mg = get_object_magic(aTHX_ self);
        if (mg && (mg->mg_private & OBJ_FLAG_FROZEN)) croak("Cannot modify frozen object");
    }
}

/* After an op that changed the container: the slot's trigger, called as the
 * setter calls it, ($self, $new_value), with the container as the new value,
 * once per call (D6). The results are already in place below the stack's
 * top, where the call leaves them; a removed value is mortal and outlives
 * it, since G_DISCARD frees only the call's own temporaries. */
static void native_trigger(pTHX_ SV *self, SV *container, SlotSpec *spec) {
    dSP;
    if (!spec->has_trigger || !spec->trigger_cb) return;
    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(container);
    PUTBACK;
    call_method(SvPV_nolen(spec->trigger_cb), G_DISCARD);
}

/* $av->[key] = a copy of val, through the element as perl's own assignment
 * does, so that a tied array's STORE runs and nothing is left to free if it
 * croaks. NULL when key is before the start of the array. */
static SV **native_av_assign(pTHX_ AV *av, SSize_t key, SV *val) {
    SV **svp = av_fetch(av, key, 1);
    if (svp) {
        sv_setsv(*svp, val);
        SvSETMAGIC(*svp);
    }
    return svp;
}

/* The number of keys of a hash: kept for a plain hash, counted through the
 * tie for a tied one */
static IV native_hv_count(pTHX_ HV *hv) {
    IV n = 0;
    /* The macros below on lines of their own: their own tests are perl's */
    if (!SvRMAGICAL(hv))
        return HvUSEDKEYS(hv);
    hv_iterinit(hv);
    while (hv_iternext(hv)) n++;
    return n;
}

/* A native ArrayRef method (phase 1 section 3): the array's own op, its
 * result as the builtin gives it, the trigger after a change */
XS_INTERNAL(xs_delegate_array) {
    dXSARGS;
    dXSTARG;                  /* the caller's target, for a number without an allocation */
    DelegateData *d = INT2PTR(DelegateData*, CvXSUBANY(cv).any_iv);
    const NativeOp *op = &array_ops[d->h->op];
    SV *self = ST(0);
    AV *self_av = delegator_self(aTHX_ items, self);
    SV *target;
    AV *av;
    I32 ret = 1;
    I32 i;

    native_precheck(aTHX_ d, op, items - 1, self, self_av);
    target = delegate_ref(aTHX_ self, self_av, d, SVt_PVAV, "an ARRAY");
    av = (AV*)SvRV(target);
    if (op->mutates && SvREADONLY(av)) croak_no_modify();

    /* The range check before the jump table (arm 11) cannot fail: the op
     * is an index into array_ops, set when the handle was resolved */
    switch (d->h->op) { /* # uncoverable branch true count:11 */
        case AOP_PUSH: {
            SSize_t at = av_len(av) + 1;
            for (i = 1; i < items; i++) native_av_assign(aTHX_ av, at++, ST(i));
            sv_setiv(TARG, av_len(av) + 1);
            ST(0) = TARG;
            break;
        }
        case AOP_UNSHIFT:
            av_unshift(av, items - 1);
            for (i = 1; i < items; i++) native_av_assign(aTHX_ av, i - 1, ST(i));
            sv_setiv(TARG, av_len(av) + 1);
            ST(0) = TARG;
            break;
        case AOP_POP:
            ST(0) = sv_2mortal(av_pop(av));      /* &PL_sv_undef when empty, left as it is */
            break;
        case AOP_SHIFT:
            ST(0) = sv_2mortal(av_shift(av));
            break;
        case AOP_LIST:
            /* The array's own elements, as @$ref gives them; its size in scalar context */
            if (GIMME_V == G_LIST) {
                SV **sp_base = PL_stack_base + ax - 1;
                ret = av_len(av) + 1;
                EXTEND(sp_base, ret);
                for (i = 0; i < ret; i++) {
                    SV **svp = av_fetch(av, i, 0);
                    ST(i) = svp ? *svp : &PL_sv_undef;
                }
                break;
            }
            /* In scalar context, the count */
            /* FALLTHROUGH */
        case AOP_COUNT:
            sv_setiv(TARG, av_len(av) + 1);
            ST(0) = TARG;
            break;
        case AOP_IS_EMPTY:
            ST(0) = av_len(av) < 0 ? &PL_sv_yes : &PL_sv_no;
            break;
        case AOP_GET: {
            SV **svp = av_fetch(av, SvIV(ST(1)), 0);
            ST(0) = svp ? *svp : &PL_sv_undef;
            break;
        }
        case AOP_SET: {
            IV key = SvIV(ST(1));
            SV **svp = native_av_assign(aTHX_ av, key, ST(2));
            if (!svp) croak("Modification of non-creatable array value attempted, subscript %" IVdf, key);
            ST(0) = *svp;
            break;
        }
        case AOP_CLEAR:
        default:
            /* @a = () gives the empty list, or 0 in scalar context */
            av_clear(av);
            if (GIMME_V == G_LIST) {
                ret = 0;
            } else {
                sv_setiv(TARG, 0);
                ST(0) = TARG;
            }
            break;
    }

    if (op->mutates) native_trigger(aTHX_ self, target, d->spec);
    XSRETURN(ret);
}

/* A native HashRef method (phase 1 section 4) */
XS_INTERNAL(xs_delegate_hash) {
    dXSARGS;
    dXSTARG;
    DelegateData *d = INT2PTR(DelegateData*, CvXSUBANY(cv).any_iv);
    const NativeOp *op = &hash_ops[d->h->op];
    SV *self = ST(0);
    AV *self_av = delegator_self(aTHX_ items, self);
    I32 nargs = items - 1;
    SV *target;
    HV *hv;
    I32 ret = 1;
    I32 i;

    native_precheck(aTHX_ d, op, nargs, self, self_av);
    target = delegate_ref(aTHX_ self, self_av, d, SVt_PVHV, "a HASH");
    hv = (HV*)SvRV(target);

    /* The range check before the jump table (arm 9) cannot fail: the op is
     * an index into hash_ops, set when the handle was resolved */
    switch (d->h->op) { /* # uncoverable branch true count:9 */
        case HOP_GET:
        case HOP_DELETE:
            /* Each key's value, in its place: a slice gives all of them, and
             * its last one in scalar context */
            for (i = 1; i < items; i++) {
                SV *value;
                if (d->h->op == HOP_GET) {
                    HE *he = hv_fetch_ent(hv, ST(i), 0, 0);
                    value = he ? HeVAL(he) : NULL;
                } else {
                    value = hv_delete_ent(hv, ST(i), 0, 0);
                }
                ST(i - 1) = value ? value : &PL_sv_undef;
            }
            /* One key gives its value in any context */
            if (nargs > 1) {
                if (GIMME_V == G_LIST) ret = nargs;
                else ST(0) = ST(nargs - 1);
            }
            break;
        case HOP_SET: {
            /* Through each element, as $h{k} = v does: a tied hash's STORE
             * runs, a restricted hash croaks before anything is made */
            I32 values = nargs / 2;
            for (i = 1; i < items; i += 2) {
                HE *he = hv_fetch_ent(hv, ST(i), 1, 0);
                sv_setsv(HeVAL(he), ST(i + 1));
                SvSETMAGIC(HeVAL(he));
                ST((i - 1) / 2) = HeVAL(he);
            }
            /* One pair gives its value; a slice assignment gives its values,
             * or their number in scalar context */
            if (values > 1) {
                if (GIMME_V == G_LIST) {
                    ret = values;
                } else {
                    sv_setiv(TARG, values);
                    ST(0) = TARG;
                }
            }
            break;
        }
        case HOP_EXISTS:
            ST(0) = hv_exists_ent(hv, ST(1), 0) ? &PL_sv_yes : &PL_sv_no;
            break;
        case HOP_DEFINED: {
            HE *he = hv_fetch_ent(hv, ST(1), 0, 0);
            SV *value = he ? HeVAL(he) : NULL;
            if (value)
                SvGETMAGIC(value);                  /* a tied hash's FETCH */
            ST(0) = value && SvOK(value) ? &PL_sv_yes : &PL_sv_no;
            break;
        }
        case HOP_KEYS:
        case HOP_VALUES:
        case HOP_KV: {
            HE *he;
            /* Like keys, in any context, this starts the hash's iterator afresh */
            hv_iterinit(hv);
            if (GIMME_V != G_LIST) {
                sv_setiv(TARG, native_hv_count(aTHX_ hv));
                ST(0) = TARG;
                break;
            }
            SP = PL_stack_base + ax - 1;
            while ((he = hv_iternext(hv))) {
                SV *out;
                if (d->h->op == HOP_KEYS) {
                    out = hv_iterkeysv(he);
                } else if (d->h->op == HOP_VALUES) {
                    out = hv_iterval(hv, he);
                } else {
                    AV *pair = newAV();
                    av_push(pair, newSVsv(hv_iterkeysv(he)));
                    av_push(pair, newSVsv(hv_iterval(hv, he)));
                    out = sv_2mortal(newRV_noinc((SV*)pair));
                }
                XPUSHs(out);
            }
            PUTBACK;
            return;
        }
        case HOP_COUNT:
            sv_setiv(TARG, native_hv_count(aTHX_ hv));
            ST(0) = TARG;
            break;
        case HOP_IS_EMPTY:
            ST(0) = native_hv_count(aTHX_ hv) ? &PL_sv_no : &PL_sv_yes;
            break;
        case HOP_CLEAR:
        default:
            hv_clear(hv);
            if (GIMME_V == G_LIST) {
                ret = 0;
            } else {
                sv_setiv(TARG, 0);
                ST(0) = TARG;
            }
            break;
    }

    if (op->mutates) native_trigger(aTHX_ self, target, d->spec);
    XSRETURN(ret);
}

/* The XSUB a handle's kind installs */
static XSUBADDR_t delegator_xsub(const ResolvedHandle *h) {
    switch (h->kind) {
        case HK_CODE:
            return h->op == HANDLE_CODE_METHOD ? xs_delegate_code_method : xs_delegate_code_call;
        case HK_ARRAY:
            return xs_delegate_array;
        case HK_HASH:
            return xs_delegate_hash;
        default:    /* HK_METHOD */
            return xs_delegate_method;
    }
}

/* Whether x is the XSUB of a delegating method */
static bool xsub_is_delegator(XSUBADDR_t x) {
    return x == xs_delegate_method || x == xs_delegate_code_call || x == xs_delegate_code_method
        || x == xs_delegate_array || x == xs_delegate_hash;
}

/* The delegating method cv is, or wraps in a before/after/around modifier;
 * NULL when it is not one */
static CV *delegator_cv(pTHX_ CV *cv) {
    if (CvISXSUB(cv) && CvXSUB(cv) == xs_modified_method_wrapper) {
        ModifiedMethod *mod = INT2PTR(ModifiedMethod*, CvXSUBANY(cv).any_iv);
        cv = mod->original_cv;
        if (!cv) return NULL;    /* a modifier on a method there was not */
    }
    return CvISXSUB(cv) && xsub_is_delegator(CvXSUB(cv)) ? cv : NULL;
}

/* The class's own sub called name (not one it inherits), or NULL */
static CV *class_method_cv(pTHX_ ClassMeta *meta, SV *name) {
    SV *fqn = sv_2mortal(newSVpvf("%s::%" SVf, meta->class_name, SVfARG(name)));
    GV *gv = gv_fetchsv(fqn, 0, SVt_PVCV);
    return gv ? GvCV(gv) : NULL;
}

/* Install one delegating method, or give the one an earlier define of the
 * class installed its new slot and handle */
static void install_delegator(pTHX_ ClassMeta *meta, IV idx, SlotSpec *spec, ResolvedHandle *h) {
    CV *cv = class_method_cv(aTHX_ meta, h->local);
    DelegateData *d;

    if (cv) {
        /* Ours, perhaps inside a modifier's wrapper: the caller has checked */
        cv = delegator_cv(aTHX_ cv);
        d = INT2PTR(DelegateData*, CvXSUBANY(cv).any_iv);
        CvXSUB(cv) = delegator_xsub(h);
    } else {
        SV *fqn = sv_2mortal(newSVpvf("%s::%" SVf, meta->class_name, SVfARG(h->local)));
        Newx(d, 1, DelegateData);
        cv = newXS_flags(SvPV_nolen(fqn), delegator_xsub(h), __FILE__, NULL,
                         SvUTF8(fqn) ? SVf_UTF8 : 0);
        CvXSUBANY(cv).any_iv = PTR2IV(d);
    }
    d->meta = meta;
    d->slot_idx = idx;
    d->spec = spec;
    d->h = h;
}

/* Install the delegating methods of every slot of a class with handles (D7).
 * Run by define once all its slots are in, and by with() once a role's are,
 * so that no accessor is still to come whose name a delegator could take.
 * Each is checked before any is installed, against the methods the slots
 * give the class, the other delegators and the class's own subs:
 *  - a slot the class declares (its own, a +attr, a role's) croaks on a
 *    reserved name or a name already taken;
 *  - a slot it only inherits gives way: a method of the class's own, or of an
 *    earlier parent's slot, overrides the inherited delegator, as a child's
 *    method overrides a parent's.
 * A delegator an earlier define of the class installed is given its new slot
 * rather than replaced, also when a method modifier wraps it. */
static void install_class_delegators(pTHX_ ClassMeta *meta) {
    HV *taken;      /* method name -> the slot that provides it */
    AV *names;
    AV *plan;       /* slot index, handle index pairs to install */
    IV idx, i;
    bool any = false;

    for (idx = 1; idx < meta->slot_count; idx++) {
        /* A slot a redefinition of the class left out has no spec */
        if (meta->slots[idx] && meta->slots[idx]->has_handles) any = true;
    }
    if (!any) return;

    taken = (HV*)sv_2mortal((SV*)newHV());
    names = (AV*)sv_2mortal((SV*)newAV());
    plan  = (AV*)sv_2mortal((SV*)newAV());

    /* The methods the slots themselves give the class */
    for (idx = 1; idx < meta->slot_count; idx++) {
        SlotSpec *spec = meta->slots[idx];
        if (!spec) continue;
        av_clear(names);
        slot_method_names(aTHX_ spec, names);
        for (i = 0; i <= av_len(names); i++) {
            (void)hv_store_ent(taken, AvARRAY(names)[i], newSVpv(spec->name, 0), 0);
        }
    }

    /* Check every delegator before installing any */
    for (idx = 1; idx < meta->slot_count; idx++) {
        SlotSpec *spec = meta->slots[idx];
        if (!spec || !spec->has_handles) continue;
        for (i = 0; i < spec->resolved_count; i++) {
            SV *local = spec->resolved[i].local;
            HE *he = hv_fetch_ent(taken, local, 0, 0);
            CV *cv = class_method_cv(aTHX_ meta, local);
            bool local_sub = cv && !delegator_cv(aTHX_ cv);

            if (spec->inherited) {
                if (he || local_sub) continue;      /* overridden */
            } else if (is_reserved_method(aTHX_ SvPVX(local), SvCUR(local), 0)) {
                croak("handles for slot '%s': method '%" SVf "' is reserved",
                      spec->name, SVfARG(local));
            } else if (he) {
                croak("handles for slot '%s': method '%" SVf "' is already provided by slot '%" SVf "'",
                      spec->name, SVfARG(local), SVfARG(HeVAL(he)));
            } else if (local_sub) {
                croak("You cannot overwrite a locally defined method (%" SVf ") with a delegation",
                      SVfARG(local));
            }
            (void)hv_store_ent(taken, local, newSVpv(spec->name, 0), 0);
            av_push(plan, newSViv(idx));
            av_push(plan, newSViv(i));
        }
    }

    for (i = 0; i < av_len(plan); i += 2) {
        IV slot = SvIVX(AvARRAY(plan)[i]);
        SlotSpec *spec = meta->slots[slot];
        install_delegator(aTHX_ meta, slot, spec, &spec->resolved[SvIVX(AvARRAY(plan)[i + 1])]);
    }
}

/* with() adding a role slot whose methods would take a delegator's name:
 * install_accessor and the others would leave the delegator in place, so croak
 * before the slot joins the class */
static void check_role_slot_against_delegators(pTHX_ ClassMeta *meta, SlotSpec *slot, RoleMeta *role) {
    AV *names = (AV*)sv_2mortal((SV*)newAV());
    IV i;
    slot_method_names(aTHX_ slot, names);
    for (i = 0; i <= av_len(names); i++) {
        CV *cv = class_method_cv(aTHX_ meta, AvARRAY(names)[i]);
        if (cv && delegator_cv(aTHX_ cv)) {
            croak("Slot conflict: method '%" SVf "' of slot '%s' from role '%s' is delegated in class '%s'",
                  SVfARG(AvARRAY(names)[i]), slot->name, role->role_name, meta->class_name);
        }
    }
}

/* ============================================
   XS API Functions
   ============================================ */

XS_INTERNAL(xs_define) {
    dXSARGS;
    STRLEN class_len;
    const char *class_pv;
    ClassMeta *meta;
    IV i;
    IV first_prop = 1;  /* index of first property arg (after class name) */

    /* Multiple inheritance support */
    ClassMeta **parent_metas = NULL;
    IV parent_count = 0;
    
    if (items < 1) croak("Usage: Object::Proto::define($class, @properties)");
    
    class_pv = SvPV(ST(0), class_len);

    /* Check for extends => 'ParentClass' or extends => ['P1','P2'] in arguments */
    for (i = 1; i < items - 1; i++) {
        STRLEN klen;
        const char *kpv = SvPV(ST(i), klen);
        if (klen == 7 && memEQ(kpv, "extends", 7)) {
            SV *val = ST(i + 1);
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                /* extends => ['Parent1', 'Parent2', ...] */
                AV *parents_av = (AV*)SvRV(val);
                IV plen = av_len(parents_av) + 1;
                IV p;
                Newx(parent_metas, plen, ClassMeta*);
                for (p = 0; p < plen; p++) {
                    SV **elem = av_fetch(parents_av, p, 0);
                    if (elem && SvPOK(*elem)) { /* # uncoverable condition right count:1 */
                        STRLEN pname_len;
                        const char *pname = SvPV(*elem, pname_len);
                        ClassMeta *pmeta = get_class_meta(aTHX_ pname, pname_len);
                        if (!pmeta) {
                            Safefree(parent_metas);
                            croak("Object::Proto::define: parent class '%s' has not been defined", pname);
                        }
                        parent_metas[parent_count++] = pmeta;
                    }
                }
            } else {
                /* extends => 'SingleParent' */
                STRLEN parent_len;
                const char *parent_pv = SvPV(val, parent_len);
                ClassMeta *pmeta = get_class_meta(aTHX_ parent_pv, parent_len);
                if (!pmeta) {
                    croak("Object::Proto::define: parent class '%s' has not been defined", parent_pv);
                }
                Newx(parent_metas, 1, ClassMeta*);
                parent_metas[parent_count++] = pmeta;
            }
            /* Shift remaining args down to remove extends => value */
            {
                IV j;
                for (j = i; j < items - 2; j++) {
                    ST(j) = ST(j + 2);
                }
                items -= 2;
            }
            break;
        }
    }

    /* Get or create class meta */
    meta = get_class_meta(aTHX_ class_pv, class_len);
    if (!meta) {
        meta = create_class_meta(aTHX_ class_pv, class_len);
        register_class_meta(aTHX_ class_pv, class_len, meta);
    }

    /* Store parent references */
    if (parent_count > 0) {
        Newx(meta->parent_classes, parent_count, char*);
        Newx(meta->parent_metas, parent_count, ClassMeta*);
        meta->parent_count = parent_count;
        for (i = 0; i < parent_count; i++) {
            STRLEN plen = strlen(parent_metas[i]->class_name);
            Newx(meta->parent_classes[i], plen + 1, char);
            Copy(parent_metas[i]->class_name, meta->parent_classes[i], plen + 1, char);
            meta->parent_metas[i] = parent_metas[i];
        }
    }

    /* Calculate total slots needed: all parent inherited + child own */
    {
        IV total_parent_slots = 0;
        IV child_props = items - 1;
        IV max_slots;
        for (i = 0; i < parent_count; i++) {
            total_parent_slots += parent_metas[i]->slot_count - 1;  /* -1 for prototype slot */
        }
        /* Slots are appended after the class's existing ones: a redefinition
         * keeps its slots where they were, so its new arrays must still reach
         * every index it had (slot_count is 1 for a new class) */
        max_slots = meta->slot_count + total_parent_slots + child_props;
        Renew(meta->idx_to_prop, max_slots + 1, char*);
        Renew(meta->slots, max_slots + 1, SlotSpec*);
        for (i = 0; i <= max_slots; i++) {
            meta->slots[i] = NULL;
            meta->idx_to_prop[i] = NULL;
        }
    }

    /* Copy parent slots (if extends) - iterate all parents, first parent wins on conflict */
    for (i = 0; i < parent_count; i++) {
        ClassMeta *pmeta = parent_metas[i];
        IV j;
        for (j = 1; j < pmeta->slot_count; j++) {
            SlotSpec *parent_spec = pmeta->slots[j];
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            if (parent_spec) {
                /* Skip if property already defined by earlier parent */
                SV **existing = hv_fetch(meta->prop_to_idx, parent_spec->name,
                                         strlen(parent_spec->name), 0);
                if (existing && SvIOK(*existing)) continue; /* # uncoverable condition right count:2 */

                {
                    SlotSpec *cloned = clone_slot_spec(aTHX_ parent_spec);
                    cloned->inherited = 1;
                    resolve_handles(aTHX_ cloned);
                    register_slot(aTHX_ class_pv, meta, meta->slot_count++, cloned);
                }
            }
        }
    }

    /* Register each child property */
    for (i = first_prop; i < items; i++) {
        STRLEN spec_len;
        const char *spec_pv = SvPV(ST(i), spec_len);
        SlotSpec *spec;
        IV idx;
        SV **existing;
        U8 is_modification = 0;
        const char *real_spec_pv = spec_pv;
        STRLEN real_spec_len = spec_len;

        /* Check for +attr modification syntax (Moo/Moose-style) */
        if (spec_len > 0 && spec_pv[0] == '+') { /* # uncoverable condition right count:1 */
            is_modification = 1;
            real_spec_pv = spec_pv + 1;
            real_spec_len = spec_len - 1;
        }

        /* Parse the slot spec (e.g., "name:Str:required" or just "name") */
        spec = parse_slot_spec(aTHX_ real_spec_pv, real_spec_len);
        spec->private_owner = savepvn(class_pv, class_len);
        /* Validate handles before the class is touched, so that a croak
         * leaves it as it was */
        if (!is_modification) resolve_handles(aTHX_ spec);

        /* Check if this property already exists (from parent) */
        existing = hv_fetch(meta->prop_to_idx, spec->name, strlen(spec->name), 0);
        
        if (is_modification) {
            /* +attr syntax: merge child modifiers onto parent spec */
            SlotSpec *parent_spec;
            SlotSpec *merged;
            
            if (!existing || !SvIOK(*existing)) { /* # uncoverable condition left count:2 */
                croak("+%s: no inherited attribute '%s' to modify", 
                      spec->name, spec->name);
            }
            idx = SvIV(*existing);
            parent_spec = meta->slots[idx];
            
            /* Merge override onto clone of parent */
            merged = merge_slot_spec(aTHX_ parent_spec, spec);
            /* Before anything is freed: a croak leaves the class as it was */
            resolve_handles(aTHX_ merged);
            
            /* Free the override spec (we cloned what we needed) */
            Safefree(spec->name);
            Safefree(spec->private_owner);
            SvREFCNT_dec((SV*)spec->handles);
            Safefree(spec);
            spec = merged;
            
            /* Free old parent spec */
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            if (parent_spec) {
                Safefree(parent_spec->name);
                Safefree(parent_spec->private_owner);
                Safefree(parent_spec->private_also);
                SvREFCNT_dec((SV*)parent_spec->handles);
                Safefree(parent_spec);
            }
        } else if (existing && SvIOK(*existing)) { /* # uncoverable condition right count:2 */
            /* Full override: reuse same slot index */
            idx = SvIV(*existing);
            /* Free old spec */
            if (meta->slots[idx]) {
                Safefree(meta->slots[idx]->name);
                Safefree(meta->slots[idx]->private_owner);
                Safefree(meta->slots[idx]->private_also);
                SvREFCNT_dec((SV*)meta->slots[idx]->handles);
                Safefree(meta->slots[idx]);
            }
        } else {
            idx = meta->slot_count++;
        }

        register_slot(aTHX_ class_pv, meta, idx, spec);
    }

    /* handles(...): now that every slot's methods are in */
    install_class_delegators(aTHX_ meta);

    /* Set up @ISA for parent classes (C3 MRO for multiple inheritance) */
    if (parent_count > 0) {
        AV *isa = get_av(Perl_form(aTHX_ "%s::ISA", class_pv), GV_ADD);
        for (i = 0; i < parent_count; i++) {
            av_push(isa, newSVpv(parent_metas[i]->class_name, 0));
        }
        /* Notify Perl's method resolution cache that ISA changed.
         * Perl_mro_isa_changed_in was made a hidden (non-exported) symbol
         * in Perl 5.36.0. mro_method_changed_in is public since 5.10.0
         * and is the correct public API for invalidating the method cache
         * after an ISA change. */
        mro_method_changed_in(meta->stash);
        Safefree(parent_metas);
    }

    /* Install constructor */
    install_constructor(aTHX_ class_pv, meta);

    /* Install prototype methods as class methods */
    {
        char method_name[256];
        snprintf(method_name, sizeof(method_name), "%s::set_prototype", class_pv);
        newXS(method_name, xs_set_prototype, __FILE__);
        snprintf(method_name, sizeof(method_name), "%s::prototype", class_pv);
        newXS(method_name, xs_prototype, __FILE__);
    }
    
    /* Check for DEMOLISH method - only set up destruction hook if class has one */
    {
        char demolish_name[256];
        CV *demolish_cv;
        snprintf(demolish_name, sizeof(demolish_name), "%s::DEMOLISH", class_pv);
        demolish_cv = get_cvn_flags(demolish_name, strlen(demolish_name), 0);
        if (demolish_cv) {
            meta->demolish_cv = demolish_cv;
            /* Install DESTROY wrapper that calls DEMOLISH */
            install_destroy_wrapper(aTHX_ class_pv, meta);
        }
    }

    /* Check for BUILD method - called after new() */
    {
        char build_name[256];
        CV *build_cv;
        snprintf(build_name, sizeof(build_name), "%s::BUILD", class_pv);
        build_cv = get_cvn_flags(build_name, strlen(build_name), 0);
        if (build_cv) {
            meta->build_cv = build_cv;
            meta->has_build = 1;
        }
    }
    
    XSRETURN_EMPTY;
}

XS_INTERNAL(xs_prototype) {
    dXSARGS;
    AV *av;
    SV **svp;
    
    if (items < 1) croak("Usage: Object::Proto::prototype($obj)");
    
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)SvRV(ST(0));
    svp = av_fetch(av, 0, 0);
    if (svp && SvOK(*svp)) {
        ST(0) = SvREFCNT_inc(*svp);
    } else {
        ST(0) = &PL_sv_undef;
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_set_prototype) {
    dXSARGS;
    AV *av;
    MAGIC *mg;

    if (items < 2) croak("Usage: Object::Proto::set_prototype($obj, $proto)");

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)SvRV(ST(0));

    mg = get_object_magic(aTHX_ ST(0));
    if (mg && (mg->mg_private & OBJ_FLAG_FROZEN)) {
        croak("Cannot modify frozen object");
    }

    av_store(av, 0, newSVsv(ST(1)));
    XSRETURN_EMPTY;
}

/* Get the full prototype chain as an arrayref */
XS_INTERNAL(xs_prototype_chain) {
    dXSARGS;
    AV *av;
    AV *chain;
    AV *visited[MAX_PROTOTYPE_DEPTH];
    int depth = 0;
    int i;

    if (items < 1) croak("Usage: Object::Proto::prototype_chain($obj)");

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("Not an object");
    }

    chain = newAV();
    av = (AV*)SvRV(ST(0));

    /*
     # uncoverable branch true count:2
     # uncoverable condition right count:1 */
    while (av && depth < MAX_PROTOTYPE_DEPTH) {
        SV **proto_svp;

        /* Check for circular reference */
        for (i = 0; i < depth; i++) {
            if (visited[i] == av) {
                goto done;  /* Cycle detected, stop */
            }
        }
        visited[depth] = av;

        /* Add this object to the chain */
        av_push(chain, newRV_inc((SV*)av));

        /* Follow prototype */
        proto_svp = av_fetch(av, 0, 0);
        /*
         # uncoverable branch true count:1 class:ignore_covered_err
         # uncoverable condition left count:1 */
        if (!proto_svp || !SvROK(*proto_svp) || SvTYPE(SvRV(*proto_svp)) != SVt_PVAV) {
            break;
        }
        av = (AV*)SvRV(*proto_svp);
        depth++;
    }

done:
    ST(0) = sv_2mortal(newRV_noinc((SV*)chain));
    XSRETURN(1);
}

/* Check if object has a property in its own slots (not prototype) */
XS_INTERNAL(xs_has_own_property) {
    dXSARGS;
    AV *av;
    SV **svp;
    const char *class_name;
    STRLEN class_len;
    ClassMeta *meta;
    const char *prop_name;
    STRLEN prop_len;
    SV **idx_sv;

    if (items < 2) croak("Usage: Object::Proto::has_own_property($obj, $property)");

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("Not an object");
    }

    av = (AV*)SvRV(ST(0));
    class_name = sv_reftype(SvRV(ST(0)), TRUE);
    class_len = strlen(class_name);

    meta = get_class_meta(aTHX_ class_name, class_len);
    if (!meta) {
        XSRETURN_NO;
    }

    prop_name = SvPV(ST(1), prop_len);
    idx_sv = hv_fetch(meta->prop_to_idx, prop_name, prop_len, 0);
    if (!idx_sv) {
        XSRETURN_NO;
    }

    /* Check if this slot has a defined value */
    svp = av_fetch(av, SvIV(*idx_sv), 0);
    if (svp && SvOK(*svp)) {
        XSRETURN_YES;
    }
    XSRETURN_NO;
}

/* Get the prototype depth (number of prototypes in chain) */
XS_INTERNAL(xs_prototype_depth) {
    dXSARGS;
    AV *av;
    AV *visited[MAX_PROTOTYPE_DEPTH];
    int depth = 0;
    int i;

    if (items < 1) croak("Usage: Object::Proto::prototype_depth($obj)");

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV) {
        croak("Not an object");
    }

    av = (AV*)SvRV(ST(0));

    /*
     # uncoverable branch true count:2
     # uncoverable condition right count:1 */
    while (av && depth < MAX_PROTOTYPE_DEPTH) {
        SV **proto_svp;

        /* Check for circular reference */
        for (i = 0; i < depth; i++) {
            if (visited[i] == av) {
                goto done;
            }
        }
        visited[depth] = av;

        proto_svp = av_fetch(av, 0, 0);
        /*
         # uncoverable branch true count:1 class:ignore_covered_err
         # uncoverable condition left count:1 */
        if (!proto_svp || !SvROK(*proto_svp) || SvTYPE(SvRV(*proto_svp)) != SVt_PVAV) {
            break;
        }
        av = (AV*)SvRV(*proto_svp);
        depth++;
    }

done:
    XSRETURN_IV(depth);
}

XS_INTERNAL(xs_lock) {
    dXSARGS;
    MAGIC *mg;
    
    if (items < 1) croak("Usage: Object::Proto::lock($obj)");
    VALIDATE_OBJECT(ST(0), "Object::Proto::lock");
    
    mg = get_object_magic(aTHX_ ST(0));
    if (!mg) mg = add_object_magic(aTHX_ ST(0));
    if (mg->mg_private & OBJ_FLAG_FROZEN) {
        croak("Object is frozen");
    }
    mg->mg_private |= OBJ_FLAG_LOCKED;
    XSRETURN_EMPTY;
}

XS_INTERNAL(xs_unlock) {
    dXSARGS;
    MAGIC *mg;
    
    if (items < 1) croak("Usage: Object::Proto::unlock($obj)");
    VALIDATE_OBJECT(ST(0), "Object::Proto::unlock");
    
    mg = get_object_magic(aTHX_ ST(0));
    if (mg) {
        if (mg->mg_private & OBJ_FLAG_FROZEN) {
            croak("Cannot unlock frozen object");
        }
        mg->mg_private &= ~OBJ_FLAG_LOCKED;
    }
    XSRETURN_EMPTY;
}

XS_INTERNAL(xs_freeze) {
    dXSARGS;
    MAGIC *mg;
    
    if (items < 1) croak("Usage: Object::Proto::freeze($obj)");
    VALIDATE_OBJECT(ST(0), "Object::Proto::freeze");
    
    mg = get_object_magic(aTHX_ ST(0));
    if (!mg) mg = add_object_magic(aTHX_ ST(0));
    mg->mg_private |= (OBJ_FLAG_FROZEN | OBJ_FLAG_LOCKED);
    XSRETURN_EMPTY;
}

XS_INTERNAL(xs_is_frozen) {
    dXSARGS;
    MAGIC *mg;
    
    if (items < 1) croak("Usage: Object::Proto::is_frozen($obj)");
    VALIDATE_OBJECT(ST(0), "Object::Proto::is_frozen");
    
    mg = get_object_magic(aTHX_ ST(0));
    if (mg && (mg->mg_private & OBJ_FLAG_FROZEN)) {
        XSRETURN_YES;
    }
    XSRETURN_NO;
}

XS_INTERNAL(xs_is_locked) {
    dXSARGS;
    MAGIC *mg;

    if (items < 1) croak("Usage: Object::Proto::is_locked($obj)");
    VALIDATE_OBJECT(ST(0), "Object::Proto::is_locked");

    mg = get_object_magic(aTHX_ ST(0));
    if (mg && (mg->mg_private & OBJ_FLAG_LOCKED)) {
        XSRETURN_YES;
    }
    XSRETURN_NO;
}

/* ============================================
   Introspection API
   ============================================ */

/* Deep clone an SV, recursing into refs.
 * seen_hv maps refaddr strings -> cloned SV* (handles circular refs).
 * Returns a mortal SV. */
static SV* deep_clone_sv(pTHX_ SV *src, HV *seen_hv) {
    SV *dst;
    char addr_buf[32];
    STRLEN addr_len;
    SV **cached;

    /* Non-references: return a plain copy */
    if (!SvROK(src)) {
        return newSVsv(src);
    }

    /* Check seen table to break circular references */
    addr_len = (STRLEN)sprintf(addr_buf, "%p", (void*)SvRV(src));
    cached = hv_fetch(seen_hv, addr_buf, (I32)addr_len, 0);
    if (cached) {
        return SvREFCNT_inc(*cached);
    }

    if (SvTYPE(SvRV(src)) == SVt_PVAV) {
        /* Array ref (possibly blessed) */
        AV *src_av = (AV*)SvRV(src);
        AV *dst_av = newAV();
        IV i, len = av_len(src_av);

        dst = newRV_noinc((SV*)dst_av);
        if (SvOBJECT(SvRV(src)))
            sv_bless(dst, SvSTASH(SvRV(src)));

        /* Register before recursing to handle circular refs */
        hv_store(seen_hv, addr_buf, (I32)addr_len, SvREFCNT_inc(dst), 0);

        av_extend(dst_av, len);
        for (i = 0; i <= len; i++) {
            SV **svp = av_fetch(src_av, i, 0);
            if (svp && SvOK(*svp)) {
                SV *child = deep_clone_sv(aTHX_ *svp, seen_hv);
                av_store(dst_av, i, child);
            } else {
                av_store(dst_av, i, newSV(0));
            }
        }

    } else if (SvTYPE(SvRV(src)) == SVt_PVHV) {
        /* Hash ref (possibly blessed) */
        HV *src_hv = (HV*)SvRV(src);
        HV *dst_hv = newHV();
        HE *he;

        dst = newRV_noinc((SV*)dst_hv);
        if (SvOBJECT(SvRV(src)))
            sv_bless(dst, SvSTASH(SvRV(src)));

        hv_store(seen_hv, addr_buf, (I32)addr_len, SvREFCNT_inc(dst), 0);

        hv_iterinit(src_hv);
        while ((he = hv_iternext(src_hv))) {
            STRLEN klen;
            const char *key = HePV(he, klen);
            SV *val  = HeVAL(he);
            SV *copy = deep_clone_sv(aTHX_ val, seen_hv);
            hv_store(dst_hv, key, (I32)klen, copy, 0);
        }

    } else if (SvTYPE(SvRV(src)) < SVt_PVAV) {
        /* Scalar ref */
        SV *inner = deep_clone_sv(aTHX_ SvRV(src), seen_hv);
        dst = newRV_noinc(inner);
        if (SvOBJECT(SvRV(src)))
            sv_bless(dst, SvSTASH(SvRV(src)));
        hv_store(seen_hv, addr_buf, (I32)addr_len, SvREFCNT_inc(dst), 0);

    } else {
        /* Code refs, globs, etc. — share as-is */
        dst = newSVsv(src);
        hv_store(seen_hv, addr_buf, (I32)addr_len, SvREFCNT_inc(dst), 0);
    }

    return dst;
}

/* Object::Proto::clone($obj) - deep clone an object, arrayref, hashref,
 * scalarref, or plain scalar */
XS_INTERNAL(xs_clone) {
    dXSARGS;
    SV *src;

    if (items < 1) croak("Usage: Object::Proto::clone($val) or $obj->clone()");

    src = ST(0);

    /* Plain scalar (non-ref): return a copy of the value */
    if (!SvROK(src)) {
        if (SvOK(src)) {
            ST(0) = sv_2mortal(newSVsv(src));
        } else {
            ST(0) = &PL_sv_undef;
        }
        XSRETURN(1);
    }

    {
        HV *seen_hv = newHV();
        SV *dst;

        /* For blessed objects backed by an AV: strip frozen/locked magic
         * by cloning the underlying AV fresh (deep_clone_sv handles the
         * bless but the new ref carries no Object::Proto magic). */
        dst = deep_clone_sv(aTHX_ src, seen_hv);
        SvREFCNT_dec((SV*)seen_hv);

        ST(0) = sv_2mortal(dst);
        XSRETURN(1);
    }
}

/* Object::Proto::properties($class) - return property names for a class */
XS_INTERNAL(xs_properties) {
    dXSARGS;
    STRLEN class_len;
    const char *class_pv;
    ClassMeta *meta;
    IV i;

    if (items < 1) croak("Usage: Object::Proto::properties($class)");

    class_pv = SvPV(ST(0), class_len);

    meta = get_class_meta(aTHX_ class_pv, class_len);
    if (!meta) {
        /* Non-existent class: return empty list / 0 */
        if (GIMME_V == G_ARRAY) {
            XSRETURN_EMPTY;
        } else {
            XSRETURN_IV(0);
        }
    }

    if (GIMME_V == G_ARRAY) {
        /* List context: return property names */
        IV count = meta->slot_count - 1;  /* -1 because slot 0 is prototype */
        SP -= items;
        EXTEND(SP, count);

        for (i = 1; i < meta->slot_count; i++) {
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            if (meta->idx_to_prop[i]) {
                PUSHs(sv_2mortal(newSVpv(meta->idx_to_prop[i], 0)));
            }
        }
        XSRETURN(count);
    } else {
        /* Scalar context: return count */
        XSRETURN_IV(meta->slot_count - 1);
    }
}

/* Object::Proto::slot_info($class, $property) - return hashref with slot metadata */
XS_INTERNAL(xs_slot_info) {
    dXSARGS;
    STRLEN class_len, prop_len;
    const char *class_pv, *prop_pv;
    ClassMeta *meta;
    SV **idx_svp;
    IV idx;
    SlotSpec *spec;
    HV *info;

    if (items < 2) croak("Usage: Object::Proto::slot_info($class, $property)");

    class_pv = SvPV(ST(0), class_len);
    prop_pv = SvPV(ST(1), prop_len);

    /* Look up class meta */
    meta = get_class_meta(aTHX_ class_pv, class_len);
    if (!meta) {
        XSRETURN_UNDEF;
    }

    /* Look up property index - O(1) hash lookup */
    idx_svp = hv_fetch(meta->prop_to_idx, prop_pv, prop_len, 0);
    if (!idx_svp) {
        XSRETURN_UNDEF;
    }
    idx = SvIV(*idx_svp);

    /* Build result hashref */
    info = newHV();

    /* Basic info always present */
    hv_store(info, "name", 4, newSVpv(prop_pv, prop_len), 0);
    hv_store(info, "index", 5, newSViv(idx), 0);

    /* Get slot spec if available */
    /*
     # uncoverable condition right count:1
     # uncoverable condition right count:2 */
    spec = (meta->slots && idx < meta->slot_count) ? meta->slots[idx] : NULL;

    if (spec && spec->has_type) { /* # uncoverable condition right count:1 */
        const char *type_name;
        if (spec->type_id == TYPE_CUSTOM && spec->registered) { /* # uncoverable condition right count:2 */
            type_name = spec->registered->name;
        } else {
            type_name = type_id_to_name(spec->type_id);
        }
        hv_store(info, "type", 4, newSVpv(type_name, 0), 0);
    }

    /* Boolean flags */
    hv_store(info, "is_required", 11, newSViv(spec ? spec->is_required : 0), 0); /* # uncoverable condition right count:1 */
    hv_store(info, "is_readonly", 11, newSViv(spec ? spec->is_readonly : 0), 0); /* # uncoverable condition right count:1 */
    hv_store(info, "is_lazy", 7, newSViv(spec ? spec->is_lazy : 0), 0); /* # uncoverable condition right count:1 */
    hv_store(info, "is_weak", 7, newSViv(spec ? spec->is_weak : 0), 0); /* # uncoverable condition right count:1 */
    hv_store(info, "has_default", 11, newSViv(spec ? spec->has_default : 0), 0); /* # uncoverable condition right count:1 */
    hv_store(info, "has_trigger", 11, newSViv(spec ? spec->has_trigger : 0), 0); /* # uncoverable condition right count:1 */
    hv_store(info, "has_coerce", 10, newSViv(spec ? spec->has_coerce : 0), 0); /* # uncoverable condition right count:1 */
    hv_store(info, "has_builder", 11, newSViv(spec ? spec->has_builder : 0), 0); /* # uncoverable condition right count:1 */
    hv_store(info, "has_clearer", 11, newSViv(spec ? spec->has_clearer : 0), 0); /* # uncoverable condition right count:1 */
    hv_store(info, "has_predicate", 13, newSViv(spec ? spec->has_predicate : 0), 0); /* # uncoverable condition right count:1 */
    hv_store(info, "has_type", 8, newSViv(spec ? spec->has_type : 0), 0); /* # uncoverable condition right count:1 */

    /* Default value (if present) */
    if (spec && spec->has_default && spec->default_sv) { /* # uncoverable condition right count:1 */
        hv_store(info, "default", 7, newSVsv(spec->default_sv), 0);
    }

    /* Builder method name */
    /*
     # uncoverable condition right count:1
     # uncoverable condition right count:3 */
    if (spec && spec->has_builder && spec->builder_name) {
        hv_store(info, "builder", 7, newSVsv(spec->builder_name), 0);
    }

    /* init_arg (if specified) */
    if (spec && spec->init_arg) { /* # uncoverable condition right count:1 */
        hv_store(info, "init_arg", 8, newSVsv(spec->init_arg), 0);
    }

    /* handles, and the default they added. Every slot of a defined class has
     * its spec, so spec needs no test here. */
    hv_store(info, "has_handles", 11, newSViv(spec->has_handles), 0);
    if (spec->default_implicit) {
        hv_store(info, "default_implicit", 16, newSViv(1), 0);
    }
    if (spec->has_handles) {
        HV *handles = newHV();
        IV h;
        for (h = 0; h < spec->resolved_count; h++) {
            (void)hv_store_ent(handles, spec->resolved[h].local, newSVsv(spec->resolved[h].remote), 0);
        }
        hv_store(info, "handles", 7, newRV_noinc((SV*)handles), 0);
    }

    ST(0) = sv_2mortal(newRV_noinc((SV*)info));
    XSRETURN(1);
}

/* Object::Proto::parent($class) - return parent class name or undef */
XS_INTERNAL(xs_parent) {
    dXSARGS;
    STRLEN class_len;
    const char *class_pv;
    ClassMeta *meta;

    if (items < 1) croak("Usage: Object::Proto::parent($class)");

    class_pv = SvPV(ST(0), class_len);
    meta = get_class_meta(aTHX_ class_pv, class_len);

    if (!meta || meta->parent_count == 0) {
        if (GIMME_V == G_ARRAY) {
            XSRETURN_EMPTY;
        }
        XSRETURN_UNDEF;
    }

    if (GIMME_V == G_ARRAY) {
        /* List context: return all parents */
        IV i;
        SP -= items;
        EXTEND(SP, meta->parent_count);
        for (i = 0; i < meta->parent_count; i++) {
            PUSHs(sv_2mortal(newSVpv(meta->parent_classes[i], 0)));
        }
        XSRETURN(meta->parent_count);
    } else {
        /* Scalar context: return first parent */
        ST(0) = sv_2mortal(newSVpv(meta->parent_classes[0], 0));
        XSRETURN(1);
    }
}

/* Object::Proto::ancestors($class) - return list of all ancestor class names (breadth-first) */
XS_INTERNAL(xs_ancestors) {
    dXSARGS;
    STRLEN class_len;
    const char *class_pv;
    ClassMeta *meta;
    AV *result;
    HV *seen;
    AV *queue;
    IV count = 0;

    if (items < 1) croak("Usage: Object::Proto::ancestors($class)");

    class_pv = SvPV(ST(0), class_len);
    meta = get_class_meta(aTHX_ class_pv, class_len);

    SP -= items;

    if (meta && meta->parent_count > 0) {
        IV i;
        result = newAV();
        seen = newHV();
        queue = newAV();

        /* Seed queue with direct parents */
        for (i = 0; i < meta->parent_count; i++) {
            av_push(queue, newSVpv(meta->parent_metas[i]->class_name, 0));
        }

        /* BFS traversal */
        while (av_len(queue) >= 0) {
            SV *cur_sv = av_shift(queue);
            STRLEN cur_len;
            const char *cur_name = SvPV(cur_sv, cur_len);
            ClassMeta *cur_meta;

            /* Skip if already seen */
            if (hv_exists(seen, cur_name, cur_len)) {
                SvREFCNT_dec(cur_sv);
                continue;
            }
            hv_store(seen, cur_name, cur_len, &PL_sv_yes, 0);
            av_push(result, cur_sv);

            /* Enqueue this class's parents */
            cur_meta = get_class_meta(aTHX_ cur_name, cur_len);
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            if (cur_meta) {
                for (i = 0; i < cur_meta->parent_count; i++) {
                    const char *pname = cur_meta->parent_classes[i];
                    if (!hv_exists(seen, pname, strlen(pname))) {
                        av_push(queue, newSVpv(pname, 0));
                    }
                }
            }
        }

        count = av_len(result) + 1;
        EXTEND(SP, count);
        for (i = 0; i < count; i++) {
            SV **elem = av_fetch(result, i, 0);
            /*
             # uncoverable branch false
             # uncoverable condition right count:1 */
            if (elem) PUSHs(sv_2mortal(newSVsv(*elem)));
        }

        SvREFCNT_dec((SV*)result);
        SvREFCNT_dec((SV*)seen);
        SvREFCNT_dec((SV*)queue);
    }

    XSRETURN(count);
}

/* ============================================
   Global cleanup
   ============================================ */

/* Cleanup during global destruction */
static void object_cleanup_globals(pTHX_ void *data) {
    PERL_UNUSED_ARG(data);

    /* During global destruction, just NULL out pointers.
     * Perl handles SV cleanup. Trying to free them ourselves
     * can cause crashes due to destruction order. */
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (PL_dirty) {
        g_type_registry = NULL;
        g_class_registry = NULL;
        g_func_accessor_registry = NULL;
        return;
    }

    /* Normal cleanup - not during global destruction */
    /* Note: Full cleanup omitted for simplicity; Perl handles SV refcounts */
    g_type_registry = NULL; /* # uncoverable statement */
    g_class_registry = NULL; /* # uncoverable statement */
    g_func_accessor_registry = NULL; /* # uncoverable statement */
}

/* ============================================
   Type Registry API
   ============================================ */

/* C-level registration for external XS modules (called from BOOT)
   This is the fast path - no Perl callback overhead */
OBJECT_API void object_register_type_xs(pTHX_ const char *name, 
                                           ObjectTypeCheckFunc check,
                                           ObjectTypeCoerceFunc coerce) {
    RegisteredType *type;
    STRLEN name_len = strlen(name);
    
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!g_type_registry) {
        g_type_registry = newHV(); /* # uncoverable statement */
    }
    
    /* Check if already registered */
    SV **existing = hv_fetch(g_type_registry, name, name_len, 0);
    if (existing) {
        croak("Type '%s' is already registered", name);
    }
    
    Newxz(type, 1, RegisteredType);
    Newx(type->name, name_len + 1, char);
    Copy(name, type->name, name_len, char);
    type->name[name_len] = '\0';
    
    type->check = check;    /* Direct C function pointer - no Perl overhead */
    type->coerce = coerce;  /* Direct C function pointer - no Perl overhead */
    type->perl_check = NULL;
    type->perl_coerce = NULL;
    type->check_ex = NULL;
    type->coerce_ex = NULL;
    type->data = NULL;
    
    hv_store(g_type_registry, name, name_len, newSViv(PTR2IV(type)), 0);
}

/* C-level registration with user-data for external XS modules (called from BOOT)
   Allows a single pair of C functions to serve multiple dynamically-created types */
OBJECT_API void object_register_type_xs_ex(pTHX_ const char *name,
                                              ObjectTypeCheckFuncEx check,
                                              ObjectTypeCoerceFuncEx coerce,
                                              void *data) {
    RegisteredType *type;
    STRLEN name_len = strlen(name);
    
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!g_type_registry) {
        g_type_registry = newHV(); /* # uncoverable statement */
    }
    
    SV **existing = hv_fetch(g_type_registry, name, name_len, 0);
    if (existing) {
        croak("Type '%s' is already registered", name);
    }
    
    Newxz(type, 1, RegisteredType);
    Newx(type->name, name_len + 1, char);
    Copy(name, type->name, name_len, char);
    type->name[name_len] = '\0';
    
    type->check = NULL;
    type->coerce = NULL;
    type->perl_check = NULL;
    type->perl_coerce = NULL;
    type->check_ex = check;
    type->coerce_ex = coerce;
    type->data = data;
    
    hv_store(g_type_registry, name, name_len, newSViv(PTR2IV(type)), 0);
}

/* Getter for external modules to look up a registered type */
OBJECT_API RegisteredType* object_get_registered_type(pTHX_ const char *name) {
    STRLEN name_len = strlen(name);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!g_type_registry) return NULL;
    
    SV **svp = hv_fetch(g_type_registry, name, name_len, 0);
    if (svp && SvIOK(*svp)) { /* # uncoverable condition right count:2 */
        return INT2PTR(RegisteredType*, SvIV(*svp));
    }
    return NULL;
}

/* Object::Proto::register_type($name, $check_cb [, $coerce_cb]) */
/* Object::Proto::register_simple_custom_op($xop_name) - let a custom op from
 * another module be used as an accessor operand without deoptimising the call.
 * The op must be free of side effects and leave exactly one value on the
 * stack; nothing here can check that, so registering is a promise. */
XS_INTERNAL(xs_register_simple_custom_op) {
    dXSARGS;
    STRLEN len;
    const char *name;
    int i;

    if (items != 1)
        croak("Usage: Object::Proto::register_simple_custom_op($xop_name)");

    name = SvPV(ST(0), len);
    if (!len)
        croak("register_simple_custom_op: name must not be empty");

    for (i = 0; i < g_simple_custom_op_count; i++) {
        if (strEQ(name, g_simple_custom_ops[i]))
            XSRETURN_YES;   /* already registered */
    }

    if (g_simple_custom_op_count >= OBJECT_MAX_SIMPLE_CUSTOM)
        croak("register_simple_custom_op: registry is full (max %d)",
              OBJECT_MAX_SIMPLE_CUSTOM);

    g_simple_custom_ops[g_simple_custom_op_count++] = savepvn(name, len);
    XSRETURN_YES;
}

XS_INTERNAL(xs_register_type) {
    dXSARGS;
    STRLEN name_len;
    const char *name;
    RegisteredType *type;
    
    if (items < 2) croak("Usage: Object::Proto::register_type($name, $check_cb [, $coerce_cb])");
    
    name = SvPV(ST(0), name_len);
    
    /* Check if already registered */
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (g_type_registry) {
        SV **existing = hv_fetch(g_type_registry, name, name_len, 0);
        if (existing) {
            croak("Type '%s' is already registered", name);
        }
    } else {
        g_type_registry = newHV(); /* # uncoverable statement */
    }
    
    Newxz(type, 1, RegisteredType);
    Newx(type->name, name_len + 1, char);
    Copy(name, type->name, name_len, char);
    type->name[name_len] = '\0';
    
    /* Store Perl check callback */
    type->perl_check = newSVsv(ST(1));
    SvREFCNT_inc(type->perl_check);
    
    /* Store Perl coerce callback if provided */
    if (items > 2 && SvOK(ST(2))) {
        type->perl_coerce = newSVsv(ST(2));
        SvREFCNT_inc(type->perl_coerce);
    }
    
    hv_store(g_type_registry, name, name_len, newSViv(PTR2IV(type)), 0);
    
    XSRETURN_YES;
}

/* Object::Proto::has_type($name) - check if a type is registered */
XS_INTERNAL(xs_has_type) {
    dXSARGS;
    STRLEN name_len;
    const char *name;
    
    if (items < 1) croak("Usage: Object::Proto::has_type($name)");
    
    name = SvPV(ST(0), name_len);
    
    /* Check built-in types */
    BuiltinTypeID builtin = parse_builtin_type(name, name_len);
    if (builtin != TYPE_NONE) {
        XSRETURN_YES;
    }
    
    /* Check registry */
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (g_type_registry) {
        SV **existing = hv_fetch(g_type_registry, name, name_len, 0);
        if (existing) {
            XSRETURN_YES;
        }
    }
    
    XSRETURN_NO;
}

/* Object::Proto::list_types() - return list of registered type names */
XS_INTERNAL(xs_list_types) {
    dXSARGS;
    AV *result = newAV();
    
    PERL_UNUSED_ARG(items);
    
    /* Add built-in types */
    av_push(result, newSVpvs("Any"));
    av_push(result, newSVpvs("Defined"));
    av_push(result, newSVpvs("Str"));
    av_push(result, newSVpvs("Int"));
    av_push(result, newSVpvs("Num"));
    av_push(result, newSVpvs("Bool"));
    av_push(result, newSVpvs("ArrayRef"));
    av_push(result, newSVpvs("HashRef"));
    av_push(result, newSVpvs("CodeRef"));
    av_push(result, newSVpvs("Object"));
    av_push(result, newSVpvs("Ref"));
    av_push(result, newSVpvs("ScalarRef"));
    av_push(result, newSVpvs("RegexpRef"));
    av_push(result, newSVpvs("GlobRef"));
    av_push(result, newSVpvs("FileHandle"));
    av_push(result, newSVpvs("ClassName"));
    av_push(result, newSVpvs("PositiveInt"));
    av_push(result, newSVpvs("NegativeInt"));
    av_push(result, newSVpvs("NonEmptyStr"));
    av_push(result, newSVpvs("Undef"));
    
    /* Add registered types */
    /*
     # uncoverable branch false
     # uncoverable condition right count:1 */
    if (g_type_registry) {
        HE *he;
        hv_iterinit(g_type_registry);
        while ((he = hv_iternext(g_type_registry))) {
            /* A registered type that shadows a built-in is listed once */
            I32 key_len;
            const char *key = hv_iterkey(he, &key_len);
            if (parse_builtin_type(key, (STRLEN)key_len) != TYPE_NONE)
                continue;
            av_push(result, newSVsv(hv_iterkeysv(he)));
        }
    }
    
    ST(0) = newRV_noinc((SV*)result);
    sv_2mortal(ST(0));
    XSRETURN(1);
}

/* ============================================
   Singleton support
   ============================================ */

/* XS implementation of instance() method for singletons */
XS_INTERNAL(xs_singleton_instance) {
    dXSARGS;
    ClassMeta *meta = INT2PTR(ClassMeta*, CvXSUBANY(cv).any_iv);

    PERL_UNUSED_ARG(items);

    /*
     # uncoverable branch true
     # uncoverable condition left count:1 */
    if (!meta) {
        croak("Singleton metadata not found"); /* # uncoverable statement */
    }

    /* Return cached instance if it exists */
    if (meta->singleton_instance && SvOK(meta->singleton_instance)) { /* # uncoverable condition right count:2 */
        ST(0) = meta->singleton_instance;
        XSRETURN(1);
    }

    /* Create new instance */
    {
        dSP;
        int count;
        SV *obj;
        GV *build_gv;
        char full_build[256];

        ENTER;
        SAVETMPS;

        /* Call ClassName->new() */
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(meta->class_name, 0)));
        PUTBACK;

        count = call_method("new", G_SCALAR);

        SPAGAIN;

        /*
         # uncoverable branch true
         # uncoverable condition left count:1 */
        if (count != 1) {
            croak("Singleton new() did not return object"); /* # uncoverable statement */
        }

        obj = POPs;
        SvREFCNT_inc(obj);  /* Keep the object alive */

        PUTBACK;

        /* Check for BUILD method and call it */
        snprintf(full_build, sizeof(full_build), "%s::BUILD", meta->class_name);
        build_gv = gv_fetchpv(full_build, 0, SVt_PVCV);
        if (build_gv && GvCV(build_gv)) { /* # uncoverable condition right count:1 */
            PUSHMARK(SP);
            XPUSHs(obj);
            PUTBACK;
            call_method("BUILD", G_VOID | G_DISCARD);
        }

        /* Cache the instance */
        meta->singleton_instance = obj;

        FREETMPS;
        LEAVE;

        ST(0) = obj;
        XSRETURN(1);
    }
}

/* ============================================
   Role API
   ============================================ */

/* Object::Proto::role("RoleName", @slot_specs) - define a role */
XS_INTERNAL(xs_role) {
    dXSARGS;
    STRLEN role_len;
    const char *role_pv;
    RoleMeta *meta;
    IV i;
    
    if (items < 1) croak("Usage: Object::Proto::role($role_name, @slot_specs)");
    
    role_pv = SvPV(ST(0), role_len);
    
    /* Check if role already exists */
    meta = get_role_meta(aTHX_ role_pv, role_len);
    if (meta) {
        croak("Role '%s' already defined", role_pv);
    }
    
    /* Create role meta */
    Newxz(meta, 1, RoleMeta);
    Newxz(meta->role_name, role_len + 1, char);
    Copy(role_pv, meta->role_name, role_len, char);
    meta->role_name[role_len] = '\0';
    meta->stash = gv_stashpvn(role_pv, role_len, GV_ADD);
    
    /* Allocate slots array */
    if (items > 1) {
        Newx(meta->slots, items - 1, SlotSpec*);
        meta->slot_count = 0;
        
        for (i = 1; i < items; i++) {
            STRLEN spec_len;
            const char *spec_pv = SvPV(ST(i), spec_len);
            SlotSpec *spec = parse_slot_spec(aTHX_ spec_pv, spec_len);
            spec->private_owner = savepvn(role_pv, role_len);
            meta->slots[meta->slot_count++] = spec;
        }
    }
    
    register_role_meta(aTHX_ role_pv, role_len, meta);
    
    XSRETURN_EMPTY;
}

/* Object::Proto::requires("RoleName", @method_names) - declare required methods */
XS_INTERNAL(xs_requires) {
    dXSARGS;
    STRLEN role_len;
    const char *role_pv;
    RoleMeta *meta;
    IV i;
    
    if (items < 2) croak("Usage: Object::Proto::requires($role_name, @method_names)");
    
    role_pv = SvPV(ST(0), role_len);
    meta = get_role_meta(aTHX_ role_pv, role_len);
    if (!meta) {
        croak("Role '%s' not defined", role_pv);
    }
    
    /* Add required methods */
    Renew(meta->required_methods, meta->required_count + items - 1, char*);
    for (i = 1; i < items; i++) {
        STRLEN name_len;
        const char *name_pv = SvPV(ST(i), name_len);
        Newx(meta->required_methods[meta->required_count], name_len + 1, char);
        Copy(name_pv, meta->required_methods[meta->required_count], name_len, char);
        meta->required_methods[meta->required_count][name_len] = '\0';
        meta->required_count++;
    }
    
    XSRETURN_EMPTY;
}

/* Object::Proto::with("ClassName", @role_names) - apply roles to a class */
XS_INTERNAL(xs_with) {
    dXSARGS;
    STRLEN class_len;
    const char *class_pv;
    ClassMeta *class_meta;
    IV i;
    
    if (items < 2) croak("Usage: Object::Proto::with($class_name, @role_names)");
    
    class_pv = SvPV(ST(0), class_len);
    class_meta = get_class_meta(aTHX_ class_pv, class_len);
    if (!class_meta) {
        croak("Class '%s' not defined with Object::Proto::define", class_pv);
    }
    
    for (i = 1; i < items; i++) {
        STRLEN role_len;
        const char *role_pv = SvPV(ST(i), role_len);
        RoleMeta *role_meta = get_role_meta(aTHX_ role_pv, role_len);
        
        if (!role_meta) {
            /* Auto-load the role module */
            SV *module_sv = newSVpvn(role_pv, role_len);
            SV *err;
            load_module(PERL_LOADMOD_NOIMPORT, module_sv, NULL);
            err = ERRSV;
            /*
             # uncoverable branch true
             # uncoverable condition left count:1 */
            if (SvTRUE(err)) {
                croak("Role '%s' not defined (failed to load: %" SVf ")", role_pv, SVfARG(err)); /* # uncoverable statement */
            }
            role_meta = get_role_meta(aTHX_ role_pv, role_len);
        }
        if (!role_meta) {
            croak("Role '%s' not defined", role_pv);
        }
        
        apply_role_to_class(aTHX_ class_meta, role_meta);
    }
    
    XSRETURN_EMPTY;
}

/* Object::Proto::does("ClassName" or $obj, "RoleName") - check if class/object does role */
XS_INTERNAL(xs_does) {
    dXSARGS;
    ClassMeta *meta;
    STRLEN role_len;
    const char *role_pv;
    IV i;
    
    if (items < 2) croak("Usage: Object::Proto::does($class_or_obj, $role_name)");
    
    /* Get class meta from class name or object */
    if (SvROK(ST(0))) {
        /* Object - get stash name */
        HV *stash = SvSTASH(SvRV(ST(0)));
        meta = get_class_meta(aTHX_ HvNAME(stash), HvNAMELEN(stash));
    } else {
        STRLEN class_len;
        const char *class_pv = SvPV(ST(0), class_len);
        meta = get_class_meta(aTHX_ class_pv, class_len);
    }
    
    if (!meta) {
        XSRETURN_NO;
    }
    
    role_pv = SvPV(ST(1), role_len);
    
    /* Check if role is in consumed_roles */
    for (i = 0; i < meta->role_count; i++) {
        if (strEQ(meta->consumed_roles[i]->role_name, role_pv)) {
            XSRETURN_YES;
        }
    }
    
    XSRETURN_NO;
}

/* ============================================
   Method Modifier API
   ============================================ */

/* Object::Proto::before("Class::method", \&callback) */
XS_INTERNAL(xs_before) {
    dXSARGS;
    STRLEN full_name_len;
    const char *full_name;
    char *class_name, *method_name, *sep;
    ClassMeta *meta;
    
    if (items != 2) croak("Usage: Object::Proto::before('Class::method', \\&callback)");
    
    full_name = SvPV(ST(0), full_name_len);
    if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVCV) {
        croak("Second argument must be a code reference");
    }
    
    /* Parse "Class::method" */
    sep = strstr(full_name, "::");
    if (!sep) {
        croak("Method name must be fully qualified (Class::method)");
    }
    
    {
        STRLEN class_len = sep - full_name;
        Newx(class_name, class_len + 1, char);
        Copy(full_name, class_name, class_len, char);
        class_name[class_len] = '\0';
        method_name = sep + 2;
    }
    
    meta = get_class_meta(aTHX_ class_name, strlen(class_name));
    if (!meta) {
        Safefree(class_name);
        croak("Class '%.*s' not defined with Object::Proto::define", (int)(sep - full_name), full_name);
    }
    
    add_modifier(aTHX_ meta, method_name, ST(1), 0);  /* 0 = before */
    
    Safefree(class_name);
    XSRETURN_EMPTY;
}

/* Object::Proto::after("Class::method", \&callback) */
XS_INTERNAL(xs_after) {
    dXSARGS;
    STRLEN full_name_len;
    const char *full_name;
    char *class_name, *method_name, *sep;
    ClassMeta *meta;
    
    if (items != 2) croak("Usage: Object::Proto::after('Class::method', \\&callback)");
    
    full_name = SvPV(ST(0), full_name_len);
    if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVCV) {
        croak("Second argument must be a code reference");
    }
    
    sep = strstr(full_name, "::");
    if (!sep) {
        croak("Method name must be fully qualified (Class::method)");
    }
    
    {
        STRLEN class_len = sep - full_name;
        Newx(class_name, class_len + 1, char);
        Copy(full_name, class_name, class_len, char);
        class_name[class_len] = '\0';
        method_name = sep + 2;
    }
    
    meta = get_class_meta(aTHX_ class_name, strlen(class_name));
    if (!meta) {
        Safefree(class_name);
        croak("Class '%.*s' not defined with Object::Proto::define", (int)(sep - full_name), full_name);
    }
    
    add_modifier(aTHX_ meta, method_name, ST(1), 1);  /* 1 = after */
    
    Safefree(class_name);
    XSRETURN_EMPTY;
}

/* Object::Proto::around("Class::method", \&callback) */
XS_INTERNAL(xs_around) {
    dXSARGS;
    STRLEN full_name_len;
    const char *full_name;
    char *class_name, *method_name, *sep;
    ClassMeta *meta;
    
    if (items != 2) croak("Usage: Object::Proto::around('Class::method', \\&callback)");
    
    full_name = SvPV(ST(0), full_name_len);
    if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVCV) {
        croak("Second argument must be a code reference");
    }
    
    sep = strstr(full_name, "::");
    if (!sep) {
        croak("Method name must be fully qualified (Class::method)");
    }
    
    {
        STRLEN class_len = sep - full_name;
        Newx(class_name, class_len + 1, char);
        Copy(full_name, class_name, class_len, char);
        class_name[class_len] = '\0';
        method_name = sep + 2;
    }
    
    meta = get_class_meta(aTHX_ class_name, strlen(class_name));
    if (!meta) {
        Safefree(class_name);
        croak("Class '%.*s' not defined with Object::Proto::define", (int)(sep - full_name), full_name);
    }
    
    add_modifier(aTHX_ meta, method_name, ST(1), 2);  /* 2 = around */
    
    Safefree(class_name);
    XSRETURN_EMPTY;
}

/* Object::Proto::singleton("Class") - marks class as singleton and installs instance() method */
XS_INTERNAL(xs_singleton) {
    dXSARGS;
    STRLEN class_len;
    const char *class_pv;
    ClassMeta *meta;
    char full_name[256];
    CV *instance_cv;

    if (items < 1) croak("Usage: Object::Proto::singleton($class)");

    class_pv = SvPV(ST(0), class_len);

    meta = get_class_meta(aTHX_ class_pv, class_len);
    if (!meta) {
        croak("Class '%s' not defined with Object::Proto::define", class_pv);
    }

    /* Mark as singleton */
    meta->is_singleton = 1;
    meta->singleton_instance = NULL;

    /* Install instance() class method */
    snprintf(full_name, sizeof(full_name), "%s::instance", class_pv);
    instance_cv = newXS(full_name, xs_singleton_instance, __FILE__);
    CvXSUBANY(instance_cv).any_iv = PTR2IV(meta);

    XSRETURN_EMPTY;
}

/* ============================================
   Boot
   ============================================ */

XS_EXTERNAL(boot_Object__Proto) {
    dXSBOOTARGSXSAPIVERCHK;
    PERL_UNUSED_VAR(items);

    /* Register custom ops */
    XopENTRY_set(&object_get_xop, xop_name, "object_get");
    XopENTRY_set(&object_get_xop, xop_desc, "object property get");
    XopENTRY_set(&object_get_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_object_get, &object_get_xop);
    
    XopENTRY_set(&object_set_xop, xop_name, "object_set");
    XopENTRY_set(&object_set_xop, xop_desc, "object property set");
    XopENTRY_set(&object_set_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_object_set, &object_set_xop);

    XopENTRY_set(&object_set_typed_xop, xop_name, "object_set_typed");
    XopENTRY_set(&object_set_typed_xop, xop_desc, "object property set with type check");
    XopENTRY_set(&object_set_typed_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_object_set_typed, &object_set_typed_xop);

    XopENTRY_set(&object_func_get_xop, xop_name, "object_func_get");
    XopENTRY_set(&object_func_get_xop, xop_desc, "object function-style get");
    XopENTRY_set(&object_func_get_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_object_func_get, &object_func_get_xop);
    
    XopENTRY_set(&object_func_set_xop, xop_name, "object_func_set");
    XopENTRY_set(&object_func_set_xop, xop_desc, "object function-style set");
    XopENTRY_set(&object_func_set_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_object_func_set, &object_func_set_xop);

    /* Initialize registries */
    g_class_registry = newHV();
    g_type_registry = newHV();

    /* handles(...) lookups */
    {
        const char *const *r;
        g_reserved_methods = newHV();
        for (r = reserved_methods; *r; r++) {
            (void)hv_store(g_reserved_methods, *r, strlen(*r), &PL_sv_yes, 0);
        }
        g_array_op_index = build_op_index(aTHX_ array_ops);
        g_hash_op_index  = build_op_index(aTHX_ hash_ops);
    }

    /* Install XS functions */
    newXS("Object::Proto::import", xs_import, __FILE__);
    newXS("Object::Proto::define", xs_define, __FILE__);
    newXS("Object::Proto::import_accessors", xs_import_accessors, __FILE__);
    newXS("Object::Proto::import_accessor", xs_import_accessor, __FILE__);
    newXS("Object::Proto::prototype", xs_prototype, __FILE__);
    newXS("Object::Proto::set_prototype", xs_set_prototype, __FILE__);
    newXS("Object::Proto::prototype_chain", xs_prototype_chain, __FILE__);
    newXS("Object::Proto::has_own_property", xs_has_own_property, __FILE__);
    newXS("Object::Proto::prototype_depth", xs_prototype_depth, __FILE__);
    newXS("Object::Proto::lock", xs_lock, __FILE__);
    newXS("Object::Proto::unlock", xs_unlock, __FILE__);
    newXS("Object::Proto::freeze", xs_freeze, __FILE__);
    newXS("Object::Proto::is_frozen", xs_is_frozen, __FILE__);
    newXS("Object::Proto::is_locked", xs_is_locked, __FILE__);

    /* Introspection API */
    newXS("Object::Proto::clone", xs_clone, __FILE__);
    newXS("Object::Proto::properties", xs_properties, __FILE__);
    newXS("Object::Proto::slot_info", xs_slot_info, __FILE__);

    /* Inheritance API */
    newXS("Object::Proto::parent", xs_parent, __FILE__);
    newXS("Object::Proto::ancestors", xs_ancestors, __FILE__);

    /* Simple custom op registry */
    newXS("Object::Proto::register_simple_custom_op", xs_register_simple_custom_op, __FILE__);

    /* Type registry API */
    newXS("Object::Proto::register_type", xs_register_type, __FILE__);
    newXS("Object::Proto::has_type", xs_has_type, __FILE__);
    newXS("Object::Proto::list_types", xs_list_types, __FILE__);

    /* Singleton support */
    newXS("Object::Proto::singleton", xs_singleton, __FILE__);
    
    /* Role API */
    newXS("Object::Proto::role", xs_role, __FILE__);
    newXS("Object::Proto::requires", xs_requires, __FILE__);
    newXS("Object::Proto::with", xs_with, __FILE__);
    newXS("Object::Proto::does", xs_does, __FILE__);
    
    /* Method modifier API */
    newXS("Object::Proto::before", xs_before, __FILE__);
    newXS("Object::Proto::after", xs_after, __FILE__);
    newXS("Object::Proto::around", xs_around, __FILE__);

    /* Register cleanup for global destruction */
    Perl_call_atexit(aTHX_ object_cleanup_globals, NULL);

    OBJECT_PROTO_XS_BOOT_EPILOG(ax);
}
