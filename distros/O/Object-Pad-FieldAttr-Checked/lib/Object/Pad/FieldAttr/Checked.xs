/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"

struct Data {
  SV *fieldname;
  SV *checkname;
  SV *checkobj;
  CV *checkcv;
};

static int magic_set(pTHX_ SV *sv, MAGIC *mg)
{
  struct Data *data = (struct Data *)mg->mg_ptr;

  bool ok;
  {
    dSP;

    ENTER;
    SAVETMPS;

    EXTEND(SP, 2);
    PUSHMARK(SP);
    PUSHs(sv_mortalcopy(data->checkobj));
    PUSHs(sv); /* Yes we're pushing the SV itself */
    PUTBACK;

    call_sv((SV *)data->checkcv, G_SCALAR);

    SPAGAIN;

    ok = SvTRUEx(POPs);

    FREETMPS;
    LEAVE;
  }

  if(ok)
    return 1;

  croak("Field %" SVf " requires a value satisfying :Checked(%" SVf ")",
    SVfARG(data->fieldname), SVfARG(data->checkname));

  return 1;
}

static const MGVTBL vtbl = {
  .svt_set = &magic_set,
};

static bool checked_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **attrdata_ptr, void *_funcdata)
{
  SV *checker;

  if(mop_field_get_sigil(fieldmeta) != '$')
    croak("Can only apply the :Checked attribute to scalar fields");

  {
    dSP;

    ENTER;
    SAVETMPS;

    /* We can't call eval_sv() because it doesn't preserve the caller's hints
     * or features. We'll have to emulate it and do different things
     *   https://github.com/Perl/perl5/issues/21415
     *
     * Additionally, it also forgets what package we're actually running in
     * because during compiletime, CopSTASH(PL_curcop == &PL_compiling) isn't
     * accurate. We need to help it along
     */

    SAVECOPSTASH_FREE(PL_curcop);
    CopSTASH_set(PL_curcop, PL_curstash);

    /* We'll turn off strict 'subs' during this code for now, to
     * support bareword package names as checker expressions
     */
    SAVEI32(PL_hints);
    PL_hints &= ~HINT_STRICT_SUBS;

    OP *o = newUNOP(OP_ENTEREVAL, G_SCALAR,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(value)));
    OP *start = LINKLIST(o);
    o->op_next = NULL;
#ifdef OPpEVAL_EVALSV
    o->op_private |= OPpEVAL_EVALSV;
#endif

    SAVEFREEOP(o);

    // Now just execute the ops in the list until the end
    SAVEVPTR(PL_op);
    PL_op = start;

#ifndef OPpEVAL_EVALSV
    /* Without OPpEVAL_EVALSV we can only detect compiler errors by
     * pp_entereval() returning NULL. We'll have to manually run the optree
     * until we see that to know
     */
    while(PL_op && PL_op->op_type != OP_ENTEREVAL)
      PL_op = (*PL_op->op_ppaddr)(aTHX);
    if(PL_op)
      PL_op = (*PL_op->op_ppaddr)(aTHX); // run the OP_ENTEREVAL
    if(!PL_op)
      croak_sv(ERRSV);
#endif
    CALLRUNOPS(aTHX);

    SPAGAIN;

#ifdef OPpEVAL_EVALSV
    if(!TOPs)
      croak_sv(ERRSV);
#endif

    checker = SvREFCNT_inc(POPs);

    FREETMPS;
    LEAVE;
  }

  HV *stash;
  if(SvROK(checker) && SvOBJECT(SvRV(checker)))
    stash = SvSTASH(SvRV(checker));
  else if(SvPOK(checker) && (stash = gv_stashsv(checker, GV_NOADD_NOINIT)))
    ; /* checker is package name */
  else
    croak("Expected the checker expression to yield an object reference or package name; got %" SVf " instead",
      SVfARG(checker));

  GV *methgv;
  if(!(methgv = gv_fetchmeth_pv(stash, "check", -1, 0)))
    croak("Expected that the checker expression can ->check");
  if(!GvCV(methgv))
    croak("Expected that methgv has a GvCV");

  struct Data *data;
  Newx(data, 1, struct Data);

  data->fieldname = SvREFCNT_inc(mop_field_get_name(fieldmeta));
  data->checkname = SvREFCNT_inc(value);
  data->checkobj  = checker;
  data->checkcv   = (CV *)SvREFCNT_inc((SV *)GvCV(methgv));

  *attrdata_ptr = (SV *)data;

  return TRUE;
}

#define newSLUGOP(idx)  S_newSLUGOP(aTHX_ idx)
static OP *S_newSLUGOP(pTHX_ int idx)
{
  OP *op = newGVOP(OP_AELEMFAST, 0, PL_defgv);
  op->op_private = idx;
  return op;
}

#define newLISTOPn(type, flags, ...)  S_newLISTOPn(aTHX_ type, flags, __VA_ARGS__, NULL)
static OP *S_newLISTOPn(pTHX_ OPCODE type, U32 flags, ...)
{
  va_list args;
  va_start(args, flags);

  OP *o = newLISTOP(OP_LIST, 0, NULL, NULL);

  OP *kid;
  while((kid = va_arg(args, OP *)))
    o = op_append_elem(OP_LIST, o, kid);

  va_end(args);

  return op_convert_list(type, flags, o);
}

static void checked_gen_accessor_ops(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *_funcdata,
    enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  struct Data *data = (struct Data *)attrdata;

  switch(type) {
    case ACCESSOR_READER:
      return;

    case ACCESSOR_WRITER:
    {
      OP *checkop = newLOGOP(OP_OR, 0,
        /* checkgv($checker, $_[0]) ... */
        newLISTOPn(OP_ENTERSUB, OPf_WANT_SCALAR|OPf_STACKED,
          newSVOP(OP_CONST, 0, SvREFCNT_inc(data->checkobj)),
          newSLUGOP(0),
          newSVOP(OP_CONST, 0, SvREFCNT_inc(data->checkcv))),
        /* ... or die MESSAGE */
        newLISTOPn(OP_DIE, 0,
          newSVOP(OP_CONST, 0,
            newSVpvf("Field %" SVf " requires a value satisfying :Checked(%" SVf ")",
              SVfARG(mop_field_get_name(fieldmeta)), SVfARG(data->checkname))))
      );

      ctx->bodyop = op_append_elem(OP_LINESEQ, checkop, ctx->bodyop);
      return;
    }

    case ACCESSOR_LVALUE_MUTATOR:
      croak("Cannot currently combine :mutator and :Checked");

    case ACCESSOR_COMBINED:
      croak("Cannot currently combine :accessor and :Checked");

    default:
      croak("TODO: Unsure what to do with accessor type %d and :Checked", type);
  }
}

/* Object::Pad doesn't currently offer a way to pre-check the values assigned
 * into fields before assigning them. The best we can do is *temporarily*
 * apply magic on the field SV itself, check it in the .set callback, then
 * remove that magic at the end of the constructor.
 *
 * This is awkward as it'll still apply the checking to post-:param mutations
 * inside ADJUST blocks and the like. Fixing that will require more field hook
 * functions in O:P though
 */

static void checked_post_makefield(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *_funcdata, SV *field)
{
  sv_magicext(field, NULL, PERL_MAGIC_ext, &vtbl, (char *)attrdata, 0);
}

static void checked_post_construct(pTHX_ FieldMeta *fieldmeta, SV *hookdata, void *_funcdata, SV *field)
{
  sv_unmagicext(field, PERL_MAGIC_ext, (MGVTBL *)&vtbl);
}

static const struct FieldHookFuncs checked_hooks = {
  .ver   = OBJECTPAD_ABIVERSION,
  .flags = OBJECTPAD_FLAG_ATTR_MUST_VALUE,
  .permit_hintkey = "Object::Pad::FieldAttr::Checked/Checked",

  .apply            = &checked_apply,
  .gen_accessor_ops = &checked_gen_accessor_ops,
  .post_makefield   = &checked_post_makefield,
  .post_construct   = &checked_post_construct,
};

MODULE = Object::Pad::FieldAttr::Checked    PACKAGE = Object::Pad::FieldAttr::Checked

BOOT:
  register_field_attribute("Checked", &checked_hooks, NULL);
