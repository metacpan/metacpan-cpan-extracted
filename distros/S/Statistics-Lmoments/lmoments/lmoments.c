#include <stdio.h>
#include "lmoments.h"

void csamlmr(double *x, int n, double *xmom, int nmom, double a, double b)
{
	samlmr_(x, &n, xmom, &nmom, &a, &b);
}

void csamlmu(double *x, int n, double *xmom, int nmom)
{
	samlmu_(x, &n, xmom, &nmom);
}

void csampwm(double *x, int n, double *xmom, int nmom, double a, double b, int kind)
{
	sampwm_(x, &n, xmom, &nmom, &a, &b, &kind);
}

double ccdfexp(double *x, double *para)
{
	return cdfexp_(x, para);
}

double cquaexp(double *f, double *para)
{
	return quaexp_(f, para);
}

void clmrexp(double *para, double *xmom, int nmom)
{
	lmrexp_(para, xmom, &nmom);
}

void cpelexp(double *xmom, double *para)
{
	pelexp_(xmom, para);
}

double ccdfgam(double *x, double *para)
{
	return cdfgam_(x, para);
}

double cquagam(double *f, double *para)
{
	return quagam_(f, para);
}

void clmrgam(double *para, double *xmom, int nmom)
{
	lmrgam_(para, xmom, &nmom);
}

void cpelgam(double *xmom, double *para)
{
	pelgam_(xmom, para);
}

double ccdfgev(double *x, double *para)
{
	return cdfgev_(x, para);
}

double cquagev(double *f, double *para)
{
	return quagev_(f, para);
}

void clmrgev(double *para, double *xmom, int nmom)
{
	lmrgev_(para, xmom, &nmom);
}

void cpelgev(double *xmom, double *para)
{
	pelgev_(xmom, para);
}

double ccdfglo(double *x, double *para)
{
	return cdfglo_(x, para);
}

double cquaglo(double *f, double *para)
{
	return quaglo_(f, para);
}

void clmrglo(double *para, double *xmom, int nmom)
{
	lmrglo_(para, xmom, &nmom);
}

void cpelglo(double *xmom, double *para)
{
	pelglo_(xmom, para);
}

double ccdfgno(double *x, double *para)
{
	return cdfgno_(x, para);
}

double cquagno(double *f, double *para)
{
	return quagno_(f, para);
}

void clmrgno(double *para, double *xmom, int nmom)
{
	lmrgno_(para, xmom, &nmom);
}

void cpelgno(double *xmom, double *para)
{
	pelgno_(xmom, para);
}

double ccdfgpa(double *x, double *para)
{
	return cdfgpa_(x, para);
}

double cquagpa(double *f, double *para)
{
	return quagpa_(f, para);
}

void clmrgpa(double *para, double *xmom, int nmom)
{
	lmrgpa_(para, xmom, &nmom);
}

void cpelgpa(double *xmom, double *para)
{
	pelgpa_(xmom, para);
}

double ccdfgum(double *x, double *para)
{
	return cdfgum_(x, para);
}

double cquagum(double *f, double *para)
{
	return quagum_(f, para);
}

void clmrgum(double *para, double *xmom, int nmom)
{
	lmrgum_(para, xmom, &nmom);
}

void cpelgum(double *xmom, double *para)
{
	pelgum_(xmom, para);
}

double ccdfkap(double *x, double *para)
{
	return cdfkap_(x, para);
}

double cquakap(double *f, double *para)
{
	return quakap_(f, para);
}

void clmrkap(double *para, double *xmom, int nmom)
{
	lmrkap_(para, xmom, &nmom);
}

void cpelkap(double *xmom, double *para, int *ifail)
{
	pelkap_(xmom, para, ifail);
}

double ccdfnor(double *x, double *para)
{
	return cdfnor_(x, para);
}

double cquanor(double *f, double *para)
{
	return quanor_(f, para);
}

void clmrnor(double *para, double *xmom, int nmom)
{
	lmrnor_(para, xmom, &nmom);
}

void cpelnor(double *xmom, double *para)
{
	pelnor_(xmom, para);
}

double ccdfpe3(double *x, double *para)
{
	return cdfpe3_(x, para);
}

double cquape3(double *f, double *para)
{
	return quape3_(f, para);
}

void clmrpe3(double *para, double *xmom, int nmom)
{
	lmrpe3_(para, xmom, &nmom);
}

void cpelpe3(double *xmom, double *para)
{
	pelpe3_(xmom, para);
}

double ccdfwak(double *x, double *para)
{
	return cdfwak_(x, para);
}

double cquawak(double *f, double *para)
{
	return quawak_(f, para);
}

void clmrwak(double *para, double *xmom, int nmom)
{
	lmrwak_(para, xmom, &nmom);
}

void cpelwak(double *xmom, double *para, int *ifail)
{
	pelwak_(xmom, para, ifail);
}
