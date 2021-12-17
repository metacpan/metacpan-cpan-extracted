/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

#include "perl-backcompat.c.inc"

#include "newOP_CUSTOM.c.inc"

struct MultiSubOption {
  int args_min, args_max;
  CV *cv;
};

#define get_optionsav(cv, padix)  S_get_optionsav(aTHX_ cv, padix)
static AV *S_get_optionsav(pTHX_ CV *cv, PADOFFSET padix)
{
  PADLIST *pl = CvPADLIST(cv);
  AV *optionsav = (AV *)PadARRAY(PadlistARRAY(pl)[1])[padix];
  return optionsav;
}

static OP *pp_dispatch_multisub(pTHX)
{
  IV nargs = av_count(GvAV(PL_defgv));
  CV *runcv = find_runcv(0);
  AV *optionsav = get_optionsav(runcv, PL_op->op_targ);

  CV *jumpcv = NULL;

  IV noptions = av_count(optionsav);
  IV optioni;
  for(optioni = 0; optioni < noptions; optioni++) {
    struct MultiSubOption *option = (struct MultiSubOption *)AvARRAY(optionsav)[optioni];

    if(nargs < option->args_min)
      continue;
    if(option->args_max > -1 && nargs > option->args_max)
      continue;

    jumpcv = option->cv;
    break;
  }

  if(!jumpcv)
    croak("Unable to find a function body for a call to &%s::%s having %d arguments",
      HvNAME(CvSTASH(runcv)), GvNAME(CvGV(runcv)), nargs);

  /* Now pretend to be  goto &$cv
   * Reuse the same PL_op structure and just call that ppfunc */
  assert(PL_op->op_flags & OPf_STACKED);
  dSP;
  mPUSHs(newRV_inc((SV *)jumpcv));
  PUTBACK;
  assert(SvROK(TOPs) && SvTYPE(SvRV(TOPs)) == SVt_PVCV);
  return (PL_ppaddr[OP_GOTO])(aTHX);
}

/* XSParseSublikeContext moddata keys */
#define MODDATA_KEY_NAME        "Syntax::Keyword::MultiSub/name"
#define MODDATA_KEY_COMPMULTICV "Syntax::Keyword::MultiSub/compmulticv"

static void parse_pre_subparse(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  SV *name = ctx->name;

  CV *multicv = get_cvn_flags(SvPVX(name), SvCUR(name), SvUTF8(name) ? SVf_UTF8 : 0);
  if(!multicv) {
    ENTER;

    I32 floor_ix = start_subparse(FALSE, 0);
    SAVEFREESV(PL_compcv);

    I32 save_ix = block_start(TRUE);

    PADOFFSET padix = pad_add_name_pvs("@(Syntax::Keyword::MultiSub/options)", 0, NULL, NULL);
    intro_my();

    OP *dispatchop = newOP_CUSTOM(&pp_dispatch_multisub, OPf_STACKED);
    dispatchop->op_targ = padix;

    OP *body = block_end(save_ix, dispatchop);

    SvREFCNT_inc(PL_compcv);

    multicv = newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, SvREFCNT_inc(name)), NULL, NULL, body);

    LEAVE;
  }

  hv_stores(ctx->moddata, MODDATA_KEY_NAME,        SvREFCNT_inc(name));
  hv_stores(ctx->moddata, MODDATA_KEY_COMPMULTICV, SvREFCNT_inc(multicv));

  /* Do not let this sub be installed as a named symbol */
  ctx->actions &= ~XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL;
}

static void parse_post_newcv(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  CV *cv = ctx->cv;
  if(!cv)
    return;

  SV *name    =       *hv_fetchs(ctx->moddata, MODDATA_KEY_NAME, 0);
  CV *multicv = (CV *)*hv_fetchs(ctx->moddata, MODDATA_KEY_COMPMULTICV, 0);

  PADNAMELIST *pln = PadlistNAMES(CvPADLIST(multicv));
  /* We can't use pad_findmy_pvn() because it gets upset about seqnums */
  PADOFFSET padix;
  for(padix = 1; padix <= PadnamelistMAX(pln); padix++)
    if(strEQ(PadnamePV(PadnamelistARRAY(pln)[padix]), "@(Syntax::Keyword::MultiSub/options)"))
      break;
  assert(padix <= PadnamelistMAX(pln));

  AV *optionsav = get_optionsav(multicv, padix);
  bool final_is_slurpy = av_count(optionsav) &&
    (((struct MultiSubOption *)AvARRAY(optionsav)[AvFILL(optionsav)])->args_max == -1);

  int args_min, args_max;

  OP *o = CvSTART(cv);
  while(o) {
redo:
    switch(o->op_type) {
      case OP_NEXTSTATE:
        o = o->op_next;
        goto redo;

      case OP_ARGCHECK: {
#if HAVE_PERL_VERSION(5, 31, 5)
        struct op_argcheck_aux *aux = (struct op_argcheck_aux *)cUNOP_AUXo->op_aux;
        char slurpy = aux->slurpy;
        args_max = aux->params;
        args_min = args_max - aux->opt_params;
#else
        UNOP_AUX_item *aux = cUNOP_AUXo->op_aux;
        char slurpy = aux[2].iv;

        args_max = aux[0].iv;
        args_min = args_max - aux[1].iv;
#endif
        if(slurpy) {
          if(final_is_slurpy)
            croak("Already have a slurpy function body for multi sub %" SVf, name);
          args_max = -1;
        }
        goto done;
      }

      default:
        croak("TODO: Unsure how to find argcheck op within %s", PL_op_name[o->op_type]);
    }
  }
done: ;

  IV noptions = av_count(optionsav);
  IV optioni;
  for(optioni = 0; optioni < noptions; optioni++) {
    struct MultiSubOption *option = (struct MultiSubOption *)AvARRAY(optionsav)[optioni];

    if(option->args_max == -1 || args_min > option->args_max)
      continue;
    if(args_max < option->args_min)
      continue;

    croak("Ambiguous argument count for multi sub %" SVf, name);
  }

  struct MultiSubOption *option;
  Newx(option, 1, struct MultiSubOption);

  option->args_min = args_min;
  option->args_max = args_max;
  option->cv       = cv_clone(cv); /* Because it is currently a protosub */

  av_push(optionsav, (SV *)option);
}

static struct XSParseSublikeHooks hooks_multi = {
  .permit_hintkey = "Syntax::Keyword::MultiSub/multi",
  .flags          = XS_PARSE_SUBLIKE_FLAG_PREFIX|XS_PARSE_SUBLIKE_COMPAT_FLAG_DYNAMIC_ACTIONS,
  .require_parts  = XS_PARSE_SUBLIKE_PART_NAME,
  .pre_subparse   = parse_pre_subparse,
  .post_newcv     = parse_post_newcv,
};

MODULE = Syntax::Keyword::MultiSub    PACKAGE = Syntax::Keyword::MultiSub

BOOT:
  boot_xs_parse_sublike(0.15);

  register_xs_parse_sublike("multi", &hooks_multi, NULL);
