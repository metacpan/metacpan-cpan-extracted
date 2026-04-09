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
    TYPE_CUSTOM       /* Uses registered or callback check */
} BuiltinTypeID;

/* Type check/coerce function signatures for external plugins */
typedef bool (*ObjectTypeCheckFunc)(pTHX_ SV *val);
typedef SV*  (*ObjectTypeCoerceFunc)(pTHX_ SV *val);

/* Registered type entry (for plugins) */
typedef struct {
    char *name;
    ObjectTypeCheckFunc check;      /* C function for type check */
    ObjectTypeCoerceFunc coerce;    /* C function for coercion */
    SV *perl_check;                 /* Fallback Perl callback */
    SV *perl_coerce;                /* Fallback Perl coercion */
} RegisteredType;

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
    U8 has_checks;                  /* is_readonly | is_required | has_coerce | TYPE_CUSTOM — skip block when 0 */
    SV *clearer_name;               /* Custom clearer method name */
    SV *predicate_name;             /* Custom predicate method name */
    SV *reader_name;                /* Custom reader method name (get_X style) */
    SV *writer_name;                /* Custom writer method name (set_X style) */
    SV *init_arg;                   /* Alternate constructor argument name */
} SlotSpec;

/* Custom op definitions */
static XOP object_new_xop;
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
XS_INTERNAL(xs_prototype);
XS_INTERNAL(xs_set_prototype);

/* ============================================
   Built-in type checking (inline)
   ============================================ */

OBJECT_INLINE BuiltinTypeID parse_builtin_type(const char *type_str, STRLEN len) {
    if (len == 3 && strEQ(type_str, "Str")) return TYPE_STR;
    if (len == 3 && strEQ(type_str, "Int")) return TYPE_INT;
    if (len == 3 && strEQ(type_str, "Num")) return TYPE_NUM;
    if (len == 3 && strEQ(type_str, "Any")) return TYPE_ANY;
    if (len == 4 && strEQ(type_str, "Bool")) return TYPE_BOOL;
    if (len == 6 && strEQ(type_str, "Object")) return TYPE_OBJECT;
    if (len == 7 && strEQ(type_str, "Defined")) return TYPE_DEFINED;
    if (len == 7 && strEQ(type_str, "CodeRef")) return TYPE_CODEREF;
    if (len == 7 && strEQ(type_str, "HashRef")) return TYPE_HASHREF;
    if (len == 8 && strEQ(type_str, "ArrayRef")) return TYPE_ARRAYREF;
    return TYPE_NONE;  /* Unknown - could be custom */
}

/* Inline type check - returns true if value passes check */
OBJECT_INLINE bool check_builtin_type(pTHX_ SV *val, BuiltinTypeID type_id) {
    switch (type_id) {
        case TYPE_ANY:
            return true;
        case TYPE_DEFINED:
            /* Be defensive: SvOK may not catch all defined values in older Perls */
            return SvOK(val) || SvIOK(val) || SvNOK(val) || SvPOK(val);
        case TYPE_STR:
            return SvOK(val) && !SvROK(val);  /* defined non-ref */
        case TYPE_INT:
            if (SvIOK(val)) return true;
            if (SvPOK(val)) {
                /* Use strtoll for fast integer parsing */
                STRLEN len;
                const char *pv = SvPV(val, len);
                char *endp;
                if (len == 0) return false;
                errno = 0;
                (void)strtoll(pv, &endp, 10);
                return errno == 0 && endp == pv + len && *pv != '\0';
            }
            return false;
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
                return errno == 0 && endp == pv + len && *pv != '\0';
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
        default:
            return true;  /* No check or unknown */
    }
}

/* Get type name for error messages */
static const char* type_id_to_name(BuiltinTypeID type_id) {
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
        case TYPE_CUSTOM: return "custom";
        default: return "unknown";
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
    /* C-registered type coercion (fast path) */
    if (spec->type_id == TYPE_CUSTOM && spec->registered && spec->registered->coerce) {
        val = spec->registered->coerce(aTHX_ val);
    }
    /* Perl-registered type coercion (from register_type) */
    if (spec->type_id == TYPE_CUSTOM && spec->registered && spec->registered->perl_coerce) {
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
    if (!spec || !spec->has_type) return true;
    
    if (spec->type_id != TYPE_CUSTOM) {
        return check_builtin_type(aTHX_ val, spec->type_id);
    }
    
    if (!spec->registered) return true;
    
    /* Try C function first (fast path - ~5 cycles) */
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

static SlotSpec* parse_slot_spec(pTHX_ const char *spec_str, STRLEN len) {
    SlotSpec *spec;
    const char *p = spec_str;
    const char *end = spec_str + len;
    const char *name_start, *name_end;
    STRLEN name_len;

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
            while (p < end && paren_depth > 0) {
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
            } else if (mod_len == 7 && strncmp(mod_start, "clearer", 7) == 0) {
                spec->has_clearer = 1;
                /* Default clearer name: clear_<property> */
            } else if (mod_len == 9 && strncmp(mod_start, "predicate", 9) == 0) {
                spec->has_predicate = 1;
                /* Default predicate name: has_<property> */
            } else {
                /* Try as type name */
                char *type_copy;
                BuiltinTypeID type_id;

                Newx(type_copy, mod_len + 1, char);
                Copy(mod_start, type_copy, mod_len, char);
                type_copy[mod_len] = '\0';

                type_id = parse_builtin_type(type_copy, mod_len);
                if (type_id != TYPE_NONE) {
                    spec->type_id = type_id;
                    spec->has_type = 1;
                } else {
                    /* Check type registry for custom types */
                    if (g_type_registry) {
                        SV **svp = hv_fetch(g_type_registry, type_copy, mod_len, 0);
                        if (svp) {
                            spec->registered = INT2PTR(RegisteredType*, SvIV(*svp));
                            spec->type_id = TYPE_CUSTOM;
                            spec->has_type = 1;
                        }
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
    if (!SvROK(obj)) return NULL;
    mg = mg_find(SvRV(obj), PERL_MAGIC_ext);
    while (mg) {
        if (mg->mg_virtual == &object_magic_vtbl) return mg;
        mg = mg->mg_moremagic;
    }
    return NULL;
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
    dst->has_default  = src->has_default;
    dst->has_trigger  = src->has_trigger;
    dst->has_coerce   = src->has_coerce;
    dst->has_type     = src->has_type;
    dst->has_builder  = src->has_builder;
    dst->has_clearer  = src->has_clearer;
    dst->has_predicate = src->has_predicate;

    if (src->default_sv)  dst->default_sv  = SvREFCNT_inc(src->default_sv);
    if (src->trigger_cb)  dst->trigger_cb  = SvREFCNT_inc(src->trigger_cb);
    if (src->coerce_cb)   dst->coerce_cb   = SvREFCNT_inc(src->coerce_cb);
    if (src->builder_name) dst->builder_name = SvREFCNT_inc(src->builder_name);
    if (src->clearer_name) dst->clearer_name = SvREFCNT_inc(src->clearer_name);
    if (src->predicate_name) dst->predicate_name = SvREFCNT_inc(src->predicate_name);
    if (src->reader_name) dst->reader_name = SvREFCNT_inc(src->reader_name);
    if (src->writer_name) dst->writer_name = SvREFCNT_inc(src->writer_name);
    if (src->init_arg) dst->init_arg = SvREFCNT_inc(src->init_arg);

    return dst;
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
        merged->builder_name = override->builder_name ? SvREFCNT_inc(override->builder_name) : NULL;
        merged->has_builder = 1;
    }
    
    /* Boolean flags - only set if explicitly enabled in override */
    if (override->is_required) merged->is_required = 1;
    if (override->is_readonly) merged->is_readonly = 1;
    if (override->is_lazy)     merged->is_lazy = 1;
    if (override->is_weak)     merged->is_weak = 1;
    
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
    
    /* Recompute has_checks flag */
    merged->has_checks = merged->is_readonly | merged->is_required | merged->has_coerce
                       | (merged->type_id == TYPE_CUSTOM ? 1 : 0);
    
    return merged;
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
    if (!g_class_registry) return NULL;
    svp = hv_fetch(g_class_registry, class_name, len, 0);
    if (svp && SvIOK(*svp)) {
        return INT2PTR(ClassMeta*, SvIV(*svp));
    }
    return NULL;
}

static void register_class_meta(pTHX_ const char *class_name, STRLEN len, ClassMeta *meta) {
    if (!g_class_registry) {
        g_class_registry = newHV();
    }
    hv_store(g_class_registry, class_name, len, newSViv(PTR2IV(meta)), 0);
}

/* ============================================
   Custom OP: object constructor
   ============================================ */

/* pp_object_new - create new object, class info in op_targ, args on stack */
static OP* pp_object_new(pTHX) {
    dSP; dMARK;
    IV items = SP - MARK;
    ClassMeta *meta = INT2PTR(ClassMeta*, PL_op->op_targ);
    AV *obj_av;
    SV *obj_sv;
    SV **ary;
    IV i;
    IV slot_count = meta->slot_count;
    U32 is_named = PL_op->op_private;  /* 1 = named pairs, 0 = positional */

    /* Create array with pre-extended size and get direct pointer */
    obj_av = newAV();
    av_extend(obj_av, slot_count - 1);
    AvFILLp(obj_av) = slot_count - 1;
    ary = AvARRAY(obj_av);

    /* Slot 0 = prototype (initially undef - read-only is fine, never written via setter) */
    ary[0] = &PL_sv_undef;

    if (is_named) {
        /* Fast path: no types, no defaults, no required */
        if (!meta->has_any_types && !meta->has_any_defaults && !meta->has_any_required) {
            /* Don't pre-fill slots - use newSVsv directly to avoid double-touch.
               Initialize ary to NULL, assign directly, then fill unfilled with newSV(0). */
            Zero(&ary[1], slot_count - 1, SV*);

            for (i = 0; i < items; i += 2) {
                SV *key_sv = MARK[i + 1];
                SV *val_sv = (i + 1 < items) ? MARK[i + 2] : &PL_sv_undef;
                STRLEN key_len;
                const char *key = SvPV(key_sv, key_len);
                SV **idx_svp = hv_fetch(meta->arg_to_idx, key, key_len, 0);
                if (idx_svp) {
                    IV idx = SvIVX(*idx_svp);
                    ary[idx] = newSVsv(val_sv);
                }
            }

            /* Fill remaining NULL slots with writable undef */
            for (i = 1; i < slot_count; i++) {
                if (!ary[i]) ary[i] = newSV(0);
            }
        } else {
            /* Slow path: has types/defaults/required
               Use NULL-init + direct newSVsv for provided slots to avoid double-touch */
            Zero(&ary[1], slot_count - 1, SV*);

            for (i = 0; i < items; i += 2) {
                SV *key_sv = MARK[i + 1];
                SV *val_sv = (i + 1 < items) ? MARK[i + 2] : &PL_sv_undef;
                STRLEN key_len;
                const char *key = SvPV(key_sv, key_len);
                SV **idx_svp = hv_fetch(meta->arg_to_idx, key, key_len, 0);
                if (idx_svp) {
                    IV idx = SvIVX(*idx_svp);

                    if (meta->has_any_types && meta->slots[idx] && meta->slots[idx]->has_type) {
                        SlotSpec *spec = meta->slots[idx];
                        if (spec->type_id != TYPE_CUSTOM) {
                            if (!check_builtin_type(aTHX_ val_sv, spec->type_id)) {
                                croak("Type constraint failed for '%s' in new(): expected %s",
                                      spec->name, type_id_to_name(spec->type_id));
                            }
                        } else if (spec->registered && spec->registered->check) {
                            if (!spec->registered->check(aTHX_ val_sv)) {
                                croak("Type constraint failed for '%s' in new(): expected %s",
                                      spec->name, spec->registered->name);
                            }
                        }
                    }
                    ary[idx] = newSVsv(val_sv);
                }
            }

            /* Fill defaults and check required; allocate undef for unfilled slots */
            for (i = 1; i < slot_count; i++) {
                if (!ary[i] || !SvOK(ary[i])) {
                    SlotSpec *spec = meta->slots[i];

                    if (spec && spec->is_required) {
                        croak("Required slot '%s' not provided in new()", spec->name);
                    }

                    if (spec && spec->has_default && spec->default_sv) {
                        if (SvROK(spec->default_sv)) {
                            if (ary[i]) SvREFCNT_dec(ary[i]);
                            if (SvTYPE(SvRV(spec->default_sv)) == SVt_PVAV) {
                                ary[i] = newRV_noinc((SV*)newAV());
                            } else if (SvTYPE(SvRV(spec->default_sv)) == SVt_PVHV) {
                                ary[i] = newRV_noinc((SV*)newHV());
                            } else {
                                ary[i] = newSVsv(spec->default_sv);
                            }
                        } else {
                            if (ary[i]) { sv_setsv(ary[i], spec->default_sv); }
                            else        { ary[i] = newSVsv(spec->default_sv); }
                        }
                    } else if (!ary[i]) {
                        ary[i] = newSV(0);
                    }
                }
            }
        }
    } else {
        /* Positional: value, value, value — newSVsv directly, no pre-fill needed */
        IV provided = items;
        if (provided > slot_count - 1) provided = slot_count - 1;

        if (!meta->has_any_types) {
            for (i = 0; i < provided; i++) {
                ary[i + 1] = newSVsv(MARK[i + 1]);
            }
        } else {
            for (i = 0; i < provided; i++) {
                IV idx = i + 1;
                SV *val_sv = MARK[i + 1];
                
                if (meta->slots[idx] && meta->slots[idx]->has_type) {
                    SlotSpec *spec = meta->slots[idx];
                    if (spec->type_id != TYPE_CUSTOM) {
                        if (!check_builtin_type(aTHX_ val_sv, spec->type_id)) {
                            croak("Type constraint failed for '%s' in new(): expected %s",
                                  spec->name, type_id_to_name(spec->type_id));
                        }
                    } else if (spec->registered && spec->registered->check) {
                        if (!spec->registered->check(aTHX_ val_sv)) {
                            croak("Type constraint failed for '%s' in new(): expected %s",
                                  spec->name, spec->registered->name);
                        }
                    }
                }
                ary[idx] = newSVsv(val_sv);
            }
        }

        /* Fill remaining empty slots with writable undef */
        for (i = provided + 1; i < slot_count; i++) {
            ary[i] = newSV(0);
        }

        /* Fill defaults/required for positional when class has them */
        if (meta->has_any_defaults || meta->has_any_required) {
            for (i = 1; i < slot_count; i++) {
                if (!SvOK(ary[i])) {
                    SlotSpec *spec = meta->slots[i];
                    
                    if (spec && spec->is_required) {
                        croak("Required slot '%s' not provided in new()", spec->name);
                    }
                    
                    if (spec && spec->has_default && spec->default_sv) {
                        if (SvROK(spec->default_sv)) {
                            if (SvTYPE(SvRV(spec->default_sv)) == SVt_PVAV) {
                                SvREFCNT_dec(ary[i]);
                                ary[i] = newRV_noinc((SV*)newAV());
                            } else if (SvTYPE(SvRV(spec->default_sv)) == SVt_PVHV) {
                                SvREFCNT_dec(ary[i]);
                                ary[i] = newRV_noinc((SV*)newHV());
                            } else {
                                sv_setsv(ary[i], spec->default_sv);
                            }
                        } else {
                            sv_setsv(ary[i], spec->default_sv);
                        }
                    }
                }
            }
        }
    }

    /* Create blessed reference */
    obj_sv = newRV_noinc((SV*)obj_av);
    sv_bless(obj_sv, meta->stash);

    /* Call builders for non-lazy builder slots that weren't set */
    if (meta->has_any_builders) {
        for (i = 1; i < slot_count; i++) {
            SlotSpec *spec = meta->slots[i];
            if (spec && spec->has_builder && !spec->is_lazy && !SvOK(ary[i])) {
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

    /* Weaken references if any slots have is_weak */
    if (meta->has_any_weak) {
        for (i = 1; i < slot_count; i++) {
            SlotSpec *spec = meta->slots[i];
            if (spec && spec->is_weak && SvROK(ary[i])) {
                sv_rvweaken(ary[i]);
            }
        }
    }

    /* Call BUILD if defined. Use tri-state: 0=unchecked, 1=has BUILD, 2=no BUILD.
       Avoids gv_fetchmeth on every construction once checked. */
    if (meta->has_build == 0) {
        GV *gv = gv_fetchmeth(meta->stash, "BUILD", 5, 0);
        if (gv && GvCV(gv)) {
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

    SP = MARK;
    XPUSHs(obj_sv);
    PUTBACK;
    return NORMAL;
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

    while (av && depth < MAX_PROTOTYPE_DEPTH) {
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
        if (proto_sv && SvROK(proto_sv) && SvTYPE(SvRV(proto_sv)) == SVt_PVAV) {
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
        if (slot) {
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
    IV registry_id;             /* ID in g_func_accessor_registry */
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
            if (slot) {
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
        
        /* Create binop with self and val */
        newop = newBINOP(OP_CUSTOM, 0, selfop, valop);
        newop->op_ppaddr = pp_object_set;
        newop->op_targ = idx;
        
        op_free(entersubop);
        return newop;
    } else {
        /* Getter: $obj->name */
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(selfop, NULL);
        
        newop = newUNOP(OP_CUSTOM, 0, selfop);
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
    if (items > 0 && SvPOK(ST(0)) && !SvROK(ST(0))) {
        /* The class name is always the first arg for Cat->new() or new Cat() style */
        start_arg = 1;
    }

    arg_count = items - start_arg;

    /* Detect named pairs: even count and first arg is a known property name or init_arg */
    if (arg_count > 0 && (arg_count % 2) == 0 && SvPOK(ST(start_arg))) {
        STRLEN len;
        const char *pv = SvPV(ST(start_arg), len);
        if (hv_exists(meta->prop_to_idx, pv, len) || hv_exists(meta->arg_to_idx, pv, len)) {
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
        if (spec && spec->has_default && spec->default_sv) {
            if (SvROK(spec->default_sv)) {
                if (SvTYPE(SvRV(spec->default_sv)) == SVt_PVAV) {
                    ary[i] = newRV_noinc((SV*)newAV());
                } else if (SvTYPE(SvRV(spec->default_sv)) == SVt_PVHV) {
                    ary[i] = newRV_noinc((SV*)newHV());
                } else {
                    ary[i] = newSVsv(spec->default_sv);
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
            SV *val_sv = (i + 1 < items) ? ST(i + 1) : &PL_sv_undef;
            STRLEN key_len;
            const char *key = SvPV(key_sv, key_len);
            SV **idx_svp = hv_fetch(meta->arg_to_idx, key, key_len, 0);
            if (idx_svp) {
                IV idx = SvIVX(*idx_svp);
                SlotSpec *spec = meta->slots[idx];
                
                /* Coerce + type check */
                if (spec && spec->has_type) {
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
                if (spec && spec->has_trigger && spec->trigger_cb) {
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
            if (spec && spec->has_type) {
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
            if (spec && spec->has_trigger && spec->trigger_cb) {
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
            if (spec && spec->has_builder && !spec->is_lazy && !SvOK(ary[i])) {
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
            if (spec && spec->is_required && !SvOK(ary[i])) {
                croak("Required slot '%s' not provided in new()", spec->name);
            }
        }
    }

    /* Weaken references if any slots have is_weak */
    if (meta->has_any_weak) {
        for (i = 1; i < slot_count; i++) {
            SlotSpec *spec = meta->slots[i];
            if (spec && spec->is_weak && SvROK(ary[i])) {
                sv_rvweaken(ary[i]);
            }
        }
    }

    /* Call BUILD if defined. Use tri-state: 0=unchecked, 1=has BUILD, 2=no BUILD.
       Avoids gv_fetchmeth on every construction once checked. */
    if (meta->has_build == 0) {
        GV *gv = gv_fetchmeth(meta->stash, "BUILD", 5, 0);
        if (gv && GvCV(gv)) {
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
            if (slot) {
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
    if (data->expected_class && SvSTASH(rv) != data->expected_class->stash) {
        croak("Expected object of class '%s', got '%s'",
              data->expected_class->class_name,
              HvNAME(SvSTASH(rv)));
    }

    /* Direct array access — no SvOK needed (func path has no prototype chain) */
    if (idx <= AvFILLp(av)) {
        sv = AvARRAY(av)[idx];
        if (sv) {
            SETs(sv);
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
    if (data->expected_class && SvSTASH(rv) != data->expected_class->stash) {
        croak("Expected object of class '%s', got '%s'",
              data->expected_class->class_name,
              HvNAME(SvSTASH(rv)));
    }

    /* In-place update if slot already has an SV (avoids alloc/dealloc) */
    if (idx <= AvFILLp(av)) {
        SV *slot = AvARRAY(av)[idx];
        if (slot) {
            sv_setsv(slot, val);
            SETs(val);
            RETURN;
        }
    }

    av_store(av, idx, newSVsv(val));
    SETs(val);  /* Replace object with value */
    RETURN;
}

/* Check if an op is "simple" (can be safely used in optimized accessor) */
OBJECT_INLINE bool is_simple_op(OP *op) {
    if (!op) return false;
    /* Simple ops: pad variables, constants, global variables */
    switch (op->op_type) {
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
    OP *pushop, *cvop, *objop, *argop, *valop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    if (!data) {
        return entersubop;  /* Fallback if data not found */
    }

    pushop = cUNOPx(entersubop)->op_first;
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
        if (valop && OpSIBLING(valop) == cvop &&
            is_simple_op(objop) && is_simple_op(valop)) {
            OpMORESIB_set(pushop, cvop);
            OpLASTSIB_set(valop, NULL);
            OpLASTSIB_set(objop, NULL);

            newop = newBINOP(OP_CUSTOM, 0, objop, valop);
            newop->op_ppaddr = pp_object_func_set;
            newop->op_targ = data->registry_id;

            op_free(entersubop);
            return newop;
        }

        /* Complex args - fall back to XS */
        return op_contextualize(entersubop, G_SCALAR);
    }

    /* Getter: name($obj) - optimize only if objop is simple */
    if (!is_simple_op(objop)) {
        return entersubop;
    }

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(objop, NULL);

    newop = newUNOP(OP_CUSTOM, 0, objop);
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

    if (!SvROK(obj) || SvTYPE(SvRV(obj)) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)SvRV(obj);

    /* Validate object is of expected class */
    if (data->expected_class && SvSTASH(SvRV(obj)) != data->expected_class->stash) {
        croak("Expected object of class '%s', got '%s'",
              data->expected_class->class_name,
              HvNAME(SvSTASH(SvRV(obj))));
    }

    if (items > 1) {
        /* In-place update if slot already has an SV */
        if (idx <= AvFILLp(av)) {
            SV *slot = AvARRAY(av)[idx];
            if (slot) {
                sv_setsv(slot, ST(1));
                ST(0) = ST(1);
                XSRETURN(1);
            }
        }
        av_store(av, idx, newSVsv(ST(1)));
        ST(0) = ST(1);
    } else {
        /* Direct array access */
        if (idx <= AvFILLp(av)) {
            SV *sv = AvARRAY(av)[idx];
            ST(0) = (sv && SvOK(sv)) ? sv : &PL_sv_undef;
        } else {
            ST(0) = &PL_sv_undef;
        }
    }
    XSRETURN(1);
}

/* Install function-style accessor in caller's namespace */
static void install_func_accessor(pTHX_ const char *pkg, const char *prop_name, IV idx, ClassMeta *expected_class, int force) {
    char full_name[256];
    CV *cv;
    SV *ckobj;
    FuncAccessorData *data;
    IV registry_id;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, prop_name);

    /* Check if this accessor already exists */
    cv = get_cvn_flags(full_name, strlen(full_name), 0);
    if (cv) {
        if (!force) {
            return;  /* Not forced: skip to preserve user-defined subs */
        }
        /* Forced (import_accessors/import_accessor): delete existing
         * to avoid "Subroutine redefined" warning from newXS. */
        {
            HV *stash = gv_stashpvn(pkg, strlen(pkg), 0);
            if (stash) {
                (void)hv_delete(stash, prop_name, strlen(prop_name), G_DISCARD);
            }
        }
    }

    /* Allocate data for this accessor and register it */
    Newx(data, 1, FuncAccessorData);
    data->slot_idx = idx;
    data->expected_class = expected_class;  /* NULL for same-class, set for cross-class */
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
    int is_same_class;

    if (items < 1) croak("Usage: Object::Proto::import_accessors($class [, $prefix [, $package]])");

    class_pv = SvPV(ST(0), class_len);

    /* Optional prefix (alias prepended to accessor names) */
    prefix_pv = NULL;
    prefix_len = 0;
    if (items > 1 && SvOK(ST(1))) {
        prefix_pv = SvPV(ST(1), prefix_len);
        if (prefix_len == 0) prefix_pv = NULL;
    }

    if (items > 2) {
        pkg_pv = SvPV(ST(2), pkg_len);
    } else {
        /* Default to caller's package */
        pkg_pv = CopSTASHPV(PL_curcop);
        pkg_len = strlen(pkg_pv);
    }

    meta = get_class_meta(aTHX_ class_pv, class_len);
    if (!meta) {
        croak("Class '%s' not defined with Object::Proto::define", class_pv);
    }

    /* Check if importing into same class (skip validation for performance) */
    is_same_class = (class_len == pkg_len && strEQ(class_pv, pkg_pv));

    /* Install function-style accessors for each property */
    for (i = 1; i < meta->slot_count; i++) {
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
                                  NULL, 1);  /* No class check, force override */
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
    int is_same_class;

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

    /* Check if importing into same class (skip validation for performance) */
    is_same_class = (class_len == pkg_len && strEQ(class_pv, pkg_pv));

    /* Install with alias name — no class check, work with any compatible object */
    install_func_accessor(aTHX_ pkg_pv, alias_pv, idx,
                          NULL, 1);  /* force override */

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

/* XS fallback accessor with type checking */
XS_INTERNAL(xs_accessor_typed_fallback) {
    dXSARGS;
    SlotOpData *data = INT2PTR(SlotOpData*, CvXSUBANY(cv).any_iv);
    IV idx = data->slot_idx;
    ClassMeta *meta = data->meta;
    SlotSpec *spec = meta->slots[idx];
    SV *self = ST(0);
    AV *av;

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
            SV *built_val = NULL;
            
            if (spec->has_builder && spec->builder_name) {
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
                if (count > 0) {
                    /* Copy the value BEFORE FREETMPS to avoid freed scalar issue */
                    built_val = newSVsv(POPs);
                } else {
                    built_val = newSV(0);  /* undef */
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
                    } else if (SvTYPE(inner) == SVt_PVHV) {
                        built_val = newRV_noinc((SV*)newHV());
                    } else {
                        built_val = newSVsv(spec->default_sv);
                    }
                } else {
                    built_val = newSVsv(spec->default_sv);
                }
            }
            
            if (built_val) {
                /* Type check the built value */
                if (spec->has_type && SvOK(built_val)) {
                    if (!check_slot_type(aTHX_ built_val, spec)) {
                        const char *type_name = (spec->type_id == TYPE_CUSTOM && spec->registered)
                            ? spec->registered->name
                            : type_id_to_name(spec->type_id);
                        croak("Type constraint failed for lazy '%s': expected %s",
                              spec->name, type_name);
                    }
                }
                
                /* Store the built value - built_val already has correct refcount from newSVsv */
                av_store(av, idx, built_val);
                result = built_val;
            }
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

    pushop = cUNOPx(entersubop)->op_first;
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
        
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(valop, NULL);
        OpLASTSIB_set(selfop, NULL);
        
        newop = newBINOP(OP_CUSTOM, 0, selfop, valop);
        newop->op_ppaddr = pp_object_set_typed;
        newop->op_targ = PTR2IV(data);
        
        op_free(entersubop);
        return newop;
    } else {
        /* Getter: $obj->name - plain getter (no type check needed) */
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(selfop, NULL);
        
        newop = newUNOP(OP_CUSTOM, 0, selfop);
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

    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV) {
        croak("Not an object");
    }
    av = (AV*)SvRV(self);

    /* Handle lazy builder */
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
                    
                    sv_setsv(AvARRAY(av)[idx], built_val);
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
    if (spec && spec->is_readonly) {
        croak("Cannot modify readonly slot '%s'", spec->name);
    }

    {
        SV *val = ST(1);
        
        /* Required fields cannot be set to undef */
        if (spec && spec->is_required && !SvOK(val)) {
            croak("Cannot set required slot '%s' to undef", spec->name);
        }
        
        /* Coerce + type check */
        if (spec && spec->has_type) {
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
        if (spec && spec->has_trigger && spec->trigger_cb) {
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
            if (slot) {
                sv_setsv(slot, val);
                /* Weaken reference if is_weak flag is set */
                if (spec && spec->is_weak && SvROK(slot)) {
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
            if (spec && spec->is_weak && SvROK(stored)) {
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

    /* Check if accessor already exists */
    cv = get_cvn_flags(full_name, strlen(full_name), 0);
    if (cv) {
        /* Update existing accessor's data (for +attr overrides) */
        data = INT2PTR(SlotOpData*, CvXSUBANY(cv).any_iv);
        if (data) {
            data->slot_idx = idx;
            data->meta = meta;
        }
        return;
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

    if (custom_name && SvOK(custom_name)) {
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

    if (custom_name && SvOK(custom_name)) {
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
        if (SvTRUE(ERRSV)) {
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
   Role Support (zero overhead if not used)
   ============================================ */

static RoleMeta* get_role_meta(pTHX_ const char *role_name, STRLEN len) {
    SV **svp;
    if (!g_role_registry) return NULL;
    svp = hv_fetch(g_role_registry, role_name, len, 0);
    if (svp && SvIOK(*svp)) {
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
    if (!from_gv || !(cv = GvCV(from_gv))) {
        return;  /* No such method in role */
    }
    
    /* Check if target already has this method */
    to_gv = gv_fetchmeth(to_stash, method_name, strlen(method_name), 0);
    if (to_gv && GvCV(to_gv)) {
        return;  /* Target already has method, don't override */
    }
    
    /* Install the CV in target stash */
    snprintf(full_name, sizeof(full_name), "%s::%s", HvNAME(to_stash), method_name);
    to_gv = gv_fetchpv(full_name, GV_ADD, SVt_PVCV);
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
        if (!gv || !GvCV(gv)) {
            croak("Class '%s' does not implement required method '%s' from role '%s'",
                  class_meta->class_name, required, role_meta->role_name);
        }
    }
    
    /* Copy role's slots to class */
    for (i = 0; i < role_meta->slot_count; i++) {
        SlotSpec *role_slot = role_meta->slots[i];
        IV new_idx;
        SV **existing;
        
        /* Check for slot name conflict */
        existing = hv_fetch(class_meta->prop_to_idx, role_slot->name, strlen(role_slot->name), 0);
        if (existing) {
            croak("Slot conflict: '%s' already exists in class '%s' (from role '%s')",
                  role_slot->name, class_meta->class_name, role_meta->role_name);
        }
        
        /* Add slot to class */
        new_idx = class_meta->slot_count++;
        Renew(class_meta->slots, class_meta->slot_count, SlotSpec*);
        Renew(class_meta->idx_to_prop, class_meta->slot_count, char*);
        
        /* Copy slot spec */
        class_meta->slots[new_idx] = role_slot;  /* Share the spec */
        class_meta->idx_to_prop[new_idx] = role_slot->name;
        hv_store(class_meta->prop_to_idx, role_slot->name, strlen(role_slot->name), 
                 newSViv(new_idx), 0);
        
        /* Add to arg_to_idx using init_arg if specified, otherwise property name */
        if (role_slot->init_arg) {
            STRLEN arg_len;
            const char *arg_name = SvPV(role_slot->init_arg, arg_len);
            hv_store(class_meta->arg_to_idx, arg_name, arg_len, newSViv(new_idx), 0);
        } else {
            hv_store(class_meta->arg_to_idx, role_slot->name, strlen(role_slot->name), 
                     newSViv(new_idx), 0);
        }
        
        /* Track class-level fast-path flags for role slots */
        if (role_slot->has_type) {
            class_meta->has_any_types = 1;
        }
        if (role_slot->has_default) {
            class_meta->has_any_defaults = 1;
        }
        if (role_slot->has_trigger) {
            class_meta->has_any_triggers = 1;
        }
        if (role_slot->is_required) {
            class_meta->has_any_required = 1;
        }
        if (role_slot->is_lazy) {
            class_meta->has_any_lazy = 1;
        }
        if (role_slot->has_builder) {
            class_meta->has_any_builders = 1;
        }
        if (role_slot->is_weak) {
            class_meta->has_any_weak = 1;
        }
        
        /* Install accessor for this slot */
        if (role_slot->has_type || role_slot->has_trigger || role_slot->has_coerce || 
            role_slot->is_readonly || role_slot->is_lazy || role_slot->is_required || role_slot->is_weak) {
            install_accessor_typed(aTHX_ class_meta->class_name, role_slot->name, new_idx, class_meta);
        } else {
            install_accessor(aTHX_ class_meta->class_name, role_slot->name, new_idx);
        }
        
        if (role_slot->has_clearer) {
            install_clearer(aTHX_ class_meta->class_name, role_slot->name, new_idx, class_meta, role_slot->clearer_name);
        }
        if (role_slot->has_predicate) {
            install_predicate(aTHX_ class_meta->class_name, role_slot->name, new_idx, class_meta, role_slot->predicate_name);
        }
        if (role_slot->reader_name) {
            install_reader(aTHX_ class_meta->class_name, SvPV_nolen(role_slot->reader_name), new_idx, class_meta);
        }
        if (role_slot->writer_name) {
            install_writer(aTHX_ class_meta->class_name, SvPV_nolen(role_slot->writer_name), new_idx, class_meta);
        }
    }
    
    /* Copy role's methods to class */
    if (role_meta->stash) {
        hv_iterinit(role_meta->stash);
        while ((entry = hv_iternext(role_meta->stash))) {
            const char *name = HePV(entry, PL_na);
            /* Skip special entries and slots (already handled) */
            if (name[0] != '_' || strncmp(name, "_build_", 7) == 0) {
                copy_method(aTHX_ role_meta->stash, class_meta->stash, name);
            }
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
    if (svp && SvIOK(*svp)) {
        return INT2PTR(ModifiedMethod*, SvIV(*svp));
    }
    
    /* Create new modified method entry */
    Newxz(mod, 1, ModifiedMethod);
    
    /* Get the original CV */
    {
        GV *gv = gv_fetchmeth(meta->stash, method_name, name_len, 0);
        if (gv && GvCV(gv)) {
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
            ST(count - 1 - i) = sv_mortalcopy(svp ? *svp : &PL_sv_undef);
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
    switch (type) {
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
    IV parent_alloc = 0;
    
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
                parent_alloc = plen;
                for (p = 0; p < plen; p++) {
                    SV **elem = av_fetch(parents_av, p, 0);
                    if (elem && SvPOK(*elem)) {
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
                parent_alloc = 1;
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
        max_slots = 1 + total_parent_slots + child_props;
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
            if (parent_spec) {
                /* Skip if property already defined by earlier parent */
                SV **existing = hv_fetch(meta->prop_to_idx, parent_spec->name,
                                         strlen(parent_spec->name), 0);
                if (existing && SvIOK(*existing)) continue;

                SlotSpec *cloned = clone_slot_spec(aTHX_ parent_spec);
                IV idx = meta->slot_count++;
                meta->slots[idx] = cloned;

                if (cloned->has_type) meta->has_any_types = 1;
                if (cloned->has_default) meta->has_any_defaults = 1;
                if (cloned->has_trigger) meta->has_any_triggers = 1;
                if (cloned->is_required) meta->has_any_required = 1;
                if (cloned->is_lazy) meta->has_any_lazy = 1;
                if (cloned->has_builder) meta->has_any_builders = 1;
                if (cloned->is_weak) meta->has_any_weak = 1;

                hv_store(meta->prop_to_idx, cloned->name, strlen(cloned->name), newSViv(idx), 0);
                
                /* Add to arg_to_idx using init_arg if specified, otherwise property name */
                if (cloned->init_arg) {
                    STRLEN arg_len;
                    const char *arg_name = SvPV(cloned->init_arg, arg_len);
                    hv_store(meta->arg_to_idx, arg_name, arg_len, newSViv(idx), 0);
                } else {
                    hv_store(meta->arg_to_idx, cloned->name, strlen(cloned->name), newSViv(idx), 0);
                }
                
                meta->idx_to_prop[idx] = cloned->name;

                if (cloned->has_type || cloned->has_trigger || cloned->has_coerce || cloned->is_readonly || cloned->is_lazy || cloned->is_required || cloned->is_weak) {
                    install_accessor_typed(aTHX_ class_pv, cloned->name, idx, meta);
                } else {
                    install_accessor(aTHX_ class_pv, cloned->name, idx);
                }
                if (cloned->has_clearer) {
                    install_clearer(aTHX_ class_pv, cloned->name, idx, meta, cloned->clearer_name);
                }
                if (cloned->has_predicate) {
                    install_predicate(aTHX_ class_pv, cloned->name, idx, meta, cloned->predicate_name);
                }
                if (cloned->reader_name) {
                    install_reader(aTHX_ class_pv, SvPV_nolen(cloned->reader_name), idx, meta);
                }
                if (cloned->writer_name) {
                    install_writer(aTHX_ class_pv, SvPV_nolen(cloned->writer_name), idx, meta);
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
        if (spec_len > 0 && spec_pv[0] == '+') {
            is_modification = 1;
            real_spec_pv = spec_pv + 1;
            real_spec_len = spec_len - 1;
        }

        /* Parse the slot spec (e.g., "name:Str:required" or just "name") */
        spec = parse_slot_spec(aTHX_ real_spec_pv, real_spec_len);

        /* Check if this property already exists (from parent) */
        existing = hv_fetch(meta->prop_to_idx, spec->name, strlen(spec->name), 0);
        
        if (is_modification) {
            /* +attr syntax: merge child modifiers onto parent spec */
            SlotSpec *parent_spec;
            SlotSpec *merged;
            
            if (!existing || !SvIOK(*existing)) {
                croak("+%s: no inherited attribute '%s' to modify", 
                      spec->name, spec->name);
            }
            idx = SvIV(*existing);
            parent_spec = meta->slots[idx];
            
            /* Merge override onto clone of parent */
            merged = merge_slot_spec(aTHX_ parent_spec, spec);
            
            /* Free the override spec (we cloned what we needed) */
            Safefree(spec->name);
            Safefree(spec);
            spec = merged;
            
            /* Free old parent spec */
            if (parent_spec) {
                Safefree(parent_spec->name);
                Safefree(parent_spec);
            }
        } else if (existing && SvIOK(*existing)) {
            /* Full override: reuse same slot index */
            idx = SvIV(*existing);
            /* Free old spec */
            if (meta->slots[idx]) {
                Safefree(meta->slots[idx]->name);
                Safefree(meta->slots[idx]);
            }
        } else {
            idx = meta->slot_count++;
        }

        meta->slots[idx] = spec;
        
        /* Update class-level flags for fast path checks */
        if (spec->has_type) meta->has_any_types = 1;
        if (spec->has_default) meta->has_any_defaults = 1;
        if (spec->has_trigger) meta->has_any_triggers = 1;
        if (spec->is_required) meta->has_any_required = 1;
        if (spec->has_builder) meta->has_any_builders = 1;
        if (spec->is_weak) meta->has_any_weak = 1;

        /* Store name -> idx mapping (use parsed name, not full spec) */
        hv_store(meta->prop_to_idx, spec->name, strlen(spec->name), newSViv(idx), 0);
        
        /* Store arg -> idx mapping (use init_arg if specified, otherwise property name) */
        if (spec->init_arg) {
            STRLEN arg_len;
            const char *arg_name = SvPV(spec->init_arg, arg_len);
            hv_store(meta->arg_to_idx, arg_name, arg_len, newSViv(idx), 0);
        } else {
            hv_store(meta->arg_to_idx, spec->name, strlen(spec->name), newSViv(idx), 0);
        }

        /* Store idx -> name mapping */
        meta->idx_to_prop[idx] = spec->name;
        
        /* Update lazy flag */
        if (spec->is_lazy) meta->has_any_lazy = 1;

        /* Install accessor method - typed or plain depending on spec */
        if (spec->has_type || spec->has_trigger || spec->has_coerce || spec->is_readonly || spec->is_lazy || spec->is_required || spec->is_weak) {
            install_accessor_typed(aTHX_ class_pv, spec->name, idx, meta);
        } else {
            install_accessor(aTHX_ class_pv, spec->name, idx);
        }
        
        /* Install clearer method if requested */
        if (spec->has_clearer) {
            install_clearer(aTHX_ class_pv, spec->name, idx, meta, spec->clearer_name);
        }
        
        /* Install predicate method if requested */
        if (spec->has_predicate) {
            install_predicate(aTHX_ class_pv, spec->name, idx, meta, spec->predicate_name);
        }
        
        /* Install custom reader method if specified */
        if (spec->reader_name) {
            install_reader(aTHX_ class_pv, SvPV_nolen(spec->reader_name), idx, meta);
        }
        
        /* Install custom writer method if specified */
        if (spec->writer_name) {
            install_writer(aTHX_ class_pv, SvPV_nolen(spec->writer_name), idx, meta);
        }
    }

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
    spec = (meta->slots && idx < meta->slot_count) ? meta->slots[idx] : NULL;

    if (spec && spec->has_type) {
        const char *type_name;
        if (spec->type_id == TYPE_CUSTOM && spec->registered) {
            type_name = spec->registered->name;
        } else {
            type_name = type_id_to_name(spec->type_id);
        }
        hv_store(info, "type", 4, newSVpv(type_name, 0), 0);
    }

    /* Boolean flags */
    hv_store(info, "is_required", 11, newSViv(spec ? spec->is_required : 0), 0);
    hv_store(info, "is_readonly", 11, newSViv(spec ? spec->is_readonly : 0), 0);
    hv_store(info, "is_lazy", 7, newSViv(spec ? spec->is_lazy : 0), 0);
    hv_store(info, "is_weak", 7, newSViv(spec ? spec->is_weak : 0), 0);
    hv_store(info, "has_default", 11, newSViv(spec ? spec->has_default : 0), 0);
    hv_store(info, "has_trigger", 11, newSViv(spec ? spec->has_trigger : 0), 0);
    hv_store(info, "has_coerce", 10, newSViv(spec ? spec->has_coerce : 0), 0);
    hv_store(info, "has_builder", 11, newSViv(spec ? spec->has_builder : 0), 0);
    hv_store(info, "has_clearer", 11, newSViv(spec ? spec->has_clearer : 0), 0);
    hv_store(info, "has_predicate", 13, newSViv(spec ? spec->has_predicate : 0), 0);
    hv_store(info, "has_type", 8, newSViv(spec ? spec->has_type : 0), 0);

    /* Default value (if present) */
    if (spec && spec->has_default && spec->default_sv) {
        hv_store(info, "default", 7, newSVsv(spec->default_sv), 0);
    }

    /* Builder method name */
    if (spec && spec->has_builder && spec->builder_name) {
        hv_store(info, "builder", 7, newSVsv(spec->builder_name), 0);
    }

    /* init_arg (if specified) */
    if (spec && spec->init_arg) {
        hv_store(info, "init_arg", 8, newSVsv(spec->init_arg), 0);
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
    if (PL_dirty) {
        g_type_registry = NULL;
        g_class_registry = NULL;
        g_func_accessor_registry = NULL;
        return;
    }

    /* Normal cleanup - not during global destruction */
    /* Note: Full cleanup omitted for simplicity; Perl handles SV refcounts */
    g_type_registry = NULL;
    g_class_registry = NULL;
    g_func_accessor_registry = NULL;
}

/* ============================================
   Type Registry API
   ============================================ */

/* C-level registration for external XS modules (called from BOOT)
   This is the fast path - no Perl callback overhead */
PERL_CALLCONV void object_register_type_xs(pTHX_ const char *name, 
                                           ObjectTypeCheckFunc check,
                                           ObjectTypeCoerceFunc coerce) {
    RegisteredType *type;
    STRLEN name_len = strlen(name);
    
    if (!g_type_registry) {
        g_type_registry = newHV();
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
    
    hv_store(g_type_registry, name, name_len, newSViv(PTR2IV(type)), 0);
}

/* Getter for external modules to look up a registered type */
PERL_CALLCONV RegisteredType* object_get_registered_type(pTHX_ const char *name) {
    STRLEN name_len = strlen(name);
    if (!g_type_registry) return NULL;
    
    SV **svp = hv_fetch(g_type_registry, name, name_len, 0);
    if (svp && SvIOK(*svp)) {
        return INT2PTR(RegisteredType*, SvIV(*svp));
    }
    return NULL;
}

/* Object::Proto::register_type($name, $check_cb [, $coerce_cb]) */
XS_INTERNAL(xs_register_type) {
    dXSARGS;
    STRLEN name_len;
    const char *name;
    RegisteredType *type;
    
    if (items < 2) croak("Usage: Object::Proto::register_type($name, $check_cb [, $coerce_cb])");
    
    name = SvPV(ST(0), name_len);
    
    /* Check if already registered */
    if (g_type_registry) {
        SV **existing = hv_fetch(g_type_registry, name, name_len, 0);
        if (existing) {
            croak("Type '%s' is already registered", name);
        }
    } else {
        g_type_registry = newHV();
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
    
    /* Add registered types */
    if (g_type_registry) {
        HE *he;
        hv_iterinit(g_type_registry);
        while ((he = hv_iternext(g_type_registry))) {
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

    if (!meta) {
        croak("Singleton metadata not found");
    }

    /* Return cached instance if it exists */
    if (meta->singleton_instance && SvOK(meta->singleton_instance)) {
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

        if (count != 1) {
            croak("Singleton new() did not return object");
        }

        obj = POPs;
        SvREFCNT_inc(obj);  /* Keep the object alive */

        PUTBACK;

        /* Check for BUILD method and call it */
        snprintf(full_build, sizeof(full_build), "%s::BUILD", meta->class_name);
        build_gv = gv_fetchpv(full_build, 0, SVt_PVCV);
        if (build_gv && GvCV(build_gv)) {
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
            if (SvTRUE(err)) {
                croak("Role '%s' not defined (failed to load: %" SVf ")", role_pv, SVfARG(err));
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
        croak("Class '%s' not defined with Object::Proto::define", class_name);
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
        croak("Class '%s' not defined with Object::Proto::define", class_name);
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
        croak("Class '%s' not defined with Object::Proto::define", class_name);
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
    XopENTRY_set(&object_new_xop, xop_name, "object_new");
    XopENTRY_set(&object_new_xop, xop_desc, "object constructor");
    XopENTRY_set(&object_new_xop, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_object_new, &object_new_xop);
    
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

    Perl_xs_boot_epilog(aTHX_ ax);
}
