/* vi: set ft=c : */

#if !HAVE_PERL_VERSION(5, 16, 0)
#  define CopLABEL_len_flags(c,len,flags)    Perl_fetch_cop_label(aTHX_ (c), len, flags)
#endif

static void walk_ops_find_labels(pTHX_ OP *o, HV *gotolabels)
{
  switch(o->op_type) {
    case OP_NEXTSTATE:
    case OP_DBSTATE:
    {
      STRLEN label_len;
      U32 label_flags;
      const char *label_pv = CopLABEL_len_flags((COP *)o, &label_len, &label_flags);
      if(!label_pv)
        break;

      SV *labelsv = newSVpvn_flags(label_pv, label_len, label_flags);
      SAVEFREESV(labelsv);

      sv_inc(HeVAL(hv_fetch_ent(gotolabels, labelsv, TRUE, 0)));
      break;
    }
  }

  if(!(o->op_flags & OPf_KIDS))
    return;

  OP *kid = cUNOPo->op_first;
  while(kid) {
    walk_ops_find_labels(aTHX_ kid, gotolabels);
    kid = OpSIBLING(kid);
  }
}

enum {
  FORBID_LOOPEX_DEFAULT = (1<<0),
};

static OPCODE walk_ops_forbid(pTHX_ OP *o, U32 flags, HV *permittedloops, HV *permittedgotos)
{
  bool is_loop = FALSE;
  SV *labelsv = NULL;

  switch(o->op_type) {
    case OP_NEXTSTATE:
    case OP_DBSTATE:
      PL_curcop = (COP *)o;
      return 0;

    case OP_RETURN:
      goto forbid;

    case OP_GOTO:
    {
      /* OPf_STACKED means either dynamically computed label or `goto &sub` */
      if(o->op_flags & OPf_STACKED)
        goto forbid;

      SV *target = newSVpv(cPVOPo->op_pv, strlen(cPVOPo->op_pv));
#if HAVE_PERL_VERSION(5, 16, 0)
      if(cPVOPo->op_private & OPpPV_IS_UTF8)
        SvUTF8_on(target);
#endif
      SAVEFREESV(target);

      if(hv_fetch_ent(permittedgotos, target, FALSE, 0))
        break;

      goto forbid;
    }

    case OP_NEXT:
    case OP_LAST:
    case OP_REDO:
    {
      /* OPf_SPECIAL means this is a default loopex */
      if(o->op_flags & OPf_SPECIAL) {
        if(flags & FORBID_LOOPEX_DEFAULT)
          goto forbid;

        break;
      }
      /* OPf_STACKED means it's a dynamically computed label */
      if(o->op_flags & OPf_STACKED)
        goto forbid;

      SV *target = newSVpv(cPVOPo->op_pv, strlen(cPVOPo->op_pv));
#if HAVE_PERL_VERSION(5, 16, 0)
      if(cPVOPo->op_private & OPpPV_IS_UTF8)
        SvUTF8_on(target);
#endif
      SAVEFREESV(target);

      if(hv_fetch_ent(permittedloops, target, FALSE, 0))
        break;

      goto forbid;
    }

    case OP_LEAVELOOP:
    {
      STRLEN label_len;
      U32 label_flags;
      const char *label_pv = CopLABEL_len_flags(PL_curcop, &label_len, &label_flags);

      if(label_pv) {
        labelsv = newSVpvn_flags(label_pv, label_len, label_flags);
        SAVEFREESV(labelsv);

        sv_inc(HeVAL(hv_fetch_ent(permittedloops, labelsv, TRUE, 0)));
      }

      is_loop = TRUE;
      break;
    }

forbid:
      return o->op_type;

    default:
      break;
  }

  if(!(o->op_flags & OPf_KIDS))
    return 0;

  OP *kid = cUNOPo->op_first;
  while(kid) {
    OPCODE ret = walk_ops_forbid(aTHX_ kid, flags, permittedloops, permittedgotos);
    if(ret)
      return ret;

    kid = OpSIBLING(kid);

    if(is_loop) {
      /* Now in the body of the loop; we can permit loopex default */
      flags &= ~FORBID_LOOPEX_DEFAULT;
    }
  }

  if(is_loop && labelsv) {
    HE *he = hv_fetch_ent(permittedloops, labelsv, FALSE, 0);
    if(SvIV(HeVAL(he)) > 1)
      sv_dec(HeVAL(he));
    else
      hv_delete_ent(permittedloops, labelsv, 0, 0);
  }

  return 0;
}

#ifndef forbid_outofblock_ops
#  define forbid_outofblock_ops(o, blockname)  S_forbid_outofblock_ops(aTHX_ o, blockname)
static void S_forbid_outofblock_ops(pTHX_ OP *o, const char *blockname)
{
  ENTER;
  SAVEVPTR(PL_curcop);

  HV *looplabels = newHV();
  SAVEFREESV((SV *)looplabels);

  HV *gotolabels = newHV();
  SAVEFREESV((SV *)gotolabels);

  walk_ops_find_labels(aTHX_ o, gotolabels);

  OPCODE forbidden = walk_ops_forbid(aTHX_ o, FORBID_LOOPEX_DEFAULT, looplabels, gotolabels);
  if(forbidden)
    croak("Can't \"%s\" out of %s", PL_op_name[forbidden], blockname);

  LEAVE;
}
#endif

#ifndef warn_outofblock_ops
#  define warn_outofblock_ops(o, fmt)  S_warn_outofblock_ops(aTHX_ o, fmt)
static void S_warn_outofblock_ops(pTHX_ OP *o, const char *fmt)
{
  ENTER;
  SAVEVPTR(PL_curcop);

  HV *looplabels = newHV();
  SAVEFREESV((SV *)looplabels);

  HV *gotolabels = newHV();
  SAVEFREESV((SV *)gotolabels);

  walk_ops_find_labels(aTHX_ o, gotolabels);

  OPCODE forbidden = walk_ops_forbid(aTHX_ o, FORBID_LOOPEX_DEFAULT, looplabels, gotolabels);
  if(forbidden)
    warn(fmt, PL_op_name[forbidden]);

  LEAVE;
}
#endif
