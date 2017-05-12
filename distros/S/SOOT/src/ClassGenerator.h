
#ifndef __ClassGenerator_h_
#define __ClassGenerator_h_

#include "ROOTIncludes.h"

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

#include <vector>
#include <TString.h>

namespace SOOT {

  /// Create stub for a given class. Calls SetupClassInheritance to set up the inheritance chain
  std::vector<TString> MakeClassStub(pTHX_ const char* className, TClass* theClass);

  /** Set up the FULL inheritance chain for the given class.
   *  Returns an array of all created classes.
   *  Calls MakeClassStub internally.
   *  You should be looking at MakeClassStub instead of calling this directly!
   */
  std::vector<TString> SetupClassInheritance(pTHX_ const char* className, TClass* theClass);

  /// Install new XSUBs for the basic SOOT TObject API. Call MakeClassStub instead!
  void SetupTObjectMethods(pTHX_ const char* className);

  /// Iterates over all known classes (cf. buildtools/ in SOOT) and calls MakeClassStub
  void GenerateClassStubs(pTHX);

  /// Initializes a bunch of globals such as gROOT, etc
  void InitializePerlGlobals(pTHX);

  /** Fetches the given perl global variable and creates a new object holding
   *  the given TObject. The global is made magical with the PreventDestruction
   *  function from TObjectEncapsulation. className is the class into which the
   *  Perl global will be blessed. (Defaults to cobj->ClassName)
   */
  void SetPerlGlobal(pTHX_ const char* variable, TObject* cobj, const char* className = NULL);

  /** Some globals (gPad!) are still NULL at this time. Therefore, we create the Perl
   *  global as usual, but store a pointer to the pointer to the C-global adn make
   *  the object magical via MakeDelayedInitObject. This magic is checked on
   *  access and if found, the global is re-initialized with a proper TObject wrapper.
   *  Also assignes PreventDestruction magic.
   */
  void SetPerlGlobalDelayedInit(pTHX_ const char* variable, TObject** cobj, const char* className);

  /// Unimplemented in XS...
  void SetupAUTOLOAD(pTHX_ const char* className);
} // end namespace SOOT

#endif

