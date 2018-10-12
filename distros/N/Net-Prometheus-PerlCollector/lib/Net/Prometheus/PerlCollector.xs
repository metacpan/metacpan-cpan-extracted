/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Net::Prometheus::PerlCollector    PACKAGE = Net::Prometheus::PerlCollector

void
count_heap()
INIT:
    SV *arena;
    STRLEN arenas = 0, svs = 0;
CODE:
    for(arena = PL_sv_arenaroot; arena; arena = (SV *)SvANY(arena)) {
      const SV *arenaend = &arena[SvREFCNT(arena)];
      SV *sv;

      arenas++;

      for(sv = arena + 1; sv < arenaend; sv++)
        if(SvTYPE(sv) != 0xFF && SvREFCNT(sv))
          svs++;
    }

    EXTEND(SP, 2);
    mPUSHu(arenas);
    mPUSHu(svs);
    XSRETURN(2);
