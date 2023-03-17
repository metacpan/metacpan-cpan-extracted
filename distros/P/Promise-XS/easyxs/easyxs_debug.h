#ifndef EASYXS_DEBUG_H
#define EASYXS_DEBUG_H 1

#include "init.h"

/* The following is courtesy of Paul Evans: */

#define exs_debug_sv_summary(sv)  S_debug_sv_summary(aTHX_ sv)

/* ------------------------------------------------------------ */

static inline void S_debug_sv_summary(pTHX_ const SV *sv)
{
  const char *type;

  if(!sv) {
    PerlIO_printf(Perl_debug_log, "NULL");
    return;
  }

  if(sv == &PL_sv_undef) {
    PerlIO_printf(Perl_debug_log, "SV=undef");
    return;
  }
  if(sv == &PL_sv_no) {
    PerlIO_printf(Perl_debug_log, "SV=false");
    return;
  }
  if(sv == &PL_sv_yes) {
    PerlIO_printf(Perl_debug_log, "SV=true");
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
      snprintf(buf, sizeof(buf), "(%d)", SvTYPE(sv));
      type = buf;
      break;
    }
  }

  if(SvROK(sv))
    type = "RV";

  PerlIO_printf(Perl_debug_log, "SV{type=%s,refcnt=%" IVdf, type, (IV) SvREFCNT(sv));

  if(SvTEMP(sv))
    PerlIO_printf(Perl_debug_log, ",TEMP");
  if(SvOBJECT(sv))
    PerlIO_printf(Perl_debug_log, ",blessed=%s", HvNAME(SvSTASH(sv)));

  switch(SvTYPE(sv)) {
    case SVt_PVAV:
      PerlIO_printf(Perl_debug_log, ",FILL=%d", (int) AvFILL((AV *)sv));
      break;

    default:
      /* regular scalars */
      if(SvROK(sv))
        PerlIO_printf(Perl_debug_log, ",ROK");
      else {
        if(SvIOK(sv))
          PerlIO_printf(Perl_debug_log, ",IV=%" IVdf, SvIVX(sv));
        if(SvUOK(sv))
          PerlIO_printf(Perl_debug_log, ",UV=%" UVuf, SvUVX(sv));
        if(SvPOK(sv)) {
          PerlIO_printf(Perl_debug_log, ",PVX=\"%.10s\"", SvPVX((SV *)sv));
          if(SvCUR(sv) > 10)
            PerlIO_printf(Perl_debug_log, "...");
        }
      }
      break;
  }

  PerlIO_printf(Perl_debug_log, "}");
}

#ifdef CX_CUR

#define exs_debug_showstack(pattern, ...)  S_debug_showstack(aTHX_ pattern, ##__VA_ARGS__)

static inline void S_debug_showstack(pTHX_ const char *pattern, ...)
{
  SV **sp;

  va_list ap;
  va_start(ap, pattern);

  if (!pattern) pattern = "Stack";

  PerlIO_vprintf(Perl_debug_log, pattern, ap);
  PerlIO_printf(Perl_debug_log, "\n");
  va_end(ap);

  PERL_CONTEXT *cx = CX_CUR();

  I32 floor = cx->blk_oldsp;
  I32 *mark = PL_markstack + cx->blk_oldmarksp + 1;

  PerlIO_printf(Perl_debug_log, "  TOPMARK=%d, floor = %d\n", (int) TOPMARK, (int) floor);
  PerlIO_printf(Perl_debug_log, "  marks (TOPMARK=@%" IVdf "):\n", (IV) (TOPMARK - floor));
  for(; mark <= PL_markstack_ptr; mark++)
    PerlIO_printf(Perl_debug_log,  "    @%" IVdf "\n", (IV) (*mark - floor));

  mark = PL_markstack + cx->blk_oldmarksp + 1;
  for(sp = PL_stack_base + floor + 1; sp <= PL_stack_sp; sp++) {
    PerlIO_printf(Perl_debug_log, sp == PL_stack_sp ? "-> " : "   ");
    PerlIO_printf(Perl_debug_log, "%p = ", *sp);
    S_debug_sv_summary(aTHX_ *sp);
    while(mark <= PL_markstack_ptr && PL_stack_base + *mark == sp)
      PerlIO_printf(Perl_debug_log, " [*M]"), mark++;
    PerlIO_printf(Perl_debug_log, "\n");
  }
}
#endif

/*
void static inline exs_debug_showmark_stack(pTHX) {
    PerlIO_printf(Perl_debug_log, "MARK STACK (start=%p; cur=%p, offset=%d):\n", PL_markstack, PL_markstack_ptr, (int) (PL_markstack_ptr - PL_markstack));
    I32 *mp = PL_markstack;
    while (mp != PL_markstack_max) {
        const char* pattern = (mp == PL_markstack_ptr ? "[%d]" : "%d");
        PerlIO_printf(Perl_debug_log, pattern, *mp++);
        PerlIO_printf(Perl_debug_log, (mp == PL_markstack_max) ? "\n" : ",");
    }
}
*/

#endif
