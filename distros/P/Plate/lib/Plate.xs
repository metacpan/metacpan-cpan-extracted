#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = Plate		PACKAGE = Plate		

PROTOTYPES: ENABLE

void
_local_vars(package,hashref)
	char * package
	HV   * hashref
ALIAS:
	_local_args = 1
CODE:
	char * key;
	I32 klen, nlen;
	SV * val, * name = sv_2mortal(newSVpv(package, 0));
	HV * stash = gv_stashsv(name, GV_ADD);

	sv_catpvn(name, "::", 2);
	nlen = SvCUR(name);

	LEAVE;	/* Operate at a higher level */

	(void)hv_iterinit(hashref);
	while ((val = hv_iternextsv(hashref, &key, &klen))) {
		GV * gv;
		int stype;
		bool constant = FALSE;

		if (SvROK(val)) {
			SV * tmp = SvRV(val);
			stype = SvTYPE(tmp);
			if (stype == SVt_PVGV)
				val = tmp;
			else if (ix && (stype < SVt_PVAV || stype > SVt_PVCV)) {
				goto new_ref;
			}
		}
		else if ((stype = SvTYPE(val)) != SVt_PVGV) {
			if (ix) {
				new_ref:
				val = sv_2mortal(newRV(val));
			} else {
				constant = TRUE;
			}
		}

		if (klen > 1 && (*key == '$' || *key == '@' || *key == '%' || *key == '&' || *key == '*')) {
			key++;
			klen--;
		}
		sv_catpvn(name, key, klen);
		gv = gv_fetchpvn_flags(SvPVX(name), nlen + klen, GV_ADDMULTI | SvUTF8(name), SVt_PVGV);
		SvCUR_set(name, nlen);

		save_gp(gv, stype == SVt_PVGV);
		if (constant)
			newCONSTSUB_flags(stash, key, klen, 0, SvOK(val) ? SvREFCNT_inc_simple(val) : NULL);
		else
			SvSetMagicSV((SV*)gv, val);	/* Alias the SV */
	}

	ENTER;	/* In lieu of the LEAVE above */
