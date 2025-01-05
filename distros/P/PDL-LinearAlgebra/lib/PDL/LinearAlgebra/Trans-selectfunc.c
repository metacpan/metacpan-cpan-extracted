#include "EXTERN.h"
#include "perl.h"
#include "pdl.h"
#include "pdlcore.h"

#define PDL PDL_LinearAlgebra_Trans
extern Core *PDL;

typedef PDL_Long integer;

/* replace BLAS one so don't terminate on bad input */
int xerbla_(char *sub, int *info) { return 0; }

void dfunc_wrapper(void *p, integer n, SV* dfunc)
{
   dSP ;
   PDL_Indx odims[] = {0};
   PDL_Indx nat_dims[] = {n};
   PDL_Indx *dims = nat_dims;
   PDL_Indx ndims = 1;
   int type_add = PDL_CF - PDL_F;
   pdl *pdl = PDL->pdlnew();
   PDL->setdims(pdl, dims, ndims);
   pdl->datatype = PDL_D + type_add;
   pdl->data = p;
   pdl->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
   HV *bless_stash = gv_stashpv("PDL", 0);
   ENTER ;   SAVETMPS ;   PUSHMARK(sp) ;
   SV *pdl1 = sv_newmortal();
   PDL->SetSV_PDL(pdl1, pdl);
   pdl1 = sv_bless(pdl1, bless_stash);
   XPUSHs(pdl1);
   PUTBACK ;
   int count = perl_call_sv(dfunc, G_SCALAR);
   SPAGAIN;
   PDL->setdims(pdl, odims, 1);
   pdl->state &= ~(PDL_ALLOCATED |PDL_DONTTOUCHDATA);
   pdl->data=NULL;
   if (count !=1)
      croak("Error calling perl function\n");
   PUTBACK ;   FREETMPS ;   LEAVE ;
}
