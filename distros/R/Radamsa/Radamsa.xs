#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "radamsa/c/radamsa.h"

MODULE = Radamsa    PACKAGE = Radamsa

BOOT:
    radamsa_init();

SV *
_mutate_raw(input, max_len, seed)
    SV *input
    size_t max_len
    unsigned int seed
PREINIT:
    STRLEN input_len = 0;
    unsigned char *input_ptr = NULL;
    SV *output = NULL;
    unsigned char *output_ptr = NULL;
    size_t out_len = 0;
CODE:
    if (!SvOK(input)) {
        croak("input must be defined");
    }

    input_ptr = (unsigned char *) SvPVbyte(input, input_len);
    output = newSV(max_len + 1);
    SvPOK_only(output);
    SvGROW(output, max_len + 1);
    output_ptr = (unsigned char *) SvPVX(output);
    out_len = radamsa(input_ptr, (size_t) input_len, output_ptr, max_len, seed);
    SvCUR_set(output, out_len);
    *SvEND(output) = '\0';
    RETVAL = output;
OUTPUT:
    RETVAL
