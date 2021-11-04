/* vi: set ft=c : */

#define padlist_dump_depth(pl, depth)  S_padlist_dump_depth(aTHX_ pl, depth)
static void S_padlist_dump_depth(pTHX_ PADLIST *padlist, I32 depth)
{
  fprintf(stderr, "PADLIST = %p / PAD[%d]", padlist, depth);

  PADNAMELIST *pnl = PadlistNAMES(padlist);
  PAD         *pad = PadlistARRAY(padlist)[depth];

  fprintf(stderr, " = %p\n", pad);

  PADOFFSET padix;
  for(padix = 0; padix <= PadnamelistMAX(pnl); padix++) {
    PADNAME *pn = PadnamelistARRAY(pnl)[padix];
    fprintf(stderr, "  %ld: %s", padix,
        padix == 0          ? "@_" :
        pn && PadnamePV(pn) ? PadnamePV(pn) :
                              "(--)");

    if(pn) {
      if(PadnameOUTER(pn))
        fprintf(stderr, " *OUTER");
      if(PadnameIsSTATE(pn))
        fprintf(stderr, " *STATE");
      if(PadnameLVALUE(pn))
        fprintf(stderr, " *LV");

      fprintf(stderr, " [%d..%d]",
          COP_SEQ_RANGE_LOW(pn), COP_SEQ_RANGE_HIGH(pn));
    }

    fprintf(stderr, " = %p\n", PadARRAY(pad)[padix]);
  }
}

#define padlist_dump(pl)  padlist_dump_depth(pl, 1)

#define debug_sv_summary(sv)  S_debug_sv_summary(aTHX_ sv)
static void S_debug_sv_summary(pTHX_ const SV *sv)
{
  const char *type;

  if(!sv) {
    fprintf(stderr, "NULL");
    return;
  }

  if(sv == &PL_sv_undef) {
    fprintf(stderr, "SV=undef");
    return;
  }
  if(sv == &PL_sv_no) {
    fprintf(stderr, "SV=false");
    return;
  }
  if(sv == &PL_sv_yes) {
    fprintf(stderr, "SV=true");
    return;
  }

  switch(SvTYPE(sv)) {
    case SVt_NULL: type = "NULL"; break;
    case SVt_IV:   type = "IV";   break;
    case SVt_NV:   type = "NV";   break;
    case SVt_PV:   type = "PV";   break;
    case SVt_PVIV: type = "PVIV"; break;
    case SVt_PVNV: type = "PVNV"; break;
    case SVt_PVGV: type = "PVGV"; break;
    case SVt_PVAV: type = "PVAV"; break;
    case SVt_PVHV: type = "PVHV"; break;
    case SVt_PVCV: type = "PVCV"; break;
    default: {
      char buf[16];
      sprintf(buf, "(%d)", SvTYPE(sv));
      type = buf;
      break;
    }
  }

  if(SvROK(sv))
    type = "RV";

  fprintf(stderr, "SV{type=%s,refcnt=%d", type, SvREFCNT(sv));

  if(SvTEMP(sv))
    fprintf(stderr, ",TEMP");
  if(SvOBJECT(sv))
    fprintf(stderr, ",blessed=%s", HvNAME(SvSTASH(sv)));

  switch(SvTYPE(sv)) {
    case SVt_PVAV:
      fprintf(stderr, ",FILL=%d", AvFILL((AV *)sv));
      break;

    default:
      /* regular scalars */
      if(SvROK(sv))
        fprintf(stderr, ",ROK");
      else {
        if(SvIOK(sv))
          fprintf(stderr, ",IV=%" IVdf, SvIVX(sv));
        if(SvUOK(sv))
          fprintf(stderr, ",UV=%" UVuf, SvUVX(sv));
        if(SvPOK(sv)) {
          fprintf(stderr, ",PVX=\"%.10s\"", SvPVX((SV *)sv));
          if(SvCUR(sv) > 10)
            fprintf(stderr, "...");
        }
      }
      break;
  }

  fprintf(stderr, "}");
}

#define debug_showstack(name)  S_debug_showstack(aTHX_ name)
static void S_debug_showstack(pTHX_ const char *name)
{
  SV **sp;

  fprintf(stderr, "%s:\n", name ? name : "Stack");

  PERL_CONTEXT *cx = CX_CUR();

  I32 floor = cx->blk_oldsp;
  I32 *mark = PL_markstack + cx->blk_oldmarksp + 1;

  fprintf(stderr, "  marks (TOPMARK=@%d):\n", TOPMARK - floor);
  for(; mark <= PL_markstack_ptr; mark++)
    fprintf(stderr,  "    @%d\n", *mark - floor);

  mark = PL_markstack + cx->blk_oldmarksp + 1;
  for(sp = PL_stack_base + floor + 1; sp <= PL_stack_sp; sp++) {
    fprintf(stderr, sp == PL_stack_sp ? "-> " : "   ");
    fprintf(stderr, "%p = ", *sp);
    debug_sv_summary(*sp);
    while(mark <= PL_markstack_ptr && PL_stack_base + *mark == sp)
      fprintf(stderr, " [*M]"), mark++;
    fprintf(stderr, "\n");
  }
}

#define savestack_dump()  S_savestack_dump(aTHX)
#if HAVE_PERL_VERSION(5, 30, 0)
/* TODO: For older perls we'll have to look into it in more detail */
static struct {
  const char *name;
  const char *argspec;
} saves[] = {
  [SAVEt_ALLOC]               = { "ALLOC",               "@" },
  [SAVEt_CLEARPADRANGE]       = { "CLEARPADRANGE",       "r" },
  [SAVEt_CLEARSV]             = { "CLEARSV",             "x" },
  [SAVEt_REGCONTEXT]          = { "REGCONTEXT",          "@" },
  [SAVEt_TMPSFLOOR]           = { "TMPSFLOOR",           " I" },
  [SAVEt_BOOL]                = { "BOOL",                "b*" },
  [SAVEt_COMPILE_WARNINGS]    = { "COMPILE_WARNINGS",    " p" },
  [SAVEt_COMPPAD]             = { "COMPPAD",             " *" },
  [SAVEt_FREECOPHH]           = { "FREECOPHH",           " *" },
  [SAVEt_FREEOP]              = { "FREEOP",              " o" },
  [SAVEt_FREEPV]              = { "FREEPV",              " p" },
  [SAVEt_FREESV]              = { "FREESV",              " s" },
  [SAVEt_I16]                 = { "I16",                 "i*" },
  [SAVEt_I32_SMALL]           = { "I32_SMALL",           "i*" },
  [SAVEt_I8]                  = { "I8",                  "i*" },
  [SAVEt_INT_SMALL]           = { "INT_SMALL",           "i*" },
  [SAVEt_MORTALIZESV]         = { "MORTALIZESV",         " s" },
  [SAVEt_NSTAB]               = { "NSTAB",               " s" },
  [SAVEt_OP]                  = { "OP",                  " *" },
  [SAVEt_PARSER]              = { "PARSER",              " *" },
  [SAVEt_STACK_POS]           = { "STACK_POS",           " i" },
  [SAVEt_READONLY_OFF]        = { "READONLY_OFF",        " s" },
  [SAVEt_FREEPADNAME]         = { "FREEPADNAME",         " *" },
#ifdef SAVEt_STRLEN_SMALL
  [SAVEt_STRLEN_SMALL]        = { "STRLEN_SMALL",        "i*" },
#endif
  [SAVEt_AV]                  = { "AV",                  " ga" },
  [SAVEt_DESTRUCTOR]          = { "DESTRUCTOR",          " &*" },
  [SAVEt_DESTRUCTOR_X]        = { "DESTRUCTOR_X",        " &*" },
  [SAVEt_GENERIC_PVREF]       = { "GENERIC_PVREF",       " pP" },
  [SAVEt_GENERIC_SVREF]       = { "GENERIC_SVREF",       " Ss" },
  [SAVEt_GP]                  = { "GP",                  " g*" },
  [SAVEt_GVSV]                = { "GVSV",                " gs" },
  [SAVEt_HINTS]               = { "HINTS",               " T*" },
  [SAVEt_HPTR]                = { "HPTR",                " sS" },
  [SAVEt_HV]                  = { "HV",                  " gh" },
  [SAVEt_I32]                 = { "I32",                 " i*" },
  [SAVEt_INT]                 = { "INT",                 " ip" },
  [SAVEt_ITEM]                = { "ITEM",                " ss" },
  [SAVEt_IV]                  = { "IV",                  " I*" },
  [SAVEt_LONG]                = { "LONG",                " *l" },
  [SAVEt_PPTR]                = { "PPTR",                " pP" },
  [SAVEt_SAVESWITCHSTACK]     = { "SAVESWITCHSTACK",     " aa" },
  [SAVEt_SHARED_PVREF]        = { "SHARED_PVREF",        " Pp" },
  [SAVEt_SPTR]                = { "SPTR",                " sS" },
  [SAVEt_STRLEN]              = { "STRLEN",              " I*" },
  [SAVEt_SV]                  = { "SV",                  " gs" },
  [SAVEt_SVREF]               = { "SVREF",               " Ss" },
  [SAVEt_VPTR]                = { "VPTR",                " **" },
  [SAVEt_ADELETE]             = { "ADELETE",             " ia" },
  [SAVEt_APTR]                = { "APTR",                " sS" },
  [SAVEt_HELEM]               = { "HELEM",               " hss" },
  [SAVEt_PADSV_AND_MORTALIZE] = { "PADSV_AND_MORTALIZE", " s*U" },
  [SAVEt_SET_SVFLAGS]         = { "SET_SVFLAGS",         " suu" },
  [SAVEt_GVSLOT]              = { "GVSLOT",              " gSs" },
  [SAVEt_AELEM]               = { "AELEM",               " aIs" },
  [SAVEt_DELETE]              = { "DELETE",              " pih" },
#ifdef SAVEt_HINTS_HH
  [SAVEt_HINTS_HH]            = { "HINTS_HH",            " T*h" },
#endif
};

static void S_savestack_dump(pTHX)
{
  fprintf(stderr, "PL_savestack begins at [idx=%d]:\n", PL_savestack_ix-1);

  I32 ix;
  for(ix = PL_savestack_ix-1; ix >= 0; /* */) {
    UV uv = PL_savestack[ix].any_uv;
    U8 type = uv & SAVE_MASK;

    if(type >= sizeof(saves)/sizeof(saves[0])) {
      fprintf(stderr, "ARGH: (save%d) unrecognised\n", type);
      return;
    }

    const char *argspec = saves[type].argspec;
    fprintf(stderr, "  [%d] SAVEt_%s:", ix, saves[type].name);
    if(!argspec[0]) { croak("ARG argspec"); }

    switch(*(argspec++)) {
      case ' ':
        break;
      case '@':
        /* the UV explains how many additional stack slots are consumed as a
         * temporary buffer */
        fprintf(stderr, " buf=<%ld>\n", (UV)(uv >> SAVE_TIGHT_SHIFT));
        ix--;
        ix -= (UV)(uv >> SAVE_TIGHT_SHIFT);
        continue;
      case 'b':
        fprintf(stderr, " bool=%s", (uv >> 8) ? "true" : "false");
        break;
      case 'r':
        fprintf(stderr, " padix=%ld count=%ld",
            (UV)(uv >> (OPpPADRANGE_COUNTSHIFT + SAVE_TIGHT_SHIFT)), (uv >> SAVE_TIGHT_SHIFT) & OPpPADRANGE_COUNTMASK);
        break;
      case 'i':
        fprintf(stderr, " i=%d", (I32)(uv >> SAVE_TIGHT_SHIFT));
        break;
      case 'x':
        fprintf(stderr, " padix=%ld", (UV)(uv >> SAVE_TIGHT_SHIFT));
        break;
    }

    int args = strlen(argspec);

    ix -= args;
    ANY *ap = &PL_savestack[ix];

    ix--;

    I32 hints;

    while(*argspec) {
      switch(*(argspec++)) {
        case '&':
          fprintf(stderr, " fptr=%p", ap->any_ptr); break;
        case '*':
          fprintf(stderr, " ptr=%p", ap->any_ptr); break;
        case 'a':
          fprintf(stderr, " av=%p", ap->any_av); break;
        case 'g':
          fprintf(stderr, " gv=%p", ap->any_gv); break;
        case 'h':
          fprintf(stderr, " hv=%p", ap->any_hv); break;
        case 'i':
          fprintf(stderr, " i32=%d", ap->any_i32); break;
        case 'I':
          fprintf(stderr, " iv=%ld", ap->any_iv); break;
        case 'l':
          fprintf(stderr, " long=%ld", ap->any_long); break;
        case 'o':
          fprintf(stderr, " op=%p", ap->any_op); break;
        case 'p':
          fprintf(stderr, " pv=%p", ap->any_pv); break;
        case 'P':
          fprintf(stderr, " pvp=%p", ap->any_pv); break;
        case 's':
          fprintf(stderr, " sv=%p", ap->any_sv); break;
        case 'S':
          fprintf(stderr, " svp=%p", ap->any_svp); break;
        case 'T':
          /* The value of PL_hints in SAVEt_HINTS is i32 but we need to save it */
          fprintf(stderr, " hints=0x%x", hints = ap->any_i32);
          if(hints & HINT_LOCALIZE_HH)
            fprintf(stderr, "+HH");
          break;
        case 'u':
          fprintf(stderr, " u32=%lu", (unsigned long)ap->any_u32); break;
        case 'U':
          fprintf(stderr, " uv=%lu", ap->any_uv); break;
      }
      ap++;
    }

    if(type == SAVEt_HINTS && (hints & HINT_LOCALIZE_HH)) {
      /* In this case, the savestack will contain an extra pointer */
      fprintf(stderr, " hv=%p", PL_savestack[ix--].any_sv);
    }

    fprintf(stderr, "\n");
  }
}
#endif

#define debug_print_cxstack()  S_debug_print_cxstack(aTHX)
static void S_debug_print_cxstack(pTHX)
{
  int cxix;
  for(cxix = cxstack_ix; cxix; cxix--) {
    char *name = "?";
    PERL_CONTEXT *cx = &cxstack[cxix];

    switch(CxTYPE(cx)) {
      case CXt_SUB:        name = "CXt_SUB";        break;
      case CXt_BLOCK:      name = "CXt_BLOCK";      break;
      case CXt_EVAL:       name = "CXt_EVAL";       break;
      case CXt_LOOP_PLAIN: name = "CXt_LOOP_PLAIN"; break;
      case CXt_LOOP_ARY:   name = "CXt_LOOP_ARY";   break;
      default: fprintf(stderr, "[type=%d]", CxTYPE(cx)); break;
    }
    fprintf(stderr, "  *-[%d] %s", cxix, name);
    switch(CxTYPE(cx)) {
      case CXt_SUB: {
        CV *cv = cx->blk_sub.cv;
        fprintf(stderr, "(&%s ret=%p)", SvPV_nolen(cv_name(cv, 0, 0)), cx->blk_sub.retop);
      }
      break;
      case CXt_EVAL:
        fprintf(stderr, "(%s)", cx->blk_eval.cur_top_env == PL_top_env ? "top" : "!TOP");
        break;
    }
    fprintf(stderr, "\n");
  }
}
