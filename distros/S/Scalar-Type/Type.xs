#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

SV* _scalar_type(SV* argument) {
    SV* rval;
    static char num_as_str[100]; /* potential buffer overflow on 256-bit machines :-) */

    if(SvIOK(argument)) {
        if(SvPOK(argument)) {
            /* int is also a string, better see if it's not int-ified 007 */
            sprintf(
                num_as_str,
                (SvIsUV(argument) ? "%" UVuf        : "%" IVdf),
                (SvIsUV(argument) ? SvUVX(argument) : SvIVX(argument))
            );
            rval = (
                (strcmp(SvPVX(argument), num_as_str)) == 0
                    ? newSVpv("INTEGER", 7)
                    : newSVpv("SCALAR",  6)
            );
        } else {
            rval = newSVpv("INTEGER", 7);
        }
    } else if(SvNOK(argument)) {
        if(SvPOK(argument)) {
            /* float is also a string, better see if it's not float-ified 007.5 */
            sprintf(num_as_str, "%" NVgf, SvNVX(argument));
            rval = (
                (strcmp(SvPVX(argument), num_as_str)) == 0
                    ? newSVpv("NUMBER", 6)
                    : newSVpv("SCALAR", 6)
            );
        } else {
            rval = newSVpv("NUMBER", 6);
        }
    } else {
        rval = newSVpv("SCALAR",  6);
    }

    return rval;
}


MODULE = Scalar::Type  PACKAGE = Scalar::Type  

PROTOTYPES: DISABLE

SV *
_scalar_type (argument)
	SV *	argument

