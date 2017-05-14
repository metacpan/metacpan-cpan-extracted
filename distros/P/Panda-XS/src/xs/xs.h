#pragma once
#define NO_XSLOCKS          // dont hook libc calls
#define PERLIO_NOT_STDIO 0  // dont hook IO
#define PERL_NO_GET_CONTEXT // we want efficiency for threaded perls
extern "C" {
#  include "EXTERN.h"
#  include "perl.h"
#  include "XSUB.h"
#  undef do_open
#  undef do_close
}
#include "ppport.h"

#include <algorithm_perlsafe> // safe c++11 compilation
#include <exception>
#include <panda/cast.h>
#include <panda/refcnt.h>
#include <panda/string.h>
#include <panda/string_view.h>

typedef SV OSV;
typedef HV OHV;
typedef AV OAV;
typedef IO OIO;

#ifndef hv_storehek
#  define hv_storehek(hv, hek, val) \
    hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), HV_FETCH_ISSTORE|HV_FETCH_JUST_SV, (val), HEK_HASH(hek))
#  define hv_fetchhek(hv, hek, lval) \
    ((SV**)hv_common( \
        (hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), (lval) ? (HV_FETCH_JUST_SV|HV_FETCH_LVALUE) : HV_FETCH_JUST_SV, NULL, HEK_HASH(hek) \
    ))
#  define hv_deletehek(hv, hek, flags) \
    hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), (flags)|HV_DELETE, NULL, HEK_HASH(hek))
#endif

#define PXS_TRY(code) {                                                                       \
    try { code; }                                                                             \
    catch (const std::exception& err) { croak_sv(xs::error_sv(err)); }                        \
    catch (const char* err)           { croak_sv(newSVpv(err, 0)); }                          \
    catch (const std::string& err)    { croak_sv(newSVpvn(err.data(), err.length())); }       \
    catch (const panda::string& err)  { croak_sv(newSVpvn(err.data(), err.length())); }       \
    catch (...)                       { croak_sv(newSVpvs("unknown c++ exception thrown")); } \
}

#define XS_HV_ITER(hv,code) {                                                       \
    STRLEN hvmax = HvMAX(hv);                                                       \
    HE** hvarr = HvARRAY(hv);                                                       \
    if (HvUSEDKEYS(hv))                                                             \
        for (STRLEN bucket_num = 0; bucket_num <= hvmax; ++bucket_num)              \
            for (const HE* he = hvarr[bucket_num]; he; he = HeNEXT(he)) { code }    \
}
#define XS_HV_ITER_NU(hv,code) XS_HV_ITER(hv,{if(!SvOK(HeVAL(he))) continue; code})

#define XS_AV_ITER(av,code) {                                           \
    SV** list = AvARRAY(av);                                            \
    SSize_t fillp = AvFILLp(av);                                        \
    for (SSize_t i = 0; i <= fillp; ++i) { SV* elem = *list++; code }   \
}
#define XS_AV_ITER_NE(av,code) XS_AV_ITER(av,{if(!elem) continue; code})
#define XS_AV_ITER_NU(av,code) XS_AV_ITER(av,{if(!elem || !SvOK(elem)) continue; code})

// Threaded-perl helpers

#ifdef PERL_IMPLICIT_CONTEXT // define class member helpers for storing perl interpreter
#  define mTHX      pTHX;
#  define mTHXa(a)  aTHX(a),
#else
#  define mTHX
#  define mTHXa(a)
#endif

namespace xs {

enum next_t {
    NEXT_SUPER  = 0,
    NEXT_METHOD = 1,
    NEXT_MAYBE  = 2
};

struct my_perl_auto_t { // per-thread interpreter to help dealing with pTHX/aTHX, especially for static initialization
#ifdef PERL_IMPLICIT_CONTEXT
    operator PerlInterpreter* () const { return PERL_GET_THX; }
    PerlInterpreter* operator-> () const { return PERL_GET_THX; }
#endif
};
extern my_perl_auto_t my_perl;

typedef int (*on_svdup_t) (pTHX_ MAGIC* mg, CLONE_PARAMS* param);

typedef MGVTBL payload_marker_t;
extern payload_marker_t sv_payload_default_marker;
payload_marker_t* sv_payload_marker (const char* class_name, on_svdup_t svdup_callback = NULL);

template <class T>
struct SVPayloadMarker {
    static payload_marker_t marker;
    static payload_marker_t* get (on_svdup_t dup_callback = NULL) {
        if (dup_callback) marker.svt_dup = dup_callback;
        return &marker;
    }
};
template <class T> payload_marker_t SVPayloadMarker<T>::marker;

inline void sv_payload_attach (pTHX_ SV* sv, void* ptr, const payload_marker_t* marker = &sv_payload_default_marker) {
    MAGIC* mg = sv_magicext(sv, NULL, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker, (const char*) ptr, 0);
    if (marker->svt_dup) mg->mg_flags |= MGf_DUP;
    SvRMAGICAL_off(sv); // remove unnecessary perfomance overheat
}

inline void sv_payload_attach (pTHX_ SV* sv, void* ptr, SV* obj, const payload_marker_t* marker = &sv_payload_default_marker) {
    MAGIC* mg = sv_magicext(sv, obj, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker, (const char*) ptr, 0);
    mg->mg_flags |= MGf_REFCOUNTED;
    if (marker->svt_dup) mg->mg_flags |= MGf_DUP;
    SvRMAGICAL_off(sv); // remove unnecessary perfomance overheat
}

inline void sv_payload_attach (pTHX_ SV* sv, SV* obj, const payload_marker_t* marker = &sv_payload_default_marker) {
    sv_payload_attach(aTHX_ sv, NULL, obj, marker);
}

inline bool sv_payload_exists (pTHX_ const SV* sv, const payload_marker_t* marker) {
    if (SvTYPE(sv) < SVt_PVMG) return false;
    return mg_findext(sv, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker) != NULL;
}

inline void* sv_payload (pTHX_ const SV* sv, const payload_marker_t* marker) {
    if (SvTYPE(sv) < SVt_PVMG) return NULL;
    MAGIC* mg = mg_findext(sv, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker);
    return mg ? mg->mg_ptr : NULL;
}

inline SV* sv_payload_sv (pTHX_ const SV* sv, const payload_marker_t* marker) {
    if (SvTYPE(sv) < SVt_PVMG) return NULL;
    MAGIC* mg = mg_findext(sv, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker);
    return mg ? mg->mg_obj : NULL;
}

inline int sv_payload_detach (pTHX_ SV* sv, payload_marker_t* marker) {
    if (SvTYPE(sv) < SVt_PVMG) return 0;
    return sv_unmagicext(sv, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker);
}

inline void rv_payload_attach (pTHX_ SV* rv, void* ptr, const payload_marker_t* marker = NULL) {
    sv_payload_attach(aTHX_ SvRV(rv), ptr, marker);
}

inline void rv_payload_attach (pTHX_ SV* rv, void* ptr, SV* obj, const payload_marker_t* marker = NULL) {
    sv_payload_attach(aTHX_ SvRV(rv), ptr, obj, marker);
}

inline void rv_payload_attach (pTHX_ SV* rv, SV* obj, const payload_marker_t* marker = NULL) {
    sv_payload_attach(aTHX_ SvRV(rv), obj, marker);
}

inline bool rv_payload_exists (pTHX_ SV* rv, const payload_marker_t* marker = NULL) {
    return sv_payload_exists(aTHX_ SvRV(rv), marker);
}

inline void* rv_payload (pTHX_ SV* rv, const payload_marker_t* marker = NULL) {
    return sv_payload(aTHX_ SvRV(rv), marker);
}

inline SV* rv_payload_sv (pTHX_ SV* rv, const payload_marker_t* marker = NULL) {
    return sv_payload_sv(aTHX_ SvRV(rv), marker);
}

inline int rv_payload_detach (pTHX_ SV* rv, payload_marker_t* marker = NULL) {
    return sv_payload_detach(aTHX_ SvRV(rv), marker);
}

SV* call_next (pTHX_ CV* cv, SV** args, I32 items, next_t type, I32 flags = 0);
inline SV* call_super       (pTHX_ CV* cv, SV** args, I32 items, I32 flags = 0) { return call_next(aTHX_ cv, args, items, NEXT_SUPER, flags); }
inline SV* call_next_method (pTHX_ CV* cv, SV** args, I32 items, I32 flags = 0) { return call_next(aTHX_ cv, args, items, NEXT_METHOD, flags); }
inline SV* call_next_maybe  (pTHX_ CV* cv, SV** args, I32 items, I32 flags = 0) { return call_next(aTHX_ cv, args, items, NEXT_MAYBE, flags); }

I32 _call_sub    (pTHX_ CV* cv, I32 flags, SV** ret, I32 maxret, AV** aref, SV* first_arg, SV** rest_args, I32 rest_items);
I32 _call_method (pTHX_ SV* obj, I32 flags, const char* name, STRLEN len, SV** ret, I32 maxret, AV** aref, SV** args, I32 items);

inline void call_sub_void (pTHX_ CV* cv, SV** args = NULL, I32 items = 0) {
    _call_sub(aTHX_ cv, G_VOID, NULL, 0, NULL, NULL, args, items);
}

inline SV* call_sub_scalar (pTHX_ CV* cv, SV** args = NULL, I32 items = 0, I32 flags = 0) {
    SV* ret = NULL;
    _call_sub(aTHX_ cv, flags|G_SCALAR, &ret, 1, NULL, NULL, args, items);
    return ret;
}

inline I32 call_sub_list (pTHX_ CV* cv, SV** ret, I32 maxret, SV** args = NULL, I32 items = 0, I32 flags = 0) {
    return _call_sub(aTHX_ cv, flags|G_ARRAY, ret, maxret, NULL, NULL, args, items);
}

inline AV* call_sub_av (pTHX_ CV* cv, SV** args = NULL, I32 items = 0, I32 flags = 0) {
    AV* ret;
    _call_sub(aTHX_ cv, flags|G_ARRAY, NULL, 0, &ret, NULL, args, items);
    return ret;

}

inline void call_method_void (pTHX_ SV* obj, const char* name, STRLEN len, SV** args = NULL, I32 items = 0) {
    _call_method(aTHX_ obj, G_VOID, name, len, NULL, 0, NULL, args, items);
}

inline SV* call_method_scalar (pTHX_ SV* obj, const char* name, STRLEN len, SV** args = NULL, I32 items = 0, I32 flags = 0) {
    SV* ret = NULL;
    _call_method(aTHX_ obj, flags|G_SCALAR, name, len, &ret, 1, NULL, args, items);
    return ret;
}

inline I32 call_method_list (pTHX_ SV* obj, const char* name, STRLEN len, SV** ret, I32 maxret, SV** args = NULL, I32 items = 0, I32 flags = 0) {
    return _call_method(aTHX_ obj, flags|G_ARRAY, name, len, ret, maxret, NULL, args, items);
}

inline AV* call_method_av (pTHX_ SV* obj, const char* name, STRLEN len, SV** args = NULL, I32 items = 0, I32 flags = 0) {
    AV* ret;
    _call_method(aTHX_ obj, flags|G_ARRAY, name, len, NULL, 0, &ret, args, items);
    return ret;
}

bool register_package (pTHX_ const char* module, const char* source_module);
void inherit_package  (pTHX_ const char* module, const char* parent);
SV*  error_sv         (const std::exception& err);

class XSBackref : public virtual panda::RefCounted {
    public:
        SV* perl_object;

        void on_perl_dup (pTHX_ int32_t refcnt); /* should be called when interpreter is cloned */

    protected:
        XSBackref () : perl_object(NULL) {}

        virtual void on_retain () const {
            SvREFCNT_inc_simple_void(perl_object);
        }

        // XS DTOR typemap sets perl_object = NULL just before DTOR code, to avoid infinite loop
        virtual void on_release () const {
            SvREFCNT_dec(perl_object);
        }

        virtual ~XSBackref () {};
};

// interface to refcounted object. if user uses its own refcnt base class, he should add overloading for these functions
inline int32_t refcnt_get (const panda::RefCounted* var) { return var->refcnt(); }
inline void    refcnt_inc (const panda::RefCounted* var) { var->retain(); }
inline void    refcnt_dec (const panda::RefCounted* var) { var->release(); }

inline panda::string sv2string (pTHX_ SV* svstr) {
    STRLEN len;
    char* ptr = SvPV(svstr, len);
    return panda::string(ptr, len);
}

inline std::string_view sv2string_view (pTHX_ SV* svstr) {
    STRLEN len;
    char* ptr = SvPV(svstr, len);
    return std::string_view(ptr, len);
}

}

#include <xs/xs-private.h>
