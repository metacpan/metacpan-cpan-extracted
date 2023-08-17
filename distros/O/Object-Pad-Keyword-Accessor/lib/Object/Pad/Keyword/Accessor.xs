/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2022-2023 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"
#include "object_pad.h"

#ifndef newSVsv_nomg
static SV *S_newSVsv_nomg(pTHX_ SV *osv)
{
  SV *nsv = newSV(0);
  sv_setsv_nomg(nsv, osv);
  return nsv;
}

#  define newSVsv_nomg(osv)  S_newSVsv_nomg(aTHX_ (osv))
#endif

struct AccessorCtx {
  CV *getcv;
  CV *setcv;
};

static int accessor_magic_get(pTHX_ SV *sv, MAGIC *mg)
{
  struct AccessorCtx *ctx = (struct AccessorCtx *)mg->mg_ptr;
  SV *self = mg->mg_obj;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(self);
  PUTBACK;

  int count = call_sv((SV *)ctx->getcv, G_SCALAR);
  PERL_UNUSED_VAR(count);
  assert(count == 1);

  SPAGAIN;

  sv_setsv_nomg(sv, POPs);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return 1;
}

static int accessor_magic_set(pTHX_ SV *sv, MAGIC *mg)
{
  struct AccessorCtx *ctx = (struct AccessorCtx *)mg->mg_ptr;
  SV *self = mg->mg_obj;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(self);
  mPUSHs(newSVsv_nomg(sv));
  PUTBACK;

  call_sv((SV *)ctx->setcv, G_VOID);

  FREETMPS;
  LEAVE;

  return 1;
}

static MGVTBL vtbl_accessor = {
  .svt_get = accessor_magic_get,
  .svt_set = accessor_magic_set,
};

XS_INTERNAL(make_accessor_lvalue)
{
  dXSARGS;

  if(items < 1 || items > 1)
    croak("Usage: $self->accessor");
  SP -= items;

  SV *self = ST(0);

  SV *retval = sv_newmortal();
  sv_magicext(retval, SvREFCNT_inc(self), PERL_MAGIC_ext, &vtbl_accessor, XSANY.any_ptr, 0);

  ST(0) = retval;

  XSRETURN(1);
}

enum {
  PART_GET = 1,
  PART_SET,
};

static int build_accessor(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  int argi = 0;

  SV *name = args[argi++]->sv;

  ClassMeta *classmeta = get_compclassmeta();

  struct AccessorCtx *ctx;
  Newxz(ctx, 1, struct AccessorCtx);

  int nparts = args[argi++]->i;
  for(int parti = 0; parti < nparts; parti++) {
    int parttype = args[argi++]->i;
    switch(parttype) {
      case PART_GET:
        if(ctx->getcv)
          croak("Cannot provide two 'get' blocks for %" SVf " accessor", SVfARG(name));
        ctx->getcv = cv_clone((CV *)args[argi++]->sv);
        assert(SvTYPE(ctx->getcv) == SVt_PVCV);
        break;

      case PART_SET:
        if(ctx->setcv)
          croak("Cannot provide two 'set' blocks for %" SVf " accessor", SVfARG(name));
        ctx->setcv = cv_clone((CV *)args[argi++]->sv);
        assert(SvTYPE(ctx->setcv) == SVt_PVCV);
        break;

      default:
        croak("TODO: Handle part type %d", parttype);
    }
  }

  /* Sanity checking */
  if(!ctx->getcv)
    croak("accessor needs a 'get' stage");
  if(!ctx->setcv)
    croak("accessor needs a 'set' stage");

  CV *cv = newXS(NULL, make_accessor_lvalue, __FILE__);
  CvMETHOD_on(cv);
  CvLVALUE_on(cv);
  CvXSUBANY(cv).any_ptr = ctx;

  mop_class_add_method_cv(classmeta, name, cv);

  return KEYWORD_PLUGIN_STMT;
}

/* stolen from perl-additions.c.inc */
#define lex_consume_unichar(c)  MY_lex_consume_unichar(aTHX_ c)
static bool MY_lex_consume_unichar(pTHX_ U32 c)
{
  if(lex_peek_unichar(0) != c)
    return FALSE;

  lex_read_unichar(0);
  return TRUE;
}

#define HINTKEY_PADIX  "Object::Pad::Keyword::Accessor/var-padix"

static void anonmethod_set_start(pTHX_ void *hookdata)
{
  if(!lex_consume_unichar('('))
    return;
  lex_read_space(0);

  char *name = PL_parser->bufptr;

  if(lex_read_unichar(0) != '$')
    croak("Expected a scalar lexical name");

  if(!isIDFIRST_uni(lex_read_unichar(0)))
    croak("Expected a scalar lexical name");
  while(isIDCONT_uni(lex_peek_unichar(0)))
    lex_read_unichar(0);

  STRLEN namelen = PL_parser->bufptr - name;

  if(namelen == 2 && name[1] == '_')
    croak("Can't use global $_ in \"my\"");

  PADOFFSET padix = pad_add_name_pvn(name, namelen, 0, NULL, NULL);
  hv_stores(GvHV(PL_hintgv), HINTKEY_PADIX, newSVuv(padix));

  if(!lex_consume_unichar(')'))
    croak("Expected ')'");

  intro_my();
}

static OP *anonmethod_set_end(pTHX_ OP *o, void *hookdata)
{
  SV **svp = hv_fetchs(GvHV(PL_hintgv), HINTKEY_PADIX, 0);
  if(!svp)
    return o;

  /* $var = $_[0]; */
  OP *padsvop;
  OP *setupop = newBINOP(OP_SASSIGN, 0,
    newGVOP(OP_AELEMFAST, 0 << 8, PL_defgv),
    padsvop = newOP(OP_PADSV, 0));
  padsvop->op_targ = SvUV(*svp);

  o = op_append_elem(OP_LINESEQ, setupop, o);

  return o;
}

static const struct XSParseKeywordHooks kwhooks_accessor = {
  .permit_hintkey = "Object::Pad::Keyword::Accessor",

  .pieces = (const struct XSParseKeywordPieceType []) {
    XPK_IDENT,
    XPK_BRACES(
      XPK_REPEATED(
        XPK_TAGGEDCHOICE(
          /* A `get` block is just a regular anon method */
          XPK_SEQUENCE(XPK_KEYWORD("get"), OPXPK_ANONMETHOD),
            XPK_TAG(PART_GET),
          /* A `set` block requires special parsing of the "($var)" syntax */
          XPK_SEQUENCE(XPK_KEYWORD("set"), XPK_STAGED_ANONSUB(
              OPXPK_ANONMETHOD_PREPARE,
              OPXPK_ANONMETHOD_START,
              /* TODO: This is rather hacky; using a code block to do some
               * parsing. Ideally we'd like to use
               *   XPK_PARENS(XPK_LEXVAR_MY(XPK_LEXVAR_SCALAR))
               * for it, but that leaves us not knowing the padix for the new
               * variable when we come to END+WRAP the method into a CV. We'd
               * need some way to interrupt and put more code in there.
               * Somehow.
               */
              XPK_ANONSUB_START(&anonmethod_set_start),
              XPK_ANONSUB_END(&anonmethod_set_end),
              OPXPK_ANONMETHOD_WRAP)),
            XPK_TAG(PART_SET)
        )
      )
    ),
    {0}
  },
  .build = &build_accessor,
};

MODULE = Object::Pad::Keyword::Accessor    PACKAGE = Object::Pad::Keyword::Accessor

BOOT:
  boot_xs_parse_keyword(0.35);

  /* TODO: Consider if this needs to be done via O:P directly */
  register_xs_parse_keyword("accessor", &kwhooks_accessor, NULL);
