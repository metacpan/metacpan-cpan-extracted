/* vim:set ts=4 sw=4 et syntax=xs.doxygen: */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "ps_parser.h"
#include "stringstore.h"
#include "convert.h"

typedef struct self {
    int flags;  ///< flags controlling deserialization
    SV *parent; ///< a PHP::Serialization object
} *self;

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

// some code adapted from Heap::Simple::XS
#define C_SELF(object, context) c_self(aTHX_ object, context)

static self c_self(pTHX_ SV *object, const char *context)
{
    if (!SvROK(object)) {
        if (SvOK(object)) croak("%s is not a reference", context);
        croak("%s is undefined", context);
    }

    SV *sv = SvRV(object);
    if (!SvOBJECT(sv)) croak("%s is not an object reference", context);
    HV *stash = SvSTASH(sv);
    HV *class_stash = gv_stashpv("PHP::Serialization::XS", FALSE);
    /// @todo check for isa
    IV address = SvIV(sv);
    return INT2PTR(self, address);
}

static void option(pTHX_ self me, SV *tag, SV *value)
{
    STRLEN len, len2;
    char *key = SvPV(tag, len);
    char *val = SvPV(value, len2);
    if (!strcmp(key, "prefer_hash")) {
        if (SvIV(value)) {
            me->flags |=  PS_XS_PREFER_HASH;
            me->flags &= ~PS_XS_PREFER_ARRAY;
            me->flags &= ~PS_XS_PREFER_UNDEF;
        }
    } else if (!strcmp(key, "prefer_undef")) {
        if (SvIV(value)) {
            me->flags |=  PS_XS_PREFER_UNDEF;
            me->flags &= ~PS_XS_PREFER_HASH;
            me->flags &= ~PS_XS_PREFER_ARRAY;
        }
    } else if (!strcmp(key, "prefer_array")) {
        if (SvIV(value)) {
            me->flags |=  PS_XS_PREFER_ARRAY;
            me->flags &= ~PS_XS_PREFER_HASH;
            me->flags &= ~PS_XS_PREFER_UNDEF;
        }
    } else {
        warn("Unknown option %s => %s", key, val);
    }
}

MODULE = PHP::Serialization::XS		PACKAGE = PHP::Serialization::XS		

PROTOTYPES: ENABLE

SV *
_get_parent(self me)
    CODE:
        RETVAL = me->parent;
    OUTPUT:
        RETVAL

SV *
new(char *class, ...)
    PREINIT:
        self me;
    CODE:
        New(__LINE__, me, 1, struct self);
        if (items % 2 == 0) croak("Odd number of elements in options");
        me->flags = 0;
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, class, (void*) me);

        for (int i = 1; i < items; i += 2) option(aTHX_ me, ST(i), ST(i + 1));

        /// @todo replace this eval with a more XS-y way of calling the
        /// super-class's new
        /// @todo permit passing parameters to this call
        me->parent = eval_pv("PHP::Serialization->new", true);
        SvREFCNT_inc(me->parent);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

SV *
_c_decode(self me, SV *input, ....)
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

        RETVAL = _convert_recurse(node, me->flags, claxx);

        ps_free(node);
        ps_fini(&ps_state);
    OUTPUT:
        RETVAL

