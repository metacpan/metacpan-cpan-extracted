/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static char *sv_typename(U8 svt)
{
  switch(svt) {
    case SVt_NULL:
      return "NULL";
    case SVt_IV:
    case SVt_NV:
    case SVt_PV:
    case SVt_PVIV:
    case SVt_PVNV:
    case SVt_PVMG:
#if PERL_VERSION < 12
    /* SVt_RV was removed after 5.10 */
    case SVt_RV:
#endif
      return "SCALAR";
#if PERL_VERSION >= 12
    /* SVt_REGEXP was added in perl 5.12 */
    case SVt_REGEXP:
      return "REGEXP";
#endif
    case SVt_PVGV:
      return "GLOB";
    case SVt_PVAV:
      return "ARRAY";
    case SVt_PVHV:
      return "HASH";
    case SVt_PVCV:
      return "CODE";
    case SVt_PVFM:
      return "FORMAT";
    case SVt_PVIO:
      return "IO";
#if PERL_VERSION >= 20
    /* SVt_INVLIST was added in perl 5.20 */
    case SVt_INVLIST:
      return "INVLIST";
#endif
    default:
      return "UNKNOWN";
  }
}

MODULE = Net::Prometheus::PerlCollector    PACKAGE = Net::Prometheus::PerlCollector

void
count_heap(detail)
    int detail
INIT:
    SV *arena;
    STRLEN arenas = 0, svs = 0;
    HV *svs_by_type = NULL, *svs_by_class = NULL;
PPCODE:
    if(detail)
      svs_by_type = newHV();
    if(detail > 1)
      svs_by_class = newHV();

    for(arena = PL_sv_arenaroot; arena; arena = (SV *)SvANY(arena)) {
      const SV *arenaend = &arena[SvREFCNT(arena)];
      SV *sv;

      arenas++;

      for(sv = arena + 1; sv < arenaend; sv++)
        if(SvTYPE(sv) != 0xFF && SvREFCNT(sv)) {
          svs++;

          if(svs_by_type) {
            char *type = sv_typename(SvTYPE(sv));
            SV **countp = hv_fetch(svs_by_type, type, strlen(type), 1);
            sv_setiv(*countp, SvIOK(*countp) ? SvIV(*countp) + 1 : 1);

            if(svs_by_class && SvOBJECT(sv)) {
              char *class = HvNAME(SvSTASH(sv));
              SV **countp = hv_fetch(svs_by_class, class, strlen(class), 1);
              sv_setiv(*countp, SvIOK(*countp) ? SvIV(*countp) + 1 : 1);
            }
          }
        }
    }

    EXTEND(SP, 4);
    mPUSHu(arenas);
    mPUSHu(svs);
    if(svs_by_type)
      mPUSHs(newRV_noinc((SV *)svs_by_type));
    if(svs_by_class)
      mPUSHs(newRV_noinc((SV *)svs_by_class));
    XSRETURN(2 + !!svs_by_type + !!svs_by_class);
