#pragma once

static inline AV* clone_array (pTHX_ AV* av, AV* to = NULL) {
    if (!av) return NULL;
    if (!to) to = newAV();
    SV** list = AvARRAY(av);
    for (I32 i = 0; i <= AvFILLp(av); ++i) {
        SV* val = *list++;
        if (!val) continue;
        SvREFCNT_inc(val);
        av_push(to, val);
    }
    return to;
}

static inline HV* clone_hash (pTHX_ HV* hv, HV* to = NULL) {
    if (!hv) return NULL;
    if (!to) to = newHV();
    HE** list = HvARRAY(hv);
    STRLEN hvmax = HvMAX(hv);
    if (!list) return to;
    for (STRLEN i = 0; i <= hvmax; ++i) {
        for (HE* entry = list[i]; entry; entry = HeNEXT(entry)) {
            SV* val = HeVAL(entry);
            SvREFCNT_inc(val);
            hv_store(to, HeKEY(entry), HeKLEN(entry), val, HeHASH(entry));
        }
    }
    return to;
}
