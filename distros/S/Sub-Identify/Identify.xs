#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifndef CvISXSUB
#   define CvISXSUB(cv) CvXSUB(cv)
#endif

/*
get_code_info:
  Pass in a coderef, returns:
  [ $pkg_name, $coderef_name ] ie:
  [ 'Foo::Bar', 'new' ]
*/

MODULE = Sub::Identify   PACKAGE = Sub::Identify

PROTOTYPES: ENABLE

void
get_code_info(coderef)
    SV* coderef
    PREINIT:
        char* name;
        char* pkg;
    PPCODE:
        if (SvOK(coderef) && SvROK(coderef) && SvTYPE(SvRV(coderef)) == SVt_PVCV) {
            coderef = SvRV(coderef);
            if (CvGV(coderef)) {
                name = GvNAME( CvGV(coderef) );
                pkg = HvNAME( GvSTASH(CvGV(coderef)) );
                EXTEND(SP, 2);
                PUSHs(sv_2mortal(newSVpvn(pkg, strlen(pkg))));
                PUSHs(sv_2mortal(newSVpvn(name, strlen(name))));
            }
            else {
                /* sub is being compiled: bail out and return nothing. */
            }
        }

void
get_code_location(coderef)
    SV* coderef
    PREINIT:
        char* file;
        line_t line;
    PPCODE:
        if (SvOK(coderef) && SvROK(coderef) && SvTYPE(SvRV(coderef)) == SVt_PVCV) {
            coderef = SvRV(coderef);
            if (CvSTART(coderef) && !CvISXSUB(coderef)) {
                file = CvFILE(coderef);
                line = CopLINE((const COP*)CvSTART(coderef));
                EXTEND(SP, 2);
                PUSHs(sv_2mortal(newSVpvn(file, strlen(file))));
                PUSHs(sv_2mortal(newSViv(line)));
            }
        }

#if PERL_VERSION >= 16

bool
is_sub_constant(coderef)
    SV* coderef
    CODE:
        if (SvOK(coderef) && SvROK(coderef) && SvTYPE(SvRV(coderef)) == SVt_PVCV) {
            coderef = SvRV(coderef);
            RETVAL = CvPROTO(coderef) && CvPROTOLEN(coderef) == 0 && CvCONST(coderef);
        }
        else
            RETVAL = 0;
    OUTPUT:
        RETVAL

#endif
