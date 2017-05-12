#include <xs/export.h>

#define EX_CROAK_NOSUB(hvname,subname)   croak("Panda::Export: can't export unexisting symbol '%s::%s'", hvname, subname)
#define EX_CROAK_EXISTS(hvname,subname)  croak("Panda::Export: can't create constant '%s::%s' - symbol already exists", hvname, subname)
#define EX_CROAK_NONAME(hvname)          croak("Panda::Export: can't define a constant with an empty name in '%s'", hvname)
#define EX_CROAK_BADNAME(hvname,subname) croak("Panda::Export: can't create constant '%s::%s' - name must be a valid string", hvname, subname)

namespace xs { namespace exp {

static thread_local HV* clists;

AV* constants_list (pTHX_ HV* stash) {
    if (!clists) clists = newHV();
    SV* clist = *hv_fetch(clists, HvNAME(stash), HvNAMELEN(stash), 1);
    AV* ret;
    if (!SvOK(clist)) {
        SvUPGRADE(clist, SVt_RV);
        SvROK_on(clist);
        ret = newAV();
        SvRV_set(clist, (SV*) ret);
    }
    else ret = (AV*)SvRV(clist);
    return ret;
}

void create_constant (pTHX_ HV* stash, SV* name, SV* value, AV* stash_constants_list) {
    if (!stash_constants_list) stash_constants_list = constants_list(aTHX_ stash);
    if (!name) EX_CROAK_NONAME(HvNAME(stash));

    // check that we won't redefine any subroutine
    HE* sym_he = hv_fetch_ent(stash, name, 0, 0);
    if (sym_he && HeVAL(sym_he) && isGV(HeVAL(sym_he)) && GvCV(HeVAL(sym_he))) EX_CROAK_EXISTS(HvNAME(stash), SvPV_nolen(name));

    if (!SvPOK(name)) EX_CROAK_BADNAME(HvNAME(stash), SvPV_nolen(name));
    if (!SvCUR(name)) EX_CROAK_NONAME(HvNAME(stash));

    if (SvIsCOW_shared_hash(name)) SvREFCNT_inc(name);
    else name = newSVpvn_share(SvPVX_const(name), SvCUR(name), 0);

    av_push(stash_constants_list, name);

    if (value) SvREFCNT_inc(value);
    else value = newSV(0);
    SvREADONLY_on(value);
    newCONSTSUB(stash, SvPVX_const(name), value);
}

void create_constant (pTHX_ HV* stash, const char* name, const char* value, AV* stash_constants_list) {
    SV* namesv = newSVpvn_share(name, strlen(name), 0);
    SV* valuesv = newSVpv(value, 0);
    create_constant(aTHX_ stash, namesv, valuesv, stash_constants_list);
    SvREFCNT_dec_NN(namesv);
    SvREFCNT_dec_NN(valuesv);
}

void create_constant (pTHX_ HV* stash, const char* name, int64_t value, AV* stash_constants_list) {
    SV* namesv = newSVpvn_share(name, strlen(name), 0);
    SV* valuesv = newSViv(value);
    create_constant(aTHX_ stash, namesv, valuesv, stash_constants_list);
    SvREFCNT_dec_NN(namesv);
    SvREFCNT_dec_NN(valuesv);
}

void create_constant (pTHX_ HV* stash, constant_t constant, AV* stash_constants_list) {
    if (constant.svalue) create_constant(aTHX_ stash, constant.name, constant.svalue, stash_constants_list);
    else create_constant(aTHX_ stash, constant.name, constant.value, stash_constants_list);
}

void create_constants (pTHX_ HV* stash, HV* constants) {
    AV* clist = constants_list(aTHX_ stash);
    XS_HV_ITER(constants, {
        SV* name = newSVpvn_share(HeKEY(he), HeKLEN(he), HeHASH(he));
        create_constant(aTHX_ stash, name, HeVAL(he), clist);
        SvREFCNT_dec_NN(name);
    });
}

void create_constants (pTHX_ HV* stash, SV** list, size_t items) {
    if (!list || !items) return;
    AV* clist = constants_list(aTHX_ stash);
    for (size_t i = 0; i < items - 1; i += 2) {
        SV* name  = *list++;
        SV* value = *list++;
        create_constant(aTHX_ stash, name, value, clist);
    }
}

void create_constants (pTHX_ HV* stash, constant_t* list, size_t items) {
    if (!list || !items) return;
    AV* clist = constants_list(aTHX_ stash);
    while (items--) {
        constant_t constant = *list++;
        if (!constant.name) break;
        SV* namesv  = newSVpvn_share(constant.name, strlen(constant.name), 0);
        SV* valuesv = constant.svalue ? newSVpv(constant.svalue, 0) : newSViv(constant.value);
        create_constant(aTHX_ stash, namesv, valuesv, clist);
        SvREFCNT_dec_NN(namesv);
        SvREFCNT_dec_NN(valuesv);
    }
}

static inline void _export_sub (pTHX_ HV* from, HV* to, SV* name) {
    HE* symentry_ent = hv_fetch_ent(from, name, 0, 0);
    GV* symentry = symentry_ent ? (GV*)HeVAL(symentry_ent) : NULL;
    if (!symentry || !GvCV(symentry)) EX_CROAK_NOSUB(HvNAME(from), SvPV_nolen(name));
    SvREFCNT_inc_simple_void_NN((SV*)symentry);
    hv_store_ent(to, name, (SV*)symentry, 0);
}

static inline void _export_sub (pTHX_ HV* from, HV* to, const char* name) {
    size_t namelen = strlen(name);
    SV** symentry_ref = hv_fetch(from, name, namelen, 0);
    GV* symentry = symentry_ref ? (GV*)(*symentry_ref) : NULL;
    if (!symentry || !GvCV(symentry)) EX_CROAK_NOSUB(HvNAME(from), name);
    SvREFCNT_inc_simple_void_NN((SV*)symentry);
    hv_store(to, name, namelen, (SV*)symentry, 0);
}

void export_sub (pTHX_ HV* from, HV* to, SV* name)         { _export_sub(aTHX_ from, to, name); }
void export_sub (pTHX_ HV* from, HV* to, const char* name) { _export_sub(aTHX_ from, to, name); }

void export_constants (pTHX_ HV* from, HV* to) {
    AV* clist = constants_list(aTHX_ from);
    export_subs(aTHX_ from, to, AvARRAY(clist), AvFILLp(clist)+1);
}

void export_subs (pTHX_ HV* from, HV* to, SV** list, size_t items) {
    while (items--) {
        SV* name = *list++;
        if (!name) continue;
        const char* name_str = SvPVX_const(name);
        if (name_str[0] == ':' && strEQ(name_str, ":const")) {
            AV* clist = constants_list(aTHX_ from);
            // this check prevents infinite loop if someone created constant with name ":const"
            if (AvARRAY(clist) != list) export_subs(aTHX_ from, to, AvARRAY(clist), AvFILLp(clist)+1);
            continue;
        }
        _export_sub(aTHX_ from, to, name);
    }
}

void export_subs (pTHX_ HV* from, HV* to, const char** list, size_t items) {
    while (items--) {
        const char* name = *list++;
        if (!name) break;
        if (name[0] == ':' && strEQ(name, ":const")) {
            AV* clist = constants_list(aTHX_ from);
            export_subs(aTHX_ from, to, AvARRAY(clist), AvFILLp(clist)+1);
            continue;
        }
        _export_sub(aTHX_ from, to, name);
    }
}

}}
