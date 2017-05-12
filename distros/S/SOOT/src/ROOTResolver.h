
#ifndef __ROOTResolver_h_
#define __ROOTResolver_h_

#include <TROOT.h>
#include <TClass.h>
#include <TCint.h>
#include <TMethod.h>

#include <CallFunc.h>
#include <Class.h>
#include <TVirtualPad.h>

#include <vector>
#include <string>

#include "SOOTTypes.h"

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
  void FindMethodPrototype(G__ClassInfo& theClass, G__MethodInfo*& mInfo,
                           const char* methName, std::vector<BasicType>& proto,
                           std::vector<std::string>& cproto, long int& offset,
                           const unsigned int nTObjects, bool isFunction,
                           bool isConstructor);

  /*** Checks whether a data member of the given name (methName) exists and is public.
   *   If so, it either fetches from it or assigns to it depending on whether one or zero
   *   arguments were supplied.
   */
  bool FindDataMember(pTHX_ TClass* theClass, const char* methName,
                      const std::vector<std::string>& cproto, const unsigned int nTObjects,
                      SV*& retval, SV* perlCallReceiver, AV* args);

  void TwiddlePointersAndReferences(std::vector<BasicType>& proto, std::vector<std::string>& cproto,
                                    unsigned int reference_map);

  void SetMethodArguments(pTHX_ G__CallFunc& theFunc, AV* args,
                          const std::vector<BasicType>& argTypes,
                          std::vector<void*>& needsCleanup, const unsigned int nSkip);

  SV* ProcessReturnValue(pTHX_ const BasicType& retType, long addr, double addrD, const char* retTypeStr, bool isConstructor, std::vector<void*> needsCleanup);
      
  SV* CallMethod(pTHX_ const char* className, char* methName, AV* args);
  SV* CallAssignmentOperator(pTHX_ const char* className, SV* receiver, SV* model);

  void CroakOnInvalidCall(pTHX_ const char* className, const char* methName,
                          TClass* c, const std::vector<std::string>& cproto, bool isFunction);
} // end namespace SOOT

#endif

