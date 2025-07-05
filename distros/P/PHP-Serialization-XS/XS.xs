/* vim:set ts=4 sw=4 et syntax=xs.doxygen: */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "ps_parser.h"
#include "stringstore.h"
#include "convert.h"

static char _error_msg[256] = "Unknown error";
static void _register_error(const char *msg)
{
    strncpy(_error_msg, msg, sizeof _error_msg);
}

static void _croak(const char *msg)
{
    SV *errsv = get_sv("@", TRUE);
    sv_setsv(errsv, newSVpvf("%s\n", msg));
    croak(Nullch);
}

MODULE = PHP::Serialization::XS		PACKAGE = PHP::Serialization::XS		

PROTOTYPES: ENABLE

SV *
_c_decode(SV *input, SV *preference, ...)
    CODE:
        struct ps_parser_state *ps_state;
        ps_parser_error_handler = _register_error;
        if (ps_init(&ps_state))
            _croak("ERROR: Failed to init ps_parser");

        const char *str = SvPV_nolen_const(input);
        ps_read_string_init(ps_state, (void*)str);
        struct ps_node *node = ps_parse(ps_state);
        if (node == PS_PARSE_FAILURE)
            _croak(_error_msg);

        const char *claxx = NULL;
        if (items > 2 && SvOK(ST(2)))
            claxx = (char *)SvPV_nolen(ST(2));

        RETVAL = _convert_recurse(node, SvIV(preference), claxx);

        ps_read_string_fini(ps_state);
        ps_free(node);
        ps_fini(&ps_state);
    OUTPUT:
        RETVAL

