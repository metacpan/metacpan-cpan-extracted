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

#ifdef HAVE_LIBFFI
/* libffi lets us call a Strada function with an arbitrary number of arguments
 * (all Strada functions share the uniform StradaValue*(...)->StradaValue* ABI),
 * lifting the fixed call_0..call_4 arity cap. Defined by Makefile.PL when the
 * libffi development headers are present. */
#include <ffi.h>
#endif

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

    /* A Strada::Object wrapping a live Strada value (e.g. passing an object
     * back into a method/function) — hand the underlying StradaValue* straight
     * through, incref'd to match the fresh-refcount-1 contract callers expect. */
    if (sv_isobject(sv) && sv_derived_from(sv, "Strada::Object")) {
        SV **pp = hv_fetchs((HV*)SvRV(sv), "ptr", 0);
        if (pp && SvIOK(*pp)) {
            StradaValue *obj = (StradaValue*)(intptr_t)SvIV(*pp);
            if (obj) {
                strada_incref(obj);
                return obj;
            }
        }
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
                    /* _take: sv_to_strada returns a fresh refcount-1 value; the
                     * container takes ownership so it isn't double-counted. */
                    strada_array_push_take(arr->value.av, sv_to_strada(aTHX_ *elem));
                }
            }
            /* A Perl arrayref maps to a Strada array REFERENCE, so Strada code
             * can use $arr->[i] / @$arr (a bare array isn't deref-indexable). */
            return strada_ref_create_take(arr);
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
                strada_hash_set_take(hash->value.hv, key, sv_to_strada(aTHX_ val));
            }
            /* A Perl hashref maps to a Strada hash REFERENCE ($h->{k} / %$h). */
            return strada_ref_create_take(hash);
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
    if (!val) {
        return &PL_sv_undef;
    }
    /* Tagged integers are encoded in the pointer (odd address), not heap
     * structs — must be checked before any val->type/val->value access. */
    if (STRADA_IS_TAGGED_INT(val)) {
        return newSViv((IV)STRADA_TAGGED_INT_VAL(val));
    }
    if (val->type == STRADA_UNDEF) {
        return &PL_sv_undef;
    }

    /* A blessed Strada object -> wrap in a Strada::Object (a blessed hashref
     * holding the live StradaValue* and its class) so Perl can dispatch methods
     * back into the runtime, instead of flattening it to a plain hashref and
     * losing the class + methods. The wrapper holds a ref until DESTROY. */
    if (val->meta && val->meta->blessed_package) {
        HV *self = newHV();
        strada_incref(val);
        (void)hv_stores(self, "ptr",   newSViv((IV)(intptr_t)val));
        (void)hv_stores(self, "class", newSVpv(val->meta->blessed_package, 0));
        SV *objref = newRV_noinc((SV*)self);
        return sv_bless(objref, gv_stashpv("Strada::Object", GV_ADD));
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
            /* Open-addressing hash: live entries occupy entries[0 .. next_slot),
             * deleted slots have a NULL key. Mirrors strada_hash_keys(). The key
             * is a StradaString (data + len), not a C string. */
            if (hash) {
                for (size_t i = 0; i < hash->next_slot; i++) {
                    StradaHashEntry *entry = &hash->entries[i];
                    if (entry->key) {
                        hv_store(hv, entry->key->data, (I32)entry->key->len,
                                 strada_to_sv(aTHX_ entry->value), 0);
                    }
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

/* Dispatch fn(args[0..n-1]) -> owned result. Uses libffi when available (any
 * arity); otherwise the fixed call_1..call_4 path (n>4 handled by the caller).
 * Does not take ownership of args. */
static StradaValue* strada_call_n(void *fn, StradaValue **args, int n) {
#ifdef HAVE_LIBFFI
    if (n == 0) return ((strada_func_0)fn)();
    ffi_type *atypes_buf[8];
    void     *avals_buf[8];
    ffi_type **atypes = atypes_buf;
    void     **avals  = avals_buf;
    int onheap = (n > 8);
    if (onheap) { Newx(atypes, n, ffi_type*); Newx(avals, n, void*); }
    for (int i = 0; i < n; i++) { atypes[i] = &ffi_type_pointer; avals[i] = &args[i]; }
    ffi_cif cif;
    StradaValue *result = NULL;
    int ok = (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, (unsigned)n,
                           &ffi_type_pointer, atypes) == FFI_OK);
    if (ok) ffi_call(&cif, (void (*)(void))fn, &result, avals);
    if (onheap) { Safefree(atypes); Safefree(avals); }
    return result;
#else
    switch (n) {
        case 0: return ((strada_func_0)fn)();
        case 1: return ((strada_func_1)fn)(args[0]);
        case 2: return ((strada_func_2)fn)(args[0], args[1]);
        case 3: return ((strada_func_3)fn)(args[0], args[1], args[2]);
        case 4: return ((strada_func_4)fn)(args[0], args[1], args[2], args[3]);
    }
    return NULL;
#endif
}

/* Called in the setjmp()!=0 (exception) branch of a protected call: pop the
 * try-frame, unwind the local() and pending-cleanup stacks to where they were
 * at try entry (releasing temps the longjmp skipped), and return the thrown
 * exception as an SV for the caller to croak with (a string, or a wrapped
 * Strada::Object for a thrown object). */
static SV* xs_extract_exception(pTHX_ int cleanup_mark, int local_mark) {
    STRADA_TRY_POP();
    strada_local_restore_to(local_mark);
    strada_cleanup_drain_to(cleanup_mark);
    /* strada_get_exception() CONSUMES strada_exception_value (transfers
     * ownership), so we own `exc` and must release it after copying/ wrapping
     * it into the SV. For a string this copies; for a blessed object
     * strada_to_sv increfs it into the Strada::Object wrapper. */
    StradaValue *exc = strada_get_exception();
    if (exc) {
        SV *sv = strada_to_sv(aTHX_ exc);
        strada_decref(exc);
        return sv;
    }
    return newSVpv(strada_exception_msg ? strada_exception_msg : "Strada exception", 0);
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
        strada_decref(result);   /* strada_to_sv deep-copies into SVs */
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
        strada_decref(a1);
        strada_decref(result);
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
        strada_decref(a1);
        strada_decref(a2);
        strada_decref(result);
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
        strada_decref(a1);
        strada_decref(a2);
        strada_decref(a3);
        strada_decref(result);
    }
OUTPUT:
    RETVAL

# Call a Strada function with variable arguments.
# With libffi: unlimited arity. Without: capped at 4 (croaks beyond).
SV*
call(func, ...)
    IV func
PREINIT:
    int argc;
CODE:
    if (!func) {
        RETVAL = &PL_sv_undef;
    } else {
        argc = items - 1;  /* Subtract 1 for func pointer */
#ifndef HAVE_LIBFFI
        if (argc > 4) {
            croak("Strada::call: at most 4 arguments are supported without "
                  "libffi (got %d); install libffi-dev and rebuild", argc);
        }
#endif
        StradaValue **args = NULL;
        Newx(args, argc > 0 ? argc : 1, StradaValue*);
        for (int i = 0; i < argc; i++) {
            args[i] = sv_to_strada(aTHX_ ST(i + 1));
        }
        /* Run inside a Strada try-frame: a thrown exception longjmps back here
         * and becomes a Perl die (catchable with eval) instead of aborting. */
        int cmark = strada_cleanup_mark();
        int lmark = strada_local_depth_get();
        jmp_buf *jb = STRADA_TRY_PUSH();
        if (!jb) {
            /* Try-frame stack exhausted: dispatching unprotected would let a
             * throw escape to an outer frame and leak these args. Fail as a
             * Perl die instead. */
            for (int i = 0; i < argc; i++) strada_decref(args[i]);
            Safefree(args);
            croak("Strada::call: try-frame stack exhausted (max %d nested)",
                  STRADA_MAX_TRY_DEPTH);
        }
        StradaValue *result = NULL;
        SV * volatile exc = NULL;
        if (setjmp(*jb) != 0) {
            exc = xs_extract_exception(aTHX_ cmark, lmark);
        } else {
            result = strada_call_n((void *)func, args, argc);
            STRADA_TRY_POP();
        }
        /* positional args are borrowed by the callee; release our refs (the
         * throw path already drained the callee's incref via cleanup_drain). */
        for (int i = 0; i < argc; i++) {
            strada_decref(args[i]);
        }
        Safefree(args);
        if (exc) {
            croak_sv(sv_2mortal((SV *)exc));
        }
        RETVAL = strada_to_sv(aTHX_ result);
        strada_decref(result);
    }
OUTPUT:
    RETVAL

# Call a variadic Strada function (constructors, @_-style, `...@rest`). The
# runtime packs every argument from index `vidx` onward into a single Strada
# array (the variadic parameter); earlier arguments are passed positionally.
# This mirrors how the compiler emits such calls — e.g. Pkg::new(k1,v1,k2,v2)
# is one packed-array argument (vidx == 0).
SV*
_call_variadic(func, vidx, ...)
    IV func
    int vidx
CODE:
    {
        if (!func) {
            RETVAL = &PL_sv_undef;
        } else {
            int total = items - 2;              /* func + vidx are fixed */
            if (vidx < 0) vidx = 0;
            if (vidx > total) vidx = total;
            int ncall = vidx + 1;               /* positional args + 1 packed array */
#ifndef HAVE_LIBFFI
            if (ncall > 4) {
                croak("Strada::_call_variadic: needs libffi for %d packed args", ncall);
            }
#endif
            StradaValue **cargs = NULL;
            Newx(cargs, ncall, StradaValue*);
            for (int i = 0; i < vidx; i++) {
                cargs[i] = sv_to_strada(aTHX_ ST(i + 2));
            }
            StradaValue *packed = strada_new_array();  /* bare STRADA_ARRAY */
            for (int i = vidx; i < total; i++) {
                strada_array_push_take(packed->value.av, sv_to_strada(aTHX_ ST(i + 2)));
            }
            cargs[vidx] = packed;
            /* try-frame: bridge a thrown exception to a Perl die. */
            int cmark = strada_cleanup_mark();
            int lmark = strada_local_depth_get();
            jmp_buf *jb = STRADA_TRY_PUSH();
            if (!jb) {
                for (int i = 0; i < ncall; i++) strada_decref(cargs[i]);
                Safefree(cargs);
                croak("Strada::_call_variadic: try-frame stack exhausted (max %d nested)",
                      STRADA_MAX_TRY_DEPTH);
            }
            StradaValue *result = NULL;
            SV * volatile exc = NULL;
            if (setjmp(*jb) != 0) {
                exc = xs_extract_exception(aTHX_ cmark, lmark);
            } else {
                result = strada_call_n((void *)func, cargs, ncall);
                STRADA_TRY_POP();
            }
            for (int i = 0; i < ncall; i++) {
                strada_decref(cargs[i]);
            }
            Safefree(cargs);
            if (exc) {
                croak_sv(sv_2mortal((SV *)exc));
            }
            RETVAL = strada_to_sv(aTHX_ result);
            strada_decref(result);
        }
    }
OUTPUT:
    RETVAL

# Dispatch a method on a blessed Strada object (used by Strada::Object::AUTOLOAD).
# obj_ptr is the StradaValue* held by the wrapper; the remaining args become the
# method's arguments. strada_method_call consumes the packed-args array and
# returns an owned result (which may itself be another blessed object).
SV*
_method_call(obj_ptr, method, ...)
    IV obj_ptr
    const char *method
CODE:
    {
        StradaValue *obj = (StradaValue*)(intptr_t)obj_ptr;
        if (!obj) {
            RETVAL = &PL_sv_undef;
        } else {
            int argc = items - 2;  /* obj_ptr + method */
            StradaValue *args = strada_new_array();  /* a bare STRADA_ARRAY */
            for (int i = 0; i < argc; i++) {
                strada_array_push_take(args->value.av, sv_to_strada(aTHX_ ST(i + 2)));
            }
            /* try-frame: a throw inside the method becomes a Perl die. method_call
             * takes ownership of `args` (do not decref it here); on the throw
             * path cleanup_drain_to releases it. */
            int cmark = strada_cleanup_mark();
            int lmark = strada_local_depth_get();
            jmp_buf *jb = STRADA_TRY_PUSH();
            if (!jb) {
                /* Not yet handed to method_call, so we still own `args`. */
                strada_decref(args);
                croak("Strada::_method_call: try-frame stack exhausted (max %d nested)",
                      STRADA_MAX_TRY_DEPTH);
            }
            StradaValue *result = NULL;
            SV * volatile exc = NULL;
            if (setjmp(*jb) != 0) {
                exc = xs_extract_exception(aTHX_ cmark, lmark);
            } else {
                result = strada_method_call(obj, method, args);
                STRADA_TRY_POP();
            }
            if (exc) {
                croak_sv(sv_2mortal((SV *)exc));
            }
            RETVAL = strada_to_sv(aTHX_ result);
            strada_decref(result);
        }
    }
OUTPUT:
    RETVAL

# Release the runtime ref a Strada::Object holds (called from its DESTROY).
void
_obj_release(obj_ptr)
    IV obj_ptr
CODE:
    {
        StradaValue *obj = (StradaValue*)(intptr_t)obj_ptr;
        if (obj) {
            strada_decref(obj);
        }
    }

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
