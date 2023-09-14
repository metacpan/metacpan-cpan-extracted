/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

/* A horrible hack. We'll replace the op_ppaddr of the varop while leaving
 * the rest of the op structure alone
 */
static OP *pp_argelem_alias(pTHX)
{
  /* Much copypaste from bleadperl's pp_argelem in pp.c */
  SV ** padentry;
  OP *o = PL_op;
  AV *defav = GvAV(PL_defgv); /* @_ */
  IV ix = PTR2IV(cUNOP_AUXo->op_aux);

  padentry = &(PAD_SVl(o->op_targ));
  save_clearsv(padentry);

  SV **svp = av_fetch(defav, ix, FALSE);
  *padentry = svp ? SvREFCNT_inc(*svp) : &PL_sv_undef;

  return o->op_next;
}

static void apply_Alias(pTHX_ struct XPSSignatureParamContext *ctx, SV *attrvalue, void **attrdata_ptr, void *funcdata)
{
  PADNAME *pn = PadnamelistARRAY(PL_comppad_name)[ctx->padix];
  if(PadnamePV(pn)[0] != '$')
    croak("Can only apply the :Alias attribute to scalar parameters");
  if(ctx->is_named)
    croak("Cannot apply the :Alias attribute to a named parameter");
}

static void post_defop_Alias(pTHX_ struct XPSSignatureParamContext *ctx, void *attrdata, void *funcdata)
{
  if(ctx->defop)
    croak("Cannot apply the :Alias attribute to a parameter with a defaulting expression");

  OP *varop = ctx->varop;
  assert(varop);
  assert((varop->op_private & OPpARGELEM_MASK) == OPpARGELEM_SV);
  assert(!(varop->op_flags & OPf_STACKED));

  varop->op_ppaddr = &pp_argelem_alias;
}

static const struct XPSSignatureAttributeFuncs funcs_Alias = {
  .ver = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "Signature::Attribute::Alias/Alias",

  .apply = apply_Alias,
  .post_defop = post_defop_Alias,
};

MODULE = Signature::Attribute::Alias    PACKAGE = Signature::Attribute::Alias

BOOT:
  boot_xs_parse_sublike(0.19);

  register_xps_signature_attribute("Alias", &funcs_Alias, NULL);
