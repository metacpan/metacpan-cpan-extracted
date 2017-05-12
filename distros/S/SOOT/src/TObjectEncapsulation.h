
#ifndef __TObjectEncapsulation_h_
#define __TObjectEncapsulation_h_

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

#include "PtrTable.h"

namespace SOOT {

   /// This class exists for the sole purpose of letting ROOT call into RecursiveRemove for clearing out TObject's
   /// Only instance should live in XS/SOOTBOOT.xs
   class TTObjectEncapsulator : public TObject {
   public:
     TTObjectEncapsulator() {}
     ~TTObjectEncapsulator() {}
     /// callback for ROOT/CINT
     virtual void RecursiveRemove( TObject* object );
   };

  extern MGVTBL gDelayedInitMagicVTable; // used for identification of our DelayedInit magic
  extern PtrTable* gSOOTObjects;

  /** Registers a new TObject with the SOOT object table and returns a new
   *  Perl object that encapsulates it. If the TObject was known before,
   *  this increments the internal refcount and returns a Perl object that
   *  refers to the same TObject.
   *  "className" defaults to calling the TObject's ClassName method.
   *  If "theReference" is given, that SV* will be made the new Perl object.
   */
  SV* RegisterObject(pTHX_ TObject* theROOTObject, const char* className = NULL, SV* theReference = NULL);
  /// Same as RegisterObject but fetches the ROOT object from the given Perl scalar
  SV* RegisterObject(pTHX_ SV* thePerlObject, const char* className = NULL);

  /** Unregisters a Perl object with the SOOT object table, sets it to undef
   *  and possibly also frees the underlying ROOT object if it's the last
   *  reference.
   *  If "mustNotClearRefPad" is set, the containing PtrAnnotation isn't freed.
   *  Returns whether or not the underlying ROOT object was freed.
   */
  bool UnregisterObject(pTHX_ SV* thePerlObject, bool mustNotClearRefPad = false);

  /** Given a Perl object (SV*) that's known to be one of our mock TObject like
   *  creatures, fetch the class name and the ROOT object.
   */
  TObject* LobotomizeObject(pTHX_ SV* thePerlObject, char*& className);
  /// Same as the other LobotomizeObject but ignoring the class name
  TObject* LobotomizeObject(pTHX_ SV* thePerlObject);

  /** Free the underlying TObject, set pointer to zero.
   *  This is to be considered INTERNAL TO SOOT only. => See UnregisterObject instead
   */
  void ClearObject(pTHX_ SV* thePerlObject);
  
  /// Prevents destruction of an object by noting the fact in the object table (SV* variant ==> slow)
  void PreventDestruction(pTHX_ SV* thePerlObject);
  /// Prevents destruction of an object by noting the fact in the object table (TObject variant ==> fast)
  void PreventDestruction(pTHX_ TObject* theROOTObject);

  /// Marks a given object as destructible by Perl
  void MarkForDestruction(pTHX_ SV* thePerlObject);

  /// Returns whether the TObject encapsulated in the given Perl object may be freed by SOOT (SV* variant ==> slow)
  bool IsIndestructible(pTHX_ SV* thePerlObject);
  /// Returns whether the TObject encapsulated in the given Perl object may be freed by SOOT (TObject* variant ==> fast)
  bool IsIndestructible(pTHX_ TObject* theROOTObject);

  /// Creates a new Perl TObject wrapper (as with RegisterObject) that dereferences itself on first access
  SV* MakeDelayedInitObject(pTHX_ TObject** cobj, const char* className);

  /// Replaces the object with its C-level dereference and removes the DelayedInit magic
  void DoDelayedInit(pTHX_ SV* thePerlObject);

  /// Compares to Perl objects by comparing their underlying TObjects
  bool IsSameTObject(pTHX_ SV* perlObj1, SV* perlObj2);
} // end namespace SOOT

#include "TObjectEncapsulation.inline.h"

#endif

