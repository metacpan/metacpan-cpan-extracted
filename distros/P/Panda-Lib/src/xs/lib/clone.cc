#include <map>
#include <panda/lib.h>
#include <xs/lib/clone.h>

#ifndef gv_fetchmeth
#define gv_fetchmeth(stash,name,len,level,flags) gv_fetchmethod_autoload(stash,name,0)
#endif

namespace xs { namespace lib {

using panda::unlikely;

static const char* HOOK_METHOD  = "HOOK_CLONE";
static const int   HOOK_METHLEN = strlen(HOOK_METHOD);

typedef std::map<uint64_t, SV*> CloneMap;
static const int CLONE_MAX_DEPTH = 5000;
static MGVTBL clone_marker;

static void _clone (pTHX_ SV* dest, SV* source, CloneMap* map, I32 depth);

SV* clone (pTHX_ SV* source, bool cross) {
    SV* ret = newSV(0);
    try {
        if (cross) {
            CloneMap map;
            _clone(aTHX_ ret, source, &map, 0);
        }
        else _clone(aTHX_ ret, source, NULL, 0);
    } catch (int val) {
        SvREFCNT_dec(ret);
        croak("clone: max depth (%d) reached, it looks like you passed a cycled structure", CLONE_MAX_DEPTH);
    }
    return ret;
}

static void _clone (pTHX_ SV* dest, SV* source, CloneMap* map, I32 depth) {
    if (depth > CLONE_MAX_DEPTH) throw 1;

    if (SvROK(source)) { // reference
        SV* source_val = SvRV(source);
        svtype val_type = SvTYPE(source_val);

        if (unlikely(val_type == SVt_PVCV || val_type == SVt_PVIO)) { // CV and IO cannot be copied - just set reference to the same SV
            SvSetSV_nosteal(dest, source);
            return;
        }

        if (map) {
            uint64_t id = PTR2UV(source_val);
            CloneMap::iterator it = map->find(id);
            if (it != map->end()) {
                SvSetSV_nosteal(dest, it->second);
                return;
            }
            (*map)[id] = dest;
        }

        GV* cloneGV;
        bool is_object = SvOBJECT(source_val);

        // cloning an object with custom clone behavior
        if (is_object && !mg_findext(source_val, PERL_MAGIC_ext, &clone_marker) &&
            (cloneGV = gv_fetchmeth(SvSTASH(source_val), HOOK_METHOD, HOOK_METHLEN, 0)))
        {
            // set cloning flag into object's magic to prevent infinite loop if user calls 'clone' again from hook
            sv_magicext(source_val, NULL, PERL_MAGIC_ext, &clone_marker, "", 0);
            dSP; ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(source);
            PUTBACK;
            int count = call_sv((SV*)GvCV(cloneGV), G_SCALAR);
            SPAGAIN;
            SV* retval = NULL;
            while (count--) retval = POPs;
            if (retval) SvSetSV(dest, retval);
            PUTBACK;
            FREETMPS; LEAVE;
            // remove cloning flag from object's magic
            sv_unmagicext(source_val, PERL_MAGIC_ext, &clone_marker);
            return;
        }

        SV* refval = newSV(0);
        sv_upgrade(dest, SVt_RV);
        SvRV_set(dest, refval);
        SvROK_on(dest);

        if (is_object) sv_bless(dest, SvSTASH(source_val)); // cloning an object without any specific clone behavior
        _clone(aTHX_ refval, source_val, map, depth+1);

        return;
    }

    switch (SvTYPE(source)) {
        case SVt_IV:     // integer
        case SVt_NV:     // long double
        case SVt_PV:     // string
        case SVt_PVIV:   // string + integer
        case SVt_PVNV:   // string + long double
        case SVt_PVMG:   // blessed scalar (doesn't really true, it's just vars or magic vars)
        case SVt_PVGV:   // typeglob
#if PERL_VERSION > 16
        case SVt_REGEXP: // regexp
#endif
            SvSetSV_nosteal(dest, source);
            return;
#if PERL_VERSION <= 16 // fix bug in SvSetSV_nosteal while copying regexp SV prior to perl 5.16.0
        case SVt_REGEXP: // regexp
            SvSetSV_nosteal(dest, source);
            if (SvSTASH(dest) == NULL) SvSTASH_set(dest, gv_stashpv("Regexp",0));
            return;
#endif
        case SVt_PVAV: { // array
            sv_upgrade(dest, SVt_PVAV);
            SV** srclist = AvARRAY((AV*)source);
            SSize_t srcfill = AvFILLp((AV*)source);
            av_extend((AV*)dest, srcfill); // dest is an empty array. we can set directly it's SV** array for speed
            AvFILLp((AV*)dest) = srcfill; // set array len
            SV** dstlist = AvARRAY((AV*)dest);
            for (SSize_t i = 0; i <= srcfill; ++i) {
                SV* srcval = *srclist++;
                if (srcval != NULL) { // if not empty slot
                    SV* elem = newSV(0);
                    dstlist[i] = elem;
                    _clone(aTHX_ elem, srcval, map, depth+1);
                }
            }
            return;
        }
        case SVt_PVHV: { // hash
            sv_upgrade(dest, SVt_PVHV);
            STRLEN hvmax = HvMAX((HV*)source);
            HE** hvarr = HvARRAY((HV*)source);
            if (!hvarr) return;

            for (STRLEN i = 0; i <= hvmax; ++i) {
                const HE* entry;
                for (entry = hvarr[i]; entry; entry = HeNEXT(entry)) {
                    HEK* hek = HeKEY_hek(entry);
                    SV* elem = newSV(0);
                    hv_storehek((HV*)dest, hek, elem);
                    _clone(aTHX_ elem, HeVAL(entry), map, depth+1);
                }
            }

            return;
        }
        case SVt_NULL: // undef
        default: // BIND, LVALUE, FORMAT - are not copied
            return;
    }
}

}}
