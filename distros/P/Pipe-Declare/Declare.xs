#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"  /* OpSIBLING / OpLASTSIB_set / pad_add_name_pvn backports */

/* pad_add_name_pvn and pad_findmy_pvn were both 5.15.1 renames of pad_add_name
 * / pad_findmy; the 5.14 functions have identical signatures.  ppport.h knows
 * these symbols but cannot emulate them, so map them to the old names. */
#if PERL_VERSION < 16
#  define pad_add_name_pvn(name, len, flags, typestash, ourstash) \
       Perl_pad_add_name(aTHX_ (name), (len), (flags), (typestash), (ourstash))
#  define pad_findmy_pvn(name, len, flags) \
       Perl_pad_findmy(aTHX_ (name), (len), (flags))
#endif

/* op_convert_list() is the 5.21.6 public rename of the older core function
 * convert() (identical signature). ppport.h knows the symbol but cannot
 * emulate it, so on pre-5.21.6 perls map it to Perl_convert() directly --
 * the long Perl_-prefixed name (with aTHX_) is used because the short
 * convert() macro is not exposed to non-core XS, whereas Perl_convert is
 * declared in proto.h and exported from libperl. */
#ifndef op_convert_list
#  define op_convert_list(type, flags, o) Perl_convert(aTHX_ (type), (flags), (o))
#endif

/* op_sibling_splice() became a public API function in 5.21.2, alongside the
 * new internal op-sibling model.  Below that it doesn't exist, but ppport.h
 * back-supplies the OpSIBLING / OpHAS_SIBLING / Op*SIB_set accessors over the
 * old (plain op_sibling pointer) model, so we can rebuild the function on top
 * of them.  This body is a faithful port of perl's own Perl_op_sibling_splice
 * in op.c -- in particular op_last is only rewritten when the parent op class
 * actually carries an op_last field (BINOP/LISTOP/PMOP/LOOP). */
#ifndef op_sibling_splice
static OP *
pd_op_sibling_splice(pTHX_ OP *parent, OP *start, int del_count, OP *insert)
{
	OP *first;
	OP *rest;
	OP *last_del = NULL;
	OP *last_ins = NULL;
	OP *lastop;
	U32 pclass;

	if (start)
		first = OpSIBLING(start);
	else if (!parent)
		croak("panic: op_sibling_splice(): NULL parent");
	else
		first = cLISTOPx(parent)->op_first;

	if (del_count && first) {
		last_del = first;
		while (--del_count && OpHAS_SIBLING(last_del))
			last_del = OpSIBLING(last_del);
		rest = OpSIBLING(last_del);
		OpLASTSIB_set(last_del, NULL);
	}
	else
		rest = first;

	if (insert) {
		last_ins = insert;
		while (OpHAS_SIBLING(last_ins))
			last_ins = OpSIBLING(last_ins);
		OpMAYBESIB_set(last_ins, rest, NULL);
	}
	else
		insert = rest;

	if (start) {
		OpMAYBESIB_set(start, insert, NULL);
	}
	else {
		cLISTOPx(parent)->op_first = insert;
		if (insert)
			parent->op_flags |= OPf_KIDS;
		else
			parent->op_flags &= ~OPf_KIDS;
	}

	if (!rest) {
		/* the splice removed the tail: fix up the parent's op_last, but
		 * only for op classes that actually have one. */
		lastop = last_ins ? last_ins : start;
		pclass = parent->op_type == OP_NULL ? (U32)parent->op_targ
		                                    : parent->op_type;
		pclass = PL_opargs[pclass] & OA_CLASS_MASK;
		if (   pclass == OA_BINOP || pclass == OA_LISTOP
		    || pclass == OA_PMOP  || pclass == OA_LOOP)
			cLISTOPx(parent)->op_last = lastop;
		if (lastop)
			OpLASTSIB_set(lastop, parent);
	}

	return last_del ? first : NULL;
}
#  define op_sibling_splice(parent, start, del, ins) \
       pd_op_sibling_splice(aTHX_ (parent), (start), (del), (ins))
#endif

/* ------------------------------------------------------------------------
 * Pipe::Declare
 *
 * A `pipe { HEAD |> step |> step ... }` block keyword. The plugin
 * recognises `pipe` only inside a lexical scope where
 * $^H{'Pipe::Declare'} is truthy; outside such a scope it falls through
 * to perl's normal parsing, so `pipe` is a free identifier everywhere
 * else.
 *
 * Lowering (planned, milestone 2+): the head is evaluated once into a
 * hidden pad temp, then each step is emitted as a call op (entersub /
 * method / aelem / helem / mapwhile / grepwhile) threading the topic.
 * Nothing of the parser survives to runtime - the construct is just an
 * optree of ordinary call ops.
 *
 * Sibling reference: Switch-Declare/Declare.xs (the keyword-plugin
 * scaffolding, sd_in_scope hint-gating, pad-temp scrutinee pattern,
 * `KEYWORD_PLUGIN_EXPR` return for statement-and-expression form).
 * ------------------------------------------------------------------------ */

/* Previous keyword plugin in the chain. */
static int (*pd_next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

/* True if the Pipe::Declare lexical pragma is in scope here. */
static int pd_in_scope(pTHX) {
	HV *hints = GvHV(PL_hintgv);
	SV **ent;
	if (!hints) return 0;
	ent = hv_fetchs(hints, "Pipe::Declare", 0);
	return ent && SvTRUE(*ent);
}

/* Hand-lex a bareword identifier (possibly package-qualified `Foo::bar`). */
static SV *pd_lex_subname(pTHX) {
	SV *buf = newSVpvs("");
	I32 c;
	while (1) {
		c = lex_peek_unichar(0);
		if (c == -1) break;
		if (isALNUM(c) || c == '_') {
			sv_catpvf(buf, "%c", (int)c);
			lex_read_unichar(0);
		} else if (c == ':'
		           && PL_parser->bufptr[0] == ':'
		           && PL_parser->bufptr[1] == ':') {
			sv_catpvs(buf, "::");
			lex_read_unichar(0);
			lex_read_unichar(0);
		} else break;
	}
	if (SvCUR(buf) == 0) { SvREFCNT_dec(buf); return NULL; }
	return buf;
}

/* Hand-lex a numeric literal (optional sign, integer/float/exponent). Lifted
 * from Switch-Declare/Declare.xs sd_lex_number. */
static SV *pd_lex_number(pTHX) {
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
			char next = (PL_parser->bufptr[0] == '.')
			            ? PL_parser->bufptr[1] : '\0';
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
		croak("pipe: malformed numeric literal");
	}
	return buf;
}

/* Hand-lex a quoted string literal ('...' or "..."), basic backslash escapes. */
static SV *pd_lex_string(pTHX) {
	I32 quote = lex_read_unichar(0);
	SV *sv = newSVpvs("");
	I32 c;
	while (1) {
		c = lex_read_unichar(0);
		if (c == -1) croak("pipe: unterminated string literal");
		if (c == '\\') {
			I32 next = lex_read_unichar(0);
			if (next == -1) croak("pipe: unterminated string literal");
			if (quote == '"') {
				switch (next) {
					case 'n': sv_catpvs(sv, "\n"); break;
					case 't': sv_catpvs(sv, "\t"); break;
					case 'r': sv_catpvs(sv, "\r"); break;
					case '0': sv_catpvs(sv, "\0"); break;
					default:  sv_catpvf(sv, "%c", (int)next); break;
				}
			} else {
				if (next != '\\' && next != '\'')
					sv_catpvf(sv, "%c", '\\');
				sv_catpvf(sv, "%c", (int)next);
			}
		} else if (c == quote) break;
		else sv_catpvf(sv, "%c", (int)c);
	}
	return sv;
}

/* Hand-lex a `$name` / `$Pkg::name` scalar variable - the leading '$' is still
 * unread. Returns a fresh op reading the variable (PADSV for an in-scope
 * lexical, RV2SV(GV) for a package global). Restricted to a bare `$name`
 * (no `[..]`/`{..}` subscripting) so we don't have to re-implement Perl's
 * subscript parser; complex heads can be written `( $h->{k} )`. */
static OP *pd_lex_scalar_var_op(pTHX) {
	SV *name, *withsig;
	PADOFFSET off;
	if (lex_peek_unichar(0) != '$')
		croak("pipe: expected '$' in scalar variable");
	lex_read_unichar(0);
	name = pd_lex_subname(aTHX);
	if (!name) croak("pipe: expected an identifier after '$'");
	withsig = newSVpvs("$");
	sv_catsv(withsig, name);
	off = pad_findmy_pvn(SvPVX(withsig), SvCUR(withsig), 0);
	SvREFCNT_dec(withsig);
	if (off != NOT_IN_PAD) {
#if PERL_VERSION >= 22
		PADNAME *pn = PadnamelistARRAY(PL_comppad_name)[off];
		const int is_our = pn && PadnameIsOUR(pn);
		HV *stash = is_our ? PadnameOURSTASH(pn) : NULL;
#else
		/* Before 5.22 (the PADNAME type is 5.21.7) a pad name is an SV
		 * in the PL_comppad_name AV, flagged with SvPAD_OUR. */
		SV *pn = AvARRAY(PL_comppad_name)[off];
		const int is_our = pn && SvPAD_OUR(pn);
		HV *stash = is_our ? SvOURSTASH(pn) : NULL;
#endif
		if (is_our) {
			/* our $x : resolve to the package scalar (see Switch::Declare's
			 * sd_lex_scalar_var for the rationale). */
			SV *q = newSVpvs("");
			GV *gv;
			if (stash && HvNAME(stash))
				sv_catpvf(q, "%s::", HvNAME(stash));
			sv_catsv(q, name);
			gv = gv_fetchpv(SvPV_nolen(q), GV_ADD, SVt_PV);
			SvREFCNT_dec(q);
			SvREFCNT_dec(name);
			return newUNOP(OP_RV2SV, 0, newGVOP(OP_GV, 0, gv));
		}
		SvREFCNT_dec(name);
		{
			OP *o = newOP(OP_PADSV, 0);
			o->op_targ = off;
			return o;
		}
	} else {
		GV *gv = gv_fetchpv(SvPV_nolen(name), GV_ADD, SVt_PV);
		SvREFCNT_dec(name);
		return newUNOP(OP_RV2SV, 0, newGVOP(OP_GV, 0, gv));
	}
}

/* ---- low-level op builders ------------------------------------------------ */

/* Build a fresh PADSV read op for the topic temp at `off`. */
static OP *pd_topic_read(pTHX_ PADOFFSET off) {
	OP *o = newOP(OP_PADSV, 0);
	o->op_targ = off;
	return o;
}

/* Allocate a fresh, uniquely-named pad temp. A unique name per use prevents
 * "masks earlier declaration" warnings when several pipes (or several tap
 * steps) share a lexical scope. `what` names the role: "topic" for the
 * pipe's threaded value, "tap" for a tap step's private copy. */
static PADOFFSET pd_alloc_temp(pTHX_ const char *what) {
	static unsigned long pd_seq = 0;
	char buf[64];
	int n = my_snprintf(buf, sizeof(buf),
	                    "$_Pipe_Declare_%s_%lu", what, pd_seq++);
	return pad_add_name_pvn(buf, (STRLEN)n, 0, NULL, NULL);
}

/* OP_METHOD_NAMED construction is a METHOP (its own op class) from 5.22 on;
 * before that it was a plain SVOP. The constructor newMETHOP_named exists only
 * on the new shape, so use it conditionally. The SV passed in is owned by the
 * resulting op. */
#if PERL_VERSION >= 22
#  define pd_new_method_named(meth) newMETHOP_named(OP_METHOD_NAMED, 0, (meth))
#else
#  define pd_new_method_named(meth) newSVOP(OP_METHOD_NAMED, 0, (meth))
#endif

/* ---- argument-list parsing ------------------------------------------------ */

/* Parse one argument from an arglist. If `saw_placeholder` is non-NULL, a
 * standalone `_` token (not followed by an identifier character) is treated as
 * the topic placeholder and substituted with a read of the pad temp at
 * `topic_off`. Anything else is handed to parse_termexpr, which stops cleanly
 * at the next ',' or ')'. */
static OP *pd_parse_arg(pTHX_ PADOFFSET topic_off, int *saw_placeholder) {
	I32 c;
	lex_read_space(0);
	c = lex_peek_unichar(0);

	if (c == '_' && saw_placeholder) {
		char next = PL_parser->bufptr[1];
		if (!isALNUM(next) && next != '_') {
			lex_read_unichar(0);
			*saw_placeholder = 1;
			return pd_topic_read(aTHX_ topic_off);
		}
	}

	return parse_termexpr(0);
}

/* Parse a (possibly empty) arglist starting just after '(' and ending at ')'.
 * Returns NULL for an empty list, otherwise an OP_LIST. Trailing ',' is
 * allowed. */
static OP *pd_parse_args(pTHX_ PADOFFSET topic_off, int *saw_placeholder) {
	OP *args = NULL;
	I32 c;

	lex_read_space(0);
	if (lex_peek_unichar(0) == ')') {
		lex_read_unichar(0);
		return NULL;
	}

	while (1) {
		OP *arg = pd_parse_arg(aTHX_ topic_off, saw_placeholder);
		args = args ? op_append_elem(OP_LIST, args, arg) : arg;

		lex_read_space(0);
		c = lex_peek_unichar(0);
		if (c == ')') { lex_read_unichar(0); break; }
		if (c == ',') {
			lex_read_unichar(0);
			lex_read_space(0);
			if (lex_peek_unichar(0) == ')') {
				lex_read_unichar(0);
				break;
			}
			continue;
		}
		croak("pipe: expected ',' or ')' in argument list");
	}
	return args;
}

/* ---- step builders -------------------------------------------------------- */

/* Bareword step:  name  or  name(args)  or  Foo::Bar::name(args).
 * Without args the call is `name($topic)`. With args the topic is prepended
 * unless a `_` placeholder appeared in the arglist, in which case the
 * placeholder substitution already wove the topic in. The OP_ENTERSUB
 * checker inserts the pushmark itself, so we must NOT add one. */
static OP *pd_step_bareword(pTHX_ SV *name, PADOFFSET topic_off) {
	GV *gv   = gv_fetchpv(SvPV_nolen(name), GV_ADD, SVt_PVCV);
	OP *cvop = newUNOP(OP_RV2CV, 0, newGVOP(OP_GV, 0, gv));
	OP *args = NULL;
	int saw_placeholder = 0;
	OP *list;

	lex_read_space(0);
	if (lex_peek_unichar(0) == '(') {
		lex_read_unichar(0);
		args = pd_parse_args(aTHX_ topic_off, &saw_placeholder);
	}

	if (saw_placeholder) {
		list = args;                            /* topic already in args */
	} else if (args) {
		list = op_prepend_elem(OP_LIST, pd_topic_read(aTHX_ topic_off), args);
	} else {
		list = pd_topic_read(aTHX_ topic_off);  /* nullary: just topic */
	}

	list = op_append_elem(OP_LIST, list, cvop);
	return newUNOP(OP_ENTERSUB, OPf_STACKED, list);
}

/* `$topic->{KEY}` - cursor is just after '{'. */
static OP *pd_step_helem(pTHX_ PADOFFSET topic_off) {
	SV *key;
	I32 c;

	lex_read_space(0);
	c = lex_peek_unichar(0);
	if (c == '"' || c == '\'') {
		key = pd_lex_string(aTHX);
	} else {
		key = pd_lex_subname(aTHX);
		if (!key) croak("pipe: expected a key in ->{...}");
	}

	lex_read_space(0);
	if (lex_peek_unichar(0) != '}') {
		SvREFCNT_dec(key);
		croak("pipe: expected '}' to close ->{...}");
	}
	lex_read_unichar(0);

	{
		OP *deref = newUNOP(OP_RV2HV, OPf_REF, pd_topic_read(aTHX_ topic_off));
		OP *konst = newSVOP(OP_CONST, 0, key);
		return newBINOP(OP_HELEM, 0, deref, konst);
	}
}

/* `$topic->[IDX]` - cursor is just after '['. */
static OP *pd_step_aelem(pTHX_ PADOFFSET topic_off) {
	OP *idx;

	lex_read_space(0);
	idx = parse_termexpr(0);
	lex_read_space(0);
	if (lex_peek_unichar(0) != ']') croak("pipe: expected ']' to close ->[...]");
	lex_read_unichar(0);

	{
		OP *deref = newUNOP(OP_RV2AV, OPf_REF, pd_topic_read(aTHX_ topic_off));
		return newBINOP(OP_AELEM, 0, deref, idx);
	}
}

/* `$topic->METHOD` or `$topic->METHOD(ARGS)`. The method op takes ownership of
 * the name SV. The `_` placeholder is not honoured in method args - the topic
 * is already the invocant. */
static OP *pd_step_method(pTHX_ SV *method_name, PADOFFSET topic_off) {
	OP *method = pd_new_method_named(method_name);
	OP *args = pd_topic_read(aTHX_ topic_off);

	lex_read_space(0);
	if (lex_peek_unichar(0) == '(') {
		OP *call_args;
		lex_read_unichar(0);
		call_args = pd_parse_args(aTHX_ NOT_IN_PAD, NULL);
		if (call_args)
			args = op_append_list(OP_LIST, args, call_args);
	}

	args = op_append_elem(OP_LIST, args, method);
	return newUNOP(OP_ENTERSUB, OPf_STACKED, args);
}

/* Dispatch after '->': {KEY}, [IDX], or METHOD[(ARGS)]. */
static OP *pd_step_arrow(pTHX_ PADOFFSET topic_off) {
	I32 c;
	lex_read_space(0);
	c = lex_peek_unichar(0);

	if (c == '{') { lex_read_unichar(0); return pd_step_helem(aTHX_ topic_off); }
	if (c == '[') { lex_read_unichar(0); return pd_step_aelem(aTHX_ topic_off); }
	if (isALPHA(c) || c == '_') {
		SV *method = pd_lex_subname(aTHX);
		if (!method) croak("pipe: expected method name after '->'");
		return pd_step_method(aTHX_ method, topic_off);
	}
	croak("pipe: expected method name, '{KEY}', or '[IDX]' after '->'");
	return NULL;
}

/* `\&NAME($topic)` - cursor is just past '\'. Functionally equivalent to a
 * plain bareword step; accepted for symmetry with how Perl spells "reference
 * to a named sub". */
static OP *pd_step_codref_amp(pTHX_ PADOFFSET topic_off) {
	SV *name;
	GV *gv;
	OP *cvop, *args;

	if (lex_peek_unichar(0) != '&') croak("pipe: expected '&' after '\\'");
	lex_read_unichar(0);
	name = pd_lex_subname(aTHX);
	if (!name) croak("pipe: expected sub name after '\\&'");
	gv = gv_fetchpv(SvPV_nolen(name), GV_ADD, SVt_PVCV);
	SvREFCNT_dec(name);
	cvop = newUNOP(OP_RV2CV, 0, newGVOP(OP_GV, 0, gv));
	args = op_append_elem(OP_LIST, pd_topic_read(aTHX_ topic_off), cvop);
	return newUNOP(OP_ENTERSUB, OPf_STACKED, args);
}

/* `(sub { ... })->($topic)` - cursor is just past 'sub'. parse_block parses
 * the body; newANONATTRSUB wraps it as a real anonymous CV. */
static OP *pd_step_anon_sub(pTHX_ PADOFFSET topic_off) {
	I32 floor;
	OP *body, *anon, *args;

	lex_read_space(0);
	if (lex_peek_unichar(0) != '{')
		croak("pipe: expected '{' after 'sub'");
	floor = start_subparse(FALSE, CVf_ANON);
	body = parse_block(0);
	anon = newANONATTRSUB(floor, NULL, NULL, body);

	args = op_append_elem(OP_LIST, pd_topic_read(aTHX_ topic_off), anon);
	return newUNOP(OP_ENTERSUB, OPf_STACKED, args);
}

/* `$cv->($topic)` - a scalar variable holding a coderef. */
static OP *pd_step_scalar_coderef(pTHX_ PADOFFSET topic_off) {
	OP *cvop = pd_lex_scalar_var_op(aTHX);
	OP *args = op_append_elem(OP_LIST, pd_topic_read(aTHX_ topic_off), cvop);
	return newUNOP(OP_ENTERSUB, OPf_STACKED, args);
}

/* Block step:  |> tap { B }
 *
 * Direct optree for
 *
 *     do { my $t = $topic; for ($t) { B } $t }
 *
 * B runs with $_ aliased to a private copy of the topic and the copy is
 * the step's value, so an assignment to $_ inside B changes what flows
 * on, exactly as the earlier helper sub (which took the topic by value
 * in @_) behaved. No closure is built and no sub is called: the step is
 * one ENTER/LEAVE pair around perl's own foreach. The do-block scope
 * (op_scope via OPf_PARENS) is what clears the copy on the way out. */
static OP *pd_step_block_tap_direct(pTHX_ PADOFFSET topic_off) {
	OP *body, *lhs, *intro, *loop, *seq;
	PADOFFSET tmp_off;

	lex_read_space(0);
	if (lex_peek_unichar(0) != '{')
		croak("pipe: expected '{' after 'tap'");
	body = parse_block(0);

	/* Allocated after the body is parsed, so B cannot see the slot. */
	tmp_off = pd_alloc_temp(aTHX_ "tap");

	/* my $t = $topic */
	lhs = newOP(OP_PADSV, 0);
	lhs->op_targ = tmp_off;
	lhs->op_private |= OPpLVAL_INTRO;
	intro = newSTATEOP(0, NULL,
	                   newASSIGNOP(OPf_STACKED, lhs, 0,
	                               pd_topic_read(aTHX_ topic_off)));

	/* for ($t) { B } - sv NULL means the global $_ is the iterator */
	loop = newSTATEOP(0, NULL,
	                  newFOROP(0, NULL, pd_topic_read(aTHX_ tmp_off),
	                           body, NULL));

	/* $t - the block's value */
	seq = op_append_list(OP_LINESEQ, intro, loop);
	seq = op_append_list(OP_LINESEQ, seq,
	                     newSTATEOP(0, NULL, pd_topic_read(aTHX_ tmp_off)));
	seq->op_flags |= OPf_PARENS;
	return op_scope(seq);
}

/* Direct optree for `map { B } @$topic` returning a fresh arrayref.
 *
 * Mirrors what perl's own parser produces for `[ map { B } @$topic ]`:
 *
 *     anonlist
 *       pushmark
 *       mapwhile -> mapstart
 *                     pushmark
 *                     null(scope(body))
 *                     rv2av(topic)
 *
 * `op_convert_list(OP_MAPSTART, OPf_STACKED, listop)` does the LISTOP ->
 * MAPSTART conversion and wraps it in a MAPWHILE LOGOP for us. */
static OP *pd_step_block_map_direct(pTHX_ PADOFFSET topic_off) {
	OP *body, *src, *list, *mapop;

	lex_read_space(0);
	if (lex_peek_unichar(0) != '{')
		croak("pipe: expected '{' after 'map'");
	body = parse_block(0);

	/* Source: @$topic - plain rv2av of the padsv, no flags (mapstart
	 * wants the array's elements on the stack). */
	src = newUNOP(OP_RV2AV, 0, pd_topic_read(aTHX_ topic_off));

	/* Argument list for MAPSTART: [null(scope(body)), src] */
	list = op_prepend_elem(OP_LIST,
	                       newUNOP(OP_NULL, 0, op_scope(body)),
	                       src);

	mapop = op_convert_list(OP_MAPSTART, OPf_STACKED, list);

	/* Wrap the map's list result in an arrayref so the next step sees
	 * the same shape as the helper-sub form did. */
	return newANONLIST(mapop);
}

/* Direct optree for `grep { B } @$topic` returning a fresh arrayref.
 * Same structure as the map builder, with OP_GREPSTART instead. */
static OP *pd_step_block_grep_direct(pTHX_ PADOFFSET topic_off) {
	OP *body, *src, *list, *grepop;

	lex_read_space(0);
	if (lex_peek_unichar(0) != '{')
		croak("pipe: expected '{' after 'grep'");
	body = parse_block(0);

	src = newUNOP(OP_RV2AV, 0, pd_topic_read(aTHX_ topic_off));

	list = op_prepend_elem(OP_LIST,
	                       newUNOP(OP_NULL, 0, op_scope(body)),
	                       src);

	grepop = op_convert_list(OP_GREPSTART, OPf_STACKED, list);

	return newANONLIST(grepop);
}

/* Parse one step after '|>' and return the call op (the new topic value).
 * Dispatch on the first character; each branch delegates to a builder.
 * `*listy` is set when the step is a map/grep block, whose optree reads
 * the topic as an array and yields an anonlist: two such steps in a row
 * can be fused (see pd_fuse_list_step). */
static OP *pd_parse_step(pTHX_ PADOFFSET topic_off, int *listy) {
	I32 c;
	*listy = 0;
	lex_read_space(0);
	c = lex_peek_unichar(0);

	/* method or deref step:  -> ... */
	if (c == '-') {
		if (PL_parser->bufptr[1] != '>')
			croak("pipe: expected '->' or a step name after '|>'");
		lex_read_unichar(0);                 /* - */
		lex_read_unichar(0);                 /* > */
		return pd_step_arrow(aTHX_ topic_off);
	}

	/* coderef ref:  \&name */
	if (c == '\\') {
		lex_read_unichar(0);
		return pd_step_codref_amp(aTHX_ topic_off);
	}

	/* scalar coderef:  $cv */
	if (c == '$') {
		return pd_step_scalar_coderef(aTHX_ topic_off);
	}

	/* bareword: name, name(args), Foo::Bar::name(args), sub { ... },
	 *           map { ... } / grep { ... } / tap { ... } */
	if (isALPHA(c) || c == '_') {
		SV *name = pd_lex_subname(aTHX);
		STRLEN nlen;
		const char *npv;
		if (!name) croak("pipe: expected a step name after '|>'");
		npv  = SvPV(name, nlen);

		if (nlen == 3 && memEQ(npv, "sub", 3)) {
			SvREFCNT_dec(name);
			return pd_step_anon_sub(aTHX_ topic_off);
		}
		if (nlen == 3 && memEQ(npv, "map", 3)) {
			SvREFCNT_dec(name);
			*listy = 1;
			return pd_step_block_map_direct(aTHX_ topic_off);
		}
		if (nlen == 4 && memEQ(npv, "grep", 4)) {
			SvREFCNT_dec(name);
			*listy = 1;
			return pd_step_block_grep_direct(aTHX_ topic_off);
		}
		if (nlen == 3 && memEQ(npv, "tap", 3)) {
			SvREFCNT_dec(name);
			return pd_step_block_tap_direct(aTHX_ topic_off);
		}

		{
			OP *call = pd_step_bareword(aTHX_ name, topic_off);
			SvREFCNT_dec(name);
			return call;
		}
	}

	croak("pipe: expected a step after '|>' (bareword, ->method, \\&name, "
	      "sub {...}, or $cv)");
	return NULL;
}

/* ---- head parsing --------------------------------------------------------- */

/* Parse one "head term" from the lexer and return its value op. The set of
 * supported forms is intentionally closed in v0.01 (mirror of how
 * Switch::Declare hand-classifies its case patterns):
 *
 *   $var / $pkg::var       scalar variable
 *   NUMBER                 numeric literal
 *   "STR" / 'STR'          string literal
 *   name, name(args),
 *   Foo::Bar::name(args)   bareword call (qualified or not)
 *   ( EXPR )               any general expression - parens delimit the parse
 *                          so parse_fullexpr stops cleanly at ')'
 *
 * `_` is NOT a topic placeholder here (the head IS the source of the topic),
 * so a bareword `_` resolves the usual way (a call to sub `_`). */
static OP *pd_parse_head(pTHX) {
	I32 c;
	lex_read_space(0);
	c = lex_peek_unichar(0);

	if (c == '$') return pd_lex_scalar_var_op(aTHX);

	if (c == '(') {
		OP *e;
		lex_read_unichar(0);
		e = parse_fullexpr(0);
		lex_read_space(0);
		if (lex_peek_unichar(0) != ')')
			croak("pipe: expected ')' to close parenthesised head");
		lex_read_unichar(0);
		return e;
	}

	/* anonymous arrayref literal: [ ... ] - hand-parse the brackets and
	 * delegate the comma-separated contents to parse_fullexpr (which is
	 * delimited cleanly by the closing ']'). newANONLIST wraps the result
	 * exactly as the Perl parser does for a bare `[...]`. */
	if (c == '[') {
		OP *list;
		lex_read_unichar(0);                       /* consume '[' */
		lex_read_space(0);
		if (lex_peek_unichar(0) == ']') {
			list = newOP(OP_STUB, 0);
		} else {
			list = parse_fullexpr(0);
		}
		lex_read_space(0);
		if (lex_peek_unichar(0) != ']')
			croak("pipe: expected ']' to close arrayref-literal head");
		lex_read_unichar(0);
		return newANONLIST(list);
	}

	if (c == '"' || c == '\'')
		return newSVOP(OP_CONST, 0, pd_lex_string(aTHX));

	if ((c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.')
		return newSVOP(OP_CONST, 0, pd_lex_number(aTHX));

	/* Bareword head: name, name(args), Foo::Bar::name(args). */
	if (isALPHA(c) || c == '_') {
		SV *name = pd_lex_subname(aTHX);
		GV *gv;
		OP *cvop, *args = NULL;
		if (!name) croak("pipe: expected a head identifier");
		gv = gv_fetchpv(SvPV_nolen(name), GV_ADD, SVt_PVCV);
		SvREFCNT_dec(name);
		cvop = newUNOP(OP_RV2CV, 0, newGVOP(OP_GV, 0, gv));

		lex_read_space(0);
		if (lex_peek_unichar(0) == '(') {
			lex_read_unichar(0);
			args = pd_parse_args(aTHX_ NOT_IN_PAD, NULL);
		}

		if (args) args = op_append_elem(OP_LIST, args, cvop);
		else      args = cvop;
		return newUNOP(OP_ENTERSUB, OPf_STACKED, args);
	}

	croak("pipe: expected a head term ($var, a literal, a name, or (EXPR))");
	return NULL; /* not reached */
}

/* ---- the nested lowering ---------------------------------------------------
 *
 * Every step is built with padsv reads of the topic slot where the topic
 * goes: once for `|> name`, `|> name(args)`, `|> $obj->m`, `|> $cv` and
 * the block steps, once per `_` for a placeholder arglist. The pipe then
 * becomes a single nested expression:
 *
 *     stepN( ... step2( step1( HEAD ) ) ... )
 *
 * For a step with one read we splice the previous level's expression in
 * place of that padsv. For a step with several reads (`name(_, _)`) the
 * first read becomes `($topic = EXPR)` and the others stay plain reads:
 * perl evaluates an arglist left to right, so the assignment has run by
 * the time the later reads execute, and the sassign keeps the
 * intermediate in scalar context like every other level. The slot is
 * `my`-introduced at its first spill so the value is cleared with the
 * enclosing scope. No step is built with zero reads. */

/* Recursively count padsv ops in `o` whose op_targ equals `topic_off`. */
static int pd_count_topic_refs(pTHX_ OP *o, PADOFFSET topic_off) {
	int n = 0;
	if (!o) return 0;
	if (o->op_type == OP_PADSV && o->op_targ == topic_off) return 1;
	if (o->op_flags & OPf_KIDS) {
		OP *kid;
		for (kid = cUNOPx(o)->op_first; kid; kid = OpSIBLING(kid))
			n += pd_count_topic_refs(aTHX_ kid, topic_off);
	}
	return n;
}

/* Walk `o`, find the (unique - caller must have verified) padsv whose
 * op_targ is `topic_off`, splice it out and splice `replacement` in.
 * Returns 1 on success, 0 if not found. Frees the discarded padsv. */
static int pd_replace_topic_ref(pTHX_ OP *o, PADOFFSET topic_off,
                                OP *replacement)
{
	OP *kid, *prev = NULL;
	if (!o || !(o->op_flags & OPf_KIDS)) return 0;
	for (kid = cUNOPx(o)->op_first; kid; kid = OpSIBLING(kid)) {
		if (kid->op_type == OP_PADSV && kid->op_targ == topic_off) {
			op_sibling_splice(o, prev, 1, replacement);
			op_free(kid);
			return 1;
		}
		if (pd_replace_topic_ref(aTHX_ kid, topic_off, replacement))
			return 1;
		prev = kid;
	}
	return 0;
}

/* Like pd_replace_topic_ref, but the thing replaced is the whole
 * `rv2av(padsv topic)` a map/grep builder emitted as its source, so the
 * replacement is read as a list of elements rather than as an arrayref. */
static int pd_replace_topic_av(pTHX_ OP *o, PADOFFSET topic_off,
                               OP *replacement)
{
	OP *kid, *prev = NULL;
	if (!o || !(o->op_flags & OPf_KIDS)) return 0;
	for (kid = cUNOPx(o)->op_first; kid; kid = OpSIBLING(kid)) {
		if (kid->op_type == OP_RV2AV && (kid->op_flags & OPf_KIDS)) {
			OP *inner = cUNOPx(kid)->op_first;
			if (inner->op_type == OP_PADSV && inner->op_targ == topic_off) {
				op_sibling_splice(o, prev, 1, replacement);
				op_free(kid);
				return 1;
			}
		}
		if (pd_replace_topic_av(aTHX_ kid, topic_off, replacement))
			return 1;
		prev = kid;
	}
	return 0;
}

/* Fuse two consecutive map/grep steps. `prev` is the anonlist the earlier
 * builder returned - `anonlist(pushmark, mapwhile|grepwhile)` - and `step`
 * is the later one, whose source is `rv2av(padsv topic)`. Lifting the
 * inner mapwhile/grepwhile straight into the source position gives
 *
 *     [ grep { B2 } map { B1 } @$topic ]
 *
 * which is what perl compiles for the hand-written chain: no
 * intermediate arrayref is built and re-read between the two steps. Only
 * the last step of a run keeps its anonlist wrap, so the next non-list
 * step still sees an arrayref. Returns 0 without touching anything when
 * `prev` is not the expected shape, and the caller falls back to the
 * plain splice. */
static int pd_fuse_list_step(pTHX_ OP *step, PADOFFSET topic_off, OP *prev) {
	OP *pushmark, *inner;
	if (prev->op_type != OP_ANONLIST || !(prev->op_flags & OPf_KIDS))
		return 0;
	pushmark = cLISTOPx(prev)->op_first;
	if (pushmark->op_type != OP_PUSHMARK) return 0;
	inner = OpSIBLING(pushmark);
	if (!inner || OpHAS_SIBLING(inner)) return 0;
	if (inner->op_type != OP_MAPWHILE && inner->op_type != OP_GREPWHILE)
		return 0;
	op_sibling_splice(prev, pushmark, 1, NULL);
	op_free(prev);
	if (!pd_replace_topic_av(aTHX_ step, topic_off, inner))
		croak("pipe: internal error - lost the list-step source");
	return 1;
}

/* ---- the keyword entry point ---------------------------------------------- */

#define PD_MAX_STEPS 4096

/* Parse a whole `pipe { HEAD |> step |> step ... }` construct (the lexer is
 * positioned just after the `pipe` keyword) and return its value-producing
 * optree: HEAD spliced into step_1, step_1 into step_2, and so on (see
 * the nested lowering notes above pd_count_topic_refs). The semantics
 * this must keep: HEAD runs once, each intermediate step runs in scalar
 * context, the final step runs in the caller's context. */
static OP *pd_parse_pipe(pTHX) {
	OP *head, *expr;
	OP *steps[PD_MAX_STEPS];
	int listy[PD_MAX_STEPS];
	PADOFFSET topic_off;
	int n_steps = 0;
	int i;
	I32 c;
	int spilled = 0;

	/* pipe { */
	lex_read_space(0);
	if (lex_peek_unichar(0) != '{')
		croak("pipe: expected '{' after 'pipe'");
	lex_read_unichar(0);
	lex_read_space(0);

	/* HEAD - hand-classified by the first token. */
	head = pd_parse_head(aTHX);

	/* Allocate the topic slot. Every step is built reading it, and it
	 * stays in the final optree only where a step reads the topic more
	 * than once. An unused slot is harmless (dropping it would require
	 * unwinding pad_add_name_pvn, which the perl API doesn't expose). */
	topic_off = pd_alloc_temp(aTHX_ "topic");

	/* Collect steps: ( '|>' step )* */
	while (1) {
		lex_read_space(0);
		c = lex_peek_unichar(0);
		if (c == '}') { lex_read_unichar(0); break; }
		if (c == ';') {
			/* Allow a single trailing ';' before '}', nothing more - this
			 * is one pipeline expression, not a statement sequence. */
			lex_read_unichar(0);
			lex_read_space(0);
			if (lex_peek_unichar(0) != '}')
				croak("pipe: a pipe { } block must contain exactly one "
				      "pipeline expression");
			lex_read_unichar(0);
			break;
		}
		if (c == -1)
			croak("pipe: unexpected end of input in pipe body");

		/* require '|>' */
		if (c != '|')
			croak("pipe: expected '|>' between pipe steps");
		lex_read_unichar(0);                       /* consume '|' */
		if (lex_peek_unichar(0) != '>')
			croak("pipe: expected '|>' (got '|' without immediate '>')");
		lex_read_unichar(0);                       /* consume '>' */

		if (n_steps >= PD_MAX_STEPS)
			croak("pipe: too many steps (limit %d)", PD_MAX_STEPS);

		steps[n_steps] = pd_parse_step(aTHX_ topic_off, &listy[n_steps]);
		n_steps++;
	}

	if (n_steps == 0) {
		op_free(head);
		croak("pipe: a pipe { } block must contain at least one '|>' step");
	}

	/* Splice HEAD into step_1, then step_1 into step_2, and so on.
	 *
	 * Each intermediate is wrapped in scalar() before it is placed, so a
	 * step sees wantarray() false as the documented semantics say. The
	 * final step gets no wrap: its context flows from the surrounding
	 * expression.
	 *
	 * A map/grep step fed by another map/grep step takes the earlier
	 * step's list directly (pd_fuse_list_step) instead of the arrayref
	 * the earlier step would otherwise build.
	 *
	 * A step reading the topic more than once gets `($topic = expr)` in
	 * its first read and plain reads elsewhere. */
	expr = op_contextualize(head, G_SCALAR);
	for (i = 0; i < n_steps; i++) {
		int refs = pd_count_topic_refs(aTHX_ steps[i], topic_off);
		int fused = 0;

		if (refs == 0)
			croak("pipe: internal error - a step without the topic");

		if (refs == 1 && i > 0 && listy[i] && listy[i - 1])
			fused = pd_fuse_list_step(aTHX_ steps[i], topic_off, expr);

		if (!fused) {
			if (refs > 1) {
				OP *lhs = newOP(OP_PADSV, 0);
				lhs->op_targ = topic_off;
				if (!spilled) {
					lhs->op_private |= OPpLVAL_INTRO;
					spilled = 1;
				}
				expr = newASSIGNOP(OPf_STACKED, lhs, 0, expr);
			}
			if (!pd_replace_topic_ref(aTHX_ steps[i], topic_off, expr)) {
				/* Should be impossible after the count above. */
				croak("pipe: internal error - lost the topic placeholder");
			}
		}

		if (i < n_steps - 1)
			expr = op_contextualize(steps[i], G_SCALAR);  /* intermediate */
		else
			expr = steps[i];          /* final - caller's context */
	}
	return expr;
}

static int pd_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr) {
	if (kwlen == 4 && memEQ(kw, "pipe", 4) && pd_in_scope(aTHX)) {
		*op_ptr = pd_parse_pipe(aTHX);
		return KEYWORD_PLUGIN_EXPR;
	}
	return pd_next_keyword_plugin(aTHX_ kw, kwlen, op_ptr);
}

/* ---- global infix `|>` operator (5.37.7+) -------------------------------
 *
 * On perls that have PL_infix_plugin (added 5.37.7, stable in 5.38), we
 * register `|>` as a real left-associative infix operator. Precedence is
 * the same as `||`: tighter than `=` (so `my $r = $x |> f` assigns the
 * piped result to `$r`), but looser than arithmetic (so `$x + 1 |> f`
 * reads as `($x + 1) |> f`).
 *
 * `build_op` is the only callback we need: given the parsed LHS and RHS
 * ops, it threads the LHS into the RHS as if the RHS were a step in a
 * `pipe { ... }` block. The two rules are:
 *
 *   1. If RHS is an OP_ENTERSUB (a function/method call):
 *      - method call (callee is OP_METHOD_NAMED / OP_METHOD):
 *           insert LHS as the SECOND positional, after the invocant
 *           ($x |> $obj->m(a, b)   ->   $obj->m($x, a, b))
 *      - sub call:
 *           insert LHS as the first positional argument
 *           ($x |> f(a, b)         ->   f($x, a, b))
 *
 *   2. Otherwise treat RHS as a coderef-yielding expression and call it
 *      with LHS as the sole argument
 *      ($x |> \&f, $x |> sub {..}, $x |> $cv   ->   RHS->($x))
 *
 * The infix plugin is lexically gated on $^H{'Pipe::Declare'}, exactly
 * like the keyword plugin - `|>` is invisible to perl's tokeniser
 * outside the pragma scope.
 *
 * Trade-off vs the recommended XS::Parse::Infix registry: we avoid the
 * extra CPAN dependency at the cost of central reflection / deparse.
 * Acceptable: this whole distribution's house style is zero-deps.
 * ------------------------------------------------------------------------ */

#ifdef PERL_VERSION_GE
#  if PERL_VERSION_GE(5,37,7)
#    define PD_HAVE_INFIX_PLUGIN 1
#  endif
#elif PERL_VERSION >= 38
#  define PD_HAVE_INFIX_PLUGIN 1
#endif

#ifdef PD_HAVE_INFIX_PLUGIN

static Perl_infix_plugin_t pd_next_infix_plugin;

/* Look up the last sibling of a LISTOP-style op. cLISTOPx(args)->op_last
 * isn't always reliable for op_lists built piecemeal via op_append_elem
 * (the field can lag), so walk the sibling chain explicitly. */
static OP *pd_last_sibling(OP *first) {
	OP *o = first;
	if (!o) return NULL;
	while (OpHAS_SIBLING(o)) o = OpSIBLING(o);
	return o;
}

static OP *pd_infix_build(pTHX_ SV **opdata, OP *lhs, OP *rhs,
                          struct Perl_custom_infix *def)
{
	PERL_UNUSED_ARG(opdata);
	PERL_UNUSED_ARG(def);

	/* Two entersub shapes show up in practice (post-finalize, which is what
	 * build_op sees):
	 *
	 *   Sub call (parsed as `f` or `f(a, b)`):
	 *     entersub -> ex-list -> [pushmark, arg1..argN, callee]
	 *     (ex-list has op_type == OP_NULL but kept its LISTOP layout)
	 *
	 *   Method call (parsed as `$obj->m` or `$obj->m(a, b)`):
	 *     entersub -> [pushmark, invocant, arg1..argN, method_named]
	 *     (no list wrapper - kids are direct siblings of entersub)
	 *
	 * We recognise both by looking at entersub->op_first: if it IS a
	 * pushmark, we're in the method-call shape; otherwise op_first is a
	 * (nulled) list whose first kid is the pushmark.
	 */
	if (rhs->op_type == OP_ENTERSUB) {
		OP *first = cUNOPx(rhs)->op_first;
		OP *parent, *pm;

		if (first && first->op_type == OP_PUSHMARK) {
			/* method-call shape */
			parent = rhs;
			pm     = first;
		} else if (first) {
			OP *list_first = cUNOPx(first)->op_first;
			if (list_first && list_first->op_type == OP_PUSHMARK) {
				/* sub-call shape */
				parent = first;
				pm     = list_first;
			} else {
				/* unrecognised shape - fall through */
				goto coderef_path;
			}
		} else {
			goto coderef_path;
		}

		{
			OP *invocant = OpSIBLING(pm);
			OP *callee   = pd_last_sibling(pm);
			int is_method = callee &&
			                (callee->op_type == OP_METHOD_NAMED ||
			                 callee->op_type == OP_METHOD);

			if (is_method && invocant && invocant != callee) {
				/* method: insert LHS after invocant, before any explicit args */
				op_sibling_splice(parent, invocant, 0, lhs);
			} else {
				/* sub: insert LHS right after pushmark */
				op_sibling_splice(parent, pm, 0, lhs);
			}
			return rhs;
		}
	}

coderef_path:
	/* Default: RHS is a coderef-yielding expression. Build  RHS->(LHS). */
	{
		OP *list = op_append_elem(OP_LIST, lhs, rhs);
		return newUNOP(OP_ENTERSUB, OPf_STACKED, list);
	}
}

static struct Perl_custom_infix pd_infix_pipe_def = {
	INFIX_PREC_LOGICAL_OR,        /* same as `||` - tighter than `=`,
	                               * looser than `+`, left-associative.
	                               * Picked so the common cases parse as
	                               * users expect:
	                               *   my $r = $x |> f      -> my $r = ($x |> f)
	                               *   $x + 1 |> f          -> ($x + 1) |> f
	                               *   $x |> f or $y        -> ($x |> f) or $y
	                               *   $x |> f |> g         -> ($x |> f) |> g
	                               */
	NULL,                         /* no extra parse callback */
	pd_infix_build,
};

static STRLEN pd_infix_plugin(pTHX_ char *op, STRLEN oplen,
                              struct Perl_custom_infix **def)
{
	if (oplen >= 2 && op[0] == '|' && op[1] == '>' && pd_in_scope(aTHX)) {
		*def = &pd_infix_pipe_def;
		return 2;                 /* consumed "|>" */
	}
	return pd_next_infix_plugin(aTHX_ op, oplen, def);
}

#endif /* PD_HAVE_INFIX_PLUGIN */

MODULE = Pipe::Declare  PACKAGE = Pipe::Declare
PROTOTYPES: DISABLE

BOOT:
	pd_next_keyword_plugin = PL_keyword_plugin;
	PL_keyword_plugin = pd_keyword_plugin;
#ifdef PD_HAVE_INFIX_PLUGIN
	wrap_infix_plugin(pd_infix_plugin, &pd_next_infix_plugin);
#endif
