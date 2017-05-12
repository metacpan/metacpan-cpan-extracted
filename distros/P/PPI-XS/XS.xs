#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

MODULE = PPI::XS	PACKAGE = PPI::XS

PROTOTYPES: DISABLE

SV *
_PPI_Element__significant (self)
    SV *    self
PPCODE:
{
    XSRETURN_YES;
}

SV *
_PPI_Token_Comment__significant (self)
    SV *    self
PPCODE:
{
    XSRETURN_NO;
}

SV *
_PPI_Token_Whitespace__significant (self)
    SV *    self
PPCODE:
{
    XSRETURN_NO;
}

SV *
_PPI_Token_End__significant (self)
    SV *    self
PPCODE:
{
    XSRETURN_NO;
}
