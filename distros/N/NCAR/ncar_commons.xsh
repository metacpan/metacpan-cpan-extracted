
void 
ncar_common_variable_get( cname, sv, offset, type, size, av_dims )
  INPUT:
    COMMON_NAME cname;
    SV* sv;
    int offset;
    char type;
    int size;
    AV* av_dims;
  CODE:
  {
    float* f;
    int* i;
    char* c;
    
    PDL_Long dims[6];
    int ndims;
    
    ndims = av_len( av_dims ) + 1;
    
    switch( type ) {
      case 'i' : 
        i = (int*)( ncar_commons[cname] + offset );
        if( ndims > 0 ) {
          int k;
          SV** sv_d;
          for( k = 0; k < ndims; k++ ) { 
            sv_d = av_fetch( av_dims, (I32)k, (I32)0 );
            dims[k] = SvIV( *sv_d );
          }
          sv_setsv( sv, pointer2piddle( (void*)i, ndims, dims, PDL_L ) );
        } else {
          sv_setiv( sv, (IV)( *i ) );
        }
      break;
      case 'f':
        f = (float*)( ncar_commons[cname] + offset );
        if( ndims > 0 ) {
          int k;
          SV** sv_d;
          for( k = 0; k < ndims; k++ ) { 
            sv_d = av_fetch( av_dims, (I32)k, (I32)0 );
            dims[k] = SvIV( *sv_d );
          }
          sv_setsv( sv, pointer2piddle( (void*)f, ndims, dims, PDL_F ) );
        } else {
          sv_setnv( sv, (NV)( *f ) );
        }
      break;
      case 'c':
        c = (char*)( ncar_commons[cname] + offset );
        sv_setpvn( sv, c, size );
      break;
      default:
        croak( "Unexpected type in NCAR::COMMON" );
    }
  }
  
void 
ncar_common_variable_set( cname, sv, offset, type, size )
  INPUT:
    COMMON_NAME cname;
    SV* sv;
    int offset;
    char type;
    int size;
  CODE:
    float* f;
    int* i;
    char* c;
    
    char* s;
    int len;
    
    
    switch( type ) {
      case 'i' : 
        i = (int*)( ncar_commons[cname] + offset );
        *i = (int)SvIV( sv );
      break;
      case 'f':
        f = (float*)( ncar_commons[cname] + offset );
        *f = (float)SvNV( sv );
      break;
      case 'c':
        c = (char*)( ncar_commons[cname] + offset );
        s = SvPV( sv, len );
        if( len > size ) {
          len = size;
        }
        strncpy( c, s, (size_t)len );
        {
          int k;
          for( k = len; k < size; k++ ) {
            c[k] = ' ';
          }
        }
      break;
      default:
        croak( "Unexpected type in NCAR::COMMON" );
    }
  
