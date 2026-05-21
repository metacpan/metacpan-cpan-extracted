/*  Object::PadX::Enum
 *
 *  Thin XS layer registering two keywords (`enum`, `item`) via XS::Parse::Keyword.
 *  All non-trivial work happens in Object::PadX::Enum (the .pm) via the
 *  documented Object::Pad::MOP::Class API.
 *
 *  Pattern reference: Object-Pad-0.825/lib/Object/Pad.xs:406-625 (build_classlike)
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

/* lex_consume_unichar is not part of the stable lexer-API export surface in
 * all perls; provide a tiny local equivalent. Same shim as
 * Object-Pad-0.825/hax/perl-additions.c.inc.
 */
static bool S_lex_consume_unichar(pTHX_ U32 c)
{
   if (lex_peek_unichar(0) != c)
      return FALSE;
   lex_read_unichar(0);
   return TRUE;
}
#define lex_consume_unichar(c) S_lex_consume_unichar(aTHX_ (c))

/* Single-keyword compile-time state. We do not support nested enums; a saved
 * snapshot at entry makes accidental nesting visible as a parse-time error
 * via `item`'s check hook rather than as silent corruption.
 */
static int  inside_enum_depth     = 0;
static SV  *current_enum_classname = NULL;

/* Construct an OP tree that, at runtime, calls a named fully-qualified Perl
 * sub with the given pre-built list of argument OPs.
 *
 * `args_list` must be an OP_LIST op (newLISTOP(OP_LIST, ...)).  Ownership of
 * `args_list` is transferred to the returned op.
 */
static OP *S_make_call_op(pTHX_ const char *subname, OP *args_list)
{
   GV *gv = gv_fetchpv(subname, GV_ADD, SVt_PVCV);
   OP *cv_ref = newCVREF(0, newGVOP(OP_GV, 0, gv));

   args_list = op_append_elem(OP_LIST, args_list, cv_ref);
   return newUNOP(OP_ENTERSUB, OPf_STACKED, args_list);
}
#define make_call_op(name, list)  S_make_call_op(aTHX_ (name), (list))

/* --------------------------------------------------------------------- */
/* `enum NAME { BODY }`                                                  */
/* --------------------------------------------------------------------- */

static int build_enum(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
   PERL_UNUSED_ARG(hookdata);
   PERL_UNUSED_ARG(nargs);

   SV *packagename = args[0]->sv;
   int nattrs      = args[1]->i;

   /* Snapshot prior context so a stray nested `enum` won't corrupt state. */
   SV  *saved_classname = current_enum_classname;
   int  saved_depth     = inside_enum_depth;

   current_enum_classname = packagename;
   inside_enum_depth      = 1;

   /* Marshal `[name, value_or_undef]` pairs into a Perl AV ref for the helper. */
   AV *attrs_av = newAV();
   for (int i = 0; i < nattrs; i++) {
      AV *pair = newAV();
      av_push(pair, SvREFCNT_inc(args[2 + i]->attr.name));
      SV *value = args[2 + i]->attr.value;
      av_push(pair, value ? SvREFCNT_inc(value) : newSV(0));
      av_push(attrs_av, newRV_noinc((SV *)pair));
   }
   SV *attrs_ref = sv_2mortal(newRV_noinc((SV *)attrs_av));

   /* Drive Object::Pad::MOP::Class->begin_class via the Perl helper. This
    * sets compclassmeta, registers UNITCHECK auto-seal, and adds $ordinal.
    */
   {
      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(packagename);
      XPUSHs(attrs_ref);
      PUTBACK;
      call_pv("Object::PadX::Enum::_begin_enum", G_VOID | G_DISCARD);
      FREETMPS;
      LEAVE;
   }

   lex_read_space(0);
   if (!lex_consume_unichar('{'))
      croak("Expected '{' after 'enum %" SVf "'", SVfARG(packagename));

   ENTER;

   /* Object::Pad's `field`/`method` keywords assert PL_curstname matches
    * compclassmeta's name. begin_class sets compclassmeta but not the
    * package; do that here, mirroring Pad.xs:546-555. SAVE machinery
    * ensures restoration at the matching LEAVE.
    */
   SAVEGENERICSV(PL_curstash);
   save_item(PL_curstname);
   PL_curstash = (HV *)SvREFCNT_inc(gv_stashsv(packagename, GV_ADD));
   sv_setsv(PL_curstname, packagename);

   I32 save_ix = block_start(TRUE);

   OP *body = parse_stmtseq(0);
   body = block_end(save_ix, body);

   if (!lex_consume_unichar('}'))
      croak("Expected '}' at end of 'enum %" SVf "' body", SVfARG(packagename));

   LEAVE;

   inside_enum_depth      = saved_depth;
   current_enum_classname = saved_classname;

   /* Trailing runtime call: Object::PadX::Enum::_finalize_enum("NAME"); */
   OP *finalize_args = newLISTOP(OP_LIST, 0, NULL, NULL);
   finalize_args = op_append_elem(OP_LIST, finalize_args,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(packagename)));

   OP *finalize_call = make_call_op("Object::PadX::Enum::_finalize_enum", finalize_args);
   OP *finalize_stmt = newSTATEOP(0, NULL, finalize_call);

   /* body may be NULL for an empty enum block. */
   OP *combined = body
      ? op_append_elem(OP_LINESEQ, body, finalize_stmt)
      : finalize_stmt;

   /* Wrap in a once-loop so it behaves as a single statement, mirroring
    * Object::Pad's class-block emission (Pad.xs:589-591).
    */
   *out = op_append_elem(OP_LINESEQ,
      newWHILEOP(0, 1, NULL, NULL, combined, NULL, 0),
      newSVOP(OP_CONST, 0, &PL_sv_yes));

   return KEYWORD_PLUGIN_STMT;
}

static const struct XSParseKeywordPieceType pieces_enum[] = {
   XPK_PACKAGENAME,
   XPK_ATTRIBUTES,
   {0}
};

static const struct XSParseKeywordHooks hooks_enum = {
   .permit_hintkey = "Object::PadX::Enum/enum",
   .pieces         = pieces_enum,
   .build          = &build_enum,
};

/* --------------------------------------------------------------------- */
/* `item NAME ( args, ... );`                                            */
/* --------------------------------------------------------------------- */

static void check_item(pTHX_ void *hookdata)
{
   PERL_UNUSED_ARG(hookdata);

   if (!inside_enum_depth)
      croak("'item' is only valid inside an 'enum { ... }' block");
}

static int build_item(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
   PERL_UNUSED_ARG(hookdata);
   PERL_UNUSED_ARG(nargs);

   SV  *itemname   = args[0]->sv;
   int  has_parens = args[1]->i;
   OP  *listexpr   = has_parens ? args[2]->op : NULL;
   int  line       = args[0]->line;

   if (!current_enum_classname)
      croak("Internal error: 'item %" SVf "' has no enclosing enum class", SVfARG(itemname));

   /* Runtime call: _register_item(CLASSNAME, NAME, LINE, ARGS...); */
   OP *call_args = newLISTOP(OP_LIST, 0, NULL, NULL);
   call_args = op_append_elem(OP_LIST, call_args,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(current_enum_classname)));
   call_args = op_append_elem(OP_LIST, call_args,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(itemname)));
   call_args = op_append_elem(OP_LIST, call_args,
      newSVOP(OP_CONST, 0, newSViv(line)));

   if (listexpr)
      call_args = op_append_elem(OP_LIST, call_args, listexpr);

   *out = make_call_op("Object::PadX::Enum::_register_item", call_args);
   return KEYWORD_PLUGIN_STMT;
}

static const struct XSParseKeywordPieceType pieces_item[] = {
   XPK_IDENT,
   XPK_PARENS_OPT(XPK_LISTEXPR),
   XPK_AUTOSEMI,
   {0}
};

static const struct XSParseKeywordHooks hooks_item = {
   .permit_hintkey = "Object::PadX::Enum/item",
   .pieces         = pieces_item,
   .check          = &check_item,
   .build          = &build_item,
};

/* --------------------------------------------------------------------- */

MODULE = Object::PadX::Enum   PACKAGE = Object::PadX::Enum

PROTOTYPES: DISABLE

BOOT:
   boot_xs_parse_keyword(0.48);
   register_xs_parse_keyword("enum", &hooks_enum, NULL);
   register_xs_parse_keyword("item", &hooks_item, NULL);
