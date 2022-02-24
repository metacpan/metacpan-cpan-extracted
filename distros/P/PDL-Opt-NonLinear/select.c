#include "EXTERN.h"
#include "perl.h"
#include "pdl.h"
#include "pdlcore.h"
#include "asa.h"

#define PDL PDL_Opt_NonLinear
extern Core *PDL;

typedef int logical;
typedef logical integer;
typedef logical ftnlen;
#ifdef __cplusplus
typedef float (*paramf)(...);
typedef double (*paramd)(...);
typedef void (*paramv)(...);
#else
typedef float (*paramf)();
typedef double (*paramd)();
typedef void (*paramv)();
#endif

pdl    *pdl1, *pdl2, *pdl3, *pdl4, *pdl5;
SV    *sv_pdl1, *sv_pdl2, *sv_pdl3, *sv_pdl4, *sv_pdl5;

SV*   pdl4_function;
void dpdl4_wrapper(
		PDL_Indx m, double *a,
		PDL_Indx n, double *b,
		PDL_Indx o, PDL_Indx *c,
		PDL_Indx p, double *d)
{

   dSP ;

   int ret ;

   PDL_Indx odims[1];

   PDL_Indx adims[] = {m};
   PDL_Indx bdims[] = {n};
   PDL_Indx cdims[] = {o};
   PDL_Indx ddims[] = {p};

   PDL->setdims (pdl1, adims, 1);
   PDL->setdims (pdl2, bdims, 1);
   PDL->setdims (pdl3, cdims, 1);
   PDL->setdims (pdl4, ddims, 1);

   pdl1->datatype = PDL_D;
   pdl1->data = a;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl2->datatype = PDL_D;
   pdl2->data = b;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl3->datatype = PDL_L;
   pdl3->data = c;
   pdl3->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl4->datatype = PDL_D;
   pdl4->data = d;
   pdl4->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   XPUSHs(sv_pdl3);
   XPUSHs(sv_pdl4);
   PUTBACK ;

   ret = perl_call_sv(pdl4_function, G_SCALAR);

   SPAGAIN;

   if (ret !=1)
      croak("Error calling perl function\n");

   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PDL->setdims (pdl3, odims, 0);
   pdl3->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl3->data=NULL;

   PDL->setdims (pdl4, odims, 0);
   pdl4->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl4->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;
}

void fpdl4_wrapper(
		PDL_Indx m, float *a,
		PDL_Indx n, float *b,
		PDL_Indx o, PDL_Indx *c,
		PDL_Indx p, float *d)
{

   dSP ;

   int ret ;

   PDL_Indx odims[1];

   PDL_Indx adims[] = {m};
   PDL_Indx bdims[] = {n};
   PDL_Indx cdims[] = {o};
   PDL_Indx ddims[] = {p};

   PDL->setdims (pdl1, adims, 1);
   PDL->setdims (pdl2, bdims, 1);
   PDL->setdims (pdl3, cdims, 1);
   PDL->setdims (pdl4, ddims, 1);

   pdl1->datatype = PDL_F;
   pdl1->data = a;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl2->datatype = PDL_F;
   pdl2->data = b;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl3->datatype = PDL_L;
   pdl3->data = c;
   pdl3->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl4->datatype = PDL_F;
   pdl4->data = d;
   pdl4->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   XPUSHs(sv_pdl3);
   XPUSHs(sv_pdl4);
   PUTBACK ;

   ret = perl_call_sv(pdl4_function, G_SCALAR);

   SPAGAIN;

   if (ret !=1)
      croak("Error calling perl function\n");

   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PDL->setdims (pdl3, odims, 0);
   pdl3->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl3->data=NULL;

   PDL->setdims (pdl4, odims, 0);
   pdl4->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl4->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;

}

SV*   doubler_function;
double np_wrapper(integer *n, double *p)
{
   dSP ;

   int pret;
   double ret;
   PDL_Indx odims[1];

   PDL_Indx dims[] = {*n};
   PDL->setdims (pdl1, dims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = p;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   PUTBACK ;

   pret = perl_call_sv(doubler_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");


   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;
   ret = (double ) POPn ;
   PUTBACK ;   FREETMPS ;   LEAVE ;
   return ret;

}

SV   *tensor_hess_function, *tensor_f_function, *tensor_grad_function;

void tensor_f_wrapper(integer *n, double *x, double *f)
{
   dSP ;

   int pret;
   PDL_Indx odims[1];
   PDL_Indx dims[1];
   PDL_Indx mdims[] = {*n};

   dims[0] = 1;


   PDL->setdims (pdl1, dims, 1);
   PDL->setdims (pdl2, mdims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = f;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   pdl2->datatype = PDL_D;
   pdl2->data = x;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   PUTBACK ;

   pret = perl_call_sv(tensor_f_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");


   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;
}

void tensor_grad_wrapper(integer *n, double *x, double *g)
{
   dSP ;

   int pret;
   PDL_Indx odims[1];
   PDL_Indx mdims[] = {*n};

   PDL->setdims (pdl1, mdims, 1);
   PDL->setdims (pdl2, mdims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = g;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   pdl2->datatype = PDL_D;
   pdl2->data = x;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   PUTBACK ;

   pret = perl_call_sv(tensor_grad_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");


   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;
}

void tensor_hess_wrapper(integer *nr, integer *n, double *x, double *hx)
{
   dSP ;

   int pret;
   PDL_Indx odims[1];
   PDL_Indx hessdims[] = {*n,*nr};
   PDL_Indx mdims[] = {*n};


   PDL->setdims (pdl1, hessdims, 2);
   PDL->setdims (pdl2, mdims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = hx;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   pdl2->datatype = PDL_D;
   pdl2->data = x;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   PUTBACK ;

   pret = perl_call_sv(tensor_hess_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");


   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;
}

int lbfgs_wrapper(PDL_Indx n, double *a, double *b, double *c, SV *lbfgs_func)
{

   dSP ;

   int pret, ret;

   PDL_Indx odims[1];

   PDL_Indx adims[] = {1};
   PDL_Indx bdims[] = {n};
   PDL_Indx cdims[] = {n};

   PDL->setdims (pdl1, adims, 1);
   PDL->setdims (pdl2, bdims, 1);
   PDL->setdims (pdl3, cdims, 1);

   pdl1->datatype = PDL_D;
   pdl1->data = a;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl2->datatype = PDL_D;
   pdl2->data = b;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl3->datatype = PDL_D;
   pdl3->data = c;
   pdl3->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;

   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   XPUSHs(sv_pdl3);

   PUTBACK ;

   pret = perl_call_sv(lbfgs_func, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");


   ret = (int ) POPi ;
   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PDL->setdims (pdl3, odims, 0);
   pdl3->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl3->data=NULL;
   PUTBACK ;   FREETMPS ;   LEAVE ;
   return ret;

}

int lbfgs_diag_wrapper(PDL_Indx n, double *a, double *b, SV *lbfgs_diag_func)
{

   dSP ;

   int pret,ret ;
   PDL_Indx odims[1];
   PDL_Indx adims[] = {n};
   PDL_Indx bdims[] = {n};

   PDL->setdims (pdl1, adims, 1);
   PDL->setdims (pdl2, bdims, 1);

   pdl1->datatype = PDL_D;
   pdl1->data = a;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl2->datatype = PDL_D;
   pdl2->data = b;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   PUTBACK ;

   pret = perl_call_sv(lbfgs_diag_func, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");

   ret = (int ) POPi ;
   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;
   return ret;

}

int lbfgsb_wrapper(PDL_Indx n , double *a, double *b, double *c, integer *d, double *e, SV *lbfgsb_func)
{

   dSP ;

   int ret ;
   PDL_Indx odims[1];

   PDL_Indx adims[] = {1};
   PDL_Indx bdims[] = {n};
   PDL_Indx cdims[] = {n};
   PDL_Indx ddims[] = {44};
   PDL_Indx edims[] = {29};

   PDL->setdims (pdl1, adims, 1);
   PDL->setdims (pdl2, bdims, 1);
   PDL->setdims (pdl3, cdims, 1);
   PDL->setdims (pdl4, ddims, 1);
   PDL->setdims (pdl5, edims, 1);

   pdl1->datatype = PDL_D;
   pdl1->data = a;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl2->datatype = PDL_D;
   pdl2->data = b;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl3->datatype = PDL_D;
   pdl3->data = c;
   pdl3->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl4->datatype = PDL_L;
   pdl4->data = d;
   pdl4->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl5->datatype = PDL_D;
   pdl5->data = e;
   pdl5->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   XPUSHs(sv_pdl3);
   XPUSHs(sv_pdl4);
   XPUSHs(sv_pdl5);
   PUTBACK ;

   ret = perl_call_sv(lbfgsb_func, G_SCALAR);

   SPAGAIN;

   if (ret !=1)
      croak("Error calling perl function\n");


   ret = (int ) POPi ;

   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PDL->setdims (pdl3, odims, 0);
   pdl3->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl3->data=NULL;

   PDL->setdims (pdl4, odims, 0);
   pdl4->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl4->data=NULL;

   PDL->setdims (pdl5, odims, 0);
   pdl5->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl5->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;
   return ret;

}

SV   *npg_pgrad_function, *npg_f_function, *npg_grad_function;

void npg_f_wrapper(integer *n, double *x, double *f, integer *inform)
{
   dSP ;

   int pret;
   integer ret;
   PDL_Indx odims[1];
   PDL_Indx dims[1];
   PDL_Indx mdims[] = {*n};

   dims[0] = 1;

   PDL->setdims (pdl1, dims, 1);
   PDL->setdims (pdl2, mdims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = f;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   pdl2->datatype = PDL_D;
   pdl2->data = x;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   PUTBACK ;

   pret = perl_call_sv(npg_f_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");


   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;
   ret = (integer ) POPi ;
   *inform  = ret;

   PUTBACK ;   FREETMPS ;   LEAVE ;
}

void npg_pgrad_wrapper(integer *n, double *x, integer *inform)
{
   dSP ;

   int pret;
   integer ret;
   PDL_Indx odims[1];
   PDL_Indx dims[] = {*n};


   PDL->setdims (pdl1, dims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = x;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   PUTBACK ;

   pret = perl_call_sv(npg_pgrad_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");


   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   ret = (integer ) POPi ;
   *inform  = ret;
   PUTBACK ;   FREETMPS ;   LEAVE ;
}

void npg_grad_wrapper(integer *n, double *x, double *g, integer *inform)
{
   dSP ;

   int pret;
   integer ret;
   PDL_Indx odims[1];
   PDL_Indx mdims[] = {*n};

   PDL->setdims (pdl1, mdims, 1);
   PDL->setdims (pdl2, mdims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = g;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   pdl2->datatype = PDL_D;
   pdl2->data = x;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   PUTBACK ;

   pret = perl_call_sv(npg_grad_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");


   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   ret = (integer ) POPi ;
   *inform  = ret;
   PUTBACK ;   FREETMPS ;   LEAVE ;
}


SV   *lm_function;
void lm_wrapper(integer *n, double *x, double *f, double *g)
{
   dSP ;

   int pret;
   PDL_Indx odims[1];
   PDL_Indx mdims[] = {*n};
   odims[0] = 1;

   PDL->setdims (pdl3, odims, 1);
   PDL->setdims (pdl1, mdims, 1);
   PDL->setdims (pdl2, mdims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = g;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   pdl2->datatype = PDL_D;
   pdl2->data = x;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   pdl3->datatype = PDL_D;
   pdl3->data = f;
   pdl3->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl3);
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   PUTBACK ;

   pret = perl_call_sv(lm_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");


   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl3, odims, 0);
   pdl3->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl3->data=NULL;

   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;
}

SV*   hooke_function;
double hooke_wrapper(int n, double *p)
{
   dSP ;

   int pret;
   double ret;
   PDL_Indx odims[1];

   PDL_Indx dims[] = {n};
   PDL->setdims (pdl1, dims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = p;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   PUTBACK ;

   pret = perl_call_sv(hooke_function, G_SCALAR);

   SPAGAIN;
   if (pret !=1)
      croak("Error calling perl function\n");


   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;
   ret = (double ) POPn ;
   PUTBACK ;   FREETMPS ;   LEAVE ;
   return ret;
}

SV   *gencanf_function;
void gencanf_wrapper(integer *n, double *x, double *f, integer *inform)
{
   dSP ;

   int pret;
   PDL_Indx odims[1];
   PDL_Indx mdims[] = {*n};
   odims[0] = 1;

   PDL->setdims (pdl2, odims, 1);
   PDL->setdims (pdl1, mdims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = x;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   pdl2->datatype = PDL_D;
   pdl2->data = f;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl2);
   XPUSHs(sv_pdl1);
   PUTBACK ;

   pret = perl_call_sv(gencanf_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");

   *inform =  (long ) POPl;

   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;
}

SV   *gencang_function;
void gencang_wrapper(integer *n, double *x, double *g, integer *inform)
{
   dSP ;

   int pret;
   PDL_Indx odims[1];
   PDL_Indx mdims[] = {*n};
   odims[0] = 1;


   PDL->setdims (pdl2, mdims, 1);
   PDL->setdims (pdl1, mdims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = x;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   pdl2->datatype = PDL_D;
   pdl2->data = g;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;


   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl2);
   XPUSHs(sv_pdl1);
   PUTBACK ;

   pret = perl_call_sv(gencang_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");

   *inform =  (long ) POPl;

   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;
}

SV   *gencanh_function;
void gencanh_wrapper(integer *nind, integer *ind, integer *n, double *x, double *d, double *hd,integer *inform)
{
   dSP ;

   int pret;
   PDL_Indx odims[1];
   PDL_Indx mdims[] = {*n};
   PDL_Indx ddims[] = {1,*n};
   PDL_Indx inddims[] = {*nind};

   PDL->setdims (pdl1, mdims, 1);
   PDL->setdims (pdl2, ddims, 2);
   PDL->setdims (pdl3, ddims, 2);
   PDL->setdims (pdl4, inddims, 1);

   pdl1->datatype = PDL_D;
   pdl1->data = x;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl2->datatype = PDL_D;
   pdl2->data = d;
   pdl2->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl3->datatype = PDL_D;
   pdl3->data = hd;
   pdl3->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   pdl4->datatype = PDL_L;
   pdl4->data = ind;
   pdl4->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl3);
   XPUSHs(sv_pdl1);
   XPUSHs(sv_pdl2);
   XPUSHs(sv_pdl4);
   PUTBACK ;

   pret = perl_call_sv(gencanh_function, G_SCALAR);

   SPAGAIN;

   if (pret !=1)
      croak("Error calling perl function\n");

   *inform =  (long ) POPl;

   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;

   PDL->setdims (pdl2, odims, 0);
   pdl2->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl2->data=NULL;

   PDL->setdims (pdl3, odims, 0);
   pdl3->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl3->data=NULL;

   PDL->setdims (pdl4, odims, 0);
   pdl4->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl4->data=NULL;

   PUTBACK ;   FREETMPS ;   LEAVE ;
}

SV*   asa_function;
double asa_wrapper (double *x,
               double *parameter_lower_bound,
               double *parameter_upper_bound,
               double *cost_tangents,
               double *cost_curvature,
               long int * parameter_dimension,
               int *parameter_int_real,
               int *cost_flag, int *exit_code, USER_DEFINES * USER_OPTIONS)
{
   dSP ;

   int pret;
   double ret;
   PDL_Indx odims[1];

   PDL_Indx dims[] = {*parameter_dimension};
   PDL->setdims (pdl1, dims, 1);
   pdl1->datatype = PDL_D;
   pdl1->data = x;
   pdl1->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   XPUSHs(sv_pdl1);
   PUTBACK ;

   pret = perl_call_sv(asa_function, G_SCALAR);

   SPAGAIN;
   if (pret !=1)
      croak("Error calling perl function\n");


   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl1, odims, 0);
   pdl1->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl1->data=NULL;
   ret = (double ) POPn ;
   PUTBACK ;   FREETMPS ;   LEAVE ;
   return ret;
}

void select_init() {
   pdl1 = PDL->pdlnew();
   pdl2 = PDL->pdlnew();
   pdl3 = PDL->pdlnew();
   pdl4 = PDL->pdlnew();
   pdl5 = PDL->pdlnew();
   sv_pdl1 = newSV(0);
   sv_pdl2 = newSV(0);
   sv_pdl3 = newSV(0);
   sv_pdl4 = newSV(0);
   sv_pdl5 = newSV(0);
   PDL->SetSV_PDL(sv_pdl1, pdl1);
   PDL->SetSV_PDL(sv_pdl2, pdl2);
   PDL->SetSV_PDL(sv_pdl3, pdl3);
   PDL->SetSV_PDL(sv_pdl4, pdl4);
   PDL->SetSV_PDL(sv_pdl5, pdl5);
}
