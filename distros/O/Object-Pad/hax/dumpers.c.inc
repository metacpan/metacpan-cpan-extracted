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

static void debug_sv_summary(const SV *sv)
{
  const char *type;

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

  fprintf(stderr, "}");
}

static void debug_showstack(const char *name)
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
  { "ALLOC",               "@" },
  { "CLEARPADRANGE",       "r" },
  { "CLEARSV",             "x" },
  { "REGCONTEXT",          "@" },
  { "TMPSFLOOR",           " I" },
  { "BOOL",                "b*" },
  { "COMPILE_WARNINGS",    " p" },
  { "COMPPAD",             " *" },
  { "FREECOPHH",           " *" },
  { "FREEOP",              " o" },
  { "FREEPV",              " p" },
  { "FREESV",              " s" },
  { "I16",                 "i*" },
  { "I32_SMALL",           "i*" },
  { "I8",                  "i*" },
  { "INT_SMALL",           "i*" },
  { "MORTALIZESV",         " s" },
  { "NSTAB",               " s" },
  { "OP",                  " *" },
  { "PARSER",              " *" },
  { "STACK_POS",           " i" },
  { "READONLY_OFF",        " s" },
  { "FREEPADNAME",         " *" },
  { "AV",                  " ga" },
  { "DESTRUCTOR",          " &*" },
  { "DESTRUCTOR_X",        " &*" },
  { "GENERIC_PVREF",       " pP" },
  { "GENERIC_SVREF",       " Ss" },
  { "GP",                  " g*" },
  { "GVSV",                " gs" },
  { "HINTS",               " T*" },
  { "HPTR",                " sS" },
  { "HV",                  " gh" },
  { "I32",                 " i*" },
  { "INT",                 " ip" },
  { "ITEM",                " ss" },
  { "IV",                  " I*" },
  { "LONG",                " *l" },
  { "PPTR",                " pP" },
  { "SAVESWITCHSTACK",     " aa" },
  { "SHARED_PVREF",        " Pp" },
  { "SPTR",                " sS" },
  { "STRLEN",              " I*" },
  { "SV",                  " gs" },
  { "SVREF",               " Ss" },
  { "VPTR",                " **" },
  { "ADELETE",             " ia" },
  { "APTR",                " sS" },
  { "HELEM",               " hss" },
  { "PADSV_AND_MORTALIZE", " s*U" },
  { "SET_SVFLAGS",         " suu" },
  { "GVSLOT",              " gSs" },
  { "AELEM",               " aIs" },
  { "DELETE",              " pih" }
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
      case ' ': break;
      case '@':
        /* the UV explains how many additional stack slots are consumed as a
         * temporary buffer */
        fprintf(stderr, " buf=<%ld>\n", (UV)(uv >> SAVE_TIGHT_SHIFT));
        ix--;
        ix -= (UV)(uv >> SAVE_TIGHT_SHIFT);
        continue;
      case 'b':
        fprintf(stderr, " bool=%s", (uv >> 8) ? "true" : "false"); break;
      case 'r':
        fprintf(stderr, " padix=%ld count=%ld",
            (UV)(uv >> (OPpPADRANGE_COUNTSHIFT + SAVE_TIGHT_SHIFT)), (uv >> SAVE_TIGHT_SHIFT) & OPpPADRANGE_COUNTMASK);
        break;
      case 'i':
        fprintf(stderr, " i=%d", (I32)(uv >> SAVE_TIGHT_SHIFT)); break;
      case 'x':
        fprintf(stderr, " padix=%ld", (UV)(uv >> SAVE_TIGHT_SHIFT)); break;
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
