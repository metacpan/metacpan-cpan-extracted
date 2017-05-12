#include "tokenizer.h"

MODULE = Salvation::TC::Parser PACKAGE = Salvation::TC::Parser::XS

PROTOTYPES: DISABLED

HV*
tokenize_type_str_impl( class, str, options )
        char * class
        char * str
        HV * options
    CODE:
        RETVAL = perl_tokenize_type_str( class, str, options );

    OUTPUT:
        RETVAL

HV*
tokenize_signature_str_impl( class, str, options )
        char * class
        char * str
        HV * options
    CODE:
        RETVAL = perl_tokenize_signature_str( class, str, options );

    OUTPUT:
        RETVAL

MODULE = Salvation::TC PACKAGE = Salvation::TC

PROTOTYPES: DISABLED
