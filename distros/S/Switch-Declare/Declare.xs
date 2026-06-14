#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"  /* backports the OpSIBLING / OpLASTSIB_set op-tree macros to
                        perl 5.14-5.20 (added to core in 5.22) */

#define MAX_ARMS 4096

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
typedef struct {
	int        kind;
	PADOFFSET  off;
	SV        *sv;
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

/* When every arm maps a distinct string-literal key to a constant value (a
 * lookup table) and there are at least this many of them, the whole switch is
 * lowered to a single O(1) hash lookup against a compile-time constant hash
 * instead of an O(n) chain of eq tests. */
#define SD_DISPATCH_MIN 4

/* What a case pattern was, for dispatch eligibility. */
typedef struct {
	int  str_key;   /* 1 if an exact string-literal pattern (eq) */
	SV  *key;       /* the literal (owned) when str_key */
} SDPat;

/* A fresh  $PKGHASH{ topic }  element op, where the hash is the package
 * variable named by `gv`. Referencing the hash through a GV (rather than an
 * op-constant hashref) keeps the dispatch table thread-safe: op constants are
 * cloned per-thread, which would dangle a reference to a shared HV. */
static OP *sd_helem(pTHX_ GV *gv, SDTopic *t) {
	OP *gvop  = newGVOP(OP_GV, 0, gv);
	OP *deref = newUNOP(OP_RV2HV, OPf_REF, gvop);
	return newBINOP(OP_HELEM, 0, deref, sd_topic(aTHX_ t));
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

/* topic CMP const, where CMP is numeric (==/>=/<=) or string (eq/ge/le). */
static OP *sd_cmp(pTHX_ SDTopic *t, int is_num, I32 numop, I32 strop, OP *konst) {
	return newBINOP(is_num ? numop : strop, 0, sd_topic(aTHX_ t), konst);
}

/* Build  CALLEE->( topic )  as an entersub. The OP_ENTERSUB checker inserts the
 * pushmark itself, so we must NOT add one - a second pushmark leaves a dangling
 * mark that corrupts a surrounding list/aassign at runtime. */
static OP *sd_predicate_call(pTHX_ OP *callee, SDTopic *t) {
	OP *args = op_append_elem(OP_LIST, sd_topic(aTHX_ t), callee);
	return newUNOP(OP_ENTERSUB, OPf_STACKED, args);
}

/* Parse one case PATTERN from the lexer and return its boolean condition op,
 * testing the topic. Fills *pat describing the pattern (for dispatch). */
static OP *sd_parse_case_cond(pTHX_ SDTopic *t, SDPat *pat) {
	I32 c = lex_peek_unichar(0);
	pat->str_key = 0;
	pat->key     = NULL;

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

	/* inline predicate:  sub { ... }  ->  (sub { ... })->($topic) */
	if (isALPHA(c) || c == '_') {
		SV *word   = sd_lex_read_ident(aTHX);
		int is_sub = word && strEQ(SvPV_nolen(word), "sub");
		if (word) SvREFCNT_dec(word);
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
		croak("switch: unexpected bareword in case pattern (expected a number, "
		      "string, /regex/, [range or list], \\&name, or sub {...})");
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
	SDTopic topic;
	OP *assign;
	OP *lhs;
	OP *chain;
	OP *seq;
	OP *body;

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
			lex_read_space(0);
			if (lex_peek_unichar(0) != '{')
				croak("switch: expected '{' after case pattern");
			blk = sd_simplify_block(aTHX_ parse_block(0), &simple);
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
		for (i = 0; i < narms; i++) {
			STRLEN klen;
			const char *kpv = SvPV(keys[i], klen);
			if (hv_exists(hv, kpv, klen)) { dup = 1; break; }
			if (!SvOK(vals[i])) any_undef = 1;
			(void)hv_store(hv, kpv, klen, newSVsv(vals[i]), 0);
		}
		if (dup) {
			hv_clear(hv);             /* duplicate keys: fall back to chain */
		} else {
			OP *deflt = default_block ? default_block
			                          : newOP(OP_UNDEF, 0);
			if (any_undef) {
				/* a value can be undef, so a miss is indistinguishable from a
				 * hit by definedness: test membership explicitly. */
				OP *cond = newUNOP(OP_EXISTS, 0, sd_helem(aTHX_ gv, &topic));
				chain = newCONDOP(0, cond, sd_helem(aTHX_ gv, &topic), deflt);
			} else {
				/* all values are defined: one lookup, miss -> default via //. */
				chain = newLOGOP(OP_DOR, 0, sd_helem(aTHX_ gv, &topic), deflt);
			}
			/* the unused per-arm condition and block ops are now dead */
			for (i = 0; i < narms; i++) { op_free(conds[i]); op_free(blocks[i]); }
		}
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

	if (topic.kind != SDT_TEMP) {
		if (topic.kind == SDT_CONST) SvREFCNT_dec(topic.sv);
		if (all_simple)
			/* Fastest path: a plain lexical/constant topic, and either a
			 * dispatch lookup or a chain of bare `{ EXPR }` arms. The whole
			 * switch is literally an expression - no temp, no scope, no
			 * nextstate - as fast as hand-written code. */
			return chain;
		/* Some arm is a multi-statement block (carries a nextstate). Wrap in a
		 * single enter/leave (OPf_PARENS makes op_scope emit OP_LEAVE) so that
		 * nextstate cannot reset the stack base of a surrounding expression. */
		chain->op_flags |= OPf_PARENS;
		return op_scope(chain);
	}

	/* General path: my $topic = SCRUTINEE; <body>, wrapped as a value-returning
	 * block so the scrutinee is evaluated exactly once. OPf_PARENS forces
	 * op_scope down its enter/leave path (OP_LEAVE) for a proper stack frame;
	 * without it a bare OP_SCOPE lets the inner nextstate reset the stack base
	 * and clobber a surrounding expression (e.g. N + switch(...)). */
	lhs = newOP(OP_PADSV, 0);
	lhs->op_targ = topic.off;
	lhs->op_private |= OPpLVAL_INTRO;               /* my */
	assign = newASSIGNOP(OPf_STACKED, lhs, 0, scrutinee);
	seq = op_append_list(OP_LINESEQ, newSTATEOP(0, NULL, assign),
	                                 newSTATEOP(0, NULL, chain));
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
