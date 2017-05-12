
SV* perl_ncar_callback;

static void default_magic( pdl *p, int pa ) { p->data = 0; }


SV* pointer2piddle(
    void* data,
    int ndims,
    PDL_Long dims[],
    int datatype
) { /* 
        Inspired from PDL::API manpage 
        Creates a mortal piddle from scratch
    */

  pdl* npdl;
  SV* sv_npdl;
  
  npdl = PDL->pdlnew();

  PDL->setdims( npdl, dims, ndims );

  npdl->datatype = datatype;
  npdl->data = data;
  
  npdl->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED ;
  
  PDL->add_deletedata_magic( npdl, default_magic, 0 );

  sv_npdl = sv_newmortal();
  PDL->SetSV_PDL( sv_npdl, npdl );

  return sv_npdl;
}
  
#include "c_ncar_callbacks/LPR.c"
