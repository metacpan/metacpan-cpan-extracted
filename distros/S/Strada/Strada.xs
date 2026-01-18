/*
 * Strada.xs - Perl XS module for calling Strada shared libraries
 *
 * This module allows Perl programs to load and call functions from
 * compiled Strada shared libraries.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <dlfcn.h>
#include <string.h>

/* Include Strada runtime for StradaValue handling */
#include "strada_runtime.h"

/* Function pointer types for Strada functions */
typedef StradaValue* (*strada_func_0)(void);
typedef StradaValue* (*strada_func_1)(StradaValue*);
typedef StradaValue* (*strada_func_2)(StradaValue*, StradaValue*);
typedef StradaValue* (*strada_func_3)(StradaValue*, StradaValue*, StradaValue*);
typedef StradaValue* (*strada_func_4)(StradaValue*, StradaValue*, StradaValue*, StradaValue*);

/* Function pointer type for __strada_export_info */
typedef const char* (*strada_export_info_func)(void);

/* Function pointer type for __strada_version */
typedef const char* (*strada_version_func)(void);

/* Convert Perl SV to StradaValue */
static StradaValue* sv_to_strada(pTHX_ SV *sv) {
    if (!SvOK(sv)) {
        return strada_new_undef();
    }

    if (SvROK(sv)) {
        SV *dereferenced = SvRV(sv);
        if (SvTYPE(dereferenced) == SVt_PVAV) {
            /* Array reference */
            AV *av = (AV*)dereferenced;
            StradaValue *arr = strada_new_array();
            SSize_t len = av_len(av) + 1;
            for (SSize_t i = 0; i < len; i++) {
                SV **elem = av_fetch(av, i, 0);
                if (elem) {
                    strada_array_push(arr->value.av, sv_to_strada(aTHX_ *elem));
                }
            }
            return arr;
        } else if (SvTYPE(dereferenced) == SVt_PVHV) {
            /* Hash reference */
            HV *hv = (HV*)dereferenced;
            StradaValue *hash = strada_new_hash();
            hv_iterinit(hv);
            HE *entry;
            while ((entry = hv_iternext(hv)) != NULL) {
                STRLEN klen;
                char *key = HePV(entry, klen);
                SV *val = HeVAL(entry);
                strada_hash_set(hash->value.hv, key, sv_to_strada(aTHX_ val));
            }
            return hash;
        }
    }

    if (SvIOK(sv)) {
        return strada_new_int(SvIV(sv));
    }

    if (SvNOK(sv)) {
        return strada_new_num(SvNV(sv));
    }

    /* Default: treat as string */
    STRLEN len;
    const char *str = SvPV(sv, len);
    return strada_new_str(str);
}

/* Convert StradaValue to Perl SV */
static SV* strada_to_sv(pTHX_ StradaValue *val) {
    if (!val || val->type == STRADA_UNDEF) {
        return &PL_sv_undef;
    }

    switch (val->type) {
        case STRADA_INT:
            return newSViv(val->value.iv);

        case STRADA_NUM:
            return newSVnv(val->value.nv);

        case STRADA_STR:
            return newSVpv(val->value.pv ? val->value.pv : "", 0);

        case STRADA_ARRAY: {
            AV *av = newAV();
            StradaArray *arr = val->value.av;
            size_t len = strada_array_length(arr);
            for (size_t i = 0; i < len; i++) {
                StradaValue *elem = strada_array_get(arr, i);
                av_push(av, strada_to_sv(aTHX_ elem));
            }
            return newRV_noinc((SV*)av);
        }

        case STRADA_HASH: {
            HV *hv = newHV();
            StradaHash *hash = val->value.hv;
            /* Iterate through hash entries */
            for (size_t i = 0; i < hash->num_buckets; i++) {
                StradaHashEntry *entry = hash->buckets[i];
                while (entry) {
                    hv_store(hv, entry->key, strlen(entry->key),
                             strada_to_sv(aTHX_ entry->value), 0);
                    entry = entry->next;
                }
            }
            return newRV_noinc((SV*)hv);
        }

        case STRADA_REF:
            return strada_to_sv(aTHX_ val->value.rv);

        default:
            return &PL_sv_undef;
    }
}

MODULE = Strada  PACKAGE = Strada

PROTOTYPES: DISABLE

# Load a Strada shared library
# Returns handle (integer) or 0 on failure
IV
load(path)
    const char *path
CODE:
    void *handle = dlopen(path, RTLD_NOW | RTLD_GLOBAL);
    if (!handle) {
        warn("Strada::load: %s", dlerror());
        RETVAL = 0;
    } else {
        RETVAL = (IV)handle;
    }
OUTPUT:
    RETVAL

# Unload a Strada shared library
void
unload(handle)
    IV handle
CODE:
    if (handle) {
        dlclose((void*)handle);
    }

# Get a function pointer from a loaded library
IV
get_func(handle, name)
    IV handle
    const char *name
CODE:
    if (!handle) {
        RETVAL = 0;
    } else {
        void *fn = dlsym((void*)handle, name);
        if (!fn) {
            warn("Strada::get_func: %s", dlerror());
        }
        RETVAL = (IV)fn;
    }
OUTPUT:
    RETVAL

# Call a Strada function with 0 arguments
SV*
call_0(func)
    IV func
CODE:
    if (!func) {
        RETVAL = &PL_sv_undef;
    } else {
        strada_func_0 fn = (strada_func_0)func;
        StradaValue *result = fn();
        RETVAL = strada_to_sv(aTHX_ result);
    }
OUTPUT:
    RETVAL

# Call a Strada function with 1 argument
SV*
call_1(func, arg1)
    IV func
    SV *arg1
CODE:
    if (!func) {
        RETVAL = &PL_sv_undef;
    } else {
        strada_func_1 fn = (strada_func_1)func;
        StradaValue *a1 = sv_to_strada(aTHX_ arg1);
        StradaValue *result = fn(a1);
        RETVAL = strada_to_sv(aTHX_ result);
    }
OUTPUT:
    RETVAL

# Call a Strada function with 2 arguments
SV*
call_2(func, arg1, arg2)
    IV func
    SV *arg1
    SV *arg2
CODE:
    if (!func) {
        RETVAL = &PL_sv_undef;
    } else {
        strada_func_2 fn = (strada_func_2)func;
        StradaValue *a1 = sv_to_strada(aTHX_ arg1);
        StradaValue *a2 = sv_to_strada(aTHX_ arg2);
        StradaValue *result = fn(a1, a2);
        RETVAL = strada_to_sv(aTHX_ result);
    }
OUTPUT:
    RETVAL

# Call a Strada function with 3 arguments
SV*
call_3(func, arg1, arg2, arg3)
    IV func
    SV *arg1
    SV *arg2
    SV *arg3
CODE:
    if (!func) {
        RETVAL = &PL_sv_undef;
    } else {
        strada_func_3 fn = (strada_func_3)func;
        StradaValue *a1 = sv_to_strada(aTHX_ arg1);
        StradaValue *a2 = sv_to_strada(aTHX_ arg2);
        StradaValue *a3 = sv_to_strada(aTHX_ arg3);
        StradaValue *result = fn(a1, a2, a3);
        RETVAL = strada_to_sv(aTHX_ result);
    }
OUTPUT:
    RETVAL

# Call a Strada function with variable arguments (up to 4)
SV*
call(func, ...)
    IV func
PREINIT:
    StradaValue *args[4] = {NULL, NULL, NULL, NULL};
    int argc;
CODE:
    if (!func) {
        RETVAL = &PL_sv_undef;
    } else {
        argc = items - 1;  /* Subtract 1 for func pointer */
        if (argc > 4) argc = 4;

        for (int i = 0; i < argc; i++) {
            args[i] = sv_to_strada(aTHX_ ST(i + 1));
        }

        StradaValue *result = NULL;
        switch (argc) {
            case 0:
                result = ((strada_func_0)func)();
                break;
            case 1:
                result = ((strada_func_1)func)(args[0]);
                break;
            case 2:
                result = ((strada_func_2)func)(args[0], args[1]);
                break;
            case 3:
                result = ((strada_func_3)func)(args[0], args[1], args[2]);
                break;
            case 4:
                result = ((strada_func_4)func)(args[0], args[1], args[2], args[3]);
                break;
        }

        RETVAL = strada_to_sv(aTHX_ result);
    }
OUTPUT:
    RETVAL

# Get export info from a Strada library
# Returns the metadata string or empty string if not a Strada library
SV*
get_export_info(handle)
    IV handle
CODE:
    if (!handle) {
        RETVAL = newSVpv("", 0);
    } else {
        void *fn = dlsym((void*)handle, "__strada_export_info");
        if (!fn) {
            RETVAL = newSVpv("", 0);
        } else {
            strada_export_info_func info_fn = (strada_export_info_func)fn;
            const char *info = info_fn();
            RETVAL = newSVpv(info ? info : "", 0);
        }
    }
OUTPUT:
    RETVAL

# Get version from a Strada library
# Returns the version string or empty string if not available
SV*
get_version(handle)
    IV handle
CODE:
    if (!handle) {
        RETVAL = newSVpv("", 0);
    } else {
        void *fn = dlsym((void*)handle, "__strada_version");
        if (!fn) {
            RETVAL = newSVpv("", 0);
        } else {
            strada_version_func ver_fn = (strada_version_func)fn;
            const char *ver = ver_fn();
            RETVAL = newSVpv(ver ? ver : "", 0);
        }
    }
OUTPUT:
    RETVAL
