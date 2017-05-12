/*
Copyright 2013 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
 */

#ifdef __GNUC__
 #if (__GNUC__ == 4 && __GNUC_MINOR__ >= 6) || __GNUC__ >= 5
  #define PRAGMA_GCC_(X) _Pragma(#X)
  #define PRAGMA_GCC(X) PRAGMA_GCC_(GCC X)
 #endif
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
 	/* WARNINGS_ENABLEW(-Wshadow) :-( */ \
 	WARNINGS_ENABLEW(-Wbad-function-cast) \
 	WARNINGS_ENABLEW(-Wcast-align) \
 	WARNINGS_ENABLEW(-Wwrite-strings) \
 	/* WARNINGS_ENABLEW(-Wnested-externs) wtf? */ \
 	WARNINGS_ENABLEW(-Wstrict-prototypes) \
 	WARNINGS_ENABLEW(-Wmissing-prototypes) \
 	WARNINGS_ENABLEW(-Winline) \
 	WARNINGS_ENABLEW(-Wdisabled-optimization)

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


#if !HAVE_PERL_VERSION(5, 13, 6)
static OP *my_append_elem(pTHX_ I32 type, OP *first, OP *last) {
	if (!first)
		return last;

	if (!last)
		return first;

	if (first->op_type != (unsigned)type
		|| (type == OP_LIST && (first->op_flags & OPf_PARENS)))
	{
		return newLISTOP(type, 0, first, last);
	}

	if (first->op_flags & OPf_KIDS)
		((LISTOP*)first)->op_last->op_sibling = last;
	else {
		first->op_flags |= OPf_KIDS;
		((LISTOP*)first)->op_first = last;
	}
	((LISTOP*)first)->op_last = last;
	return first;
}

#define op_append_elem(type, first, last) my_append_elem(aTHX_ type, first, last)
#endif

#define MY_PKG "Quote::Ref"

#define HINTK_QWA     MY_PKG "/qwa"
#define HINTK_QWH     MY_PKG "/qwh"

enum QxType {
	QX_ARRAY,
	QX_HASH
};

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static void free_ptr_op(pTHX_ void *vp) {
	OP **pp = vp;
	op_free(*pp);
	Safefree(pp);
}

typedef struct {
	enum QxType type;
	I32 delim_start, delim_stop;
} QxSpec;

static void missing_terminator(pTHX_ const QxSpec *spec, line_t line) {
	I32 c = spec->delim_stop;
	SV *sv = sv_2mortal(newSVpvs("'\"'"));

	if (c != '"') {
		U8 utf8_tmp[UTF8_MAXBYTES + 1], *d;
		d = uvchr_to_utf8(utf8_tmp, c);
		pv_uni_display(sv, utf8_tmp, d - utf8_tmp, 100, UNI_DISPLAY_QQ);
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

static OP *parse_qxtail(pTHX_ const QxSpec *spec) {
	I32 c;
	OP **gen_sentinel;
	SV *sv;
	int nesting;
	const int is_utf8 = lex_bufutf8();
	const line_t start = CopLINE(PL_curcop);

	nesting = spec->delim_start == spec->delim_stop ? -1 : 0;

	Newx(gen_sentinel, 1, OP *);
	*gen_sentinel = NULL;
	SAVEDESTRUCTOR_X(free_ptr_op, gen_sentinel);

	sv = sv_2mortal(newSVpvs(""));
	if (is_utf8) {
		SvUTF8_on(sv);
	}

	for (;;) {
		c = lex_peek_unichar(0);
		if (c == -1) {
			missing_terminator(aTHX_ spec, start);
		}

		lex_read_unichar(0);

		if (nesting != -1 && c == spec->delim_start) {
			nesting++;
		} else if (c == spec->delim_stop) {
			if (nesting == -1 || nesting == 0) {
				break;
			}
			nesting--;
		}

		if (c == '\\') {
			const I32 d = lex_peek_unichar(0);

			if (d == '\\' || d == spec->delim_start || d == spec->delim_stop) {
				c = d;
				lex_read_unichar(0);
			}
		}

		if (!isSPACE_uni(c)) {
			my_sv_cat_c(aTHX_ sv, c);
		} else if (SvCUR(sv)) {
			*gen_sentinel = op_append_elem(
				OP_LIST,
				*gen_sentinel,
				newSVOP(OP_CONST, 0, SvREFCNT_inc_NN(sv))
			);
			sv = sv_2mortal(newSVpvs(""));
			if (is_utf8) {
				SvUTF8_on(sv);
			}
		}
	}

	if (SvCUR(sv)) {
		*gen_sentinel = op_append_elem(
			OP_LIST,
			*gen_sentinel,
			newSVOP(OP_CONST, 0, SvREFCNT_inc_NN(sv))
		);
		sv = NULL;
	}

	{
		OP *gen = spec->type == QX_ARRAY ? newANONLIST(*gen_sentinel) : newANONHASH(*gen_sentinel);
		*gen_sentinel = NULL;

		return gen;
	}
}

static void parse_qx(pTHX_ OP **op_ptr, const enum QxType t) {
	I32 c;

	c = lex_peek_unichar(0);

	if (c != '#') {
		lex_read_space(0);
		c = lex_peek_unichar(0);
		if (c == -1) {
			croak("Unexpected EOF after qw%c", t == QX_ARRAY ? 'a' : 'h');
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
		const QxSpec spec = {
			t,
			delim_start, delim_stop
		};

		*op_ptr = parse_qxtail(aTHX_ &spec);
	}
}

static int qx_enabled(pTHX_ const char *hk_ptr, size_t hk_len) {
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
#define qx_enableds(S) qx_enabled(aTHX_ "" S "", sizeof (S) - 1)

static int my_keyword_plugin(pTHX_ char *keyword_ptr, STRLEN keyword_len, OP **op_ptr) {
	int ret;
	enum QxType t;

	if (
		keyword_len == 3 &&
		keyword_ptr[0] == 'q' &&
		keyword_ptr[1] == 'w' &&
		(
			keyword_ptr[2] == 'a' ? t = QX_ARRAY, qx_enableds(HINTK_QWA) :
			keyword_ptr[2] == 'h' ? t = QX_HASH , qx_enableds(HINTK_QWH) :
			0
		)
	) {
		ENTER;
		parse_qx(aTHX_ op_ptr, t);
		LEAVE;
		ret = KEYWORD_PLUGIN_EXPR;
	} else {
		ret = next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
	}

	return ret;
}


WARNINGS_RESET

MODULE = Quote::Ref   PACKAGE = Quote::Ref
PROTOTYPES: ENABLE

BOOT:
WARNINGS_ENABLE {
	HV *const stash = gv_stashpvs(MY_PKG, GV_ADD);
	/**/
	newCONSTSUB(stash, "HINTK_QWA", newSVpvs(HINTK_QWA));
	newCONSTSUB(stash, "HINTK_QWH", newSVpvs(HINTK_QWH));
	/**/
	next_keyword_plugin = PL_keyword_plugin;
	PL_keyword_plugin = my_keyword_plugin;
} WARNINGS_RESET
