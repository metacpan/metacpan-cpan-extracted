/*
Copyright 2012, 2013 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
 */

#ifdef __GNUC__
 #if __GNUC__ >= 5
  #define IF_HAVE_GCC_5(X) X
 #endif

 #if (__GNUC__ == 4 && __GNUC_MINOR__ >= 6) || __GNUC__ >= 5
  #define PRAGMA_GCC_(X) _Pragma(#X)
  #define PRAGMA_GCC(X) PRAGMA_GCC_(GCC X)
 #endif
#endif

#ifndef IF_HAVE_GCC_5
 #define IF_HAVE_GCC_5(X)
#endif

#ifndef PRAGMA_GCC
 #define PRAGMA_GCC(X)
#endif

#ifdef DEVEL
 #define WARNINGS_RESET PRAGMA_GCC(diagnostic pop)
 #define WARNINGS_ENABLEW(X) PRAGMA_GCC(diagnostic error #X)
 #define WARNINGS_ENABLE \
    WARNINGS_ENABLEW(-Wall) \
    WARNINGS_ENABLEW(-Wextra) \
    WARNINGS_ENABLEW(-Wundef) \
    WARNINGS_ENABLEW(-Wshadow) \
    WARNINGS_ENABLEW(-Wbad-function-cast) \
    WARNINGS_ENABLEW(-Wcast-align) \
    WARNINGS_ENABLEW(-Wwrite-strings) \
    WARNINGS_ENABLEW(-Wstrict-prototypes) \
    WARNINGS_ENABLEW(-Wmissing-prototypes) \
    WARNINGS_ENABLEW(-Winline) \
    WARNINGS_ENABLEW(-Wdisabled-optimization) \
    IF_HAVE_GCC_5(WARNINGS_ENABLEW(-Wnested-externs))

#else
 #define WARNINGS_RESET
 #define WARNINGS_ENABLE
#endif


#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <ctype.h>
#include <assert.h>


WARNINGS_ENABLE


#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 16, 0)
 #define IF_HAVE_PERL_5_16(YES, NO) YES
#else
 #define IF_HAVE_PERL_5_16(YES, NO) NO
#endif


#define MY_PKG "Quote::Code"

#define HINTK_QC     MY_PKG "/qc"
#define HINTK_QC_TO  MY_PKG "/qc_to"
#define HINTK_QCW    MY_PKG "/qcw"

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static void free_ptr_op(pTHX_ void *vp) {
    OP **pp = vp;
    op_free(*pp);
    Safefree(pp);
}

enum {
    FLAG_BACKSLASH_ESCAPE = 0x1,
    FLAG_HASH_INTERPOLATE = 0x2,
    FLAG_STOP_AT_SPACE    = 0x4
};

typedef struct {
    I32 delim_start, delim_stop;
    SV *delim_str, *leftover;
    int flags;
} QCSpec;

static void missing_terminator(pTHX_ const QCSpec *spec, line_t line) {
    I32 c = spec->delim_stop;
    SV *sv = spec->delim_str;

    if (!sv) {
        sv = sv_2mortal(newSVpvs("'\"'"));
        if (c != '"') {
            U8 utf8_tmp[UTF8_MAXBYTES + 1], *d;
            d = uvchr_to_utf8(utf8_tmp, c);
            pv_uni_display(sv, utf8_tmp, d - utf8_tmp, 100, UNI_DISPLAY_QQ);
        }
    }

    if (c != '"') {
        sv_insert(sv, 0, 0, "\"", 1);
        sv_catpvs(sv, "\"");
    }

    if (line) {
        CopLINE_set(PL_curcop, line);
    }
    croak("Can't find string terminator %"SVf" anywhere before EOF", SVfARG(sv));
}

static void my_sv_cat_c(pTHX_ SV *sv, U32 c) {
    U8 ds[UTF8_MAXBYTES + 1], *d;
    d = uvchr_to_utf8(ds, c);
    if (d - ds > 1) {
        sv_utf8_upgrade(sv);
    }
    sv_catpvn(sv, (char *)ds, d - ds);
}

static U32 hex2int(unsigned char c) {
    static char xdigits[] = "0123456789abcdef";
    char *p = strchr(xdigits, tolower(c));
    if (!c || !p) {
        return 0;
    }
    return p - xdigits;
}

static void my_op_cat_sv(pTHX_ OP **pop, SV *sv) {
    OP *const str = newSVOP(OP_CONST, 0, SvREFCNT_inc_simple_NN(sv));
    *pop = !*pop ? str : newBINOP(OP_CONCAT, 0, *pop, str);
}

static OP *parse_qctail(pTHX_ const QCSpec *spec, int *pnesting) {
    I32 c;
    OP **gen_sentinel;
    SV *sv;
    line_t start;
    SV *const delim_str = spec->delim_str;
    const int
        have_delim_stop = spec->delim_stop != -1;

    assert(have_delim_stop == !delim_str);
    assert(!delim_str || spec->leftover);

    start = CopLINE(PL_curcop);

    Newx(gen_sentinel, 1, OP *);
    *gen_sentinel = NULL;
    SAVEDESTRUCTOR_X(free_ptr_op, gen_sentinel);

    sv = sv_2mortal(newSVpvs(""));
    if (lex_bufutf8()) {
        SvUTF8_on(sv);
    }
    c = '\n';

    for (;;) {
        char *elim;
        I32 b = c;

        c = lex_peek_unichar(0);
        if (c == -1) {
            missing_terminator(aTHX_ spec, start);
        }

        assert(PL_parser->bufend >= PL_parser->bufptr);

        if (
            b == '\n' &&
            delim_str &&
            /* c == spec->delim_start && */
            (STRLEN)(PL_parser->bufend - PL_parser->bufptr) >= SvCUR(delim_str) &&
            (elim = PL_parser->bufptr + SvCUR(delim_str),
             memcmp(PL_parser->bufptr, SvPVX(delim_str), SvCUR(delim_str)) == 0) && (
                !(
                    (STRLEN)(PL_parser->bufend - PL_parser->bufptr) > SvCUR(delim_str) ||
                    lex_next_chunk(0)
                ) ||
                (elim++, PL_parser->bufptr[SvCUR(delim_str)] == '\n') || (
                    elim++,
                    PL_parser->bufptr[SvCUR(delim_str)] == '\r' &&
                    PL_parser->bufptr[SvCUR(delim_str) + 1] == '\n'
                )
            )
        ) {
            lex_read_to(elim);
            lex_stuff_sv(spec->leftover, 0);
            break;
        }

        if (
            !(spec->flags & FLAG_HASH_INTERPOLATE)
                ? c == '{'
                : c == '#' &&
                  spec->delim_stop != '#' &&
                  PL_parser->bufptr[1] == '{' &&
                  (lex_read_unichar(0), 1)
        ) {
            OP *op;

            op = parse_block(0);
            op = newUNOP(OP_NULL, OPf_SPECIAL, op_scope(op));

            if (SvCUR(sv)) {
                my_op_cat_sv(aTHX_ gen_sentinel, sv);

                sv = sv_2mortal(newSVpvs(""));
                if (lex_bufutf8()) {
                    SvUTF8_on(sv);
                }
            }

            if (*gen_sentinel) {
                *gen_sentinel = newBINOP(OP_CONCAT, 0, *gen_sentinel, op);
            } else {
                *gen_sentinel = op;
            }

            c = -1;
            continue;
        }

        lex_read_unichar(0);

        if (pnesting && c == spec->delim_start) {
            (*pnesting)++;
        } else if (have_delim_stop && c == spec->delim_stop) {
            if (!pnesting || *pnesting == 0) {
                if (spec->flags & FLAG_STOP_AT_SPACE) {
                    /* terrible hack to let qcw() know to stop parsing */
                    char tmp = c;
                    lex_stuff_pvn(&tmp, 1, 0);
                }
                break;
            }
            (*pnesting)--;
        } else if ((spec->flags & FLAG_STOP_AT_SPACE) && isSPACE(c)) {
            break;
        } else if (c == '\\' && (spec->flags & FLAG_BACKSLASH_ESCAPE)) {
            U32 u;

            c = lex_read_unichar(0);
            switch (c) {
                case -1:
                    missing_terminator(aTHX_ spec, start);

                case 'a': c = '\a'; break;
                case 'b': c = '\b'; break;
                case 'e': c = '\033'; break;
                case 'f': c = '\f'; break;
                case 'n': c = '\n'; break;
                case 'r': c = '\r'; break;
                case 't': c = '\t'; break;

                case 'c':
                    c = lex_read_unichar(0);
                    if (c == -1) {
                        missing_terminator(aTHX_ spec, start);
                    }
                    c = toUPPER(c) ^ 64;
                    break;

                case 'o':
                    c = lex_read_unichar(0);
                    if (c != '{') {
                        croak("Missing braces on \\o{}");
                    }
                    u = 0;
                    while (c = lex_peek_unichar(0), c >= '0' && c <= '7') {
                        u = u * 8 + (c - '0');
                        lex_read_unichar(0);
                    }
                    if (c != '}') {
                        croak("Missing right brace on \\o{}");
                    }
                    lex_read_unichar(0);
                    c = u;
                    break;

                case 'x':
                    c = lex_read_unichar(0);
                    if (c == '{') {
                        u = 0;
                        while (c = lex_peek_unichar(0), isXDIGIT(c)) {
                            u = u * 16 + hex2int(c);
                            lex_read_unichar(0);
                        }
                        if (c != '}') {
                            croak("Missing right brace on \\x{}");
                        }
                        lex_read_unichar(0);
                        c = u;
                    } else if (isXDIGIT(c)) {
                        u = hex2int(c);
                        c = lex_peek_unichar(0);
                        if (isXDIGIT(c)) {
                            u = u * 16 + hex2int(c);
                            lex_read_unichar(0);
                        }
                        c = u;
                    } else {
                        c = 0;
                    }
                    break;

                case 'N': {
                    SV *name;
                    char *n_ptr;
                    STRLEN n_len;

                    c = lex_read_unichar(0);
                    if (c != '{') {
                        croak("Missing braces on \\N{}");
                    }

                    name = sv_2mortal(newSVpvs(""));
                    if (lex_bufutf8()) {
                        SvUTF8_on(name);
                    }

                    while ((c = lex_read_unichar(0)) != '}') {
                        if (c == -1) {
                            croak("Missing right brace on \\N{}");
                        }
                        my_sv_cat_c(aTHX_ name, c);
                    }

                    n_ptr = SvPV(name, n_len);

                    if (n_len >= 2 && n_ptr[0] == 'U' && n_ptr[1] == '+') {
                        I32 flags = PERL_SCAN_ALLOW_UNDERSCORES | PERL_SCAN_DISALLOW_PREFIX;
                        STRLEN x_len;

                        n_ptr += 2;
                        n_len -= 2;

                        x_len = n_len;
                        c = grok_hex(n_ptr, &x_len, &flags, NULL);
                        if (x_len == 0 || x_len != n_len) {
                            croak("Invalid hexadecimal number in \\N{U+...}");
                        }

                        break;
                    }

                    {
                        HV *table;
                        SV **cvp;

                        #if HAVE_PERL_VERSION(5, 15, 7)
                            if (
                                !(table = GvHV(PL_hintgv)) ||
                                !(PL_hints & HINT_LOCALIZE_HH) ||
                                !(cvp = hv_fetchs(table, "charnames", FALSE)) ||
                                !SvOK(*cvp)
                            ) {
                                load_module(
                                    0, newSVpvs("charnames"), NULL,
                                    newSVpvs(":full"), newSVpvs(":short"), (SV *)NULL
                                );
                            }
                        #endif

                        if (
                            !(table = GvHV(PL_hintgv)) ||
                            !(PL_hints & HINT_LOCALIZE_HH)
                        ) {
                            /* ??? */
                            croak("Constant(\\N{%"SVf"} unknown", SVfARG(name));
                        }

                        if (
                            !(cvp = hv_fetchs(table, "charnames", FALSE)) ||
                            !SvOK(*cvp)
                        ) {
                            croak("Unknown charname '%"SVf"'", SVfARG(name));
                        }

                        {
                            SV *r, *cv = *cvp;
                            {
                                dSP;

                                PUSHSTACKi(PERLSI_OVERLOAD);
                                ENTER;
                                SAVETMPS;

                                PUSHMARK(SP);
                                EXTEND(SP, 1);
                                PUSHs(name);
                                PUTBACK;

                                call_sv(cv, G_SCALAR);
                                SPAGAIN;

                                r = POPs;
                                SvREFCNT_inc_simple_void_NN(r);

                                PUTBACK;
                                FREETMPS;
                                LEAVE;
                            }
                            POPSTACK;

                            if (!SvOK(r)) {
                                SvREFCNT_dec(r);
                                croak("Unknown charname '%"SVf"'", SVfARG(name));
                            }

                            sv_catsv(sv, r);
                            SvREFCNT_dec(r);
                            continue;
                        }
                    }

                    break;
                }

                default:
                    if (c >= '0' && c <= '7') {
                        u = c - '0';
                        c = lex_peek_unichar(0);
                        if (c >= '0' && c <= '7') {
                            u = u * 8 + (c - '0');
                            lex_read_unichar(0);
                            c = lex_peek_unichar(0);
                            if (c >= '0' && c <= '7') {
                                u = u * 8 + (c - '0');
                                lex_read_unichar(0);
                            }
                        }
                        c = u;
                    }
                    break;
            }
        }

        my_sv_cat_c(aTHX_ sv, c);
    }

    if (SvCUR(sv) || !*gen_sentinel) {
        my_op_cat_sv(aTHX_ gen_sentinel, sv);
    }

    {
        OP *gen = *gen_sentinel;
        *gen_sentinel = NULL;

        if (gen->op_type == OP_CONST) {
            SvPOK_only_UTF8(((SVOP *)gen)->op_sv);
        } else if (gen->op_type != OP_CONCAT) {
            /* can't do this because B::Deparse dies on it:
             * gen = newUNOP(OP_STRINGIFY, 0, gen);
             */
            gen = newBINOP(OP_CONCAT, 0, gen, newSVOP(OP_CONST, 0, newSVpvs("")));
        }

        return gen;
    }
}

static void parse_qc(pTHX_ OP **op_ptr) {
    I32 c;

    c = lex_peek_unichar(0);

    if (c != '#') {
        lex_read_space(0);
        c = lex_peek_unichar(0);
        if (c == -1) {
            croak("Unexpected EOF after qc");
        }
    }
    lex_read_unichar(0);

    {
        I32 delim_start = c;
        I32 delim_stop =
            c == '(' ? ')' :
            c == '[' ? ']' :
            c == '{' ? '}' :
            c == '<' ? '>' :
            c
        ;
        int nesting = 0;
        const QCSpec spec = {
            delim_start, delim_stop,
            NULL, NULL,
            FLAG_BACKSLASH_ESCAPE
        };

        *op_ptr = parse_qctail(aTHX_ &spec, delim_start == delim_stop ? NULL : &nesting);
    }
}

static void parse_qcw(pTHX_ OP **op_ptr) {
    I32 c;

    c = lex_peek_unichar(0);

    if (c != '#') {
        lex_read_space(0);
        c = lex_peek_unichar(0);
        if (c == -1) {
            croak("Unexpected EOF after qcw");
        }
    }
    lex_read_unichar(0);

    {
        I32 delim_start = c;
        I32 delim_stop =
            c == '(' ? ')' :
            c == '[' ? ']' :
            c == '{' ? '}' :
            c == '<' ? '>' :
            c
        ;
        int nesting = 0;
        const QCSpec spec = {
            delim_start, delim_stop,
            NULL, NULL,
            FLAG_BACKSLASH_ESCAPE | FLAG_STOP_AT_SPACE
        };
        OP **gen_sentinel;

        Newx(gen_sentinel, 1, OP *);
        *gen_sentinel = NULL;
        SAVEDESTRUCTOR_X(free_ptr_op, gen_sentinel);

        for (;;) {
            OP *cur;
            while (c = lex_peek_unichar(0), c != -1 && isSPACE(c)) {
                lex_read_unichar(0);
            }
            if (c == delim_stop && nesting == 0) {
                lex_read_unichar(0);
                break;
            }
            cur = parse_qctail(aTHX_ &spec, delim_start == delim_stop ? NULL : &nesting);
            *gen_sentinel = op_append_elem(OP_LIST, *gen_sentinel, cur);
        }

        if (*gen_sentinel) {
            *op_ptr = *gen_sentinel;
            *gen_sentinel = NULL;
        } else {
            *op_ptr = newNULLLIST();
        }
        (*op_ptr)->op_flags |= OPf_PARENS;
    }
}

static void parse_qc_to(pTHX_ OP **op_ptr) {
    I32 c, qdelim;
    SV *delim, *leftover;
    line_t start;

    lex_read_space(0);
    if (!strnEQ(PL_parser->bufptr, "<<", 2)) {
        croak("Missing \"<<\" after qc_to");
    }
    lex_read_to(PL_parser->bufptr + 2);

    lex_read_space(0);
    start = CopLINE(PL_curcop);
    c = lex_peek_unichar(0);
    if (!(c == '\'' || c == '"')) {
        croak("Missing \"'\" or '\"' after qc_to <<");
    }
    qdelim = c;
    lex_read_unichar(0);

    delim = sv_2mortal(newSVpvs(""));
    if (lex_bufutf8()) {
        SvUTF8_on(delim);
    }

    for (;;) {
        c = lex_read_unichar(0);
        if (c == -1) {
            CopLINE_set(PL_curcop, start);
            croak("Can't find string terminator %s anywhere before EOF", qdelim == '"' ? "'\"'" : "\"'\"");
        }
        if (c == qdelim) {
            break;
        }
        my_sv_cat_c(aTHX_ delim, c);
    }

    {
        char *fin = memchr(PL_parser->bufptr, '\n', PL_parser->bufend - PL_parser->bufptr);
        if (fin) {
            fin++;
        } else {
            fin = PL_parser->bufend;
        }

        leftover = sv_2mortal(newSVpvn_utf8(PL_parser->bufptr, fin - PL_parser->bufptr, lex_bufutf8()));
        lex_unstuff(fin);
    }

    {
        const QCSpec spec = {
            -1, -1,
            delim, leftover,
            FLAG_HASH_INTERPOLATE | (qdelim == '"' ? FLAG_BACKSLASH_ESCAPE : 0)
        };
        *op_ptr = parse_qctail(aTHX_ &spec, NULL);
    }
}

static int qc_enabled(pTHX_ const char *hk_ptr, size_t hk_len) {
    HV *hints;
    SV *sv, **psv;

    if (!(hints = GvHV(PL_hintgv))) {
        return FALSE;
    }
    if (!(psv = hv_fetch(hints, hk_ptr, hk_len, 0))) {
        return FALSE;
    }
    sv = *psv;
    return SvTRUE(sv);
}
#define qc_enableds(S) qc_enabled(aTHX_ STR_WITH_LEN(S))

static int my_keyword_plugin(pTHX_ char *keyword_ptr, STRLEN keyword_len, OP **op_ptr) {
    int ret;

    if (keyword_len == 2 && keyword_ptr[0] == 'q' && keyword_ptr[1] == 'c' && qc_enableds(HINTK_QC)) {
        ENTER;
        parse_qc(aTHX_ op_ptr);
        LEAVE;
        ret = KEYWORD_PLUGIN_EXPR;
    } else if (keyword_len == 5 && memcmp(keyword_ptr, "qc_to", 5) == 0 && qc_enableds(HINTK_QC_TO)) {
        ENTER;
        parse_qc_to(aTHX_ op_ptr);
        LEAVE;
        ret = KEYWORD_PLUGIN_EXPR;
    } else if (keyword_len == 3 && memcmp(keyword_ptr, "qcw", 3) == 0 && qc_enableds(HINTK_QCW)) {
        ENTER;
        parse_qcw(aTHX_ op_ptr);
        LEAVE;
        ret = KEYWORD_PLUGIN_EXPR;
    } else {
        ret = next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
    }

    return ret;
}


WARNINGS_RESET

MODULE = Quote::Code   PACKAGE = Quote::Code
PROTOTYPES: ENABLE

BOOT:
WARNINGS_ENABLE {
    HV *const stash = gv_stashpvs(MY_PKG, GV_ADD);
    /**/
    newCONSTSUB(stash, "HINTK_QC",    newSVpvs(HINTK_QC));
    newCONSTSUB(stash, "HINTK_QC_TO", newSVpvs(HINTK_QC_TO));
    newCONSTSUB(stash, "HINTK_QCW",   newSVpvs(HINTK_QCW));
    /**/
    next_keyword_plugin = PL_keyword_plugin;
    PL_keyword_plugin = my_keyword_plugin;
} WARNINGS_RESET
