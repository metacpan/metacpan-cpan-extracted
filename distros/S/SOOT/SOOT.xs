
/* must load ROOT stuff veeery early due to pollution */
#include "ROOTIncludes.h"

/* For versions of ExtUtils::ParseXS > 3.04_02, we need to
 * explicitly enforce exporting of XSUBs since we want to
 * refer to them using XS(). This isn't strictly necessary,
 * but it's by far the simplest way to be backwards-compatible.
 */
#define PERL_EUPXS_ALWAYS_EXPORT

#include "SOOTDebug.h"

// manually include headers for classes with explicit wrappers
// rootclasses.h was auto-generated to include all ROOT headers
// for which there is a ROOT_XSP/...xsp file
#include "rootclasses.h"

#include "CPerlTypeConversion.h"
#include "PerlCTypeConversion.h"
#include "SOOTTypes.h"
#include "ClassGenerator.h"
#include "TObjectEncapsulation.h"
#include "ROOTResolver.h"
#include "ClassIterator.h"
#include "PtrTable.h"
#include "TExecImpl.h"
#include "PerlCallback.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#undef do_open
#undef do_close
#ifdef __cplusplus
}
#endif

#include "const-c.inc"

#include <iostream>
#include <string>
#include <vector>
#include <cstring>

using namespace SOOT;
using namespace std;

/*
// Broken due to bug in perl.
void
AUTOLOAD(...)
  PPCODE:
    SV* fullname = get_sv("AUTOLOAD", 0);
    if (fullname == 0 || !SvOK(fullname))
      croak("$AUTOLOAD undefined in AUTOLOAD");
    STRLEN len;
    char* strptr = SvPV(fullname, len);
    if (len < 2)
      croak("$AUTOLOAD is empty string in AUTOLOAD");
    char* lastcolon = strptr+len;
    for (; lastcolon != strptr; --lastcolon) {
      if (*lastcolon == ':')
        break;
    }
    if (lastcolon == strptr)
      croak("Cannot autoload method call without a class");
    *(lastcolon-1) = '\0';
    SV* class_name = newSVpv(strptr, lastcolon-1-strptr);
    *(lastcolon-1) = ':';
    SV* method_name = newSVpv(lastcolon+1, strptr+len-lastcolon);
    cout << class_name << endl;
    cout << method_name << endl;
    sv_2mortal(class_name);
    sv_2mortal(method_name);
    XSRETURN_UNDEF;
*/


MODULE = SOOT		PACKAGE = SOOT

PROTOTYPES: DISABLE

INCLUDE: ../const-xs.inc

INCLUDE: ../XS/SOOTBOOT.xs

INCLUDE: ../XS/SOOTAPI.xs

INCLUDE: ../XS/TObject.xs

INCLUDE: ../RunTimeXS/SOOT_RTXS.xs

INCLUDE: ../rootclasses.xsinclude

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t ../typemap.xsp ../XS/ClassIterator.xsp

MODULE = SOOT		PACKAGE = SOOT

SV*
CallMethod(className, methodName, argv)
    char* className
    char* methodName
    SV* argv
  INIT:
    AV* arguments;
  CODE:
  /*
   * Strategy:
   * - Is it a class or object method call?
   *   => if first argument is an eSTRING, it's a class method call
   *   => otherwise, object method (double check with eTOBJECT)
   * - If it's a class method, check for constructor
   * - convert parameters to cproto
   * - resolve method via CINT
   * - resolve return type via CINT
   * - caching?
   * - convert arguments to state suitebable for CINT
   * - call method
   * - convert return type to SV*
   * - return
   * 
   */
    /* not a reference to an array of arguments? */
    if (!SvROK(argv) || SvTYPE(SvRV(argv)) != SVt_PVAV)
      croak("Need array reference as third argument");
    arguments = (AV*)SvRV(argv);
    RETVAL = SOOT::CallMethod(aTHX_ className, methodName, arguments);
  OUTPUT: RETVAL


SV*
CallAssignmentOperator(className, receiver, model)
    char* className
    SV* receiver
    SV* model
  CODE:
    croak("CallAssignmentOperator not implemented correctly");
    RETVAL = SOOT::CallAssignmentOperator(aTHX_ className, receiver, model);
  OUTPUT: RETVAL


SV*
GenerateROOTClass(className)
    char* className
  CODE:
    TClass* cl = TClass::GetClass(className);
    if (!cl)
      RETVAL = &PL_sv_undef;
    else {
      std::vector<TString> classes = SOOT::MakeClassStub(aTHX_ className, NULL);
      // Convert vector<TString> to AV.
      // FIXME test for leaks and make a typemap
      AV* av = newAV();
      RETVAL = newRV_noinc((SV*)av);
      const unsigned int len = classes.size();
      av_extend(av, len-1);
      for (unsigned int i = 0; i < len; ++i)
        av_store(av, i, newSVpv(classes[i].Data(), classes[i].Length()));
    }
  OUTPUT: RETVAL


void
GenerateClassStubs()
  PPCODE:
    SOOT::GenerateClassStubs(aTHX);


