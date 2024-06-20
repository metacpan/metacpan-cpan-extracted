/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023-2024 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "object_pad.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "compilerun_sv.c.inc"
#include "optree-additions.c.inc"

#include "DataChecks.h"

static int magic_set(pTHX_ SV *sv, MAGIC *mg)
{
  struct DataChecks_Checker *data = (struct DataChecks_Checker *)mg->mg_ptr;
  assert_value(data, sv);
  return 1;
}

static const MGVTBL vtbl = {
  .svt_set = &magic_set,
};

static int checkmagic_get(pTHX_ SV *sv, MAGIC *mg)
{
  SV *fieldsv = mg->mg_obj;
  sv_setsv_nomg(sv, fieldsv);
  return 1;
}

static int checkmagic_set(pTHX_ SV *sv, MAGIC *mg)
{
  struct DataChecks_Checker *data = (struct DataChecks_Checker *)mg->mg_ptr;
  assert_value(data, sv);

  SV *fieldsv = mg->mg_obj;
  sv_setsv_nomg(fieldsv, sv);
  return 1;
}

static const MGVTBL vtbl_checkmagic = {
  .svt_get = &checkmagic_get,
  .svt_set = &checkmagic_set,
};

static OP *pp_wrap_checkmagic(pTHX)
{
  dSP;
  SV *sv = TOPs;
  SV *ret = sv_newmortal();

  struct DataChecks_Checker *data = (struct DataChecks_Checker *)cUNOP_AUX->op_aux;

  sv_magicext(ret, sv, PERL_MAGIC_ext, &vtbl_checkmagic, (char *)data, 0);

  SETs(ret);
  RETURN;
}

static bool checked_apply(pTHX_ FieldMeta *fieldmeta, SV *value, SV **attrdata_ptr, void *_funcdata)
{
  SV *checker;

  if(mop_field_get_sigil(fieldmeta) != '$')
    croak("Can only apply the :Checked attribute to scalar fields");

  {
    dSP;

    ENTER;
    SAVETMPS;

    /* eval_sv() et.al. will forgets what package we're actually running in
     * because during compiletime, CopSTASH(PL_curcop == &PL_compiling) isn't
     * accurate. We need to help it along
     */

    SAVECOPSTASH_FREE(PL_curcop);
    CopSTASH_set(PL_curcop, PL_curstash);

    compilerun_sv(value, G_SCALAR);

    SPAGAIN;

    checker = SvREFCNT_inc(POPs);

    FREETMPS;
    LEAVE;
  }

  struct DataChecks_Checker *data = make_checkdata(checker);

  data->assertmess =
    newSVpvf("Field %" SVf " requires a value satisfying :Checked(%" SVf ")",
      SVfARG(mop_field_get_name(fieldmeta)), SVfARG(value));

  *attrdata_ptr = (SV *)data;

  return TRUE;
}

static void checked_gen_accessor_ops(pTHX_ FieldMeta *fieldmeta, SV *attrdata, void *_funcdata,
    enum AccessorType type, struct AccessorGenerationCtx *ctx)
{
  struct DataChecks_Checker *data = (struct DataChecks_Checker *)attrdata;

  switch(type) {
    case ACCESSOR_READER:
      return;

    case ACCESSOR_WRITER:
      ctx->bodyop = op_append_elem(OP_LINESEQ,
        make_assertop(data, newSLUGOP(0)),
        ctx->bodyop);
      return;

    case ACCESSOR_LVALUE_MUTATOR:
    {
      OP *o = ctx->retop;
      if(o->op_type != OP_RETURN)
        croak("Expected ctx->retop to be OP_RETURN");
      OP *kid = o->op_flags & OPf_KIDS ? cLISTOPo->op_first : NULL, *prevkid = NULL;
      if(kid && kid->op_type == OP_PUSHMARK)
        prevkid = kid, kid = OpSIBLING(kid);
      // TODO: maybe kid is always OP_PADSV, or maybe not.. Should we assert on it?
      OP *newkid = newUNOP_AUX(OP_CUSTOM, 0, kid, (UNOP_AUX_item *)attrdata);
      newkid->op_ppaddr = &pp_wrap_checkmagic;
      if(prevkid)
        OpMORESIB_set(prevkid, newkid);
      else
        croak("TODO: Need to set newkid as kid of listop?!");

      if(OpSIBLING(kid))
        OpMORESIB_set(newkid, OpSIBLING(kid));
      else
        OpLASTSIB_set(newkid, o);

      if(cLISTOPo->op_last == kid)
        cLISTOPo->op_last = newkid;

      OpLASTSIB_set(kid, newkid);
      return;
    }

    case ACCESSOR_COMBINED:
      ctx->bodyop = op_append_elem(OP_LINESEQ,
        newLOGOP(OP_AND, 0,
          /* scalar @_ */
          op_contextualize(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv)), G_SCALAR),
          make_assertop(data, newSLUGOP(0))),
        ctx->bodyop);
      return;

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
  boot_data_checks(0);

  register_field_attribute("Checked", &checked_hooks, NULL);
