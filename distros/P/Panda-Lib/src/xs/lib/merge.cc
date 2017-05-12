#include <xs/lib/merge.h>
#include <xs/lib/clone.h>

#define MERGE_CAN_ALIAS(flags, value) (!(flags & MERGE_COPY_SOURCE) && !SvROK(value))
#define MERGE_CAN_LAZY(flags, value)  ((flags & MERGE_LAZY) && !SvROK(value))

namespace xs { namespace lib {

static void _hash_merge (pTHX_ HV* dest, HV* source, IV flags);
static void _array_merge (pTHX_ AV* dest, AV* source, IV flags);

static inline void _elem_merge (pTHX_ SV* dest, SV* source, IV flags) {
    if (SvROK(source)) {
        uint8_t type = SvTYPE(SvRV(source));
        if (type == SVt_PVHV && dest != NULL && SvROK(dest) && SvTYPE(SvRV(dest)) == type) {
            _hash_merge(aTHX_ (HV*) SvRV(dest), (HV*) SvRV(source), flags);
            return;
        }
        else if (type == SVt_PVAV && (flags & MERGE_ARRAY_CM) && dest != NULL && SvROK(dest) && SvTYPE(SvRV(dest)) == type) {
            _array_merge(aTHX_ (AV*) SvRV(dest), (AV*) SvRV(source), flags);
            return;
        }

        if ((flags & MERGE_LAZY) && SvOK(dest)) return;

        if (flags & MERGE_COPY_SOURCE) { // deep copy reference value
            SV* copy = newRV_noinc(clone(aTHX_ SvRV(source), false));
            SvSetSV_nosteal(dest, copy);
            SvREFCNT_dec(copy);
            return;
        }

        SvSetSV_nosteal(dest, source);
    }
    else {
        if ((flags & MERGE_LAZY) && SvOK(dest)) return;
        SvSetSV_nosteal(dest, source);
    }
}

static void _hash_merge (pTHX_ HV* dest, HV* source, IV flags) {
    STRLEN hvmax = HvMAX(source);
    HE** hvarr = HvARRAY(source);
    if (!hvarr) return;
    for (STRLEN i = 0; i <= hvmax; ++i) {
        const HE* entry;
        for (entry = hvarr[i]; entry; entry = HeNEXT(entry)) {
            HEK* hek = HeKEY_hek(entry);
            SV* valueSV = HeVAL(entry);
            if ((flags & MERGE_SKIP_UNDEF) && !SvOK(valueSV)) continue; // skip undefs
            if ((flags & MERGE_DELETE_UNDEF) && !SvOK(valueSV)) {
                hv_deletehek(dest, hek, G_DISCARD);
                continue;
            }
            if (MERGE_CAN_LAZY(flags, valueSV)) {
                SV** elemref = hv_fetchhek(dest, hek, 0);
                if (elemref != NULL && SvOK(*elemref)) continue;
            }
            if (MERGE_CAN_ALIAS(flags, valueSV)) { // make aliases for simple values
                SvREFCNT_inc(valueSV);
                hv_storehek(dest, hek, valueSV);
                continue;
            }
            SV* destSV  = *(hv_fetchhek(dest, hek, 1));
            _elem_merge(aTHX_ destSV, valueSV, flags);
        }
    }
}

static void _array_merge (pTHX_ AV* dest, AV* source, IV flags) {
    // we are using low-level code for AV for efficiency (it is 5-10x times faster)
    if (SvREADONLY(dest)) Perl_croak_no_modify();
    SV** srclist = AvARRAY(source);
    SSize_t srcfill = AvFILLp(source);

    if (flags & MERGE_ARRAY_CONCAT) {
        SSize_t savei = AvFILLp(dest) + 1;
        av_extend(dest, savei + srcfill);
        SV** dstlist = AvARRAY(dest);
        if (flags & MERGE_COPY_SOURCE) {
            while (srcfill-- >= 0) {
                SV* elem = *srclist++;
                dstlist[savei++] = elem == NULL ? newSV(0) : clone(aTHX_ elem, false);
            }
        } else {
            while (srcfill-- >= 0) {
                SV* elem = *srclist++;
                if (elem == NULL) dstlist[savei++] = newSV(0);
                else {
                    SvREFCNT_inc_simple_void_NN(elem);
                    dstlist[savei++] = elem;
                }
            }
        }
        AvFILLp(dest) = savei - 1;
    }
    else {
        av_extend(dest, srcfill);
        SV** dstlist = AvARRAY(dest);
        for (int i = 0; i <= srcfill; ++i) {
            SV* elem = *srclist++;
            if (elem == NULL) continue; // skip empty slots
            if ((flags & MERGE_SKIP_UNDEF) && !SvOK(elem)) continue; // skip undefs
            if (MERGE_CAN_LAZY(flags, elem) && dstlist[i] && SvOK(dstlist[i])) continue;
            if (MERGE_CAN_ALIAS(flags, elem)) { // hardcode for speed - make aliases for simple values
                SvREFCNT_inc_simple_void_NN(elem);
                if (AvREAL(dest)) SvREFCNT_dec(dstlist[i]);
                dstlist[i] = elem;
                continue;
            }
            if (!dstlist[i]) dstlist[i] = newSV(0);
            _elem_merge(aTHX_ dstlist[i], elem, flags);
        }
        if (AvFILLp(dest) < srcfill) AvFILLp(dest) = srcfill;
    } 
}

HV* hash_merge (pTHX_ HV* dest, HV* source, IV flags) {
    if (!dest) dest = newHV();
    else if (flags & MERGE_COPY_DEST) dest = (HV*)clone(aTHX_ (SV*)dest, false);
    if (source) _hash_merge(aTHX_ dest, source, flags);
    return dest;
}

SV* merge (pTHX_ SV* dest, SV* source, IV flags) {
    if ((flags & MERGE_COPY) && dest) dest = clone(aTHX_ dest, false);
    if (!source) source = &PL_sv_undef;
    _elem_merge(aTHX_ dest, source, flags);
    return dest;
}

}}
