
%typemap(out) dtc_U1 {
  $result = sv_newmortal();
  sv_setuv($result, (UV) $1);
  argvi++;
}

%typemap(in) dtc_U1 {
  $1 = (dtc_U1) SvIV($input);
}

%typemap(out) dtc_U2 {
  $result = sv_newmortal();
  sv_setuv($result, (UV) $1);
  argvi++;
}

%typemap(in) dtc_U2 {
  $1 = (dtc_U2) SvUV($input);
}

%typemap(out) dtc_U4 {
  $result = sv_newmortal();
  sv_setuv($result, (UV) $1);
  argvi++;
}

%typemap(in) dtc_U4 {
  $1 = (dtc_U4) SvIV($input);
}

%typemap(out) dtc_I1 {
  $result = sv_newmortal();
  sv_setiv($result, (IV) $1);
  argvi++;
}

%typemap(in) dtc_I1 {
  $1 = (dtc_I1) SvIV($input);
}

%typemap(out) dtc_I2 {
  $result = sv_newmortal();
  sv_setiv($result, (IV) $1);
  argvi++;
}

%typemap(in) dtc_I2 {
  $1 = (dtc_I2) SvIV($input);
}

%typemap(out) dtc_I4 {
  $result = sv_newmortal();
  sv_setiv($result, (IV) $1);
  argvi++;
}

%typemap(in) dtc_I4 {
  $1 = (dtc_I4) SvIV($input);
}

%typemap(out) dtc_Cn {
  $result = sv_newmortal();
  STRLEN len = (unsigned char) *$1;
  (len > 0 ) ?  sv_setpvn ($result, $1+1, len) : sv_setpv($result,""); 
  argvi++;
}

%typemap(in) dtc_Cn {
  char *p; 
  STRLEN len;
  int i;
  p = SvPV($input,len); 
  $1 = (dtc_Cn) calloc( len+2, sizeof(dtc_C1) ); // calloc enough for len and null byte 
  $1[0] = (unsigned char) len;
  memmove($1+1, p, len);
}

%typemap(out) dtc_Dn {
  dtc_U2 len;  
  memmove(&len, $1, sizeof(len) );
  SV **svs = (SV **) malloc(len*sizeof(SV*));
  for (int i=0; i < len; i++ ) {
    svs[i] = sv_newmortal();
    sv_setuv((SV*) svs[i], *((dtc_U1*) $1+2+i) );
  }
  AV *av = av_make(len,svs);
  $result = newRV_noinc((SV*) av ); 
  argvi++;
}


%typemap(in) dtc_Dn {
  if (!SvROK($input))
      croak("Argument $argnum is not a reference.");
  if (SvTYPE(SvRV($input)) != SVt_PVAV)
      croak("Argument $argnum is not an array.");

  // Each array element assumed 1 byte

  AV *av = (AV*)SvRV($input);
  I32 last_idx = av_len(av);

  $1 = ( dtc_Dn ) calloc ( last_idx+1+2, sizeof(dtc_U1));

  dtc_U2 num_bytes = (dtc_U2) last_idx+1; 
  memmove($1, &num_bytes, sizeof(num_bytes) );

  for (int i=0; i <= last_idx; i++ ) {
     SV **tv = av_fetch(av, i, 0);
     dtc_U1 u1 = (dtc_U1) SvIV(*tv); 
     *($1+2+i) =  u1;
  }
}


%typemap(in) dtc_xU1 {
  if (!SvROK($input))
      croak("Argument $argnum is not a reference.");
  if (SvTYPE(SvRV($input)) != SVt_PVAV)
      croak("Argument $argnum is not an array.");

  AV *av = (AV*)SvRV($input);
  I32 len = av_len(av);

  $1 = ( dtc_xU1 ) calloc ( len+1, sizeof(dtc_U1));

  for (int i=0; i <= len; i++ ) {
     SV **tv = av_fetch(av, i, 0);
     dtc_U1 u1 = (dtc_U1) SvIV(*tv);
     memmove($1+i, &u1, sizeof(u1) );
  }
}

%typemap(in) dtc_xU2 {
  if (!SvROK($input))
      croak("Argument $argnum is not a reference.");
  if (SvTYPE(SvRV($input)) != SVt_PVAV)
      croak("Argument $argnum is not an array.");

  AV *av = (AV*)SvRV($input);
  I32 len = av_len(av);

  $1 = ( dtc_xU2 ) calloc ( len+1, sizeof(dtc_U2));

  for (int i=0; i <= len; i++ ) {
     SV **tv = av_fetch(av, i, 0);
     dtc_U2 u2 = (dtc_U2) SvIV(*tv);
     memmove($1+i, &u2, sizeof(u2) );
  }
}

%typemap(in) dtc_xR4 {
  if (!SvROK($input))
      croak("Argument $argnum is not a reference.");
  if (SvTYPE(SvRV($input)) != SVt_PVAV)
      croak("Argument $argnum is not an array.");

  AV *av = (AV*)SvRV($input);
  I32 len = av_len(av);

  $1 = ( dtc_xR4 ) calloc ( len+1, sizeof(dtc_R4));

  for (int i=0; i <= len; i++ ) {
     SV **tv = av_fetch(av, i, 0);
     dtc_R4 r4 = (dtc_R4) SvNV(*tv);
     memmove($1+i, &r4, sizeof(r4) );
  }
}

%typemap(in) dtc_xN1 {
  if (!SvROK($input))
      croak("Argument $argnum is not a reference.");
  if (SvTYPE(SvRV($input)) != SVt_PVAV)
      croak("Argument $argnum is not an array.");

  AV *av = (AV*)SvRV($input);
  I32 len = av_len(av);

  $1 = ( dtc_xN1 ) calloc ( len+1, sizeof(dtc_N1));

  for (int i=0; i <= len; i++ ) {
     SV **tv = av_fetch(av, i, 0);
     dtc_N1 n1 = (dtc_N1) SvIV(*tv);
     memmove($1+i, &n1, sizeof(n1) );
  }
}

%typemap(in) dtc_xCn {
    if (!SvROK($input))
      croak("Argument $argnum is not a reference.");
    if (SvTYPE(SvRV($input)) != SVt_PVAV)
      croak("Argument $argnum is not an array.");

    AV *av = (AV*)SvRV($input);
    I32 len = av_len(av);

    $1 = ( dtc_xCn ) calloc ( len+1, sizeof(dtc_Cn));

    for (int i=0; i <= len; i++ ) {
      SV **tv = av_fetch(av, i, 0);
      STRLEN l;
      char* p = (char*) SvPV(*tv, l);
      $1[i] = (dtc_Cn) calloc( l+2, sizeof(dtc_C1) ); // calloc enough for len and null byte
      $1[i][0] = (unsigned char) l;
      memmove($1[i]+1, p, l);
    }
}


