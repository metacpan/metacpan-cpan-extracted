#pragma once
#include <memory>

namespace xs { namespace _tm {

template <class DOWN, class UP>
inline DOWN downgrade (UP* var) { return static_cast<DOWN>(var); }
template <class DOWN, class UP>
inline DOWN downgrade (const panda::shared_ptr<UP, true>& sp) { return panda::static_pointer_cast<typename DOWN::element_type>(sp); }
template <class DOWN, class UP>
inline DOWN downgrade (const panda::shared_ptr<UP, false>& sp) { return panda::static_pointer_cast<typename DOWN::element_type>(sp); }
template <class DOWN, class UP>
inline DOWN downgrade (const std::shared_ptr<UP>& sp) { return std::static_pointer_cast<typename DOWN::element_type>(sp); }

template <class UP, class DOWN>
inline UP upgrade (DOWN* var) { return panda::dyn_cast<UP>(var); }
template <class UP, class DOWN>
inline UP upgrade (const panda::shared_ptr<DOWN, true>& sp) { return panda::dynamic_pointer_cast<typename UP::element_type>(sp); }
template <class UP, class DOWN>
inline UP upgrade (const panda::shared_ptr<DOWN, false>& sp) { return panda::dynamic_pointer_cast<typename UP::element_type>(sp); }
template <class UP, class DOWN>
inline UP upgrade (const std::shared_ptr<DOWN>& sp) { return std::dynamic_pointer_cast<typename UP::element_type>(sp); }


inline SV* out_oref (pTHX_ SV* var, HV* CLASS) {
    return var ? sv_bless(newRV_noinc(var), CLASS) : &PL_sv_undef;
}
inline SV* out_oref (pTHX_ SV* var, const char* CLASS) {
    return out_oref(aTHX_ var, gv_stashpvn(CLASS, strlen(CLASS), GV_ADD));
}
inline SV* out_oref (pTHX_ SV* var, SV* CLASS) {
    return out_oref(aTHX_ var, gv_stashsv(CLASS, GV_ADD));
}

inline SV* out_optr (pTHX_ void* var, HV* CLASS) {
    return var ? sv_bless(newRV_noinc(newSViv((IV)var)), CLASS) : &PL_sv_undef;
}
inline SV* out_optr (pTHX_ void* var, const char* CLASS) {
    return out_optr(aTHX_ var, gv_stashpvn(CLASS, strlen(CLASS), GV_ADD));
}
inline SV* out_optr (pTHX_ void* var, SV* CLASS) {
    return out_optr(aTHX_ var, gv_stashsv(CLASS, GV_ADD));
}

template <class T, typename C>
inline SV* out_optr (pTHX_ const panda::shared_ptr<T, true>& sp, C CLASS) {
     if (sp) sp->retain();
     return out_optr(aTHX_ sp.get(), CLASS);
}

template <class T, typename C>
inline SV* out_optr (pTHX_ const panda::shared_ptr<T, false>& sp, C CLASS) {
    return out_optr(aTHX_ new panda::shared_ptr<T>(sp), CLASS);
}

template <class T, typename C>
inline SV* out_optr (pTHX_ const std::shared_ptr<T>& sp, C CLASS) {
    return out_optr(aTHX_ new std::shared_ptr<T>(sp), CLASS);
}



template <class T>
void* out_oext_mgp (T* varptr) { return varptr; }
template <class T>
void* out_oext_mgp (const panda::shared_ptr<T, true>& sp) { if (sp) sp->retain(); return sp.get(); }
template <class T>
void* out_oext_mgp (const panda::shared_ptr<T, false>& sp) { return new panda::shared_ptr<T>(sp); }
template <class T>
void* out_oext_mgp (const std::shared_ptr<T>& sp) { return new std::shared_ptr<T>(sp); }

SV* _out_oext (pTHX_ SV* self, void* var, HV* CLASS, payload_marker_t* marker = NULL);
SV* _out_oext (pTHX_ SV* self, void* var, SV* CLASS, payload_marker_t* marker = NULL);
SV* _out_oext (pTHX_ SV* self, void* var, const char* CLASS, payload_marker_t* marker = NULL);

template <class T, typename C>
inline SV* out_oext (pTHX_ SV* self, T var, C CLASS, payload_marker_t* marker = NULL) {
     return _out_oext(aTHX_ self, out_oext_mgp(var), CLASS, marker);
}



template <class T>
inline void* in_optr (pTHX_ SV* arg, T* varptr) {
    if (sv_isobject(arg)) {
        SV* obj = SvRV(arg);
        if (SvIOK(obj)) {
            void* mgp = (void*)SvIVX(obj);
            *varptr = static_cast<T>(mgp);
            return mgp;
        }
    }
    *varptr = NULL;
    return NULL;
}

template <class T>
inline void* in_optr (pTHX_ SV* arg, panda::shared_ptr<T,true>* sptr) {
    void* mgp;
    in_optr(aTHX_ arg, &mgp);
    *sptr = static_cast<T*>(mgp);
    return mgp;
}

template <class T>
inline void* in_optr (pTHX_ SV* arg, panda::shared_ptr<T,false>* sptr) {
    void* mgp;
    in_optr(aTHX_ arg, &mgp);
    *sptr = *(static_cast<panda::shared_ptr<T,false>*>(mgp));
    return mgp;
}

template <class T>
inline void* in_optr (pTHX_ SV* arg, std::shared_ptr<T>* sptr) {
    void* mgp;
    in_optr(aTHX_ arg, &mgp);
    *sptr = *(static_cast<std::shared_ptr<T>*>(mgp));
    return mgp;
}



template <class T>
inline void in_oext_mgp (T* varptr, void* mgp) { *varptr = static_cast<T>(mgp); }
template <class T>
inline void in_oext_mgp (panda::shared_ptr<T,true>* sptr, void* mgp) { *sptr = static_cast<T*>(mgp); }
template <class T>
inline void in_oext_mgp (panda::shared_ptr<T,false>* sptr, void* mgp) { *sptr = *(static_cast<panda::shared_ptr<T,false>*>(mgp)); }
template <class T>
inline void in_oext_mgp (std::shared_ptr<T>* sptr, void* mgp) { *sptr = *(static_cast<std::shared_ptr<T>*>(mgp)); }

// set null only for pointers, not for shared pointers as they are already nulls on creation
template <class T>
inline void vnull (T** varptr) { *varptr = NULL; }
template <class T>
inline void vnull (T* varptr) { PERL_UNUSED_VAR(varptr); }

template <class T>
inline void* in_oext (pTHX_ SV* arg, T* varptr, payload_marker_t* marker = NULL) {
    if (SvROK(arg)) {
        void* mgp = rv_payload(aTHX_ arg, marker);
        if (mgp) {
            in_oext_mgp(varptr, mgp);
            return mgp;
        }
    }
    vnull(varptr);
    return NULL;
}


template <class T>
struct AutoRelease {
    T obj;
    AutoRelease (T obj) : obj(obj) {}
    ~AutoRelease () { xs::refcnt_dec(obj); }
};

template <class UP, class DOWN>
struct AutoDelete {
    UP obj;
    AutoDelete (UP obj, void* /*mgp*/) : obj(obj) {}
    ~AutoDelete () { delete obj; }
};

// These destructors don't kill an object instantly, because it is possibly needed for user-defined XS DESTROY function code.
// local $var shared ptr holds it until the end of DESTROY XS function
// These funcs just decrease refcnt, so that local $var shared ptr becomes the last owner of the object.
template <class UP, class DOWN>
struct AutoDelete<panda::shared_ptr<UP, true>, DOWN> {
    AutoDelete (const panda::shared_ptr<UP, true>& sp, void* /*mgp*/) { sp->release(); }
};

template <class UP, class DOWN>
struct AutoDelete<panda::shared_ptr<UP, false>, DOWN> {
    AutoDelete (const panda::shared_ptr<UP, false>& /*sp*/, void* mgp) { delete static_cast<panda::shared_ptr<DOWN,false>*>(mgp); }
};

template <class UP, class DOWN>
struct AutoDelete<std::shared_ptr<UP>, DOWN> {
    AutoDelete (const std::shared_ptr<UP>& /*sp*/, void* mgp) { delete static_cast<std::shared_ptr<DOWN>*>(mgp); }
};

template <class T>
xs::XSBackref* get_xsbr (T var) { return panda::dyn_cast<xs::XSBackref*>(var); }
template <class T>
xs::XSBackref* get_xsbr (panda::shared_ptr<T,true>& var) { return panda::dyn_cast<xs::XSBackref*>(var.get()); }
template <class T>
xs::XSBackref* get_xsbr (panda::shared_ptr<T,false>& var) { return panda::dyn_cast<xs::XSBackref*>(var.get()); }
template <class T>
xs::XSBackref* get_xsbr (std::shared_ptr<T>& var) { return panda::dyn_cast<xs::XSBackref*>(var.get()); }

template <class T>
T svdup_clone (pTHX_ T obj) { return obj->clone(); }
template <class T>
T svdup_retain (pTHX_ T obj) { xs::refcnt_inc(obj); return obj; }

}}
