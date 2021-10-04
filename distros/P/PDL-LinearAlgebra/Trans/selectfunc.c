#include "EXTERN.h"
#include "perl.h"
#include "pdl.h"
#include "pdlcore.h"

#define PDL PDL_LinearAlgebra_Trans
extern Core *PDL;

typedef PDL_Long integer;
typedef struct { double r, i; } dcomplex;

void dfunc_wrapper(dcomplex *p, integer n, SV* dfunc)
{
   dSP ;
   int count;
   SV *pdl1;
   HV *bless_stash;
   pdl *pdl;
   PDL_Indx odims[1];
   PDL_Indx dims[] = {2,n};
   pdl = PDL->pdlnew();
   PDL->setdims (pdl, dims, 2);
   pdl->datatype = PDL_D;
   pdl->data = (double *) &p[0].r;
   pdl->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   bless_stash = gv_stashpv("PDL::Complex", 0);
   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   pdl1 = sv_newmortal();
   PDL->SetSV_PDL(pdl1, pdl);
   pdl1 = sv_bless(pdl1, bless_stash); /* bless in PDL::Complex  */
   XPUSHs(pdl1);
   PUTBACK ;
   count = perl_call_sv(dfunc, G_SCALAR);
   SPAGAIN;
   // For pdl_free
   odims[0] = 0;
   PDL->setdims (pdl, odims, 0);
   pdl->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl->data=NULL;
   if (count !=1)
      croak("Error calling perl function\n");
   PUTBACK ;   FREETMPS ;   LEAVE ;
}
