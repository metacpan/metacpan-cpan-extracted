#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MAGIC *
_find_mg(SV* sv) {
  MAGIC *mg;
  return mg_find(sv, 'r');
}

MODULE = Regexp::Copy     PACKAGE = Regexp::Copy

SV*
re_copy_xs(newre,re)
    SV* newre
    SV* re
PREINIT:
    SV     *sv, *othersv;
    MAGIC  *mg;
    MGVTBL *vtable = 0;
CODE:
    if (!SvROK(re)) {
        croak("re_copy needs a reference");
    }

    sv      = (SV*) SvRV(re);
    othersv = (SV*) SvRV(newre);
    mg      = _find_mg(othersv);

    if (mg) {
      mg_free( sv );
      /* ensure that we are doing the right thing for the
	 right version of Perl.  5.8.1 changed behaviour of
         qr// things to have S-magic rather than R-magic. */
      if (SvNV(PL_patchlevel) > 5.008) {
	SvSMAGICAL_on(sv);
      } else {
	SvRMAGICAL_on(sv);
      }
      /* copy the magic in mg to sv */
      sv_magicext(sv, mg->mg_obj, 'r', vtable, NULL, 0);
    } else {
        croak("no re magic currently set in re");
    }
OUTPUT:
    newre
    
