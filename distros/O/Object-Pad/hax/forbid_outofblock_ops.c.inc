/* vi: set ft=c : */

enum {
  FORBID_LOOPEX_DEFAULT = (1<<0),
};

static void walk_ops_forbid(pTHX_ OP *o, U32 flags, HV *permittedloops, const char *blockname)
{
  bool is_loop = FALSE;
  SV *labelsv = NULL;

  switch(o->op_type) {
    case OP_NEXTSTATE:
      PL_curcop = (COP *)o;
      return;

    case OP_RETURN:
      goto forbid;

    case OP_GOTO:
      /* TODO: This might be safe, depending on the target */
      goto forbid;

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
      if(cPVOPo->op_private & OPpPV_IS_UTF8)
        SvUTF8_on(target);
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
        labelsv = newSVpvn(label_pv, label_len);
        if(label_flags & SVf_UTF8)
          SvUTF8_on(labelsv);
        SAVEFREESV(labelsv);

        sv_inc(HeVAL(hv_fetch_ent(permittedloops, labelsv, TRUE, 0)));
      }

      is_loop = TRUE;
      break;
    }

forbid:
      croak("Can't \"%s\" out of %s", PL_op_name[o->op_type], blockname);

    default:
      break;
  }

  if(!(o->op_flags & OPf_KIDS))
    return;

  OP *kid = cUNOPo->op_first;
  while(kid) {
    walk_ops_forbid(aTHX_ kid, flags, permittedloops, blockname);
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
}

#define forbid_outofblock_ops(o, blockname)  S_forbid_outofblock_ops(aTHX_ o, blockname)
static void S_forbid_outofblock_ops(pTHX_ OP *o, const char *blockname)
{
  ENTER;
  SAVEVPTR(PL_curcop);

  HV *looplabels = newHV();
  SAVEFREESV((SV *)looplabels);

  walk_ops_forbid(aTHX_ o, FORBID_LOOPEX_DEFAULT, looplabels, blockname);

  LEAVE;
}
