#include "pdlperlfunc.h"

#define PDL PDL_Fit_Levmar
extern Core *PDL;

typedef void (*DelMagic)(pdl *, Size_t param);
static void default_magic(pdl *p, Size_t pa) { p->data = 0; }

// Don't free data, it is allocated inside liblevmar
static void delete_levmar_pdls(pdl* p, Size_t param)
{
  if (p->data) {
    // free(p->data);
  }
  else {
     }
  p->data = 0;
}

// Code from  PDL::API docs. For creating a pdl and giving it
// data storage allocated elswhere.
static pdl* pdl_wrap(void *data, int datatype, PDL_Indx dims[],
		     int ndims, DelMagic delete_magic, int delparam)
{
  pdl* npdl = PDL->pdlnew(); /* get the empty container */
  PDL->setdims(npdl,dims,ndims); /* set dims      */
  npdl->datatype = datatype;     /* and data type */
  npdl->data = data;             /* point it to your data */
  /* make sure the core doesn't meddle with your data */
  npdl->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
  if (delete_magic != NULL) {
    PDL->add_deletedata_magic(npdl, delete_magic, delparam);
  } else
     PDL->add_deletedata_magic(npdl, default_magic, 0);
  return npdl;
}

/* We use a struct holding data for the wrapper functions to
 * perl fit code, LEVFUNC, and JLEVFUNC. liblevmar uses fit
 * functions whose the last argument is a pointer to
 * unpecified data. When fitting data it is normally used
 * for the ordinate data (t). We pass a DFP struct instead.
 * These functions are all re-entrant, i hope. The DFP
 * struct holds pdls which are created once at the start of
 * a fit and destroyed when it is finished. Data is not put
 * in the pdls here. The fit routines send different arrays
 * on different calls, so the pdl pointer to the data must
 * be set in the wrapper functions at each call.  t is an
 * exception-- it is set by the user just once. levmar calls
 * DFP_check() (below) which either sets t, or points the
 * DFP *dat directly to t, if the wrapper functions are not
 * used (ie for pure C fit functions).
 */
static void DFP_create_pdls( DFP *dat, int data_type, int m, int n, int nt) {
  pdl *p_pdl, *x_pdl, *d_pdl, *t_pdl;
  SV  *p_sv, *x_sv, *d_sv, *t_sv;
  PDL_Indx mf_dims[] = {m};
  int num_mf_dims = 1;
  PDL_Indx mjac_dims[] = {m,n}; // for jacobian 'd' variable
  int num_mjac_dims = 2;
  PDL_Indx n_dims[] = {n};
  int num_n_dims = 1;
  PDL_Indx nt_dims[] = {nt};
  int num_nt_dims = 1;
  // create pdls, but with no data;
  p_pdl = pdl_wrap(NULL, data_type, mf_dims, num_mf_dims, delete_levmar_pdls, 0);
  d_pdl = pdl_wrap(NULL, data_type, mjac_dims, num_mjac_dims, delete_levmar_pdls, 0);
  x_pdl = pdl_wrap(NULL, data_type, n_dims, num_n_dims, delete_levmar_pdls, 0);
  t_pdl = pdl_wrap(NULL, data_type, nt_dims, num_nt_dims, delete_levmar_pdls, 0);
  // otherwise we get a memory leak
  p_sv = sv_newmortal();
  d_sv = sv_newmortal();
  x_sv = sv_newmortal();
  t_sv = sv_newmortal();
  PDL->SetSV_PDL(p_sv, p_pdl);
  PDL->SetSV_PDL(d_sv, d_pdl);
  PDL->SetSV_PDL(x_sv, x_pdl);
  PDL->SetSV_PDL(t_sv, t_pdl);
  dat->p_pdl = p_pdl;
  dat->d_pdl = d_pdl;
  dat->t_pdl = t_pdl;
  dat->x_pdl = x_pdl;
  dat->p_sv = p_sv;
  dat->d_sv = d_sv;
  dat->t_sv = t_sv;
  dat->x_sv = x_sv;
}

/* If dat is null then no DFP struct was created because we
 * are using a C function and it will expect t as the last
 * argument (and dat is passed as the last argument).  If
 * dat is non-null, it will hold a struct with all the pdls
 * and we must put t in its proper place.
 */
void DFP_check(DFP **dat, int data_type, int m, int n, int nt, void *t ) {
  if ( *dat != NULL) {
    DFP_create_pdls( *dat, data_type, m, n, nt);
    (*dat)->t_pdl->data = t;
  }
  else { // Pure C routine that don't need this wrapper, expect t as last arg
    *dat = (DFP *)t; // cast in case compiler complains.
  }
}

//-----------------------------------------------------
// Modified Function from pdl gsl interp code
// It follows the perlembed doc example closely

void LEVFUNC(double *p, double *x, int m, int n, DFP *dat) {
  int count;
  dSP;

  dat->p_pdl->data = p;
  dat->x_pdl->data = x;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  // Dont make mortal, they come from outside this routine
  XPUSHs(dat->p_sv);
  XPUSHs(dat->x_sv);
  XPUSHs(dat->t_sv);

  PUTBACK;
  count=call_sv(dat->perl_fit_func,G_SCALAR);
  SPAGAIN;
  if (count!=1)
    croak("error calling perl function\n");

  PUTBACK;
  FREETMPS;
  LEAVE;

}

void JLEVFUNC(double *p, double *d, int m, int n, DFP *dat) {
  int count;
  dat->p_pdl->data = p;
  dat->d_pdl->data = d;

  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(dat->p_sv);
  XPUSHs(dat->d_sv);
  XPUSHs(dat->t_sv);
  PUTBACK;
  count=call_sv(dat->perl_jac_func,G_SCALAR);
  SPAGAIN;
  if (count!=1)
    croak("error calling perl function\n");
  PUTBACK;
  FREETMPS;
  LEAVE;
}
