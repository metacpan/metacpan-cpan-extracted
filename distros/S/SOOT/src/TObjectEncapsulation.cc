
#include "TObjectEncapsulation.h"
#include "SOOTDebug.h"

#include <string>
#include <iostream>
#include <cstring>
#include <cstdlib>

using namespace SOOT;
using namespace std;

#include "PtrTable.h"

namespace SOOT {
  PtrTable* gSOOTObjects = NULL;

  // Inspired by XS::Variable::Magic
  MGVTBL gDelayedInitMagicVTable= {
      NULL, /* get */
      NULL, /* set */
      NULL, /* len */
      NULL, /* clear */
      NULL, /* free */
#if MGf_COPY
      NULL, /* copy */
#endif /* MGf_COPY */
#if MGf_DUP
      NULL, /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
      NULL, /* local */
#endif /* MGf_LOCAL */
  };


  SV*
  RegisterObject(pTHX_ TObject* theROOTObject, const char* className, SV* theReference)
  {
    if (theROOTObject == NULL)
      return &PL_sv_undef;

    if (className == NULL)
      className = theROOTObject->ClassName();

    // Fetch the reference pad for this TObject
    PtrAnnotation* refPad = gSOOTObjects->FetchOrCreate(theROOTObject);

    ++(refPad->fNReferences);

    if (theReference == NULL)
      theReference = newSV(0);

    sv_setref_pv(theReference, className, (void*)theROOTObject );
    // This was done for std::list
    //(refPad->fPerlObjects).push_back(theReference);
    (refPad->fPerlObjects).insert(theReference);

    theROOTObject->SetBit(kMustCleanup);

    return theReference;
  }


  bool
  UnregisterObject(pTHX_ SV* thePerlObject, bool mustNotClearRefPad)
  {
    if (!SvROK(thePerlObject))
      return false;
    SV* inner = (SV*)SvRV(thePerlObject);
    if (!SvIOK(inner))
      return false;
    //DoDelayedInit(aTHX_ thePerlObject); // FIXME not necessary?
    TObject* obj = INT2PTR(TObject*, SvIV(inner));
    if (obj == NULL)
      return false;
    
    // It's global destruction
    if (SOOT::gSOOTObjects == NULL) {
      return false;
    }

    // Fetch the reference pad for this TObject
    PtrAnnotation* refPad = gSOOTObjects->Fetch(obj);
    if (!refPad)
      return false;

    --(refPad->fNReferences);
    (refPad->fPerlObjects).erase(thePerlObject); // nuke the SV* in the set
    sv_setiv(inner, 0);

    // FIXME doesn't work / isn't necessary?
    //sv_setsv_nomg(thePerlObject, &PL_sv_undef);

    bool was_freed = false;
    if (refPad->fNReferences == 0) {
      bool doNotDestroyTObj = refPad->fDoNotDestroy;
      gSOOTObjects->Delete(obj); // also frees refPad if necessary!
      if (!doNotDestroyTObj) {
      //if (!refPad->fDoNotDestroy && obj->TestBit(kCanDelete)) {
        //gDirectory->Remove(obj); // TODO investigate Remove vs. RecursiveRemove -- Investigate necessity, too.
        //obj->SetBit(kMustCleanup);
        //cout << "Deleting TObject '" << (void*) obj << "'" << endl;
        // Wild contortions just to call a destructor
        const char* className = HvNAME(SvSTASH(SvRV(thePerlObject)));
        G__ClassInfo cInfo(className);
        string methName = string("~") + string(className);
        long offset;
        G__CallFunc func;
        func.SetFunc(&cInfo, methName.c_str(), "", &offset);
        func.Exec((void*)((long)obj+offset));
        func.Init(); // FIXME is this needed?
        //delete (void*)obj;
        was_freed = true;
      }
    }

    return was_freed;
  }


  void
  PreventDestruction(pTHX_ SV* thePerlObject) {
    // We accept either a reference (i.e. the blessed object)
    // or the already dereferenced object which is really just an
    // SvIOK with the pointer to the TObject.

    // Dereference if necessary
    if (SvROK(thePerlObject))
      thePerlObject = (SV*)SvRV(thePerlObject);

    // Check that we have what we presume to be a pointer
    if (SvIOK(thePerlObject)) {
      TObject* ptr = INT2PTR(TObject*, SvIV(thePerlObject));
      PtrAnnotation* refPad = gSOOTObjects->Fetch(ptr);
      if (ptr == NULL || refPad == NULL) {
        // late intialization always prevents destruction
        return;
      }
      else {
        // Normal encapsulated TObject
        refPad->fDoNotDestroy = true;
      }
    } // end if it's a good object
    else
      croak("BAD");
  }


  void
  MarkForDestruction(pTHX_ SV* thePerlObject) {
    if (SvROK(thePerlObject) && SvIOK((SV*)SvRV(thePerlObject))) {
      SV* inner = (SV*)SvRV(thePerlObject);
      TObject* ptr = INT2PTR(TObject*, SvIV(inner));
      PtrAnnotation* refPad = gSOOTObjects->Fetch(ptr);
      if (ptr == NULL || refPad == NULL) {
        // late intialization always prevents destruction
        return;
      }
      else {
        // Normal encapsulated TObject
        refPad->fDoNotDestroy = false;
      }
    } // end if it's a good object
    else
      croak("BAD");
  }


  SV*
  MakeDelayedInitObject(pTHX_ TObject** cobj, const char* className) {
    SV* ref = newSV(0);
    sv_setref_pv(ref, className, (void*)cobj);
    sv_magicext(SvRV(ref), NULL, PERL_MAGIC_ext, &gDelayedInitMagicVTable, 0, 0 );
    return ref;
  }


  void
  DoDelayedInit(pTHX_ SV* thePerlObj) {
    // My hat goes off to XS::Variable::Magic.
    // Essentially, we just check whether the attached magic is *exactly* the type
    // (and value, we use g as an identifier) of our delayed-init
    // magic.
    SV* derefPObj = SvRV(thePerlObj);
    MAGIC *mg;
    if (SvTYPE(derefPObj) >= SVt_PVMG) {
      for (mg = SvMAGIC(derefPObj); mg; mg = mg->mg_moremagic) {
        if ((mg->mg_type == PERL_MAGIC_ext)) {
          if (mg->mg_virtual == &gDelayedInitMagicVTable) {
            TObject* ptr = *INT2PTR(TObject**, SvIV(derefPObj));
            sv_unmagic(derefPObj, PERL_MAGIC_ext);
            // Fetch the reference pad for this TObject and append this SV
            PtrAnnotation* refPad = gSOOTObjects->FetchOrCreate(ptr);
            ++(refPad->fNReferences);
            sv_setpviv(derefPObj, PTR2IV(ptr));
            // This was done for std::list
            //(refPad->fPerlObjects).push_back(thePerlObj);
            (refPad->fPerlObjects).insert(thePerlObj);
            refPad->fDoNotDestroy = true; // can't destroy late init objects
          }
          break;
        } // end is PERL_MAGIC_ext magic
      } // end foreach magic
    } // end if magical
  }

  void
  TTObjectEncapsulator::RecursiveRemove(TObject* object)
  {
    // global destruction...
    if (!object || !gSOOTObjects)
      return;

    //cout << "ROOT asks us to remove references to " << object << endl;
    //cout << "It is a " << object->ClassName() << endl;
    //gSOOTObjects->PrintStats();

    // Nuke it!
    gSOOTObjects->Delete(object);
  }


  bool
  IsSameTObject(pTHX_ SV* perlObj1, SV* perlObj2)
  {
    void* tobj1 = (void*)LobotomizeObject(aTHX_ perlObj1);
    void* tobj2 = (void*)LobotomizeObject(aTHX_ perlObj2);
    return(tobj1 == tobj2);
  }
} // end namespace SOOT

