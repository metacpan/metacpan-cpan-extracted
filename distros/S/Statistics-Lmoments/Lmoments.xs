#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "lmoments/lmoments.h"
#include "arrays.h"   /* Pack functions decs */
#include "arrays.c"   /* Pack functions defs */

AV *x2av(double *x, int n)
{
	int i;
	AV *av = newAV();
	if (!av) return NULL;
	for (i=0; i<n; i++) {
		SV *sv = newSVnv(x[i]);
		if (!sv) {
			fprintf(stderr,"Out of memory!\n");
			break;
		}
		av_push(av, sv);
	}
	return av;
}

MODULE = Statistics::Lmoments		PACKAGE = Statistics::Lmoments

AV *
csamlmr(x, n, nmom, a, b)
	double *x
	int n
	int nmom
	double a
	double b
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			csamlmr(x, n, xmom, nmom, a, b);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
csamlmu(x, n, nmom)
	double *x
	int n
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			csamlmu(x, n, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
csampwm(x, n, nmom, a, b, kind)
	double *x
	int n
	int nmom
	double a
	double b
	int kind
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			csampwm(x, n, xmom, nmom, a, b, kind);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfexp(x, para)
	double *x
	double *para

double
cquaexp(f, para)
	double *f
	double *para

AV *
_clmrexp(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrexp(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelexp(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(2,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			cpelexp(xmom, para);
			ret = x2av(para, 2);
			free(para);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfgam(x, para)
	double *x
	double *para

double
cquagam(f, para)
	double *f
	double *para

AV *
clmrgam(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrgam(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelgam(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(2,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			cpelgam(xmom, para);
			ret = x2av(para, 2);
			free(para);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfgev(x, para)
	double *x
	double *para

double
cquagev(f, para)
	double *f
	double *para

AV *
clmrgev(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrgev(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelgev(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(3,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			cpelgev(xmom, para);
			ret = x2av(para, 3);
			free(para);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfglo(x, para)
	double *x
	double *para

double
cquaglo(f, para)
	double *f
	double *para

AV *
clmrglo(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrglo(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelglo(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(3,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			cpelglo(xmom, para);
			ret = x2av(para, 3);
			free(para);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfgno(x, para)
	double *x
	double *para

double
cquagno(f, para)
	double *f
	double *para

AV *
clmrgno(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrgno(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelgno(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(3,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			cpelgno(xmom, para);
			ret = x2av(para, 3);
			free(para);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfgpa(x, para)
	double *x
	double *para

double
cquagpa(f, para)
	double *f
	double *para

AV *
clmrgpa(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrgpa(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelgpa(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(3,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			cpelgpa(xmom, para);
			ret = x2av(para, 3);
			free(para);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfgum(x, para)
	double *x
	double *para

double
cquagum(f, para)
	double *f
	double *para

AV *
clmrgum(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrgum(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelgum(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(2,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			cpelgum(xmom, para);
			ret = x2av(para, 2);
			free(para);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfkap(x, para)
	double *x
	double *para

double
cquakap(f, para)
	double *f
	double *para

AV *
clmrkap(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrkap(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelkap(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(4,sizeof(double));
		int i, ifail;
		AV *ret = NULL;
		if (xmom) {
			cpelkap(xmom, para, &ifail);
			ret = x2av(para, 4);
			free(para);
			if (ret) {
				SV *sv = newSViv(ifail);
				if (!sv)
					fprintf(stderr,"Out of memory!\n");
				else
					av_push(ret, sv);
			}
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfnor(x, para)
	double *x
	double *para

double
cquanor(f, para)
	double *f
	double *para

AV *
clmrnor(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrnor(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelnor(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(2,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			cpelnor(xmom, para);
			ret = x2av(para, 2);
			free(para);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfpe3(x, para)
	double *x
	double *para

double
cquape3(f, para)
	double *f
	double *para

AV *
clmrpe3(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrpe3(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelpe3(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(3,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			cpelpe3(xmom, para);
			ret = x2av(para, 3);
			free(para);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

double
ccdfwak(x, para)
	double *x
	double *para

double
cquawak(f, para)
	double *f
	double *para

AV *
clmrwak(para, nmom)
	double *para
	int nmom
	CODE:
	{
		double *xmom = (double *)calloc(nmom,sizeof(double));
		int i;
		AV *ret = NULL;
		if (xmom) {
			clmrwak(para, xmom, nmom);
			ret = x2av(xmom, nmom);
			free(xmom);
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL

AV *
cpelwak(xmom)
	double *xmom
	CODE:
	{
		double *para = (double *)calloc(5,sizeof(double));
		int i, ifail;
		AV *ret = NULL;
		if (xmom) {
			cpelwak(xmom, para, &ifail);
			ret = x2av(para, 5);
			free(para);
			if (ret) {
				SV *sv = newSViv(ifail);
				if (!sv)
					fprintf(stderr,"Out of memory!\n");
				else
					av_push(ret, sv);
			}
		} else {
			fprintf(stderr,"Out of memory!\n");
		}
		RETVAL = ret;
	}
  OUTPUT:
    RETVAL
