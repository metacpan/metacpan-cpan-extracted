/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023-2024 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "compilerun_sv.c.inc"

#include "DataChecks.h"

static void apply_Checked(pTHX_ struct XPSSignatureParamContext *ctx, SV *attrvalue, void **attrdata_ptr, void *funcdata)
{
  PADNAME *pn = PadnamelistARRAY(PL_comppad_name)[ctx->padix];
  if(PadnamePV(pn)[0] != '$')
    croak("Can only apply the :Checked attribute to scalar parameters");

  SV *checker;

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

    compilerun_sv(attrvalue, G_SCALAR);

    SPAGAIN;

    checker = SvREFCNT_inc(POPs);

    FREETMPS;
    LEAVE;
  }

  struct DataChecks_Checker *data = make_checkdata(checker);

  data->assertmess =
    newSVpvf(
      ctx->is_named ? "Named parameter :%s requires a value satisfying :Checked(%" SVf ")"
                    : "Parameter %s requires a value satisfying :Checked(%" SVf ")",
    PadnamePV(pn), SVfARG(attrvalue));

  *attrdata_ptr = data;
}

#ifndef newPADxVOP
#  define newPADxVOP(type, flags, padix)  S_newPADxVOP(aTHX_ type, flags, padix)
static OP *S_newPADxVOP(pTHX_ I32 type, I32 flags, PADOFFSET padix)
{
  OP *op = newOP(type, flags);
  op->op_targ = padix;
  return op;
}
#endif

static void post_defop_Checked(pTHX_ struct XPSSignatureParamContext *ctx, void *attrdata, void *funcdata)
{
  struct DataChecks_Checker *data = attrdata;

  OP *assertop = make_assertop(data, newPADxVOP(OP_PADSV, 0, ctx->padix));

  ctx->op = op_append_elem(OP_SCOPE,
    ctx->op, assertop);
}

static void free_Checked(pTHX_ struct XPSSignatureParamContext *ctx, void *attrdata, void *funcdata)
{
  struct DataChecks_Checker *data = attrdata;

  SvREFCNT_dec(data->assertmess);

  Safefree(data);
}

static const struct XPSSignatureAttributeFuncs funcs_Checked = {
  .ver = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "Signature::Attribute::Checked/Checked",

  .apply = apply_Checked,
  .post_defop = post_defop_Checked,
};

MODULE = Signature::Attribute::Checked    PACKAGE = Signature::Attribute::Checked

BOOT:
  boot_xs_parse_sublike(0.19);
  boot_data_checks(0);

  register_xps_signature_attribute("Checked", &funcs_Checked, NULL);
