
#ifndef __DataMemberAccess_h_
#define __DataMemberAccess_h_

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

namespace SOOT {
  // FIXME for now, we punt on multi-dim arrays. C->Perl conversion would be trivial, but the other way, not so due to variable dimension size in Perl

  /** Installs a new XSUB that converts the given ROOT TDataMember
   *  of the struct/object that lives at baseAddr to a Perl structure.
   *  Additionally performs the conversion and returns the result.
   *  Calls InstallArrayDataMemberToPerlConverter as appropriate.
   */
  SV* InstallDataMemberToPerlConverter(pTHX_ TClass* theClass, const char* methName,
                                       TDataMember* dm, void* baseAddr, SV* argument);
  /// Internal to InstallDataMemberToPerlConverter!
  SV* InstallArrayDataMemberToPerlConverter(pTHX_ TClass* theClass, const char* methName,
                                            TDataMember* dm, void* baseAddr, SV* argument);
} // end namespace SOOT

#endif

