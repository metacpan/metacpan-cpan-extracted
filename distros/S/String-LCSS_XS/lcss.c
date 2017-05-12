#include "lcss.h"
#include "macros.h"

#define NEED_newSVpvn_flags
#include "ppport.h"


#define SWAP(type, a, b) \
    STMT_START { \
        type SWAP_t;  \
        SWAP_t = a;   \
        a = b;        \
        b = SWAP_t;   \
    } STMT_END


#define GRAB_AND_ADVANCE_ONE(ch, cur, rem) \
    if (UTF8_IS_INVARIANT(*cur)) {                              \
        ch = *cur;                                              \
        ++cur;                                                  \
        --rem;                                                  \
    } else {                                                    \
        STRLEN ch_len;                                          \
        ch = utf8n_to_uvchr(cur, rem, &ch_len, UTF8_ALLOW_ANY); \
        cur += ch_len;                                          \
        rem -= ch_len;                                          \
    }

#define ADVANCE_ONE(cur, rem) \
    if (UTF8_IS_INVARIANT(*cur)) {                               \
        ++cur;                                                   \
        --rem;                                                   \
    } else {                                                     \
        STRLEN ch_len;                                           \
        (void)utf8n_to_uvchr(cur, rem, &ch_len, UTF8_ALLOW_ANY); \
        cur += ch_len;                                           \
        rem -= ch_len;                                           \
    }


static
SV*  /* Mortal PV */
_get_utf8_str(
    const U8* s,
    STRLEN    rem,
    STRLEN    pos,
    STRLEN    len
) {
    const U8* beg;
    const U8* end;

    while (rem && pos--) { ADVANCE_ONE(s, rem); }
    beg = s;
    while (rem && len--) { ADVANCE_ONE(s, rem); }
    end = s;

    return newSVpvn_utf8(beg, end-beg, 1);
}


static
SV*  /* Mortal PV */
_get_utf8_str_iter(
    const U8** p_s,
    STRLEN*    p_rem,
    STRLEN     skip,
    STRLEN     len
) {
    const U8* beg;
    const U8* end;

    while (*p_rem && skip--) { ADVANCE_ONE(*p_s, *p_rem); }
    beg = *p_s;
    while (*p_rem && len-- ) { ADVANCE_ONE(*p_s, *p_rem); }
    end = *p_s;

    return newSVpvn_utf8(beg, end-beg, 1);
}


SV*  /* AV if want_pos or want_all, PV otherwise */
lcss(
    int         wide,      /* s and t are in the UTF8=1 format    */
    const char* s,         /* Format determined by utf8 parameter */
    STRLEN      s_len,     /* Byte length of s                    */
    const char* t,         /* Format determined by utf8 parameter */
    STRLEN      t_len,     /* Byte length of t                    */
    int         min,       /* Ignore substrings shorter than this */
    int         want_pos,  /* Return positions as well as strings */
    int         want_all   /* Return all matches, or just one     */
) {
    UV found;       /* Number of longest substrings */
    STRLEN z;       /* Length of longuest substr */

    int swapped;    /* If s and t were swapped */
    STRLEN* pos_s;  /* 1-based char pos of the start of each longest substring in s */
    STRLEN* pos_t;  /* 1-based char pos of the start of each longest substring in t */
    size_t allocated;

    STRLEN* K;      /* Previous row */
    STRLEN* L;      /* Current row */

    SV* rv;

    /* To save memory */
    swapped = s_len < t_len;
    if (swapped) {
        SWAP(const char*, s,     t);
        SWAP(STRLEN,      s_len, t_len);
    }

    /* This is potentially longer than needed when wide */
    CALLOC(K, STRLEN, t_len + 1);
    CALLOC(L, STRLEN, t_len + 1);

    z = min - 1;
    found = 0;
    allocated = want_all ? 256 : 1;
    MALLOC(pos_s, STRLEN, allocated);
    MALLOC(pos_t, STRLEN, allocated);

    /* Compute matrix */
    if (wide) {
        STRLEN    s_pos;   STRLEN    t_pos;   /* 1-based current char pos */
        const U8* s_cur;   const U8* t_cur;   /* Pointer to current char  */
        STRLEN    s_rem;   STRLEN    t_rem;   /* Bytes remaining          */
        UV        s_ch;    UV        t_ch;    /* Current character        */

        for (s_pos=1, s_cur=(const U8*)s, s_rem=s_len; s_rem; ++s_pos) {
            GRAB_AND_ADVANCE_ONE(s_ch, s_cur, s_rem);
            for (t_pos=1, t_cur=(const U8*)t, t_rem=t_len; t_rem; ++t_pos) {
                GRAB_AND_ADVANCE_ONE(t_ch, t_cur, t_rem);
                if (s_ch == t_ch) {
                    L[t_pos] = K[t_pos - 1] + 1;
                    if (L[t_pos] > z) {
                        z = L[t_pos];
                        pos_s[0] = s_pos - z;
                        pos_t[0] = t_pos - z;
                        found = 1;
                    } else if (want_all & L[t_pos] == z && found) {
                        /* Maybe we need some more space */
                        if (found >= allocated) {
                            allocated += 256;
                            REALLOC(pos_s, STRLEN, allocated);
                            REALLOC(pos_t, STRLEN, allocated);
                        }
                        pos_s[found] = s_pos - z;
                        pos_t[found] = t_pos - z;
                        ++found;
                    }
                } else {
                    L[t_pos] = 0;
                }
            }

            SWAP(STRLEN*, K, L);
        }
    } else {
        STRLEN s_pos;  /* 1-based current char pos */
        STRLEN t_pos;

        for (s_pos = 1; s_pos <= s_len; ++s_pos) {
            for (t_pos = 1; t_pos <= t_len; ++t_pos) {
                if (s[s_pos - 1] == t[t_pos - 1]) {
                    L[t_pos] = K[t_pos - 1] + 1;
                    if (L[t_pos] > z) {
                        z = L[t_pos];
                        pos_s[0] = s_pos - z;
                        pos_t[0] = t_pos - z;
                        found = 1;
                    } else if (want_all & L[t_pos] == z && found) {
                        /* Maybe we need some more space */
                        if (found >= allocated) {
                            allocated += 256;
                            REALLOC(pos_s, STRLEN, allocated);
                            REALLOC(pos_t, STRLEN, allocated);
                        }
                        pos_s[found] = s_pos - z;
                        pos_t[found] = t_pos - z;
                        ++found;
                    }
                } else {
                    L[t_pos] = 0;
                }
            }

            SWAP(STRLEN*, K, L);
        }
    }

    FREE(K);
    FREE(L);

    if (want_all) {
        AV* const av = newAV();
        I32 i;
        STRLEN cur_pos;
        rv = (SV*)av;
        av_extend(av, found-1);
        for (cur_pos=0, i=0; i<found; ++i) {
            AV* const inner_av = newAV();
            av_store(av, i, newRV_noinc((SV*)inner_av));
            av_extend(inner_av, 2);
            if (wide) {
                av_store(inner_av, 0, _get_utf8_str_iter((const U8**)&t, &t_len, pos_t[i]-cur_pos, z));
                cur_pos = pos_t[i] + z;
            } else {
                av_store(inner_av, 0, newSVpvn_utf8(t+pos_t[i], z, 0));
            }
            if (swapped) {
                av_store(inner_av, 2, newSViv(pos_s[i]));
                av_store(inner_av, 1, newSViv(pos_t[i]));
            } else {
                av_store(inner_av, 1, newSViv(pos_s[i]));
                av_store(inner_av, 2, newSViv(pos_t[i]));
            }
        }
    }
    else if (want_pos) {
        AV* const av = newAV();
        rv = (SV*)av;
        if (found) {
            av_extend(av, 2);
            if (wide) {
                av_store(av, 0, _get_utf8_str((const U8*)t, t_len, pos_t[0], z));
            } else {
                av_store(av, 0, newSVpvn_utf8(t+pos_t[0], z, 0));
            }
            if (swapped) {
                av_store(av, 2, newSViv(pos_s[0]));
                av_store(av, 1, newSViv(pos_t[0]));
            } else {
                av_store(av, 1, newSViv(pos_s[0]));
                av_store(av, 2, newSViv(pos_t[0]));
            }
        }
    }
    else {
        if (found) {
            if (wide)
                rv = _get_utf8_str((const U8*)t, t_len, pos_t[0], z);
            else
                rv = newSVpvn(t+pos_t[0], z);
        }
        else
            rv = &PL_sv_undef;
    }

    FREE(pos_s);
    FREE(pos_t);
    return rv;
}
