void c_ncar_callback_LPR(
    float* XCS,
    float* YCS,
    int* NCS,
    int* IAI,
    int* IAG,
    int* NAI
) {
    PDL_Long XCS_dims[1];
    PDL_Long YCS_dims[1];
    PDL_Long IAI_dims[1];
    PDL_Long IAG_dims[1];
    SV* sv_pdl_XCS;
    SV* sv_pdl_YCS;
    SV* sv_pdl_IAI;
    SV* sv_pdl_IAG;
  
    if( ! SvTRUE( perl_ncar_callback ) ) {
      croak( "No callback defined\n" );
    }  
    
    XCS_dims[0] = *NCS;
    YCS_dims[0] = *NCS;
    IAI_dims[0] = *NAI;
    IAG_dims[0] = *NAI;

    sv_pdl_XCS = pointer2piddle( ( void* )XCS, 1, XCS_dims, PDL_F );
    sv_pdl_YCS = pointer2piddle( ( void* )YCS, 1, YCS_dims, PDL_F );
    sv_pdl_IAI = pointer2piddle( ( void* )IAI, 1, IAI_dims, PDL_L );
    sv_pdl_IAG = pointer2piddle( ( void* )IAG, 1, IAG_dims, PDL_L );
    {
      dSP;
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);
      
      XPUSHs( sv_pdl_XCS );
      XPUSHs( sv_pdl_YCS );
      XPUSHs( sv_2mortal( newSViv( ( IV )( *NCS ) ) ) );
      XPUSHs( sv_pdl_IAI );
      XPUSHs( sv_pdl_IAG );
      XPUSHs( sv_2mortal( newSViv( ( IV )( *NAI ) ) ) );
  
      PUTBACK;
    
      call_sv( perl_ncar_callback, G_DISCARD );
    
      FREETMPS;
      LEAVE;
    }
}
