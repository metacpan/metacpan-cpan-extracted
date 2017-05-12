#ifdef NO_TRAILING_USCORE

#define MNINIT mninit
#define MNSETI mnseti
#define MNPARM mnparm
#define MNPARS mnpars
#define MNEXCM mnexcm
#define MNCOMD mncomd
#define MNPOUT mnpout
#define MNSTAT mnstat
#define MNEMAT mnemat
#define MNERRS mnerrs
#define MNCONT mncont

#define ABRE   abre
#define CIERRA cierra

#else

#define MNINIT mninit_
#define MNSETI mnseti_
#define MNPARM mnparm_
#define MNPARS mnpars_
#define MNEXCM mnexcm_
#define MNCOMD mncomd_
#define MNPOUT mnpout_
#define MNSTAT mnstat_
#define MNEMAT mnemat_
#define MNERRS mnerrs_
#define MNCONT mncont_

#define ABRE   abre_
#define CIERRA cierra_

#endif 

static SV* mnfunname;
static int ene;

void FCN(int* npar,double* grad,double* fval,double* xval,int* iflag,double* futil);

void FCN(int* npar,double* grad,double* fval,double* xval,int* iflag,double* futil){

  SV* funname;

  int count,i;
  double* x;

  I32 ax ; 
  
  pdl* pgrad;
  SV* pgradsv;

  pdl* pxval;
  SV* pxvalsv;
  
  int ndims;
  PDLA_Indx *pdims;

  dSP;
  ENTER;
  SAVETMPS;

  /* get name of function on the Perl side */
  funname = mnfunname;

  ndims = 1;
  pdims = (PDLA_Indx *)  PDLA->smalloc( (STRLEN) ((ndims) * sizeof(*pdims)) );
  
  pdims[0] = (PDLA_Indx) ene;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpv("PDLA", 0)));
  PUTBACK;
  perl_call_method("initialize", G_SCALAR);
  SPAGAIN;
  pxvalsv = POPs;
  PUTBACK;
  pxval = PDLA->SvPDLAV(pxvalsv);
 
  PDLA->converttype( &pxval, PDLA_D, PDLA_PERM );
  PDLA->children_changesoon(pxval,PDLA_PARENTDIMSCHANGED|PDLA_PARENTDATACHANGED);
  PDLA->setdims (pxval,pdims,ndims);
  pxval->state &= ~PDLA_NOMYDIMS;
  pxval->state |= PDLA_ALLOCATED | PDLA_DONTTOUCHDATA;
  PDLA->changed(pxval,PDLA_PARENTDIMSCHANGED|PDLA_PARENTDATACHANGED,0);

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpv("PDLA", 0)));
  PUTBACK;
  perl_call_method("initialize", G_SCALAR);
  SPAGAIN;
  pgradsv = POPs;
  PUTBACK;
  pgrad = PDLA->SvPDLAV(pgradsv);
  
  PDLA->converttype( &pgrad, PDLA_D, PDLA_PERM );
  PDLA->children_changesoon(pgrad,PDLA_PARENTDIMSCHANGED|PDLA_PARENTDATACHANGED);
  PDLA->setdims (pgrad,pdims,ndims);
  pgrad->state &= ~PDLA_NOMYDIMS;
  pgrad->state |= PDLA_ALLOCATED | PDLA_DONTTOUCHDATA;
  PDLA->changed(pgrad,PDLA_PARENTDIMSCHANGED|PDLA_PARENTDATACHANGED,0);

  pxval->data = (void *) xval;
  pgrad->data = (void *) grad;  

  PUSHMARK(SP);

  XPUSHs(sv_2mortal(newSViv(*npar)));
  XPUSHs(pgradsv);
  XPUSHs(sv_2mortal(newSVnv(*fval)));
  XPUSHs(pxvalsv);
  XPUSHs(sv_2mortal(newSViv(*iflag)));

  PUTBACK;

  count=call_sv(funname,G_ARRAY);

  SPAGAIN; 
  SP -= count ;
  ax = (SP - PL_stack_base) + 1 ;

  if (count!=2)
    croak("error calling perl function\n");

  pgradsv = ST(1);
  pgrad = PDLA->SvPDLAV(pgradsv);

  x = (double *) pgrad->data;

  for(i=0;i<ene;i++)
    grad[i] = x[i];

  *fval = SvNV(ST(0));

  PUTBACK;
  FREETMPS;
  LEAVE;

}
