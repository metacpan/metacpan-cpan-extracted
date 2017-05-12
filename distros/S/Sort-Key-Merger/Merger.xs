#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static I32
sv_icmp(pTHX_ SV *a, SV *b) {
    IV iv1 = SvIV(a);
    IV iv2 = SvIV(b);
    return iv1 < iv2 ? -1 : iv1 > iv2 ? 1 : 0;
}

static I32
sv_ncmp(pTHX_ SV *a, SV *b) {
    NV nv1 = SvNV(a);
    NV nv2 = SvNV(b);
    return nv1 < nv2 ? -1 : nv1 > nv2 ? 1 : 0;
}



/* WARNING: _resort(type, src) does NOT check if its arguments are
 * properly structured, neither it does support magic on them!,
 * calling module has to ensure that these conditions are meet */



MODULE = Sort::Key::Merger		PACKAGE = Sort::Key::Merger		
PROTOTYPES: DISABLE

#define SRCIJ(i, j) ((AvARRAY((AV*)(SvRV(srci[i]))))[j])


void
_resort(I32 type, AV *src)
PREINIT:
    I32 (*cmp)(pTHX_ SV *, SV *);
    int min, max, pv;
    SV **srci, **src0j, *k0, *i0;
    SV *src0;
PPCODE:
    switch (type) {
    case 0:
        cmp=&Perl_sv_cmp;
        break;
    case 1:
        cmp=&Perl_sv_cmp_locale;
        break;
    case 2:
        cmp=&sv_ncmp;
        break;
    case 3:
        cmp=&sv_icmp;
        break;
    }
    max=av_len(src);
    if (max>0) {
	min=0;
	srci = AvARRAY(src);
	src0 = srci[0];
	src0j = AvARRAY((AV*)(SvRV(src0)));
	k0 = src0j[0];
	/* Perl_warn(aTHX_ "s: 0 (%_, %_), min %d, max %d\n",
	             k0, SRCIJ(0, 1), min, max); */
	for (pv=1; min<max; pv=(max+min+1)>>1) {
	    SV **srcpvj = AvARRAY((AV*)(SvRV(srci[pv])));
	    I32 c=(*cmp)(aTHX_ k0, srcpvj[0]);
	    if (c<0) {
		max=pv-1;
	    }
	    else if (c>0) {
		min=pv;
	    }
	    else {
		int i0 = SvIV(src0j[1]);
		int ipv = SvIV(srcpvj[1]);
		if (i0>ipv) {
		    min=pv;
		}
		else {
		    max=pv-1;
		}
	    }
	    /* Perl_warn(aTHX_ "pv: %d (%_, %_), min %d, max %d\n",
                         pv, SRCIJ(pv, 0), SRCIJ(pv, 1), min, max); */
	}
	if (min>0) {
	    int i;
	    for (i=0; i<min; i++) {
		srci[i]=srci[i+1];
	    }
	    srci[min]=src0;
	}
    }
