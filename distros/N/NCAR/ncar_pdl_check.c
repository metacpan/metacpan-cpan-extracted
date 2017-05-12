#ifndef NCAR_PDL_CHECK_C
#define NCAR_PDL_CHECK_C

int ncar_pdl_check_out( pdl* x ) {
  PDL->changed( x, PDL_PARENTDATACHANGED, 0 ); 
}

int ncar_pdl_check_in( pdl* x, char* sub, int iarg, char type, int ndims, ... ) {
  va_list ap;
  int idim;
  int dim;
  int asize;
  int bsize;
  char error[128];
  int r;

  PDL->make_physical( x );
  PDL->children_changesoon( x, PDL_PARENTDATACHANGED );  

  switch( type ) {
  
    case 'f' :
    
      if( x->datatype != PDL_F ) {
        sprintf( error, "Arg %d of %s has to be a float", iarg, sub );
        croak( error );
      }
      
    break;
    
    case 'd' :

      if( x->datatype != PDL_D ) {
        sprintf( error, "Arg %d of %s has to be a double", iarg, sub );
        croak( error );
      }
      
    break;
    
    case 'i' :

      if( x->datatype != PDL_L ) {
        sprintf( error, "Arg %d of %s has to be a long", iarg, sub );
        croak( error );
      }
      
    break;
    
  }
  
  if( ndims != 0 ) {
    va_start( ap, ndims );
    asize = 1;
    bsize = 1;
    r = 0;
    for( idim = 0; idim < ndims; idim++ ) {
       dim = va_arg( ap, int );
       if( dim == -1 ) {
          r = 1;
       }
       asize *= dim;
    }
  
    va_end( ap );
  
    if( r > 0 ) {
      return;
    }
  
    for( idim = 0; idim < x->ndims; idim++ ) {
     bsize *= ( int )( x->dims[ idim ] );
    }
  
    if( bsize < asize ) {
      sprintf( 
          error, 
          "Arg %d of %s is not big enough:\n size = %d, should be %d",
          iarg, sub, bsize, asize
      );
      croak( error );
    }
  }
}
#endif
