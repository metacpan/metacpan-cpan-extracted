#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "sys/loadavg.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_LOADAVG_1(char *name, int len, int arg)
{
    switch (name[9 + 0]) {
    case '5':
	if (strEQ(name + 9, "5MIN")) {	/* LOADAVG_1 removed */
#ifdef LOADAVG_15MIN
	    return LOADAVG_15MIN;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 9, "MIN")) {	/* LOADAVG_1 removed */
#ifdef LOADAVG_1MIN
	    return LOADAVG_1MIN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    if (0 + 8 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[0 + 8]) {
    case '1':
	if (!strnEQ(name + 0,"LOADAVG_", 8))
	    break;
	return constant_LOADAVG_1(name, len, arg);
    case '5':
	if (strEQ(name + 0, "LOADAVG_5MIN")) {	/*  removed */
#ifdef LOADAVG_5MIN
	    return LOADAVG_5MIN;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 0, "LOADAVG_NSTATS")) {	/*  removed */
#ifdef LOADAVG_NSTATS
	    return LOADAVG_NSTATS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Solaris::loadavg		PACKAGE = Solaris::loadavg		

double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

void
loadavg(nelem=LOADAVG_NSTATS)
   int nelem;
PREINIT:
   double *loadavg;
   int     rc, i;
PPCODE:
   if (nelem > 3 || nelem < 1)
      croak("invalid nelem (%d)", nelem);
   New(0, loadavg, sizeof(double)*nelem, double);
   if ((rc = getloadavg(loadavg, nelem)) != nelem)
      croak("getloadavg failed (%d)", rc);
   EXTEND(SP, nelem);
   for(i=0; i<nelem; i++)
      PUSHs(sv_2mortal(newSVnv(loadavg[i])));
