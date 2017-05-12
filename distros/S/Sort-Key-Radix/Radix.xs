/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define BE4 1
#define LE4 2
#define BE8 3
#define LE8 4
#define LE12 5
#define BE12 6
#define LE12_x86 7
#define BE16 9
#define LE16 10
#define LE16_x86 11

#include "rconfig.h"

#define CUTOFF 16

#ifdef inline
#undef inline
#endif

#if defined(__GNU__)
#define inline __inline__
#else
#define inline
#endif


static void
print_keys(pTHX_ char *name, unsigned char **keys, int n, int byte) {
    int i;
    printf("%s[%d] %p:", name, byte, keys);
    for (i = 0; i < n; i++) {
        int j;
        UV acu = 0;
        printf(" ");
        for (j = byte; j >= 0; j--)
            printf("%02x", keys[i][j]);
        printf("(");
        for (j = byte; j >= 0; j--)
            printf("%c", (isalnum(keys[i][j]) ? keys[i][j] : '.'));
        printf(")");
    }
    printf("\n\n");
    fflush(stdout);
}

static void
print_blens(pTHX_ int *blens) {
    int i;
    printf("blens:");
    for (i = 0; i < 256; i++)
        printf(" %d", blens[i]);
    printf("\n\n");
    fflush(stdout);
}

static void
radix_sort_1(unsigned char **keys, unsigned char **temps, int n, int byte) {
    
    /* byte must be equal or greater than 0! */
    /* assert (byte >= 0); */

    if (n > CUTOFF) {
        unsigned char **bucket[256];
        int blen[256];
        int i;

        Zero(blen, 256, int);
        
        for (i = 0; i < n; i++)
            blen[keys[i][byte]]++;

        /* print_blens(blen); */
            
        bucket[0] = temps;
        for (i = 0; i < 255; i++)
            bucket[i + 1] = bucket[i] + blen[i];
    
        for (i = 0; i < n; i++)
            *(bucket[keys[i][byte]]++) = keys[i];

        if (byte > 0) {
            byte--;
            for (i = 0; i < 256; i++) {
                int bli = blen[i];
                if (bli) {
                    radix_sort_1(temps, keys, bli, byte);
                    keys += bli;
                    temps += bli;
                }
            }
        }
    }
    else {
        /* insertion sort */
            
        unsigned char **dest = (byte & 1) ? keys : temps;
        int i;

        for (i = 0; i < n; i++) {
            unsigned char *pivot = keys[i];
            int j = i;
            while (j) {
                int k;
                for (k = byte; k >= 0; k--) {
                    unsigned char db =  dest[j - 1][k];
                    
                    if (pivot[k] > db)
                        goto insert_now;

                    if (pivot[k] < db) {
                        /* printf("pivot is <\n"); */
                        dest[j] = dest[j - 1];
                        goto continue_loop_j;
                    }
                }
                break;
            continue_loop_j:
                --j;
            }
        insert_now:
            dest[j] = pivot;
        }
    }
}

static unsigned char *
init_keys(pTHX_
          SV **data, I32 offset, I32 ax, int n,
          SV *keygen,
          void (*sv_to_key)(pTHX_ SV *, unsigned char *, int, int *),
          unsigned char ***keys, unsigned char ***temps, int klen, int *byte) {
    unsigned char *start, *key;
    int i;
    SV **svkeys;

    Newx(*keys, n * 2, unsigned char *);
    SAVEFREEPV(*keys);
    *temps = *keys + n;
    
    Newx(start, n * klen, unsigned char);
    SAVEFREEPV(start);
    
    *byte = 0;
    key = start;

    for (i = 0; i < n; i++, key += klen) {
        SV *current = data ? data[i] : ST(i + offset);
        (*keys)[i] = key;
        if (keygen) {
            dSP;
            IV count;
            SV *result;
            /* printf ("calc key\n"); fflush(stdout); */
            ENTER;
            SAVETMPS;
            SAVE_DEFSV;
            DEFSV = sv_2mortal(current ? SvREFCNT_inc(current) : newSV(0));
            PUSHMARK(SP);
            PUTBACK;
            count = call_sv(keygen, G_SCALAR);
            SPAGAIN;
            if (count != 1)
                Perl_croak(aTHX_ "wrong number of results returned from key generation sub");
            result = POPs;
            (*sv_to_key)(aTHX_ result, key, klen, byte);
            FREETMPS;
            LEAVE;
        }
        else {
            (*sv_to_key)(aTHX_ current, key, klen, byte);
        }
        
    }
    return start;
}

static int
calc_klen_pv(pTHX_ SV **keys, I32 offset, I32 ax, int n) {
    int klen = 0;
    int i;

    for (i = 0; i < n; i++) {
        SV *current = keys ? keys[i] : ST(offset + i);
        if (current) {
            STRLEN cur = SvCUR(current);
            if (cur > klen)
                klen = cur;
        }
    }
    return klen;
}

static SV **
calc_svkeys(pTHX_ SV *keygen, SV **data, I32 offset, I32 ax, int n) {
    int i;
    SV **keys = 0;
    AV *av;

    av = newAV();
    sv_2mortal((SV*)av);
    av_extend(av, n);
    keys = AvARRAY(av);
        
    for (i = 0; i < n; i++) {
        dSP;
        IV count;
        SV *result;
        SV *current = data ? data[i] : ST(offset + i);
        ENTER;
        SAVETMPS;
        SAVE_DEFSV;
        DEFSV = sv_2mortal(current ? SvREFCNT_inc(current) : newSV(0));
        PUSHMARK(SP);
        PUTBACK;
        count = call_sv(keygen, G_SCALAR);
        SPAGAIN;
        if (count != 1)
            Perl_croak(aTHX_ "wrong number of results returned from key generation sub");
        keys[i] = result = POPs;
        if (result)
            SvREFCNT_inc(result);
        FREETMPS;
        LEAVE;
    }
    return keys;
}

static void
resort_as_keys(pTHX_ SV **data, SV **dest, unsigned char *start, unsigned char **keys, int n, int klen) {
    SV **sorted = (SV**)keys;
    int i;
    for (i = 0; i < n; i++) {
        int ix = (keys[i] - start) / klen;
        sorted[i] = data[ix];
    }
    Move(sorted, dest, n, SV *);
}

inline static void
uv_to_key(pTHX_ UV uv, unsigned char *key, int *byte) {
#if UV_FORMAT == LE4 || UV_FORMAT == LE8
    *((UV*)key) = uv;
    while (uv_byte_mask[*byte] & uv)
        (*byte)++;
#else
    int i;
    for (i = sizeof(UV) - 1; i >= 0; i--) {
        unsigned char uc = (uv >> (8 * i));
        key[i] = uc;
        if (uc && i > *byte)
            *byte = i;
    }
#endif
}

static void
sv_uv_to_key(pTHX_ SV *sv, unsigned char *key, int klen, int *byte) {
#if UV_FORMAT == LE4 || UV_FORMAT == LE8
    UV uv = SvUV(sv);
    *((UV*)key) = uv;
    while (uv_byte_mask[*byte] & uv)
        (*byte)++;
#else
    uv_to_key(aTHX_ SvUV(sv), key, byte);
#endif
}

static void
sv_ruv_to_key(pTHX_ SV *sv, unsigned char *key, int klen, int *byte) {
#if UV_FORMAT == LE4 || UV_FORMAT == LE8
    UV uv = ~SvUV(sv);
    *((UV*)key) = uv;
    while (uv_byte_mask[*byte] & uv)
        (*byte)++;
#else
    uv_to_key(aTHX_ ~SvUV(sv), key, byte);
#endif
}

static void
sv_iv_to_key(pTHX_ SV *iv, unsigned char *key, int klen, int *byte) {
#if UV_FORMAT == LE4 || UV_FORMAT == LE8
    UV uv = SvIV(iv) + (((UV)1) << (8 * sizeof(IV) - 1));
    *((UV*)key) = uv;
    while (uv_byte_mask[*byte] & uv)
        (*byte)++;
#else
    uv_to_key(aTHX_ SvIV(iv) + (((UV)1) << (8 * sizeof(IV) - 1)), key, byte);
#endif
}

static void
sv_riv_to_key(pTHX_ SV *iv, unsigned char *key, int klen, int *byte) {
#if UV_FORMAT == LE4 || UV_FORMAT == LE8
    UV uv = ~(UV)(SvIV(iv) + (((UV)1) << (8 * sizeof(IV) - 1)));
    *((UV*)key) = uv;
    while (uv_byte_mask[*byte] & uv)
        (*byte)++;
#else
    uv_to_key(aTHX_ ~(UV)(SvIV(iv) + (((UV)1) << (8 * sizeof(IV) - 1))), key, byte);
#endif
}

#if NV_FORMAT == LE12_x86 || NV_FORMAT == LE16_x86
#define NVBYTE1 10
#else
#define NVBYTE1 (sizeof(NV))
#endif

static void
nv_to_key(pTHX_ NV nv, unsigned char *key, int klen, int *byte) {
#if defined(NV_FORMAT)
    int i;
    *((NV *)key) = nv;
#if NV_FORMAT == BE8 || NV_FORMAT == BE12 || NV_FORMAT == BE16
    for (i = 0; i < (NVBYTE1 / 2); i++) {
        unsigned char tmp;
        tmp = key[i];
        key[i] = key[(NVBYTE1 - 1) - i];
        key[(NVBYTE1 - 1) - i] = tmp;
    }
#endif
    if (nv >= 0.0)
        key[NVBYTE1 - 1] |= 0x80;
    else
        for (i = 0; i < NVBYTE1; i++)
            key[i] = ~key[i];
    *byte = NVBYTE1 - 1;
#else
    Perl_croak(aTHX_ "Sorting of floating point keys is not supported on this computer. Please, send a bug report to Sort::Key::Radix author (0.124 => " NV_0124 ")");
#endif
}

static void
sv_nv_to_key(pTHX_ SV *sv, unsigned char *key, int klen, int *byte) {
    nv_to_key(aTHX_ SvNV(sv), key, klen, byte);
}

static void
sv_rnv_to_key(pTHX_ SV *sv, unsigned char *key, int klen, int *byte) {
    nv_to_key(aTHX_ -SvNV(sv), key, klen, byte);
}

static void
sf_to_key(pTHX_ float sf, unsigned char *key, int klen, int *byte) {
#if defined(SF_FORMAT)
    int i;
    *((float *)key) = sf;
#if SF_FORMAT == BE8 || SF_FORMAT == BE4 || SF_FORMAT == BE12 || SF_FORMAT == BE16
    for (i = 0; i < (sizeof(float) >> 1); i++) {
        unsigned char tmp;
        tmp = key[i];
        key[i] = key[(sizeof(float) - 1) - i];
        key[(sizeof(float) - 1) - i] = tmp;
    }
#endif
    if (sf >= 0.0)
        key[sizeof(float) - 1] |= 0x80;
    else
        for (i = 0; i < sizeof(float); i++)
            key[i] = ~key[i];
            *byte = sizeof(float) - 1;
#else
            Perl_croak(aTHX_ "Sorting of single floating point keys is not supported on this computer. Please, send a bug report to Sort::Key::Radix author  (0.124 => " SF_0124 ")");
#endif
}

static void
sv_sf_to_key(pTHX_ SV *sv, unsigned char *key, int klen, int *byte) {
    sf_to_key(aTHX_ SvNV(sv), key, klen, byte);
}

static void
sv_rsf_to_key(pTHX_ SV *sv, unsigned char *key, int klen, int *byte) {
    sf_to_key(aTHX_ -SvNV(sv), key, klen, byte);
}

static void
sv_pv_to_key(pTHX_ SV *sv, unsigned char *key, int klen, int *byte) {
    STRLEN len, i;
    char *pv = SvPV(sv, len);
    /* printf("sv: %s, len: %d\n", pv, len); fflush(stdout); */
    for (i = 0; i < klen && i < len; i++)
        key[klen - 1 - i] = pv[i];
    if (*byte < i - 1)
        *byte = i - 1;
    for (; i < klen; i++)
        key[klen - 1 - i] = 0;
}

static void
sv_rpv_to_key(pTHX_ SV *sv, unsigned char *key, int klen, int *byte) {
    STRLEN len, i;
    char *pv = SvPV(sv, len);
    for (i = 0; i < klen && i < len; i++)
        key[klen - 1 - i] = ~pv[i];
    if (*byte < i - 1)
        *byte = i - 1;
    for (; i < klen; i++)
        key[klen - 1 - i] = ~0;
}

static void
radix_sort(pTHX_ IV type, SV *keygen, SV **values, I32 offset, I32 ax, IV n) {
    dSP;
    if (n) {
        unsigned char **keys, **temps, *start;
        int klen, byte;
        int (*calc_klen)(pTHX_ SV **, I32, I32, int);
        void (*sv_to_key)(pTHX_ SV *, unsigned char *, int, int *);
        int hints;
        
        calc_klen = 0;

#if (PERL_VERSION < 9)
        hints = PL_curcop->op_private;
#else
        hints = CopHINTS_get(PL_curcop);
#endif

        if ((type == 2 || type == 130) && (hints & HINT_INTEGER))
            type |= 1;
        
        switch(type) {
        case 2:
            klen = sizeof(NV);
            sv_to_key = &sv_nv_to_key;
            break;
        case 3:
            klen = sizeof(UV);
            sv_to_key = &sv_iv_to_key;
            break;
        case 4:
            klen = sizeof(UV);
            sv_to_key = &sv_uv_to_key;
            break;
        case 5:
            klen = sizeof(float);
            sv_to_key = &sv_sf_to_key;
            break;
        case 7:
            klen = 0;
            calc_klen = *calc_klen_pv;
            sv_to_key = &sv_pv_to_key;
            break;
        case 130:
            klen = sizeof(NV);
            sv_to_key = &sv_rnv_to_key;
            break;
        case 131:
            klen = sizeof(UV);
            sv_to_key = &sv_riv_to_key;
            break;
        case 132:
            klen = sizeof(UV);
            sv_to_key = &sv_ruv_to_key;
            break;
        case 133:
            klen = sizeof(float);
            sv_to_key = &sv_rsf_to_key;
            break;
        case 135:
            klen = 0;
            calc_klen = *calc_klen_pv;
            sv_to_key = &sv_rpv_to_key;
            break;

        default:
            Perl_croak(aTHX_ "internal error: bad ix value");
        }

        if (calc_klen) {
            SV **svkeys = ( keygen
                            ? calc_svkeys(aTHX_ keygen, values, offset, ax, n)
                            : values );
            klen = (*calc_klen)(aTHX_ svkeys, offset, ax, n);
            if (klen) {
                start = init_keys(aTHX_
                                  svkeys, offset, ax, n, NULL,
                                  sv_to_key, &keys, &temps, klen, &byte);

                /* if (n) print_keys("subkeys", keys, n, byte); */
        

            }
        }
        else if (klen)  {
            start = init_keys(aTHX_
                              values, offset, ax, n, keygen,
                              sv_to_key, &keys, &temps, klen, &byte);
        }
        if (byte >= 0) {
            SPAGAIN;
            /* printf("byte: %d\n", byte); */
            radix_sort_1(keys, temps, n, byte);
            
            if (values)
                resort_as_keys(aTHX_
                               values, values, start,
                               ((byte & 1) ? keys : temps),
                               n, klen);
            else
                resort_as_keys(aTHX_
                               &(ST(offset)), &(ST(0)), start,
                               ((byte & 1) ? keys : temps),
                               n, klen);
        }
    }
}

MODULE = Sort::Key::Radix		PACKAGE = Sort::Key::Radix		

void
_sort(...)
ALIAS:
    nsort = 2
    isort = 3
    usort = 4
    fsort = 5
    ssort = 7
    rnsort = 130
    risort = 131
    rusort = 132
    rfsort = 133
    rssort = 135
PPCODE:
    radix_sort(aTHX_ ix, 0, 0, 0, ax, items);
    SPAGAIN;
    XSRETURN(items);

void
_sort_inplace(AV *values)
PROTOTYPE: \@
PREINIT:
    AV *magic_values = 0;
    int len;
ALIAS:
    nsort_inplace = 2
    isort_inplace = 3
    usort_inplace = 4
    fsort_inplace = 5
    ssort_inplace = 7
    rnsort_inplace = 130
    risort_inplace = 131
    rusort_inplace = 132
    rfsort_inplace = 133
    rssort_inplace = 135
CODE:
    if ((len = av_len(values) + 1)) {
        /* warn("ix=%d\n", ix); */
	if (SvMAGICAL(values) || AvREIFY(values)) {
	    int i;
	    magic_values = values;
	    values = (AV*)sv_2mortal((SV*)newAV());
	    av_extend(values, len-1);
	    for (i=0; i<len; i++) {
		SV **currentp = av_fetch(magic_values, i, 0);
		av_store( values, i,
			  ( currentp
			    ? SvREFCNT_inc(*currentp)
			    : newSV(0) ) );
	    }
	}
	radix_sort(aTHX_ ix, 0, AvARRAY(values), 0, 0, len);
        SPAGAIN;
	if (magic_values) {
	    int i;
	    SV **values_array = AvARRAY(values);
	    for(i=0; i<len; i++) {
		SV *current = values_array[i];
		if (!current) current = &PL_sv_undef;
		if (!av_store(magic_values, i, SvREFCNT_inc(current)))
		    SvREFCNT_dec(current);
	    }
	}
    }

void
_keysort(SV *keygen, ...)
PROTOTYPE: &@
ALIAS:
    nkeysort = 2
    ikeysort = 3
    ukeysort = 4
    fkeysort = 5
    skeysort = 7
    rnkeysort = 130
    rikeysort = 131
    rukeysort = 132
    rfkeysort = 133
    rskeysort = 135
PPCODE:
    radix_sort(aTHX_ ix, keygen, 0, 1, ax, items - 1);
    SPAGAIN;
    XSRETURN(items - 1);


void
_keysort_inplace(SV *keygen, AV *values)
PROTOTYPE: &\@
PREINIT:
    AV *magic_values = 0;
    int len;
ALIAS:
    nkeysort_inplace = 2
    ikeysort_inplace = 3
    ukeysort_inplace = 4
    fkeysort_inplace = 5
    skeysort_inplace = 7
    rnkeysort_inplace = 130
    rikeysort_inplace = 131
    rukeysort_inplace = 132
    rfkeysort_inplace = 133
    rskeysort_inplace = 135
CODE:
    if ((len = av_len(values) + 1)) {
        /* warn("ix=%d\n", ix); */
	if (SvMAGICAL(values) || AvREIFY(values)) {
	    int i;
	    magic_values = values;
	    values = (AV*)sv_2mortal((SV*)newAV());
	    av_extend(values, len-1);
	    for (i=0; i<len; i++) {
		SV **currentp = av_fetch(magic_values, i, 0);
		av_store( values, i,
			  ( currentp
			    ? SvREFCNT_inc(*currentp)
			    : newSV(0) ) );
	    }
	}
	radix_sort(aTHX_ ix, keygen, AvARRAY(values), 0, 0, len);
        SPAGAIN;
	if (magic_values) {
	    int i;
	    SV **values_array = AvARRAY(values);
	    for(i=0; i<len; i++) {
		SV *current = values_array[i];
		if (!current) current = &PL_sv_undef;
		if (!av_store(magic_values, i, SvREFCNT_inc(current)))
		    SvREFCNT_dec(current);
	    }
	}
    }

