/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#if (PERL_VERSION < 7)
#include "sort.h"
#endif

#define MODE_TOP      0
#define MODE_SORT     1
#define MODE_PART    2
#define MODE_PARTREF 3

#define INSERTION_CUTOFF 6

static I32
ix_sv_cmp(pTHX_ SV **a, SV **b) {
    int r = sv_cmp(*a, *b);
    return r ? r : a < b ? -1 : 1;
}

static I32
ix_rsv_cmp(pTHX_ SV **a, SV **b) {
    int r = sv_cmp(*b, *a);
    return r ? r : a < b ? -1 : 1;
}

static I32
ix_lsv_cmp(pTHX_ SV **a, SV **b) {
    int r = sv_cmp_locale(*a, *b);
    return r ? r : a < b ? -1 : 1;
}

static I32
ix_rlsv_cmp(pTHX_ SV **a, SV **b) {
    int r = sv_cmp_locale(*b, *a);
    return r ? r : a < b ? -1 : 1;
}

static I32
ix_n_cmp(pTHX_ NV *a, NV *b) {
    NV nv1 = *a;
    NV nv2 = *b;
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : a < b ? -1 : 1;
}

static I32
ix_rn_cmp(pTHX_ NV *a, NV *b) {
    NV nv1 = *b;
    NV nv2 = *a;
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : a < b ? -1 : 1;
}

static I32
ix_i_cmp(pTHX_ IV *a, IV *b) {
    IV iv1 = *a;
    IV iv2 = *b;
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : a < b ? -1 : 1;
}

static I32
ix_ri_cmp(pTHX_ IV *a, IV *b) {
    IV iv1 = *b;
    IV iv2 = *a;
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : a < b ? -1 : 1;
}

static I32
ix_u_cmp(pTHX_ UV *a, UV *b) {
    UV uv1 = *a;
    UV uv2 = *b;
    return uv1 < uv2 ? -1 : uv1 > uv2 ? 1 : a < b ? -1 : 1;
}

static I32
ix_ru_cmp(pTHX_ UV *a, UV *b) {
    UV uv1 = *b;
    UV uv2 = *a;
    return uv1 < uv2 ? -1 : uv1 > uv2 ? 1 : a < b ? -1 : 1;
}

static void *v_alloc(pTHX_ IV n, IV lsize) {
    void *r;
    Newxc(r, n<<lsize, char, void);
    SAVEFREEPV(r);
    return r;
}

static void *av_alloc(pTHX_ IV n, IV lsize) {
    AV *av=(AV*)sv_2mortal((SV*)newAV());
    av_fill(av, n-1);
    return AvARRAY(av);
}

static void i_store(pTHX_ SV *v, void *to) {
    *((IV*)to) = SvIV(v);
}

static void u_store(pTHX_ SV *v, void *to) {
    *((UV*)to) = SvUV(v);
}

static void n_store(pTHX_ SV *v, void *to) {
    *((NV*)to) = SvNV(v);
}

static void sv_store(pTHX_ SV *v, void *to) {
    *((SV**)to) = SvREFCNT_inc(v);
}

#define lsizeof(A) (ilog2(sizeof(A)))

static int ilog2(int i) {
    if (i > 256) croak("internal error");
    if (i > 128) return 8;
    if (i >  64) return 7;
    if (i >  32) return 6;
    if (i >  16) return 5;
    if (i >   8) return 4;
    if (i >   4) return 3;
    if (i >   2) return 2;
    if (i >   1) return 1;
    return 0;
}

typedef I32 (*COMPARE_t)(pTHX_ void*, void*);
typedef void (*STORE_t)(pTHX_ SV*, void*);

I32
_keytop(pTHX_ IV type, SV *keygen, IV top, int mode, I32 offset, IV items, I32 ax, I32 warray) {
    int deep = (((mode == MODE_SORT) && !warray) ? 1 : 0);
    int dir = 1;

    if (top < 0) {
        dir = -1;
        top = -top;
    }

    if (top > items) {
        if (warray || (mode == MODE_PARTREF))
            top = items;
        else
            return 0;
    }

    if (top && (items > 1) && ((top < items) || (mode == MODE_SORT))) {
        dSP;
        void *keys;
        void **ixkeys;
        SV *old_defsv;
        U32 lsize;
        COMPARE_t cmp;
        STORE_t store;
        int already_sorted = 0;

        switch (type) {
        case 0:
            cmp = (COMPARE_t)&ix_sv_cmp;
            lsize = lsizeof(SV*);
            keys = av_alloc(aTHX_ items, lsize);
            store = &sv_store;
            break;
	case 1:
	    cmp = (COMPARE_t)&ix_lsv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ items, lsize);
	    store = &sv_store;
	    break;
	case 2:
	    cmp = (COMPARE_t)&ix_n_cmp;
	    lsize = lsizeof(NV);
	    keys = v_alloc(aTHX_ items, lsize);
	    store = &n_store;
	    break;
	case 3:
	    cmp = (COMPARE_t)&ix_i_cmp;
	    lsize = lsizeof(IV);
	    keys = v_alloc(aTHX_ items, lsize);
	    store = &i_store;
	    break;
	case 4:
	    cmp = (COMPARE_t)&ix_u_cmp;
	    lsize = lsizeof(UV);
	    keys = v_alloc(aTHX_ items, lsize);
	    store = &u_store;
	    break;
	case 128:
	    cmp = (COMPARE_t)&ix_rsv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ items, lsize);
	    store = &sv_store;
	    break;
	case 129:
	    cmp = (COMPARE_t)&ix_rlsv_cmp;
	    lsize = lsizeof(SV*);
	    keys = av_alloc(aTHX_ items, lsize);
	    store = &sv_store;
	    break;
	case 130:
	    cmp = (COMPARE_t)&ix_rn_cmp;
	    lsize = lsizeof(NV);
	    keys = v_alloc(aTHX_ items, lsize);
	    store = &n_store;
	    break;
	case 131:
	    cmp = (COMPARE_t)&ix_ri_cmp;
	    lsize = lsizeof(IV);
	    keys = v_alloc(aTHX_ items, lsize);
	    store = &i_store;
	    break;
	case 132:
	    cmp = (COMPARE_t)&ix_ru_cmp;
	    lsize = lsizeof(UV);
	    keys = v_alloc(aTHX_ items, lsize);
	    store = &u_store;
	    break;
        default:
            croak("unsupported type %d", (int)type);
        }
        Newx(ixkeys, items, void*);
        SAVEFREEPV(ixkeys);
        if (keygen) {
            if (SvROK(keygen)) {
                I32 i;
                old_defsv = DEFSV;
                SAVE_DEFSV;
                for (i = 0; i<items; i++) {
                    I32 count;
                    SV *current;
                    SV *result;
                    void *target;
                    ENTER;
                    SAVETMPS;
                    current = ST(i + offset);
                    DEFSV = current ? current : sv_newmortal();
                    PUSHMARK(SP);
                    PUTBACK;
                    count = call_sv(keygen, G_SCALAR);
                    SPAGAIN;
                    if (count != 1)
                        croak("wrong number of results returned from key generation sub");
                    result = POPs;
                    ixkeys[i] = target = ((char*)keys) + (i << lsize);
                    (*store)(aTHX_ result, target);
                    FREETMPS;
                    LEAVE;
                }
                DEFSV = old_defsv;
            }
            else {
                int i;
                for (i = 0; i < items; i++) {
                    SV *current = ST(i + offset);
                    if (current && SvROK(current)) {
                        SV **resultp;
                        void *target;

                        SV *rv = (SV*)SvRV(current);
                        if (SvTYPE(rv) == SVt_PVAV) {
                            resultp = av_fetch((AV*)rv, SvIV(keygen), 0);
                        }
                        else if (SvTYPE(rv) == SVt_PVHV) {
                            STRLEN len;
                            char *pv = SvPV(keygen, len);
                            resultp = hv_fetch((HV*)rv, pv, (SvUTF8(keygen) ? -len : len), 0);
                        }
                        else goto bad_ref;

                        ixkeys[i] = target = ((char*)keys) + (i << lsize);
                        (*store)(aTHX_ (resultp ? *resultp : &PL_sv_undef), target);
                    }
                    else {
                    bad_ref:
                        croak("argument at position %d is not an array or hash reference", (int)(i + items));
                    }
                }
            }
        }
        else {
            I32 i;
            for (i=0; i<items; i++) {
                void *target;
                SV *current = ST(i+offset);
                ixkeys[i] = target = ((char*)keys)+(i<<lsize);
                (*store)(aTHX_
                         current ? current : sv_newmortal(),
                         target);
            }
        }

        if ((mode == MODE_SORT) && (top == items) && !warray) {
            top = 1;
            dir = -dir;
        }

        if ((top == 1) && (mode != MODE_PART) && (mode != MODE_PARTREF)) {
            I32 p = 0, i;
            for (i = 1; i < items; i++)
                if (cmp(aTHX_ ixkeys[p], ixkeys[i]) == dir)
                    p = i;
            ST(0) = ST(offset + p);
            return 1;
        }

        if (top < items) {
            if (top <= INSERTION_CUTOFF) {
                I32 n, i, j;
                void *current;

                for (n = i = 1; i < items; i++) {
                    current = ixkeys[i];
                    for (j = n; j; j--) {
                        if (cmp(aTHX_ ixkeys[j - 1], current) != dir)
                            break;

                        if (j < top)
                            ixkeys[j] = ixkeys[j - 1];
                    }
                    if (j < top) {
                        ixkeys[j] = current;
                        if (n < top)
                            n++;
                    }
                }
                if (dir == 1)
                    already_sorted = 1;
                
            }
            else {
                I32 left = 0;
                I32 right = items - 1;

                while (1) {
                    I32 pivot = (left + right) >> 1;
                    void *pivot_value = ixkeys[pivot];
                    I32 i;
                    SV *out = sv_newmortal();

                    ixkeys[pivot] = ixkeys[right];
                    for (pivot = i = left; i < right; i++) {
                        if (cmp(aTHX_ ixkeys[i], pivot_value) != dir) {
                            void *swap = ixkeys[i];
                            ixkeys[i] = ixkeys[pivot];
                            ixkeys[pivot] = swap;
                            pivot++;
                        }
                    }
                    ixkeys[right] = ixkeys[pivot];
                    ixkeys[pivot] = pivot_value;
                    if (deep) {
                        if (pivot >= top)
                            right = pivot - 1;
                        else {
                            if (pivot == top - 1)
                                break;
                            left = pivot + 1;
                        }
                    }
                    else {
                        if (pivot >= top) {
                            right = pivot - 1;
                            if (right < top)
                                break;
                        }
                        if (pivot <= top) {
                            left = pivot + 1;
                            if (left >= top)
                                break;
                        }
                    }
                }
            }
        }
        if (warray) {
            if (mode == MODE_SORT) {
                I32 i;
                sortsv((SV**)ixkeys, top, (SVCOMPARE_t)cmp);
                for(i = 0; i < top; i++) {
                    I32 j = ( ((char*)(ixkeys[i])) - ((char*)keys) ) >> lsize;
                    ixkeys[i] = ST(j + offset);
                }
                for(i = 0; i < top; i++)
                    ST(i) = (SV*)ixkeys[i];
                return top;
            }
            else {
                I32 i;
                unsigned char *bitmap;
                Newxz(bitmap, (items / 8) + 1, unsigned char);
                SAVEFREEPV(bitmap);
                /* this bitmap hack is used to ensure the stability of the operation */
                for (i = 0; i < top; i++) {
                    I32 j = ( ((char*)(ixkeys[i])) - ((char*)keys) ) >> lsize;
                    bitmap[j / 8] |= (1 << (j & 7));
                }
                switch (mode) {
                case MODE_PART:
                {
                    I32 j, to;
                    SV **tail = (SV**)ixkeys;
                    for (to = j = i = 0; i < items; i++) {
                        if (bitmap[i / 8] & (1 << (i & 7)))
                            ST(to++) = ST(i+offset);
                        else
                            tail[j++] = ST(i+offset);
                    }
                    while (to < items)
                        ST(to++) = *(tail++);
                    return items;
                }
                case MODE_PARTREF:
                {
                    AV *a = newAV();
                    AV *b = newAV();
                    SV *arv = sv_2mortal(newRV_noinc((SV*)a));
                    SV *brv = sv_2mortal(newRV_noinc((SV*)b));
                    av_extend(a, top);
                    av_extend(b, items - top);
                    for (i = 0; i < items; i++)
                        av_push(((bitmap[i / 8] & (1 << (i & 7))) ? a : b), newSVsv(ST(i+offset)));
                    ST(0) = arv;
                    ST(1) = brv;
                    return 2;
                }
                case MODE_TOP:
                {
                    I32 to;
                    for (to = i = 0; to < top; i++) {
                        if (bitmap[i / 8] & (1 << (i & 7)))
                            ST(to++) = ST(i+offset);
                    }
                    return top;
                }
                default:
                    Perl_croak(aTHX_ "internal error");
                }
            }
        }
        else { /* !warray */
            if (mode == MODE_SORT) {
                I32 j = ( ((char*)(ixkeys[top - 1])) - ((char*)keys) ) >> lsize;
                ST(0) = ST(offset + j);
                return 1;
            }
            else {
                I32 last, i;
                for (i = 0, last = 0; i < top; i++) {
                    I32 j = ( ((char*)(ixkeys[i])) - ((char*)keys) ) >> lsize;
                    if (j > last)
                        last = j;
                }
                ST(0) = ST(offset + last);
                return 1;
            }
        }
    }
    else if (mode == MODE_PARTREF) {
        I32 i;
        AV *a = newAV();
        SV *arv = sv_2mortal(newRV_noinc((SV*)a));
        SV *brv = sv_2mortal(newRV_noinc((SV*)newAV()));
        av_extend(a, top);
        for (i = 0; i < top; i++)
            av_push(a, newSVsv(ST(i+offset)));
        if (top) {
            ST(0) = arv;
            ST(1) = brv;
        }
        else {
            ST(0) = brv;
            ST(1) = arv;
        }
        return 2;
    }
    else {
        I32 i;
        for (i = 0; i < top; i++)
            ST(i) = ST(i + offset);
        return top;
    }
}

static void
check_keygen(pTHX_ SV *keygen) {
    if (!(keygen && SvROK(keygen) && (SvTYPE(SvRV(keygen)) == SVt_PVCV)))
        Perl_croak(aTHX_ "keygen argument is not a CODE reference");
}

static void
check_slot(pTHX_ SV *slot) {
    if (slot && SvROK(slot))
        Perl_croak(aTHX_ "slot selector can not be a reference");
}

MODULE = Sort::Key::Top		PACKAGE = Sort::Key::Top		
PROTOTYPES: ENABLE

void
keytop(SV *keygen, IV top, ...)
PROTOTYPE: &@
ALIAS:
        lkeytop = 1
        nkeytop = 2
        ikeytop = 3
        ukeytop = 4
        rkeytop = 128
        rlkeytop = 129
        rnkeytop = 130
        rikeytop = 131
        rukeytop = 132
PPCODE:
        check_keygen(aTHX_ keygen);
        XSRETURN(_keytop(aTHX_ ix, keygen, top, 0, 2, items-2, ax, (GIMME_V == G_ARRAY)));

void
top(IV top, ...)
PROTOTYPE: @
ALIAS:
        ltop = 1
        ntop = 2
        itop = 3
        utop = 4
        rtop = 128
        rltop = 129
        rntop = 130
        ritop = 131
        rutop = 132
PPCODE:
        XSRETURN(_keytop(aTHX_ ix, 0, top, 0, MODE_SORT, items-1, ax, (GIMME_V == G_ARRAY)));

void
keypart(SV *keygen, IV top, ...)
PROTOTYPE: &@
ALIAS:
        lkeypart = 1
        nkeypart = 2
        ikeypart = 3
        ukeypart = 4
        rkeypart = 128
        rlkeypart = 129
        rnkeypart = 130
        rikeypart = 131
        rukeypart = 132
PPCODE:
        check_keygen(aTHX_ keygen);
        XSRETURN(_keytop(aTHX_ ix, keygen, top, MODE_PART, 2, items-2, ax, (GIMME_V == G_ARRAY)));

void
part(IV top, ...)
PROTOTYPE: @
ALIAS:
        lpart = 1
        npart = 2
        ipart = 3
        upart = 4
        rpart = 128
        rlpart = 129
        rnpart = 130
        ripart = 131
        rupart = 132
PPCODE:
        XSRETURN(_keytop(aTHX_ ix, 0, top, MODE_PART, 1, items-1, ax, (GIMME_V == G_ARRAY)));

void
keypartref(SV *keygen, IV top, ...)
PROTOTYPE: &@
ALIAS:
        lkeypartref = 1
        nkeypartref = 2
        ikeypartref = 3
        ukeypartref = 4
        rkeypartref = 128
        rlkeypartref = 129
        rnkeypartref = 130
        rikeypartref = 131
        rukeypartref = 132
PPCODE:
        check_keygen(aTHX_ keygen);
        XSRETURN(_keytop(aTHX_ ix, keygen, top, MODE_PARTREF, 2, items-2, ax, (GIMME_V == G_ARRAY)));

void
partref(IV top, ...)
PROTOTYPE: @
ALIAS:
        lpartref = 1
        npartref = 2
        ipartref = 3
        upartref = 4
        rpartref = 128
        rlpartref = 129
        rnpartref = 130
        ripartref = 131
        rupartref = 132
PPCODE:
        XSRETURN(_keytop(aTHX_ ix, 0, top, MODE_PARTREF, 1, items-1, ax, (GIMME_V == G_ARRAY)));

void
keytopsort(SV *keygen, IV top, ...)
PROTOTYPE: &@
ALIAS:
        lkeytopsort = 1
        nkeytopsort = 2
        ikeytopsort = 3
        ukeytopsort = 4
        rkeytopsort = 128
        rlkeytopsort = 129
        rnkeytopsort = 130
        rikeytopsort = 131
        rukeytopsort = 132
PPCODE:
        check_keygen(aTHX_ keygen);
        XSRETURN(_keytop(aTHX_ ix, keygen, top, MODE_SORT, 2, items-2, ax, (GIMME_V == G_ARRAY)));

void
topsort(IV top, ...)
PROTOTYPE: @
ALIAS:
        ltopsort = 1
        ntopsort = 2
        itopsort = 3
        utopsort = 4
        rtopsort = 128
        rltopsort = 129
        rntopsort = 130
        ritopsort = 131
        rutopsort = 132
PPCODE:
        XSRETURN(_keytop(aTHX_ ix, 0, top, MODE_SORT, 1, items-1, ax, (GIMME_V == G_ARRAY)));

void
keyhead(SV *keygen, ...)
PROTOTYPE: &@
ALIAS:
        lkeyhead = 1
        nkeyhead = 2
        ikeyhead = 3
        ukeyhead = 4
        rkeyhead = 128
        rlkeyhead = 129
        rnkeyhead = 130
        rikeyhead = 131
        rukeyhead = 132
PPCODE:
        check_keygen(aTHX_ keygen);
        XSRETURN(_keytop(aTHX_ ix, keygen, 1, 0, 1, items-1, ax, 0));

void
keytail(SV *keygen, ...)
PROTOTYPE: &@
ALIAS:
        lkeytail = 1
        nkeytail = 2
        ikeytail = 3
        ukeytail = 4
        rkeytail = 128
        rlkeytail = 129
        rnkeytail = 130
        rikeytail = 131
        rukeytail = 132
PPCODE:
        check_keygen(aTHX_ keygen);
        XSRETURN(_keytop(aTHX_ ix, keygen, -1, 0, 1, items-1, ax, 0));

void
head(...)
PROTOTYPE: @
ALIAS:
        lhead = 1
        nhead = 2
        ihead = 3
        uhead = 4
        rhead = 128
        rlhead = 129
        rnhead = 130
        rihead = 131
        ruhead = 132
PPCODE:
        XSRETURN(_keytop(aTHX_ ix, 0, 1, 0, 0, items, ax, 0));

void
tail(...)
PROTOTYPE: @
ALIAS:
        ltail = 1
        ntail = 2
        itail = 3
        utail = 4
        rtail = 128
        rltail = 129
        rntail = 130
        ritail = 131
        rutail = 132
PPCODE:
        XSRETURN(_keytop(aTHX_ ix, 0, -1, 0, 0, items, ax, 0));

void
keyatpos(SV *keygen, IV n, ...)
PROTOTYPE: &@
ALIAS:
        lkeyatpos = 1
        nkeyatpos = 2
        ikeyatpos = 3
        ukeyatpos = 4
        rkeyatpos = 128
        rlkeyatpos = 129
        rnkeyatpos = 130
        rikeyatpos = 131
        rukeyatpos = 132
PPCODE:
        check_keygen(aTHX_ keygen);
        XSRETURN(_keytop(aTHX_ ix, keygen, (n < 0 ? n : n + 1), 1, 2, items-2, ax, 0));

void
atpos(IV n, ...)
PROTOTYPE: @
ALIAS:
        latpos = 1
        natpos = 2
        iatpos = 3
        uatpos = 4
        ratpos = 128
        rlatpos = 129
        rnatpos = 130
        riatpos = 131
        ruatpos = 132
PPCODE:
        XSRETURN(_keytop(aTHX_ ix, 0, (n < 0 ? n : n + 1), 1, 1, items-1, ax, 0));

void
slottop(SV *slot, IV top, ...)
PROTOTYPE: @
ALIAS:
        lslottop = 1
        nslottop = 2
        islottop = 3
        uslottop = 4
        rslottop = 128
        rlslottop = 129
        rnslottop = 130
        rislottop = 131
        ruslottop = 132
PPCODE:
        check_slot(aTHX_ slot);
        XSRETURN(_keytop(aTHX_ ix, slot, top, 0, 2, items-2, ax, (GIMME_V == G_ARRAY)));

void
slotpart(SV *slot, IV top, ...)
PROTOTYPE: @
ALIAS:
        lslotpart = 1
        nslotpart = 2
        islotpart = 3
        uslotpart = 4
        rslotpart = 128
        rlslotpart = 129
        rnslotpart = 130
        rislotpart = 131
        ruslotpart = 132
PPCODE:
        check_slot(aTHX_ slot);
        XSRETURN(_keytop(aTHX_ ix, slot, top, MODE_PART, 2, items-2, ax, (GIMME_V == G_ARRAY)));

void
slotpartref(SV *slot, IV top, ...)
PROTOTYPE: @
ALIAS:
        lslotpartref = 1
        nslotpartref = 2
        islotpartref = 3
        uslotpartref = 4
        rslotpartref = 128
        rlslotpartref = 129
        rnslotpartref = 130
        rislotpartref = 131
        ruslotpartref = 132
PPCODE:
        check_slot(aTHX_ slot);
        XSRETURN(_keytop(aTHX_ ix, slot, top, MODE_PARTREF, 2, items-2, ax, (GIMME_V == G_ARRAY)));

void
slottopsort(SV *slot, IV top, ...)
PROTOTYPE: @
ALIAS:
        lslottopsort = 1
        nslottopsort = 2
        islottopsort = 3
        uslottopsort = 4
        rslottopsort = 128
        rlslottopsort = 129
        rnslottopsort = 130
        rislottopsort = 131
        ruslottopsort = 132
PPCODE:
        check_slot(aTHX_ slot);
        XSRETURN(_keytop(aTHX_ ix, slot, top, MODE_SORT, 2, items-2, ax, (GIMME_V == G_ARRAY)));

void
slothead(SV *slot, ...)
PROTOTYPE: @
ALIAS:
        lslothead = 1
        nslothead = 2
        islothead = 3
        uslothead = 4
        rslothead = 128
        rlslothead = 129
        rnslothead = 130
        rislothead = 131
        ruslothead = 132
PPCODE:
        check_slot(aTHX_ slot);
        XSRETURN(_keytop(aTHX_ ix, slot, 1, 0, 1, items-1, ax, 0));

void
slottail(SV *slot, ...)
PROTOTYPE: @
ALIAS:
        lslottail = 1
        nslottail = 2
        islottail = 3
        uslottail = 4
        rslottail = 128
        rlslottail = 129
        rnslottail = 130
        rislottail = 131
        ruslottail = 132
PPCODE:
        check_slot(aTHX_ slot);
        XSRETURN(_keytop(aTHX_ ix, slot, -1, 0, 1, items-1, ax, 0));

void
slotatpos(SV *slot, IV n, ...)
PROTOTYPE: @
ALIAS:
        lslotatpos = 1
        nslotatpos = 2
        islotatpos = 3
        uslotatpos = 4
        rslotatpos = 128
        rlslotatpos = 129
        rnslotatpos = 130
        rislotatpos = 131
        ruslotatpos = 132
PPCODE:
        check_slot(aTHX_ slot);
        XSRETURN(_keytop(aTHX_ ix, slot, (n < 0 ? n : n + 1), 1, 2, items-2, ax, 0));
