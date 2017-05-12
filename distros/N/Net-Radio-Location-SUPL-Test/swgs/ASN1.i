%ignore asn_TYPE_descriptor_t;
%ignore asn_struct_free_f;
%ignore asn_struct_print_f;
%ignore asn_constr_check_f;
%ignore ber_type_decoder_f;
%ignore der_type_encoder_f;
%ignore xer_type_decoder_f;
%ignore xer_type_encoder_f;
%ignore per_type_decoder_f;
%ignore per_type_encoder_f;

%typemap(arginit) OCTET_STRING_t {
    memset(&$1, 0, sizeof($1));
}

%typemap(in) OCTET_STRING_t {
    if( 0 == (SvFLAGS($input) & (SVf_OK & ~SVf_ROK)) )
	croak("Argument $argnum is not a string.");
    OCTET_STRING_fromBuf((OCTET_STRING_t *)(&$1), SvPV_nolen($input), SvCUR($input));
}

%typemap(in) OCTET_STRING_t * {
    if( 0 == (SvFLAGS($input) & (SVf_OK & ~SVf_ROK)) )
	croak("Argument $argnum is not a string.");
    $1 = calloc(1, sizeof(*($1)));
    if( NULL == $1 )
        croak("Out of memory allocating new " "$*1_type");
    OCTET_STRING_fromBuf((OCTET_STRING_t *)($1), SvPV_nolen($input), SvCUR($input));
}

%typemap(out) OCTET_STRING_t {
    if (argvi >= items) {
	EXTEND(sp,1); /* Extend the stack by 1 object */
    }
    $result = sv_newmortal();
    sv_setpvn($result, (char *)($1.buf), $1.size);

    ++argvi; /* intentional - not portable between languages */
}

%typemap(out) OCTET_STRING_t * {
    if (argvi >= items) {
	EXTEND(sp,1); /* Extend the stack by 1 object */
    }
    $result = sv_newmortal();
    sv_setpvn($result, (char *)($1->buf), $1->size);

    ++argvi; /* intentional - not portable between languages */
}

%typemap(arginit) BIT_STRING_t {
    memset(&$1, 0, sizeof($1));
}

%typemap(in) BIT_STRING_t {
    if( 0 == (SvFLAGS($input) & (SVf_OK & ~SVf_ROK)) )
	croak("Argument $argnum is not a string.");
    OCTET_STRING_fromBuf((OCTET_STRING_t *)(&$1), SvPV_nolen($input), SvCUR($input));
    $1.bits_unused = 0;
}

%typemap(in) BIT_STRING_t * {
    if( 0 == (SvFLAGS($input) & (SVf_OK & ~SVf_ROK)) )
	croak("Argument $argnum is not a string.");
    $1 = calloc(1, sizeof(*($1)));
    if( NULL == $1 )
        croak("Out of memory allocating new " "$*1_type");
    OCTET_STRING_fromBuf((OCTET_STRING_t *)($1), SvPV_nolen($input), SvCUR($input));
    $1->bits_unused = 0;
}

%typemap(out) BIT_STRING_t {
    if (argvi >= items) {
	EXTEND(sp,1); /* Extend the stack by 1 object */
    }
    $result = sv_newmortal();
    sv_setpvn($result, (char *)($1.buf), $1.size); // XXX bits_unused ...

    ++argvi; /* intentional - not portable between languages */
}

%typemap(out) BIT_STRING_t * {
    if (argvi >= items) {
	EXTEND(sp,1); /* Extend the stack by 1 object */
    }
    $result = sv_newmortal();
    sv_setpvn($result, (char *)($1->buf), $1->size); // XXX bits_unused ...

    ++argvi; /* intentional - not portable between languages */
}

%typemap(newfree) BIT_STRING_t "asn_DEF_BIT_STRING.free_struct(&asn_DEF_BIT_STRING, &$1, 1);"
%typemap(newfree) BIT_STRING_t * "if( $1 ) { asn_DEF_BIT_STRING.free_struct(&asn_DEF_BIT_STRING, $1, 0); }"

%typemap(newfree) OCTET_STRING_t "asn_DEF_OCTET_STRING.free_struct(&asn_DEF_OCTET_STRING, &$1, 1);"
%typemap(newfree) OCTET_STRING_t * "if( $1 ) { asn_DEF_OCTET_STRING.free_struct(&asn_DEF_OCTET_STRING, $1, 0); }"

// built-in
%apply OCTET_STRING_t { IA5String_t };
%apply OCTET_STRING_t * { IA5String_t * };
%apply OCTET_STRING_t { VisibleString_t };
%apply OCTET_STRING_t * { VisibleString_t * };
