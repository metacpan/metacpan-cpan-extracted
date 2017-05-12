#include <map>
#include <string>
#include <stdexcept>
#include <xs/xs.h>

namespace xs {

my_perl_auto_t my_perl;

payload_marker_t sv_payload_default_marker;
std::map<std::string, payload_marker_t> sv_class_markers;

const int CVf_NEXT_WRAPPER_CREATED = 0x10000000;

payload_marker_t* sv_payload_marker (const char* class_name, on_svdup_t dup_callback) {
    if (!class_name[0]) return &sv_payload_default_marker;
    payload_marker_t* marker = &sv_class_markers[class_name];
    if (!marker->svt_dup && dup_callback) marker->svt_dup = dup_callback;
    return marker;
}

static SV* _next_create_wrapper (pTHX_ CV* cv, next_t type) {
    CvFLAGS(cv) |= CVf_NEXT_WRAPPER_CREATED;
    GV* gv = CvGV(cv);
    HV* stash = GvSTASH(gv);
    std::string name = GvNAME(gv);
    std::string stashname = HvNAME(stash);
    std::string origxs = "_xs_orig_" + name;
    std::string next_code;
    switch (type) {
        case NEXT_SUPER:  next_code = "shift->SUPER::" + name; break;
        case NEXT_METHOD: next_code = "next::method"; break;
        case NEXT_MAYBE:  next_code = "maybe::next::method"; break;
    }
    if (!next_code.length()) throw std::invalid_argument("type");
    std::string code =
        "package " + stashname + ";\n" +
        "use feature 'state';\n" +
        "no warnings 'redefine';\n" +
        "BEGIN { *" + origxs + " = \\&" + name + "; }\n" +
        "sub " + name + " {\n" +
        "    eval q!sub " + name + " { " + origxs + "(@_) } !;\n" +
        "    " + next_code + "(@_);\n" +
        "}\n" +
        "\\&" + name;
    return eval_pv(code.c_str(), 1);
}

SV* call_next (pTHX_ CV* cv, SV** args, I32 items, next_t type, I32 flags) {
    SV* ret = NULL;
    if (CvFLAGS(cv) & CVf_NEXT_WRAPPER_CREATED) { // ensure module has a perl wrapper for cv
        dSP; ENTER; SAVETMPS;
        PUSHMARK(SP);
        for (I32 i = 0; i < items; ++i) XPUSHs(*args++);
        PUTBACK;
        int count;
        if (type == NEXT_SUPER) {
            GV* gv = CvGV(cv);
            GV* supergv = gv_fetchmethod_pvn_flags(
                GvSTASH(gv), GvNAME(gv), GvNAMELEN(gv), GV_CROAK|GV_SUPER|(GvNAMEUTF8(gv) ? SVf_UTF8 : 0)
            );
            count = call_sv((SV*)GvCV(supergv), flags|G_SCALAR);
        } else {
            count = call_method(type == NEXT_METHOD ? "next::method" : "maybe::next::method", flags|G_SCALAR);
        }
        SPAGAIN;
        while (count--) ret = POPs;
        SvREFCNT_inc_simple(ret);
        PUTBACK;
        FREETMPS; LEAVE;
    }
    else {
        SV* wrapper = _next_create_wrapper(aTHX_ cv, type);
        dSP; ENTER; SAVETMPS;
        PUSHMARK(SP);
        for (I32 i = 0; i < items; ++i) XPUSHs(*args++);
        PUTBACK;
        int count = call_sv(wrapper, flags|G_SCALAR);
        SPAGAIN;
        while (count--) ret = POPs;
        SvREFCNT_inc_simple_void(ret);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    return ret;
}

I32 _call_sub (pTHX_ CV* cv, I32 flags, SV** ret, I32 maxret, AV** aref, SV* first_arg, SV** rest_args, I32 rest_items) {
    dSP; ENTER; SAVETMPS;
    PUSHMARK(SP);
    if (first_arg) XPUSHs(first_arg);
    for (I32 i = 0; i < rest_items; ++i) XPUSHs(*rest_args++);
    PUTBACK;
    if (maxret <= 0 && !aref) { flags |= G_DISCARD; maxret = 0; }
    I32 count = call_sv((SV*)cv, flags);
    I32 nret = count > maxret ? maxret : count;
    SPAGAIN;

    if (!aref) {
        while (count > maxret) { POPs; --count; }
        while (count > 0) ret[--count] = SvREFCNT_inc_NN(POPs);
    }
    else if (count) {
        AV* arr = *aref = newAV();
        av_extend(arr, count-1);
        AvFILLp(arr) = count-1;
        SV** svlist = AvARRAY(arr);
        while (count--) svlist[count] = SvREFCNT_inc_NN(POPs);
    }
    else *aref = NULL;

    PUTBACK;
    FREETMPS; LEAVE;

    if (aref && *aref) sv_2mortal((SV*)*aref);
    else for (I32 i = 0; i < nret; ++i) sv_2mortal(ret[i]);

    return nret;
}

I32 _call_method (pTHX_ SV* obj, I32 flags, const char* name, STRLEN len, SV** ret, I32 maxret, AV** aref, SV** args, I32 items) {
    HV* stash = NULL;
    if (SvROK(obj)) {
        SV* sv = SvRV(obj);
        if (SvOBJECT(sv)) stash = SvSTASH(sv);
    }
    if (!stash) stash = gv_stashsv(obj, GV_ADD);

    GV* methgv = gv_fetchmethod_pvn_flags(stash, name, len, GV_CROAK);

    return _call_sub(aTHX_ GvCV(methgv), flags, ret, maxret, aref, obj, args, items);
}


/* should be called when interpreter is cloned. If we get here then our perl_object is cloned, that is it is present in PL_ptr_table
 * So we only need to get the new pointer instead of the old one */
void XSBackref::on_perl_dup (pTHX_ int32_t refcnt) {
    if (perl_object) {
        perl_object = MUTABLE_SV(ptr_table_fetch(PL_ptr_table, perl_object));
        assert(perl_object); assert(refcnt);
        SvREFCNT(perl_object) = refcnt;
    }
}

static size_t module2path (const char* module, char* path) {
    char* pathptr = path;
    while (*module) {
        if (*module == ':') {
            *pathptr = '/';
            ++module;
        }
        else *pathptr = *module;
        ++pathptr;
        ++module;
    }
    *pathptr++ = '.';
    *pathptr++ = 'p';
    *pathptr++ = 'm';
    *pathptr = 0;
    return pathptr-path;
}

bool register_package (pTHX_ const char* module, const char* source_module) {
    char source_module_path[strlen(source_module)+4];
    size_t source_module_path_len = module2path(source_module, source_module_path);

    HV* inc = get_hv("INC", GV_ADD);
    SV** ref = hv_fetch(inc, source_module_path, source_module_path_len, 0);
    if (!ref) return false;

    char module_path[strlen(module)+4];
    size_t module_path_len = module2path(module, module_path);
    hv_store(inc, module_path, module_path_len, SvREFCNT_inc(*ref), 0);
    return true;
}

void inherit_package (pTHX_ const char* module, const char* parent) {
    size_t mlen = strlen(module);
    char module_isa[mlen + 6];
    memcpy(module_isa, module, mlen);
    module_isa[mlen]   = ':';
    module_isa[mlen+1] = ':';
    module_isa[mlen+2] = 'I';
    module_isa[mlen+3] = 'S';
    module_isa[mlen+4] = 'A';
    module_isa[mlen+5] = 0;
    av_push(get_av(module_isa, GV_ADD), newSVpv_share(parent, 0));
}

namespace _tm {

    static inline HV* _get_stash (pTHX_ HV* stash)         { return stash; }
    static inline HV* _get_stash (pTHX_ SV* CLASS)         { return gv_stashsv(CLASS, GV_ADD); }
    static inline HV* _get_stash (pTHX_ const char* CLASS) { return gv_stashpvn(CLASS, strlen(CLASS), GV_ADD); }

    template <typename C>
    static inline SV* _out_oext_ (pTHX_ SV* obase, void* var, C CLASS, payload_marker_t* marker) {
        if (!var) return &PL_sv_undef;
        SV* objrv;
        if (obase) {
            if (SvROK(obase)) {
                objrv = obase;
                obase = SvRV(obase);
            }
            else {
                objrv = newRV_noinc(obase);
                sv_bless(objrv, _get_stash(aTHX_ CLASS));
            }
        } else {
            obase = newSV(0);
            objrv = newRV_noinc(obase);
            sv_bless(objrv, _get_stash(aTHX_ CLASS));
        }
        sv_payload_attach(aTHX_ obase, var, marker);
        return objrv;
    }

    SV* _out_oext (pTHX_ SV* obase, void* var, HV* CLASS, payload_marker_t* marker) {
        return _out_oext_(aTHX_ obase, var, CLASS, marker);
    }

    SV* _out_oext (pTHX_ SV* obase, void* var, SV* CLASS, payload_marker_t* marker) {
        return _out_oext_(aTHX_ obase, var, CLASS, marker);
    }

    SV* _out_oext (pTHX_ SV* obase, void* var, const char* CLASS, payload_marker_t* marker) {
        return _out_oext_(aTHX_ obase, var, CLASS, marker);
    }
}

};
