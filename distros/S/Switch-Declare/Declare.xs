#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"  /* backports the OpSIBLING / OpLASTSIB_set op-tree macros to
                        perl 5.14-5.20 (added to core in 5.22) */

/* pad_add_name_pvn was a 5.15.1 rename of pad_add_name; the 5.14 function has the
 * identical (name, len, flags, typestash, ourstash) */
#if PERL_VERSION < 16
#  define pad_add_name_pvn(name, len, flags, typestash, ourstash) \
       Perl_pad_add_name(aTHX_ (name), (len), (flags), (typestash), (ourstash))
/* pad_findmy_pvn is the 5.15.1 rename of pad_findmy; the 5.14 function takes the
 * identical (name, len, flags) arguments. */
#  define pad_findmy_pvn(name, len, flags) \
       Perl_pad_findmy(aTHX_ (name), (len), (flags))
#endif

#define MAX_ARMS 4096

/* Shared compile-time destructuring engine (dd_pat / dd_parse_pattern / dd_emit
 * and the dd_tail / dd_hrest custom ops). Powers the `case PAT -> [..]` binding
 * bridge below. Must come after the pad_add_name_pvn shim above. */
#include "destructure.h"

/* Previous keyword plugin in the chain. */
static int (*sd_next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

/* Read a bareword identifier from the lexer (or NULL if none). */
static SV *sd_lex_read_ident(pTHX) {
	SV *buf = newSVpvs("");
	I32 c;
	while (1) {
		c = lex_peek_unichar(0);
		if (c == -1) break;
		if (!isALNUM(c) && c != '_') break;
		sv_catpvf(buf, "%c", (int)c);
		lex_read_unichar(0);
	}
	if (SvCUR(buf) == 0) {
		SvREFCNT_dec(buf);
		return NULL;
	}
	return buf;
}

/* Read a possibly package-qualified sub name (Foo::bar, Foo'bar). */
static SV *sd_lex_subname(pTHX) {
	SV *buf = newSVpvs("");
	I32 c;
	while (1) {
		c = lex_peek_unichar(0);
		if (c == -1) break;
		if (isALNUM(c) || c == '_') {
			sv_catpvf(buf, "%c", (int)c);
			lex_read_unichar(0);
		} else if (c == ':' && PL_parser->bufptr[0] == ':'
		                    && PL_parser->bufptr[1] == ':') {
			sv_catpvs(buf, "::");
			lex_read_unichar(0);
			lex_read_unichar(0);
		} else break;
	}
	if (SvCUR(buf) == 0) {
		SvREFCNT_dec(buf);
		return NULL;
	}
	return buf;
}

/* Hand-lex a numeric literal (optional sign, integer/float/exponent). */
static SV *sd_lex_number(pTHX) {
	SV *buf = newSVpvs("");
	I32 c = lex_peek_unichar(0);
	int seen_dot = 0, seen_digit = 0;
	if (c == '-' || c == '+') {
		sv_catpvf(buf, "%c", (int)c);
		lex_read_unichar(0);
	}
	while (1) {
		c = lex_peek_unichar(0);
		if (c >= '0' && c <= '9') { seen_digit = 1; }
		else if (c == '.' && !seen_dot) {
			/* Only a decimal point if followed by a digit; otherwise it is
			 * the '..' range operator (or a terminator) - leave it alone. */
			char next = (PL_parser->bufptr[0] == '.') ? PL_parser->bufptr[1] : '\0';
			if (next < '0' || next > '9') break;
			seen_dot = 1;
		}
		else if ((c == 'e' || c == 'E') && seen_digit) {
			sv_catpvf(buf, "%c", (int)c);
			lex_read_unichar(0);
			c = lex_peek_unichar(0);
			if (c == '-' || c == '+') {
				sv_catpvf(buf, "%c", (int)c);
				lex_read_unichar(0);
			}
			continue;
		}
		else break;
		sv_catpvf(buf, "%c", (int)c);
		lex_read_unichar(0);
	}
	if (!seen_digit) {
		SvREFCNT_dec(buf);
		croak("switch: malformed numeric case pattern");
	}
	return buf;
}

/* Hand-lex a quoted string literal ('...' or "..."), basic backslash escapes. */
static SV *sd_lex_string(pTHX) {
	I32 quote = lex_read_unichar(0);
	SV *sv = newSVpvs("");
	I32 c;
	while (1) {
		c = lex_read_unichar(0);
		if (c == -1) croak("switch: unterminated string in case pattern");
		if (c == '\\') {
			I32 next = lex_read_unichar(0);
			if (next == -1) croak("switch: unterminated string in case pattern");
			if (quote == '"') {
				switch (next) {
					case 'n': sv_catpvs(sv, "\n"); break;
					case 't': sv_catpvs(sv, "\t"); break;
					case 'r': sv_catpvs(sv, "\r"); break;
					case '0': sv_catpvs(sv, "\0"); break;
					default:  sv_catpvf(sv, "%c", (int)next); break;
				}
			} else {
				/* single quotes: only \\ and \' are special */
				if (next != '\\' && next != '\'')
					sv_catpvf(sv, "%c", '\\');
				sv_catpvf(sv, "%c", (int)next);
			}
		} else if (c == quote) {
			break;
		} else {
			sv_catpvf(sv, "%c", (int)c);
		}
	}
	return sv;
}

/* Describes where the matched topic comes from. When the scrutinee is already
 * a plain lexical or a constant, each case test re-reads it directly (just like
 * a hand-written if/elsif chain) and no temp / do-block is needed. Otherwise
 * the scrutinee is stored once in a pad temp. */
#define SDT_TEMP  0   /* stored once in pad temp `off` (do-block) */
#define SDT_PAD   1   /* re-read scrutinee's own lexical at `off` */
#define SDT_CONST 2   /* re-read a constant value */

/* How the numeric looks_like_number($topic) guard is sourced. For a defined
 * constant scrutinee it folds to a compile-time boolean; otherwise it is
 * computed once into a pad temp and each numeric arm just reads that temp. */
#define LLN_CONST 0   /* compile-time constant in `lln_const` */
#define LLN_PAD   1   /* computed once into pad temp `lln_off` */

typedef struct {
	int        kind;
	PADOFFSET  off;
	SV        *sv;
	int        lln_mode;   /* LLN_CONST or LLN_PAD */
	int        lln_const;  /* folded looks_like_number value (LLN_CONST) */
	PADOFFSET  lln_off;    /* pad temp holding the guard (LLN_PAD) */
	int        lln_used;   /* a numeric arm referenced the LLN_PAD temp */
} SDTopic;

/* A fresh op yielding the topic value. */
static OP *sd_topic(pTHX_ SDTopic *t) {
	if (t->kind == SDT_CONST)
		return newSVOP(OP_CONST, 0, newSVsv(t->sv));
	{
		OP *o = newOP(OP_PADSV, 0);
		o->op_targ = t->off;
		return o;
	}
}

/* ---- looks_like_number($topic) as a fast custom op ---------------------
 * A numeric pattern (==, range, list) must only fire for a topic that really
 * is a number. Without this, `switch("one") { case 1 {...} }` would warn
 * ("Argument isn't numeric in numeric eq") and - worse - "one" == 0 would
 * *match* a `case 0`. Guarding each numeric compare with looks_like_number()
 * makes a non-numeric topic simply not match (and not warn), mirroring how an
 * undef topic is handled. It compiles to a single custom op: no sub call, no
 * module dependency. */
static OP *sd_pp_looks_number(pTHX) {
	dSP;
	SV *sv = TOPs;
	SETs(boolSV(sv && SvOK(sv) && looks_like_number(sv)));
	RETURN;
}

static XOP sd_looks_number_xop;

/* The raw  looks_like_number($topic)  custom op (one pp call, no sub call).
 * Built as an OP_NULL unop (always accepted by newUNOP on every perl) then
 * retyped to our registered custom op; newUNOP sets OPf_KIDS so op_free still
 * reclaims the child topic op. */
static OP *sd_looks_number_op(pTHX_ SDTopic *t) {
	OP *o = newUNOP(OP_NULL, 0, sd_topic(aTHX_ t));
	o->op_type   = OP_CUSTOM;
	o->op_ppaddr = sd_pp_looks_number;
	return o;
}

/* looks_like_number(OPERAND) over an arbitrary operand op (not just the topic).
 * Used to guard a `case num $var` operand so a non-numeric $var neither matches
 * nor warns - mirroring the topic guard. */
static OP *sd_lln_raw(pTHX_ OP *operand) {
	OP *o = newUNOP(OP_NULL, 0, operand);
	o->op_type   = OP_CUSTOM;
	o->op_ppaddr = sd_pp_looks_number;
	return o;
}

/* The numeric guard expression used by each numeric arm. For a defined constant
 * topic it folds to a compile-time boolean; otherwise the guard is computed once
 * per switch (see the LLN_PAD prelude in sd_parse_switch) and each arm just reads
 * that pad temp - so a switch with N numeric arms calls looks_like_number once,
 * not N times. */
static OP *sd_looks_number(pTHX_ SDTopic *t) {
	if (t->lln_mode == LLN_CONST)
		return newSVOP(OP_CONST, 0, boolSV(t->lln_const));
	t->lln_used = 1;
	{
		OP *o = newOP(OP_PADSV, 0);
		o->op_targ = t->lln_off;
		return o;
	}
}

/* ---- reftype($topic) as a fast custom op -------------------------------
 * Like ref(), but reports the underlying type ("ARRAY"/"HASH"/...) even for a
 * blessed reference, and undef for a non-reference. Used by the reftype(TYPE)
 * pattern. Same OP_NULL->OP_CUSTOM construction as the looks_number op. */
static OP *sd_pp_reftype(pTHX) {
	dSP;
	SV *sv = TOPs;
	/* Like ref(), a non-reference yields a defined empty/false value (not
	 * undef) so `reftype(TYPE)` compares as `"" eq "TYPE"` without warning and
	 * bare `reftype` is simply false. */
	SETs(SvROK(sv) ? sv_2mortal(newSVpv(sv_reftype(SvRV(sv), 0), 0))
	               : &PL_sv_no);
	RETURN;
}

static XOP sd_reftype_xop;

static OP *sd_reftype_op(pTHX_ SDTopic *t) {
	OP *o = newUNOP(OP_NULL, 0, sd_topic(aTHX_ t));
	o->op_type   = OP_CUSTOM;
	o->op_ppaddr = sd_pp_reftype;
	return o;
}

/* When every arm maps a distinct string-literal key to a constant value (a
 * lookup table) and there are at least this many of them, the whole switch is
 * lowered to a single O(1) hash lookup against a compile-time constant hash
 * instead of an O(n) chain of eq tests. */
#define SD_DISPATCH_MIN 4

/* What a case pattern was, for dispatch eligibility. */
typedef struct {
	int  str_key;     /* 1 if an exact string-literal pattern (eq) */
	SV  *key;         /* the literal (owned) when str_key */
	int  is_undef;    /* 1 if the pattern was the `undef` keyword */
	int  undef_safe;  /* 1 if the pattern can't match/warn on an undef topic */
} SDPat;

/* A fresh  $PKGHASH{ topic }  element op, where the hash is the package
 * variable named by `gv`. Referencing the hash through a GV (rather than an
 * op-constant hashref) keeps the dispatch table thread-safe: op constants are
 * cloned per-thread, which would dangle a reference to a shared HV.
 *
 * When `sentinel` is non-NULL the topic may be undef, so the key is guarded as
 *   defined($topic) ? $topic : SENTINEL
 * with SENTINEL a string known not to be in the table - an undef topic then
 * misses cleanly (-> default) instead of warning on an undef hash key. */
static OP *sd_helem(pTHX_ GV *gv, SDTopic *t, SV *sentinel) {
	OP *gvop  = newGVOP(OP_GV, 0, gv);
	OP *deref = newUNOP(OP_RV2HV, OPf_REF, gvop);
	OP *key;
	if (sentinel)
		key = newCONDOP(0, newUNOP(OP_DEFINED, 0, sd_topic(aTHX_ t)),
		                sd_topic(aTHX_ t),
		                newSVOP(OP_CONST, 0, newSVsv(sentinel)));
	else
		key = sd_topic(aTHX_ t);
	return newBINOP(OP_HELEM, 0, deref, key);
}

/* Read a literal (number or string) into an OP_CONST, setting *is_num. */
static OP *sd_lex_literal(pTHX_ int *is_num) {
	I32 c = lex_peek_unichar(0);
	if (c == '"' || c == '\'') {
		*is_num = 0;
		return newSVOP(OP_CONST, 0, sd_lex_string(aTHX));
	}
	if ((c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.') {
		*is_num = 1;
		return newSVOP(OP_CONST, 0, sd_lex_number(aTHX));
	}
	croak("switch: expected a number or string literal");
	return NULL; /* not reached */
}

/* topic CMP const, where CMP is numeric (==/>=/<=) or string (eq/ge/le).
 * Numeric comparisons are guarded by looks_like_number($topic) so a non-numeric
 * topic never matches or warns; string comparisons (eq/ge/le) never warn and
 * need no guard. */
static OP *sd_cmp(pTHX_ SDTopic *t, int is_num, I32 numop, I32 strop, OP *konst) {
	OP *cmp = newBINOP(is_num ? numop : strop, 0, sd_topic(aTHX_ t), konst);
	if (is_num)
		cmp = newLOGOP(OP_AND, 0, sd_looks_number(aTHX_ t), cmp);
	return cmp;
}

/* ---- $topic =~ PATTERN  as a fast custom op ----------------------------
 * The `=~ $var` pattern matches the topic against a *runtime* pattern held in a
 * scalar (a qr// or a string), so it cannot be compiled once at compile time
 * like the `/literal/` form. Rather than hand-wire an OP_REGCOMP/OP_MATCH pair
 * (fragile to thread correctly), it is a self-contained custom op in the same
 * family as the looks_number / reftype ops: pop the pattern and the topic, run
 * the match, push a boolean. A qr// operand reuses its compiled program; a bare
 * string is compiled per evaluation (and freed). Both operands are guaranteed
 * defined here - the pattern is guarded with defined() and an undef topic is
 * guarded by the chain - so the match itself never warns. */
static OP *sd_pp_rxmatch(pTHX) {
	dSP;
	SV *pat = POPs;
	SV *str = TOPs;
	bool matched = FALSE;
	REGEXP *rx = SvRXOK(pat) ? SvRX(pat) : NULL;
	int owned = 0;
	if (!rx) { rx = pregcomp(pat, 0); owned = 1; }
	if (rx) {
		STRLEN len;
		char *s = SvPV(str, len);
		if (pregexec(rx, s, s + len, s, 0, str, 1))
			matched = TRUE;
		if (owned) ReREFCNT_dec(rx);
	}
	SETs(boolSV(matched));
	RETURN;
}

static XOP sd_rxmatch_xop;

/* topic and pattern are pushed by the two child ops; the custom op pops both.
 * A native OP_MATCH cannot be built here - perl's pattern builders (pmruntime)
 * are entangled with the parser's own pattern-lexing state and crash when driven
 * from a keyword plugin - so this is a self-contained custom op. The trade-off
 * is that it is a pure membership test: it sets no capture variables ($1, @+).
 * For captures from a runtime pattern, use a predicate arm: case sub { $_[0] =~ $rx }. */
static OP *sd_rxmatch_op(pTHX_ SDTopic *t, OP *patop) {
	OP *o = newBINOP(OP_NULL, 0, sd_topic(aTHX_ t), patop);
	o->op_type   = OP_CUSTOM;
	o->op_ppaddr = sd_pp_rxmatch;
	return o;
}

/* Build  CALLEE->( topic )  as an entersub. The OP_ENTERSUB checker inserts the
 * pushmark itself, so we must NOT add one - a second pushmark leaves a dangling
 * mark that corrupts a surrounding list/aassign at runtime. */
static OP *sd_predicate_call(pTHX_ OP *callee, SDTopic *t) {
	OP *args = op_append_elem(OP_LIST, sd_topic(aTHX_ t), callee);
	return newUNOP(OP_ENTERSUB, OPf_STACKED, args);
}

/* Build  Switch::Declare::_isa($topic, "Class")  -> true iff the topic is a
 * blessed object derived from Class (a fast @ISA check; see the XS _isa below).
 * An entersub rather than a custom op keeps the two-argument call portable
 * across the supported perls. */
static OP *sd_isa_call(pTHX_ SDTopic *t, SV *klass) {
	GV *gv   = gv_fetchpvs("Switch::Declare::_isa", GV_ADD, SVt_PVCV);
	OP *cvop = newUNOP(OP_RV2CV, 0, newGVOP(OP_GV, 0, gv));
	OP *args = op_append_elem(OP_LIST, sd_topic(aTHX_ t),
	                          newSVOP(OP_CONST, 0, klass));
	args = op_append_elem(OP_LIST, args, cvop);
	return newUNOP(OP_ENTERSUB, OPf_STACKED, args);
}

/* Read an optional/required  ( NAME )  argument after a pattern keyword, where
 * NAME is a package-qualified bareword (ARRAY, Foo::Bar) or a quoted string.
 * Returns the name SV (caller owns) or NULL when there is no '('. */
static SV *sd_lex_paren_arg(pTHX) {
	I32 c;
	SV *name;
	lex_read_space(0);
	if (lex_peek_unichar(0) != '(') return NULL;
	lex_read_unichar(0);
	lex_read_space(0);
	c = lex_peek_unichar(0);
	if (c == '"' || c == '\'')
		name = sd_lex_string(aTHX);
	else
		name = sd_lex_subname(aTHX);
	if (!name) croak("switch: expected a name inside (...)");
	lex_read_space(0);
	if (lex_peek_unichar(0) != ')') {
		SvREFCNT_dec(name);
		croak("switch: expected ')' after pattern argument");
	}
	lex_read_unichar(0);
	return name;
}

/* A parsed scalar-variable operand for `case num $x` / `case str $x`. It is
 * either an in-scope lexical (off != NOT_IN_PAD) or a package scalar (gv), and
 * is rebuilt fresh by sd_var_op on each use so the operand can be referenced by
 * both the type guard and the comparison without sharing an op. */
typedef struct { PADOFFSET off; GV *gv; } SDVar;

/* Hand-lex a plain scalar variable - the leading '$' is still unread. Restricted
 * to a bare `$name` / `$Pkg::name` (no `[...]`/`{...}` element access) so the
 * arm's opening `{` is never misparsed as a `$x{...}` hash subscript. */
static void sd_lex_scalar_var(pTHX_ SDVar *v) {
	SV *name, *withsig;
	PADOFFSET off;
	if (lex_peek_unichar(0) != '$')
		croak("switch: expected a scalar variable ($name) after ==, eq, or =~");
	lex_read_unichar(0);
	name = sd_lex_subname(aTHX);
	if (!name) croak("switch: expected a variable name after '$'");
	withsig = newSVpvs("$");
	sv_catsv(withsig, name);
	off = pad_findmy_pvn(SvPVX(withsig), SvCUR(withsig), 0);
	SvREFCNT_dec(withsig);
	if (off != NOT_IN_PAD) {
		/* An `our` variable has a pad entry, but the slot aliases a GV rather
		 * than holding the value - reading it as a plain PADSV is wrong. Resolve
		 * it to the package scalar it really is, qualified by the `our`'s own
		 * stash so the lookup neither trips strict 'vars' nor guesses the wrong
		 * package. The PAD_COMPNAME_* macros take the offset directly and are
		 * stable from 5.8 through current perl, so this is one path on every
		 * version - unlike the PADNAME API, which only exists from 5.18. */
		if (PAD_COMPNAME_FLAGS_isOUR(off)) {
			HV *stash = PAD_COMPNAME_OURSTASH(off);
			SV *q = newSVpvs("");
			if (stash && HvNAME(stash))
				sv_catpvf(q, "%s::", HvNAME(stash));
			sv_catsv(q, name);
			v->off = NOT_IN_PAD;
			v->gv  = gv_fetchpv(SvPV_nolen(q), GV_ADD, SVt_PV);
			SvREFCNT_dec(q);
			SvREFCNT_dec(name);
			return;
		}
		v->off = off;
		v->gv  = NULL;
	} else {
		/* A plain package global: sd_lex_subname keeps any `Pkg::` qualifier, so
		 * gv_fetchpv sees a qualified name and strict 'vars' stays satisfied. */
		v->off = NOT_IN_PAD;
		v->gv  = gv_fetchpv(SvPV_nolen(name), GV_ADD, SVt_PV);
	}
	SvREFCNT_dec(name);
}

/* A fresh op yielding the variable operand's value. */
static OP *sd_var_op(pTHX_ SDVar *v) {
	if (v->off != NOT_IN_PAD) {
		OP *o = newOP(OP_PADSV, 0);
		o->op_targ = v->off;
		return o;
	}
	return newUNOP(OP_RV2SV, 0, newGVOP(OP_GV, 0, v->gv));
}

/* Parse one case PATTERN from the lexer and return its boolean condition op,
 * testing the topic. Fills *pat describing the pattern (for dispatch). */
static OP *sd_parse_case_cond(pTHX_ SDTopic *t, SDPat *pat) {
	I32 c = lex_peek_unichar(0);
	pat->str_key = 0;
	pat->key     = NULL;
	pat->is_undef = 0;
	pat->undef_safe = 0;

	/* regex:  /PATTERN/flags  ->  native  topic =~ /PATTERN/flags
	 * The pattern is compiled once, here at compile time, and bound to a
	 * standard OP_MATCH - no runtime helper, no per-match recompilation. */
	if (c == '/') {
		SV *pat = newSVpvs("");
		U32 rxflags = 0;
		REGEXP *rx;
		PMOP *pmop;
		OP *target;
		lex_read_unichar(0);
		while (1) {
			c = lex_read_unichar(0);
			if (c == -1) croak("switch: unterminated regex in case pattern");
			if (c == '\\') {
				I32 n = lex_read_unichar(0);
				if (n == -1) croak("switch: unterminated regex in case pattern");
				sv_catpvf(pat, "%c", '\\');
				sv_catpvf(pat, "%c", (int)n);
				continue;
			}
			if (c == '/') break;
			sv_catpvf(pat, "%c", (int)c);
		}
		while (isALPHA((c = lex_peek_unichar(0)))) {
			switch (c) {
				case 'i': rxflags |= PMf_FOLD;       break;
				case 'm': rxflags |= PMf_MULTILINE;  break;
				case 's': rxflags |= PMf_SINGLELINE; break;
				case 'x': rxflags |= PMf_EXTENDED;   break;
				default:  croak("switch: unsupported regex flag '%c' in case pattern", (int)c);
			}
			lex_read_unichar(0);
		}
		rx = pregcomp(pat, rxflags);
		SvREFCNT_dec(pat);
		pmop = (PMOP *)newPMOP(OP_MATCH, 0);
		PM_SETRE(pmop, rx);
		/* bind the topic as the match target ($topic =~ ...) */
		target = sd_topic(aTHX_ t);
		((PMOP *)pmop)->op_first = target;
		((PMOP *)pmop)->op_last  = target;
		OpLASTSIB_set(target, (OP *)pmop);
		pmop->op_flags |= OPf_KIDS | OPf_STACKED;
		return (OP *)pmop;
	}

	/* predicate:  \&name  -> name($topic) */
	if (c == '\\') {
		SV *name;
		GV *gv;
		OP *cvop;
		lex_read_unichar(0);
		if (lex_peek_unichar(0) != '&')
			croak("switch: expected '&' after '\\' in case predicate");
		lex_read_unichar(0);
		name = sd_lex_subname(aTHX);
		if (!name) croak("switch: expected sub name after '\\&'");
		gv = gv_fetchpv(SvPV_nolen(name), GV_ADD, SVt_PVCV);
		SvREFCNT_dec(name);
		cvop = newUNOP(OP_RV2CV, 0, newGVOP(OP_GV, 0, gv));
		return sd_predicate_call(aTHX_ cvop, t);
	}

	/* bracket:  [LO .. HI] range, or [a, b, c] membership list */
	if (c == '[') {
		int is_num;
		OP *first;
		lex_read_unichar(0);
		lex_read_space(0);
		first = sd_lex_literal(aTHX_ &is_num);
		lex_read_space(0);
		if (lex_peek_unichar(0) == '.') {
			/* range: [LO .. HI] */
			OP *hi;
			int hi_num;
			lex_read_unichar(0);
			if (lex_peek_unichar(0) != '.')
				croak("switch: expected '..' in range case pattern");
			lex_read_unichar(0);
			lex_read_space(0);
			hi = sd_lex_literal(aTHX_ &hi_num);
			lex_read_space(0);
			if (lex_peek_unichar(0) != ']')
				croak("switch: expected ']' to close range case pattern");
			lex_read_unichar(0);
			return newLOGOP(OP_AND, 0,
				sd_cmp(aTHX_ t, is_num, OP_GE, OP_SGE, first),
				sd_cmp(aTHX_ t, hi_num, OP_LE, OP_SLE, hi));
		}
		/* membership list: [a, b, c] -> OR-chain of equality tests */
		{
			OP *chain = sd_cmp(aTHX_ t, is_num, OP_EQ, OP_SEQ, first);
			while (1) {
				OP *elt;
				int en;
				lex_read_space(0);
				if (lex_peek_unichar(0) == ',') lex_read_unichar(0);
				lex_read_space(0);
				if (lex_peek_unichar(0) == ']') { lex_read_unichar(0); break; }
				elt = sd_lex_literal(aTHX_ &en);
				chain = newLOGOP(OP_OR, 0, chain,
					sd_cmp(aTHX_ t, en, OP_EQ, OP_SEQ, elt));
			}
			return chain;
		}
	}

	/* == $var : numeric comparison against a runtime scalar.
	 * =~ $var : regex match against a runtime pattern (a qr// or string in a
	 *           variable).  Because a variable's type/pattern is unknown at
	 *           compile time, the operator is written out - `==` for numeric,
	 *           `=~` for match (here); `eq` for string is a bareword, below. */
	if (c == '=') {
		SDVar v;
		I32 c2;
		lex_read_unichar(0);
		c2 = lex_peek_unichar(0);
		if (c2 == '=') {
			lex_read_unichar(0);
			lex_read_space(0);
			sd_lex_scalar_var(aTHX_ &v);
			/* looks_like_number($var) && looks_like_number($topic)
			 *                          && $topic == $var  - undef-safe both sides. */
			pat->undef_safe = 1;
			return newLOGOP(OP_AND, 0,
				sd_lln_raw(aTHX_ sd_var_op(aTHX_ &v)),
				sd_cmp(aTHX_ t, 1, OP_EQ, OP_SEQ, sd_var_op(aTHX_ &v)));
		}
		if (c2 == '~') {
			lex_read_unichar(0);
			lex_read_space(0);
			sd_lex_scalar_var(aTHX_ &v);
			/* defined($var) && $topic =~ $var. An undef topic is guarded by the
			 * chain (undef_safe = 0); guarding $var keeps an undef pattern from
			 * warning (it simply does not match). */
			pat->undef_safe = 0;
			return newLOGOP(OP_AND, 0,
				newUNOP(OP_DEFINED, 0, sd_var_op(aTHX_ &v)),
				sd_rxmatch_op(aTHX_ t, sd_var_op(aTHX_ &v)));
		}
		croak("switch: expected '==' or '=~' in case comparison");
	}

	/* inline predicate:  sub { ... }  ->  (sub { ... })->($topic)
	 * undef keyword:      undef       ->  !defined($topic)
	 * ref / ref(TYPE):    ref($topic) [eq "TYPE"]
	 * reftype / (TYPE):   reftype($topic) [eq "TYPE"]   (sees through blessing)
	 * isa(Class):         blessed object derived from Class
	 * eq $var:            $topic eq $var  (string compare vs a runtime scalar) */
	if (isALPHA(c) || c == '_') {
		/* read a possibly package-qualified bareword (so a constant may be
		 * `Foo::BAR`); keyword names never contain '::' so they still match. */
		SV *word       = sd_lex_subname(aTHX);
		const char *wp = word ? SvPV_nolen(word) : "";
		int is_sub     = strEQ(wp, "sub");
		int is_undef   = strEQ(wp, "undef");
		int is_ref     = strEQ(wp, "ref");
		int is_reftype = strEQ(wp, "reftype");
		int is_isa     = strEQ(wp, "isa");
		int is_eq      = strEQ(wp, "eq");
		/* Eagerly resolve the bareword as an inlinable constant while `word` is
		 * still alive. cv_const_sv returns the value owned by the (persistent)
		 * constant sub, so it stays valid after we release `word`. */
		CV *cv         = word ? get_cvn_flags(SvPVX(word), SvCUR(word), 0) : NULL;
		SV *const_val  = cv ? cv_const_sv(cv) : NULL;
		char errbuf[128];
		errbuf[0] = '\0';
		if (word) {
			my_strlcpy(errbuf, SvPV_nolen(word), sizeof(errbuf));
			SvREFCNT_dec(word);
		}
		/* eq $var : string comparison against a runtime scalar. Honoured only
		 * when a '$' actually follows, so a bareword `eq` otherwise falls through
		 * to constant / error handling. (Its numeric sibling `== $var` is parsed
		 * above, as it does not begin with a word character.) */
		if (is_eq) {
			lex_read_space(0);
			if (lex_peek_unichar(0) == '$') {
				SDVar v;
				sd_lex_scalar_var(aTHX_ &v);
				/* defined($var) && $topic eq $var. An undef topic is guarded by
				 * the chain (undef_safe = 0), so a string variable matches
				 * exactly like a string literal. */
				pat->undef_safe = 0;
				return newLOGOP(OP_AND, 0,
					newUNOP(OP_DEFINED, 0, sd_var_op(aTHX_ &v)),
					sd_cmp(aTHX_ t, 0, OP_EQ, OP_SEQ, sd_var_op(aTHX_ &v)));
			}
			/* no '$' - fall through to constant / error handling */
		}
		if (is_undef) {
			pat->is_undef = 1;
			pat->undef_safe = 1;
			return newUNOP(OP_NOT, 0,
				newUNOP(OP_DEFINED, 0, sd_topic(aTHX_ t)));
		}
		if (is_ref) {
			/* ref($topic) [eq "TYPE"] - pure ops, never warns. */
			SV *type = sd_lex_paren_arg(aTHX);
			pat->undef_safe = 1;
			if (!type)
				return newUNOP(OP_REF, 0, sd_topic(aTHX_ t));
			return newBINOP(OP_SEQ, 0,
				newUNOP(OP_REF, 0, sd_topic(aTHX_ t)),
				newSVOP(OP_CONST, 0, type));
		}
		if (is_reftype) {
			/* reftype($topic) [eq "TYPE"] - underlying type, blessing aside. */
			SV *type = sd_lex_paren_arg(aTHX);
			pat->undef_safe = 1;
			if (!type)
				return sd_reftype_op(aTHX_ t);
			return newBINOP(OP_SEQ, 0, sd_reftype_op(aTHX_ t),
				newSVOP(OP_CONST, 0, type));
		}
		if (is_isa) {
			SV *klass = sd_lex_paren_arg(aTHX);
			if (!klass)
				croak("switch: isa requires a class: case isa(Class)");
			pat->undef_safe = 1;
			return sd_isa_call(aTHX_ t, klass);
		}
		if (is_sub) {
			I32 floor;
			OP *body, *anon;
			lex_read_space(0);
			if (lex_peek_unichar(0) != '{')
				croak("switch: expected '{' after 'sub' in case predicate");
			floor = start_subparse(FALSE, CVf_ANON);
			body  = parse_block(0);
			anon  = newANONATTRSUB(floor, NULL, NULL, body);
			return sd_predicate_call(aTHX_ anon, t);
		}
		if (const_val) {
			/* An inlinable constant (use constant FOO => ...) folds to its value
			 * and is classified just like the literal it holds: a number compiles
			 * to ==, anything with a string form to eq (dispatch-eligible). */
			int cnum  = (SvIOK(const_val) || SvNOK(const_val)) && !SvPOK(const_val);
			OP *konst = newSVOP(OP_CONST, 0, newSVsv(const_val));
			if (cnum) {
				pat->undef_safe = 1;
			} else {
				pat->str_key = 1;
				pat->key     = newSVsv(const_val);
			}
			return sd_cmp(aTHX_ t, cnum, OP_EQ, OP_SEQ, konst);
		}
		croak("switch: unexpected bareword '%s' in case pattern (expected a number, "
		      "string, /regex/, [range or list], \\&name, sub {...}, a constant, "
		      "or == / eq $var)", errbuf);
	}

	/* scalar literal:  number -> ==,  string -> eq */
	{
		int is_num;
		OP *konst = sd_lex_literal(aTHX_ &is_num);
		if (!is_num) {
			/* exact string match: hash lookup is exactly eq semantics, so
			 * this arm is eligible for dispatch-table lowering. */
			pat->str_key = 1;
			pat->key     = newSVsv(((SVOP *)konst)->op_sv);
		} else {
			/* numeric == is already looks_like_number-guarded: undef-safe. */
			pat->undef_safe = 1;
		}
		return sd_cmp(aTHX_ t, is_num, OP_EQ, OP_SEQ, konst);
	}
}

/* True if any op in the tree introduces a lexical (my/our/local): such a block
 * needs its own scope and must not be unwrapped. */
static int sd_has_intro(pTHX_ OP *o) {
	OP *kid;
	if (!o) return 0;
	if (o->op_private & OPpLVAL_INTRO) return 1;
	if (o->op_flags & OPf_KIDS) {
		for (kid = cUNOPx(o)->op_first; kid; kid = OpSIBLING(kid))
			if (sd_has_intro(aTHX_ kid)) return 1;
	}
	return 0;
}

/* If `block` is a trivial `{ EXPR }` - a lineseq of exactly [nextstate, EXPR]
 * with no lexical introductions - return the bare EXPR (freeing the wrapper)
 * and set *simple. Such a branch carries no nextstate, so it is safe as a bare
 * conditional arm and needs no enclosing scope. Otherwise return block as-is. */
static OP *sd_simplify_block(pTHX_ OP *block, int *simple) {
	*simple = 0;
	if (block->op_type == OP_LINESEQ) {
		OP *first = cLISTOPx(block)->op_first;
		if (first
		    && (first->op_type == OP_NEXTSTATE || first->op_type == OP_DBSTATE)
		    && OpSIBLING(first) && !OpSIBLING(OpSIBLING(first))
		    && !sd_has_intro(aTHX_ OpSIBLING(first))) {
			OP *expr = OpSIBLING(first);
			/* Lift EXPR out of the lineseq, leaving { nextstate } to be
			 * freed.  Portable equivalent of
			 *     op_sibling_splice(block, first, 1, NULL)
			 * which is not provided by core (or ppport.h) before 5.22.
			 * OpLASTSIB_set is backported by ppport.h to 5.14. */
			OpLASTSIB_set(expr, NULL);     /* detach EXPR: no parent, no sibling  */
			cLISTOPx(block)->op_last = first;
			OpLASTSIB_set(first, block);   /* nextstate is now the sole/last kid  */
			op_free(block);
			*simple = 1;
			return expr;
		}
	}
	return block;
}

/* Parse a whole `switch (EXPR) { ... }` construct (the lexer is positioned
 * just after the `switch` keyword) and return its value-producing op tree. */
/* Parse  -> PATTERN { BODY }  for a case arm and return the block op with the
 * destructured topic bound as lexicals visible inside BODY. The `->` has
 * already been consumed. The bindings are prepended to BODY inside the block's
 * own lexical scope (so each arm's bindings are private to that arm and vanish
 * at the closing brace).
 *
 * A flat array pattern lowers to a single native `my (...) = @{$topic // []}`
 * list-assignment - the same fast path the `let` keyword uses; hash, nested and
 * default patterns capture the topic once into a hidden temp and bind per
 * element via dd_emit(). */
static OP *sd_parse_bound_block(pTHX_ SDTopic *topic) {
	dd_pat pat;
	I32 floor;
	OP *seq, *body, *blk, *lhs, *store;
	PADOFFSET src;
	I32 c;

	lex_read_space(0);
	c = lex_peek_unichar(0);
	if (c != '[' && c != '{')
		croak("switch: expected '[' or '{' pattern after '->'");

	dd_parse_pattern(aTHX_ &pat);
	if (pat.shape == DD_LIST) {       /* not reachable via [ / { but be explicit */
		dd_free_pat(aTHX_ &pat);
		croak("switch: list patterns '(...)' are not allowed in a case binding");
	}

	lex_read_space(0);
	if (lex_peek_unichar(0) != '{') {
		dd_free_pat(aTHX_ &pat);
		croak("switch: expected '{' to open the case block after the '->' pattern");
	}

	/* Open an outer block scope to hold the destructured lexicals so they are
	 * private to this arm (and vanish at its closing brace). The arm's own
	 * block is parsed inside it and its statements can see the bindings. */
	floor = Perl_block_start(aTHX_ TRUE);

	/* The fast path derefs the topic as @{ <topic> // [] }. A constant topic
	 * would constant-fold to a symbolic deref (@{"str"}) and die at compile
	 * time under strict, so a constant scrutinee (which can never be an aref,
	 * and whose arm therefore never matches a [..] pattern) takes the general
	 * runtime-deref path instead. */
	if (dd_is_listassign(&pat) && topic->kind != SDT_CONST) {
		/* Fast path: my (LHS) = @{ <topic> // [] }; one native list-assignment. */
		OP *llist = dd_listassign_lhs(aTHX_ &pat);
		OP *rv = newUNOP(OP_RV2AV, 0,
		                 newLOGOP(OP_DOR, 0, sd_topic(aTHX_ topic),
		                          dd_empty_aref(aTHX)));
		seq = newSTATEOP(0, NULL, newASSIGNOP(OPf_STACKED, llist, 0, rv));
	}
	else {
		/* General path: my $src = <topic>; then per-element binds. */
		src = dd_temp(aTHX);
		lhs = dd_padsv(aTHX_ src);
		lhs->op_private |= OPpLVAL_INTRO;
		store = newSTATEOP(0, NULL,
		                   newASSIGNOP(OPf_STACKED, lhs, 0, sd_topic(aTHX_ topic)));
		seq = store;
		dd_emit(aTHX_ &pat, src, &seq);
	}
	dd_free_pat(aTHX_ &pat);

	body = parse_block(0);           /* consumes the whole { ... } */
	seq  = op_append_list(OP_LINESEQ, seq, body);
	blk  = Perl_block_end(aTHX_ floor, seq);
	return op_scope(blk);
}

static OP *sd_parse_switch(pTHX) {
	OP *scrutinee;
	OP *conds[MAX_ARMS];
	OP *blocks[MAX_ARMS];
	SV *keys[MAX_ARMS];     /* string-literal key per arm, or NULL */
	SV *vals[MAX_ARMS];     /* constant value per arm (borrowed), or NULL */
	OP *default_block = NULL;
	int narms = 0;
	int i;
	I32 c;
	int all_simple = 1;    /* every block is a bare-expression `{ EXPR }` */
	int dispatchable = 1;  /* every arm is (string key -> constant value) */
	int topic_maybe_undef; /* scrutinee could be undef at run time */
	SDTopic topic;
	OP *assign;
	OP *lhs;
	OP *chain;
	OP *seq;
	OP *body;
	OP *lln_prelude = NULL; /* `$lln = looks_like_number($topic)`, when hoisted */

	/* switch ( EXPR ) */
	lex_read_space(0);
	if (lex_peek_unichar(0) != '(')
		croak("switch: expected '(' after 'switch'");
	lex_read_unichar(0);
	scrutinee = parse_fullexpr(0);
	lex_read_space(0);
	if (lex_peek_unichar(0) != ')')
		croak("switch: expected ')' after switch expression");
	lex_read_unichar(0);

	/* Decide how case tests will obtain the topic. A plain lexical or a
	 * constant scrutinee is side-effect-free to re-read, so each test reads it
	 * directly and the whole switch lowers to a bare conditional expression -
	 * no temp, no do-block - exactly like a hand-written if/elsif chain.
	 * Anything else (a call, an expression, a possibly-magical global) is
	 * stored once in a pad temp inside a value-returning block. */
	if (scrutinee->op_type == OP_PADSV
	    && !(scrutinee->op_private & OPpLVAL_INTRO)) {
		topic.kind = SDT_PAD;
		topic.off  = scrutinee->op_targ;
		op_free(scrutinee);
		scrutinee = NULL;
	}
	else if (scrutinee->op_type == OP_CONST) {
		topic.kind = SDT_CONST;
		topic.sv   = newSVsv(((SVOP *)scrutinee)->op_sv);
		op_free(scrutinee);
		scrutinee = NULL;
	}
	else {
		/* A unique pad-temp name per switch avoids "masks earlier
		 * declaration" warnings when switches share a lexical scope. */
		static unsigned long sd_seq = 0;
		char namebuf[64];
		int n = my_snprintf(namebuf, sizeof(namebuf),
			"$_Switch_Declare_topic_%lu", sd_seq++);
		topic.kind = SDT_TEMP;
		topic.off  = pad_add_name_pvn(namebuf, (STRLEN)n, 0, NULL, NULL);
	}

	/* A constant scrutinee whose value is defined can never be undef at run
	 * time, so its case tests need no undef guarding (and stay exactly as fast
	 * as before). Any other scrutinee might be undef. */
	topic_maybe_undef = !(topic.kind == SDT_CONST && SvOK(topic.sv));

	/* Numeric guard sourcing: a defined constant topic folds looks_like_number
	 * at compile time; otherwise it is computed once into a pad temp and shared
	 * by every numeric arm (see the LLN_PAD prelude after the body is parsed). */
	topic.lln_used = 0;
	if (topic.kind == SDT_CONST && SvOK(topic.sv)) {
		topic.lln_mode  = LLN_CONST;
		topic.lln_const = looks_like_number(topic.sv) ? 1 : 0;
	} else {
		static unsigned long sd_lln_seq = 0;
		char lbuf[64];
		int ln = my_snprintf(lbuf, sizeof(lbuf),
			"$_Switch_Declare_lln_%lu", sd_lln_seq++);
		topic.lln_mode = LLN_PAD;
		topic.lln_off  = pad_add_name_pvn(lbuf, (STRLEN)ln, 0, NULL, NULL);
	}

	/* { ... } */
	lex_read_space(0);
	if (lex_peek_unichar(0) != '{')
		croak("switch: expected '{' to open switch body");
	lex_read_unichar(0);

	while (1) {
		SV *kw;
		lex_read_space(0);
		c = lex_peek_unichar(0);
		if (c == '}') { lex_read_unichar(0); break; }
		if (c == -1) croak("switch: unexpected end of input in switch body");

		kw = sd_lex_read_ident(aTHX);
		if (!kw) croak("switch: expected 'case' or 'default'");

		if (strEQ(SvPV_nolen(kw), "case")) {
			OP *cond, *blk;
			SDPat pat;
			int simple;
			if (default_block)
				croak("switch: 'case' after 'default' is not allowed");
			if (narms >= MAX_ARMS)
				croak("switch: too many case arms");
			lex_read_space(0);
			cond = sd_parse_case_cond(aTHX_ &topic, &pat);
			/* A value pattern that could match or warn on an undef topic
			 * (string eq / regex / list / range) is guarded with defined($topic)
			 * so undef can only be caught by an explicit `case undef` (or fall
			 * through to default). Patterns that are already undef-safe - numeric
			 * (looks_like_number-guarded), ref/reftype/isa, and undef itself -
			 * skip the guard. The shared default stays the single chain tail. */
			if (topic_maybe_undef && !pat.undef_safe)
				cond = newLOGOP(OP_AND, 0,
					newUNOP(OP_DEFINED, 0, sd_topic(aTHX_ &topic)),
					cond);
			lex_read_space(0);
			/* Optional `-> PATTERN` destructuring bind before the arm block. */
			if (lex_peek_unichar(0) == '-' && PL_parser->bufptr[1] == '>') {
				lex_read_unichar(0);   /* - */
				lex_read_unichar(0);   /* > */
				blk = sd_parse_bound_block(aTHX_ &topic);
				simple = 0;            /* a bound block always carries lexicals */
			}
			else {
				if (lex_peek_unichar(0) != '{')
					croak("switch: expected '{' after case pattern");
				blk = sd_simplify_block(aTHX_ parse_block(0), &simple);
			}
			all_simple &= simple;
			conds[narms]  = cond;
			blocks[narms] = blk;
			keys[narms]   = pat.key;   /* NULL unless an exact string key */
			vals[narms]   = (blk->op_type == OP_CONST)
			                ? ((SVOP *)blk)->op_sv : NULL;
			/* dispatchable iff string key AND constant-valued block */
			if (!pat.key || !vals[narms]) dispatchable = 0;
			narms++;
		}
		else if (strEQ(SvPV_nolen(kw), "default")) {
			if (default_block)
				croak("switch: multiple 'default' blocks");
			lex_read_space(0);
			if (lex_peek_unichar(0) != '{')
				croak("switch: expected '{' after 'default'");
			{
				int simple;
				default_block = sd_simplify_block(aTHX_ parse_block(0), &simple);
				all_simple &= simple;
			}
		}
		else {
			croak("switch: expected 'case' or 'default', got '%s'",
				SvPV_nolen(kw));
		}
		SvREFCNT_dec(kw);
	}

	if (narms == 0 && !default_block)
		croak("switch: empty switch body");

	/* Try the O(1) dispatch-table lowering: every arm maps a distinct string
	 * literal to a constant value, and there are enough of them to beat a
	 * linear eq chain. Build a compile-time constant hash and emit a single
	 * lookup:  exists $H{topic} ? $H{topic} : DEFAULT . */
	chain = NULL;
	if (dispatchable && narms >= SD_DISPATCH_MIN) {
		static unsigned long sd_dt_seq = 0;
		char hashname[64];
		int hn = my_snprintf(hashname, sizeof(hashname),
			"Switch::Declare::_dt%lu", sd_dt_seq++);
		GV *gv = gv_fetchpvn(hashname, (STRLEN)hn, GV_ADD, SVt_PVHV);
		HV *hv = GvHVn(gv);
		int dup = 0, any_undef = 0;
		/* If the topic could be undef, look it up under a guarded key so an
		 * undef topic misses the table (-> default) instead of warning. The
		 * sentinel is a binary string we treat as reserved; in the wildly
		 * unlikely event a real key collides with it, fall back to the chain. */
		SV *sentinel = topic_maybe_undef
			? newSVpvn("\1\0Switch::Declare::undef-key\0\1", 28) : NULL;
		for (i = 0; i < narms; i++) {
			STRLEN klen;
			const char *kpv = SvPV(keys[i], klen);
			if (hv_exists(hv, kpv, klen)) { dup = 1; break; }
			if (!SvOK(vals[i])) any_undef = 1;
			(void)hv_store(hv, kpv, klen, newSVsv(vals[i]), 0);
		}
		if (!dup && sentinel) {
			STRLEN sl;
			const char *sp = SvPV(sentinel, sl);
			if (hv_exists(hv, sp, sl)) dup = 1;
		}
		if (dup) {
			hv_clear(hv);             /* duplicate keys: fall back to chain */
		} else {
			OP *deflt = default_block ? default_block
			                          : newOP(OP_UNDEF, 0);
			if (any_undef) {
				/* a value can be undef, so a miss is indistinguishable from a
				 * hit by definedness: test membership explicitly. */
				OP *cond = newUNOP(OP_EXISTS, 0, sd_helem(aTHX_ gv, &topic, sentinel));
				chain = newCONDOP(0, cond, sd_helem(aTHX_ gv, &topic, sentinel), deflt);
			} else {
				/* all values are defined: one lookup, miss -> default via //. */
				chain = newLOGOP(OP_DOR, 0, sd_helem(aTHX_ gv, &topic, sentinel), deflt);
			}
			/* the unused per-arm condition and block ops are now dead */
			for (i = 0; i < narms; i++) { op_free(conds[i]); op_free(blocks[i]); }
		}
		if (sentinel) SvREFCNT_dec(sentinel);
	}

	/* Otherwise (or on fall-back), build the conditional chain right-to-left. */
	if (!chain) {
		chain = default_block ? default_block
		                      : newOP(OP_UNDEF, 0);
		for (i = narms - 1; i >= 0; i--)
			chain = newCONDOP(0, conds[i], blocks[i], chain);
	}

	for (i = 0; i < narms; i++)
		if (keys[i]) SvREFCNT_dec(keys[i]);

	/* If any numeric arm used the hoisted guard, build the one-time
	 * `$lln = looks_like_number($topic)` that they all read. */
	if (topic.lln_mode == LLN_PAD && topic.lln_used) {
		OP *llhs = newOP(OP_PADSV, 0);
		llhs->op_targ = topic.lln_off;
		llhs->op_private |= OPpLVAL_INTRO;          /* my */
		lln_prelude = newASSIGNOP(OPf_STACKED, llhs, 0,
		                          sd_looks_number_op(aTHX_ &topic));
	}

	if (topic.kind != SDT_TEMP) {
		if (topic.kind == SDT_CONST) SvREFCNT_dec(topic.sv);
		if (!lln_prelude && all_simple)
			/* Fastest path: a plain lexical/constant topic, and either a
			 * dispatch lookup or a chain of bare `{ EXPR }` arms. The whole
			 * switch is literally an expression - no temp, no scope, no
			 * nextstate - as fast as hand-written code. */
			return chain;
		if (lln_prelude) {
			/* Hoisted numeric guard over a plain lexical: wrap in a block that
			 * computes $lln once, then runs the chain (which reads $lln). */
			seq = op_append_list(OP_LINESEQ, newSTATEOP(0, NULL, lln_prelude),
			                                 newSTATEOP(0, NULL, chain));
			seq->op_flags |= OPf_PARENS;
			return op_scope(seq);
		}
		/* Some arm is a multi-statement block (carries a nextstate). Wrap in a
		 * single enter/leave (OPf_PARENS makes op_scope emit OP_LEAVE) so that
		 * nextstate cannot reset the stack base of a surrounding expression. */
		chain->op_flags |= OPf_PARENS;
		return op_scope(chain);
	}

	/* General path: my $topic = SCRUTINEE; [my $lln = looks_like_number($topic);]
	 * <body>, wrapped as a value-returning block so the scrutinee is evaluated
	 * exactly once. OPf_PARENS forces op_scope down its enter/leave path
	 * (OP_LEAVE) for a proper stack frame; without it a bare OP_SCOPE lets the
	 * inner nextstate reset the stack base and clobber a surrounding expression
	 * (e.g. N + switch(...)). */
	lhs = newOP(OP_PADSV, 0);
	lhs->op_targ = topic.off;
	lhs->op_private |= OPpLVAL_INTRO;               /* my */
	assign = newASSIGNOP(OPf_STACKED, lhs, 0, scrutinee);
	seq = newSTATEOP(0, NULL, assign);
	if (lln_prelude)
		/* $lln computed after $topic is stored, before the chain reads it. */
		seq = op_append_list(OP_LINESEQ, seq,
		                     newSTATEOP(0, NULL, lln_prelude));
	seq = op_append_list(OP_LINESEQ, seq, newSTATEOP(0, NULL, chain));
	seq->op_flags |= OPf_PARENS;
	body = op_scope(seq);

	return body;
}

/* True if the Switch::Declare lexical pragma is in scope at the current
 * point of compilation (set by import via $^H{'Switch::Declare'}). */
static int sd_in_scope(pTHX) {
	HV *hints = GvHV(PL_hintgv);
	SV **ent;
	if (!hints) return 0;
	ent = hv_fetchs(hints, "Switch::Declare", 0);
	return ent && SvTRUE(*ent);
}

static int sd_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr) {
	if (kwlen == 6 && memEQ(kw, "switch", 6) && sd_in_scope(aTHX)) {
		*op_ptr = sd_parse_switch(aTHX);
		return KEYWORD_PLUGIN_EXPR;
	}
	return sd_next_keyword_plugin(aTHX_ kw, kwlen, op_ptr);
}

MODULE = Switch::Declare  PACKAGE = Switch::Declare
PROTOTYPES: DISABLE

BOOT:
	sd_next_keyword_plugin = PL_keyword_plugin;
	PL_keyword_plugin = sd_keyword_plugin;
	XopENTRY_set(&sd_looks_number_xop, xop_name, "sd_looks_number");
	XopENTRY_set(&sd_looks_number_xop, xop_desc, "Switch::Declare numeric topic guard");
	XopENTRY_set(&sd_looks_number_xop, xop_class, OA_UNOP);
	Perl_custom_op_register(aTHX_ sd_pp_looks_number, &sd_looks_number_xop);
	XopENTRY_set(&sd_reftype_xop, xop_name, "sd_reftype");
	XopENTRY_set(&sd_reftype_xop, xop_desc, "Switch::Declare reftype()");
	XopENTRY_set(&sd_reftype_xop, xop_class, OA_UNOP);
	Perl_custom_op_register(aTHX_ sd_pp_reftype, &sd_reftype_xop);
	XopENTRY_set(&sd_rxmatch_xop, xop_name, "sd_rxmatch");
	XopENTRY_set(&sd_rxmatch_xop, xop_desc, "Switch::Declare =~ match");
	XopENTRY_set(&sd_rxmatch_xop, xop_class, OA_BINOP);
	Perl_custom_op_register(aTHX_ sd_pp_rxmatch, &sd_rxmatch_xop);
	XopENTRY_set(&dd_tail_xop, xop_name, "dd_tail");
	XopENTRY_set(&dd_tail_xop, xop_desc, "Switch::Declare bind slurpy tail");
	XopENTRY_set(&dd_tail_xop, xop_class, OA_BINOP);
	Perl_custom_op_register(aTHX_ dd_pp_tail, &dd_tail_xop);
	XopENTRY_set(&dd_hrest_xop, xop_name, "dd_hrest");
	XopENTRY_set(&dd_hrest_xop, xop_desc, "Switch::Declare bind hash %rest");
	XopENTRY_set(&dd_hrest_xop, xop_class, OA_LISTOP);
	Perl_custom_op_register(aTHX_ dd_pp_hrest, &dd_hrest_xop);

bool
_isa(obj, klass)
	SV *obj
	SV *klass
	CODE:
		/* fast @ISA check: a blessed object derived from `klass`. sv_isobject
		 * keeps plain strings/non-objects from matching; never dies. */
		RETVAL = (sv_isobject(obj)
		          && sv_derived_from(obj, SvPV_nolen(klass))) ? 1 : 0;
	OUTPUT:
		RETVAL
