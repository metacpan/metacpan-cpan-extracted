/*
Copyright 2012, 2014, 2016 Lukas Mai.

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
 #define WARNINGS_ENABLEW(X) PRAGMA_GCC(diagnostic warning #X)
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

#ifdef PERL_MAD
#error "MADness is not supported."
#endif

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 19, 3)
 #define IF_HAVE_PERL_5_19_3(YES, NO) YES
#else
 #define IF_HAVE_PERL_5_19_3(YES, NO) NO
#endif

#ifndef SvREFCNT_dec_NN
#define SvREFCNT_dec_NN(SV) SvREFCNT_dec(SV)
#endif

#define MY_PKG "Switch::Plain"


/* 5.22+ shouldn't require any hax */
#if !HAVE_PERL_VERSION(5, 22, 0)

#include "hax/intro_my.c.inc"
#include "hax/block_start.c.inc"
#include "hax/block_end.c.inc"

#endif


WARNINGS_ENABLE

#define HINTK_FLAGS  MY_PKG "/flags"


static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static void free_ptr_op(pTHX_ void *vp) {
    OP **pp = vp;
    op_free(*pp);
    Safefree(pp);
}

enum {
    FLAG_SSWITCH = 0x01,
    FLAG_NSWITCH = 0x02
};

static void my_sv_cat_c(pTHX_ SV *sv, U32 c) {
    char ds[UTF8_MAXBYTES + 1], *d;
    d = (char *)uvchr_to_utf8((U8 *)ds, c);
    if (d - ds > 1) {
        sv_utf8_upgrade(sv);
    }
    sv_catpvn(sv, ds, d - ds);
}


#define MY_UNI_IDFIRST(C) isIDFIRST_uni(C)
#define MY_UNI_IDCONT(C)  isALNUM_uni(C)

static SV *my_scan_word(pTHX) {
    I32 c;
    SV *sv;

    c = lex_peek_unichar(0);
    if (c == -1 || !MY_UNI_IDFIRST(c)) {
        return NULL;
    }
    lex_read_unichar(0);

    sv = sv_2mortal(newSVpvs(""));
    if (lex_bufutf8()) {
        SvUTF8_on(sv);
    }

    my_sv_cat_c(aTHX_ sv, c);

    while ((c = lex_peek_unichar(0)) != -1 && MY_UNI_IDCONT(c)) {
        lex_read_unichar(0);
        my_sv_cat_c(aTHX_ sv, c);
    }

    return sv;
}

#define DEFSTRUCT(T) typedef struct T T; struct T

DEFSTRUCT(IfThen) {
    OP *cond;
    OP *body;
};

DEFSTRUCT(IfThenVector) {
    IfThen *data;
    size_t used, size;
};

static void ifthen_destroy(pTHX_ IfThen *it) {
    op_free(it->cond);
    it->cond = NULL;
    op_free(it->body);
    it->body = NULL;
}

static void itv_free(pTHX_ void *vp) {
    IfThenVector *itv = vp;
    while (itv->used > 0) {
        itv->used--;
        ifthen_destroy(aTHX_ &itv->data[itv->used]);
    }
    Safefree(itv->data);
    Safefree(itv);
}

static IfThenVector *itv_alloc_ephemeral(pTHX) {
    IfThenVector *itv;

    Newx(itv, 1, IfThenVector);
    itv->data = NULL;
    itv->used = itv->size = 0;
    SAVEDESTRUCTOR_X(itv_free, itv);

    itv->size = 42;
    Newx(itv->data, itv->size, IfThen);

    return itv;
}

static void itv_push(IfThenVector *itv, OP *cond, OP *body) {
    IfThen *it;

    assert(itv->used <= itv->size);
    if (itv->used == itv->size) {
        itv->size += itv->size / 2 + 1;
        Renew(itv->data, itv->size, IfThen);
    }

    it = &itv->data[itv->used++];
    it->cond = cond;
    it->body = body;
}

static void do_alternative(pTHX_ IfThenVector *itv, int compare_numeric) {
    OP *cond_acc;

    cond_acc = NULL;

    do {
        OP *cond;
        SV *sv1, *sv2;
        const char *kw;
        size_t kw_len;

        sv1 = my_scan_word(aTHX);
        if (!sv1) {
            int n = PL_parser->bufend - PL_parser->bufptr;
            if (n > 0) {
                croak("Missing 'case' or 'default' before \"%.*s\"", n, PL_parser->bufptr);
            }
            croak("Missing 'case' or 'default'");
        }

        kw = SvPV(sv1, kw_len);
        if (!(
                (kw_len == 4 && memcmp(kw, "case", 4) == 0) ||
                (kw_len == 7 && memcmp(kw, "default", 7) == 0)
        )) {
            croak("Missing 'case' or 'default' before \"%"SVf"\"", sv1);
        }

        /* default */
        if (kw_len == 7) {
            cond = NULL;
        } else {
            if (!(cond = parse_fullexpr(PARSE_OPTIONAL))) {
                croak("Missing expression after 'case'");
            }
            cond = newBINOP(
                compare_numeric ? OP_EQ : OP_SEQ,
                0,
                newSVREF(newGVOP(OP_GV, 0, PL_defgv)),
                op_contextualize(cond, G_SCALAR)
            );
        }

        lex_read_space(0);
        sv2 = my_scan_word(aTHX);
        if (sv2) {
            OP *cond2;

            kw = SvPV(sv2, kw_len);
            if (!(
                (kw_len == 2 && memcmp(kw, "if", 2) == 0) ||
                (kw_len == 6 && memcmp(kw, "unless", 6) == 0)
            )) {
                croak("Missing ':' after '%"SVf"'", sv1);
            }

            cond2 = parse_fullexpr(PARSE_OPTIONAL);
            if (!cond2) {
                croak("Missing expression after '%"SVf"'", sv2);
            }
            lex_read_space(0);
            cond2->op_flags |= OPf_PARENS;

            /* unless */
            if (kw_len == 6) {
                cond2 = newUNOP(OP_NOT, OPf_SPECIAL, op_contextualize(cond2, G_SCALAR));
            }

            cond = !cond ? cond2 : newLOGOP(OP_AND, 0, cond, cond2);
        }

        if (lex_peek_unichar(0) != ':') {
            croak("Missing ':' after '%"SVf"'", sv1);
        }
        lex_read_unichar(0);
        lex_read_space(0);

        cond_acc = !cond_acc ? cond : newLOGOP(OP_OR, 0, cond_acc, cond);

    } while (lex_peek_unichar(0) != '{');

    if (cond_acc) {
        intro_my();
    }

    {
        OP *body;
        int block_ix;

        block_ix = block_start(FALSE);
        body = parse_block(0);
        body = block_end(block_ix, body);
        /*
        body->op_flags |= OPf_PARENS;
        body = op_scope(aTHX_ body);
        */

        itv_push(itv, cond_acc, body);
    }

    lex_read_space(0);
}

static void parse_switch(pTHX_ int compare_numeric, OP **op_ptr) {
    IfThenVector *itv;
    OP **gen_sentinel;
    int save_ix;
    I32 c;

    lex_read_space(0);

    c = lex_peek_unichar(0);
    if (c != '(') {
        croak("Missing '(' after '%cswitch'", compare_numeric ? 'n' : 's');
    }
    lex_read_unichar(0);

    Newx(gen_sentinel, 1, OP *);
    *gen_sentinel = NULL;
    SAVEDESTRUCTOR_X(free_ptr_op, gen_sentinel);

    /* create outer block: '{' */
    save_ix = block_start(TRUE);

    if (!(*gen_sentinel = parse_fullexpr(PARSE_OPTIONAL))) {
        croak("Missing expression after '%cswitch ('", compare_numeric ? 'n' : 's');
    }
    lex_read_space(0);

    c = lex_peek_unichar(0);
    if (c != ')') {
        croak("Missing ')'");
    }
    lex_read_unichar(0);
    lex_read_space(0);

    {
        OP *target, *gen;

        gen = *gen_sentinel;
        gen = newUNOP(OP_REFGEN, 0, op_lvalue(op_contextualize(gen, G_SCALAR), OP_REFGEN));

        target = newGVREF(0, newGVOP(OP_GV, 0, PL_defgv));
        target = op_lvalue(target, OP_NULL);
        gen = newASSIGNOP(OPf_STACKED, target, 0, gen);

        *gen_sentinel = gen;
    }

    c = lex_peek_unichar(0);
    if (c != '{') {
        croak("Missing '{'");
    }
    lex_read_unichar(0);
    lex_read_space(0);

    itv = itv_alloc_ephemeral(aTHX);

    while (lex_peek_unichar(0) != '}') {
        do_alternative(aTHX_ itv, compare_numeric);
    }
    lex_read_unichar(0);

    {
        OP *gbody = NULL;

        while (itv->used) {
            const IfThen *cur = &itv->data[--itv->used];
            gbody = newCONDOP(
                0,
                /* newSTATEOP(OPf_SPECIAL, NULL, ) XXX? */
                cur->cond ? cur->cond : newSVOP(OP_CONST, 0, &PL_sv_yes),
                op_scope(cur->body),
                gbody
            );
        }

        *gen_sentinel = op_append_list(OP_LINESEQ, *gen_sentinel, newSTATEOP(0, NULL, gbody));
    }

    /* close outer block: '}' */
    *gen_sentinel = block_end(save_ix, *gen_sentinel);
    *gen_sentinel = op_scope(*gen_sentinel); /* XXX? */

    *op_ptr = *gen_sentinel;
    *gen_sentinel = NULL;
}

static IV bc_flags(pTHX) {
    HV *hints;
    SV *sv, **psv;

    if (!(hints = GvHV(PL_hintgv))) {
        return 0;
    }
    if (!(psv = hv_fetch(hints, HINTK_FLAGS, sizeof HINTK_FLAGS - 1, 0))) {
        return 0;
    }
    sv = *psv;
    return SvIV(sv);
}

static int my_keyword_plugin(pTHX_ char *keyword_ptr, STRLEN keyword_len, OP **op_ptr) {
    int ret;
    char c;

    c = *keyword_ptr;
    if (
        keyword_len == 7 &&
        (c == 's' || c == 'n') &&
        memcmp(keyword_ptr + 1, "switch", 6) == 0 &&
        (bc_flags(aTHX) & (c == 'n' ? FLAG_NSWITCH : FLAG_SSWITCH))
    ) {
        ENTER;
        SAVETMPS;
        parse_switch(aTHX_ c == 'n', op_ptr);
        FREETMPS;
        LEAVE;
        ret = KEYWORD_PLUGIN_STMT;
    } else {
        ret = next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
    }


    return ret;
}

static void my_boot(pTHX) {
    HV *const stash = gv_stashpvs(MY_PKG, GV_ADD);

    newCONSTSUB(stash, "FLAG_SSWITCH", newSViv(FLAG_SSWITCH));
    newCONSTSUB(stash, "FLAG_NSWITCH", newSViv(FLAG_NSWITCH));
    newCONSTSUB(stash, "HINTK_FLAGS", newSVpvs(HINTK_FLAGS));

    next_keyword_plugin = PL_keyword_plugin;
    PL_keyword_plugin = my_keyword_plugin;
}

WARNINGS_RESET

MODULE = Switch::Plain   PACKAGE = Switch::Plain
PROTOTYPES: ENABLE

BOOT:
    my_boot(aTHX);
