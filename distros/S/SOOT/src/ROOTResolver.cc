
#include "ROOTResolver.h"
#include "SOOTDebug.h"
#include "SOOTTypes.h"
#include "TObjectEncapsulation.h"

#include "PerlCTypeConversion.h"
#include "CPerlTypeConversion.h"
#include "DataMemberAccess.h"
#include <string>
#include <iostream>
#include <sstream>
#include <cstring>
#include <cstdlib>

using namespace SOOT;
using namespace std;

namespace SOOT {
  void
  SetMethodArguments(pTHX_ G__CallFunc& theFunc, AV* args,
                     const vector<BasicType>& argTypes, std::vector<void*>& needsCleanup,
                     const unsigned int nSkip = 1)
  {
    const unsigned int nElem = (unsigned int)(av_len(args)+1);
    for (unsigned int iElem = nSkip; iElem < nElem; ++iElem) {
      SV* const* elem = av_fetch(args, iElem, 0);
      if (elem == NULL)
        croak("av_fetch failed. Severe error.");
      void* vec = NULL;
      size_t len;
      switch (argTypes[iElem]) {
        case eINTEGER:
          theFunc.SetArg((long)SvIV(*elem));
          break;
        case eFLOAT:
          theFunc.SetArg((double)SvNV(*elem));
          break;
        case eSTRING:
          theFunc.SetArg((long)SvPV_nolen(*elem));
          break;
        case eARRAY_INTEGER:
          // FIXME memory leak?
          // allocate C-array here and convert the AV
          vec = (void*)SOOT::AVToIntegerVec<int>(aTHX_ (AV*)SvRV(*elem), len);
          theFunc.SetArg((long)vec);
          needsCleanup.push_back(vec);
          break;
        case eARRAY_FLOAT:
          // FIXME memory leak?
          // allocate C-array here and convert the AV
          vec = (void*)SOOT::AVToFloatVec<double>(aTHX_ (AV*)SvRV(*elem), len);
          theFunc.SetArg((long)vec);
          needsCleanup.push_back(vec);
          break;
        case eARRAY_STRING:
          // FIXME memory leak?
          // allocate C-array here and convert the AV
          vec = (void*)SOOT::AVToCStringVec(aTHX_ (AV*)SvRV(*elem), len);
          theFunc.SetArg((long)vec);
          needsCleanup.push_back(vec);
          break;
        case eTOBJECT:
          theFunc.SetArg((long)LobotomizeObject(aTHX_ *elem));
          break;
        default:
          croak("BAD ARGUMENT");
      }
    }
    return;
  }


  SV*
  ProcessReturnValue(pTHX_ const BasicType& retType, long addr, double addrD, const char* retTypeStr, bool isConstructor, std::vector<void*> needsCleanup)
  {
    char* typeStrWithoutPtr;
    char* ptr;
    unsigned int ptr_level, i;
    SV* retval;

    switch (retType) {
      case eINTEGER:
        retval = newSViv(addr);
        break;
      case eFLOAT:
        retval = newSVnv(addrD);
        break;
      case eSTRING:
        retval = newSVpv((char*)addr, strlen((char*)addr));
        break;
      case eARRAY_INTEGER:
      case eARRAY_FLOAT:
      case eARRAY_STRING:
        // allocate C-array here and convert the AV
        for (i = 0; i < needsCleanup.size(); ++i)
          free(needsCleanup[i]);
        croak("FIXME Array return values to be implemented");
        break;
      case eTOBJECT:
        if ((void*)addr == NULL) {
          retval = &PL_sv_undef;
          break;
        }
        // FIXME this is so hideous it's not even funny
        typeStrWithoutPtr = strdup(retTypeStr);
        ptr = typeStrWithoutPtr;
        ptr_level = 0;
        while (*(ptr++)) {
          if (*ptr == '*')
            ++ptr_level;
        }
        --ptr;
        // FIXME I think this can break on stuff like
        //       char* const* where the *'s aren't all at the end
        if (ptr_level > 0)
          *(ptr - ptr_level) = '\0';
        //cout << "Registering object '" << (void*)addr << "' of type '" << typeStrWithoutPtr << "'" << endl;
        if (ptr-typeStrWithoutPtr >= 13 && !strncmp(ptr-13, "TFitResultPtr", 13)) {
          addr = (long int) ((TFitResultPtr*)addr)->Get();
        }
        retval = SOOT::RegisterObject(aTHX_ (TObject*)addr);
        /* This used to be the following line, but since RegisterObject can ask the object
         * about its classname, we're doing the cleverer thing that way instead of relying
         * on the typeStrWithoutPtr which is bound to be the most general class due to
         * the C++ typing */
        /* retval = SOOT::RegisterObject(aTHX_ (TObject*)addr, typeStrWithoutPtr); */

        // If we're not creating a TObject via a constructor, it's likely not ours to delete
        if (!isConstructor && retval != &PL_sv_undef)
          SOOT::PreventDestruction(aTHX_ (TObject*)addr);
        if (ptr_level > 0)
          *(ptr - ptr_level) = ' ';
        free(typeStrWithoutPtr);
        break;
      case eUNDEF:
        retval = &PL_sv_undef;
        break;
      default:
        for (i = 0; i < needsCleanup.size(); ++i)
          free(needsCleanup[i]);
        croak("Unhandled return type '%s' (SOOT type '%s')", retTypeStr, gBasicTypeStrings[retType]);
    } // end switch ret type

    for (i = 0; i < needsCleanup.size(); ++i)
      free(needsCleanup[i]);
    return retval;
  }


  SV*
  CallMethod(pTHX_ const char* className, char* methName, AV* args)
  {
#ifdef SOOT_DEBUG
    cout << "CallMethod: " << className << "::" << methName << endl;
#endif
    // Determine the class...
    TClass* c = TClass::GetClass(className);
    if (c == NULL)
      croak("Can't locate method \"%s\" via package \"%s\"",
            methName, className);

    vector<BasicType> argTypes;
    vector<string> cproto;
    unsigned int nTObjects = CProtoAndTypesFromAV(aTHX_ args, argTypes, cproto);
#ifdef SOOT_DEBUG
    { char* cp = JoinCProto(cproto);
      cout << "Full C proto: " << (cp==NULL?"NULL":cp) << endl;
      free(cp); }
#endif
    SV* perlCallReceiver;
    BasicType receiverType = eINVALID;
    if (argTypes.size() == 0)
      perlCallReceiver = NULL;
    else {
      // Fetch the call receiver (object or class name)
      SV** elem = av_fetch(args, 0, 0);
      if (elem == 0)
        croak("BAD, elem zero");
      perlCallReceiver = *elem;
      receiverType = argTypes[0];
      if (receiverType != eTOBJECT
          && (receiverType != eSTRING || !strEQ(SvPV_nolen(perlCallReceiver), className))) {
        //croak("Trying to invoke method '%s' on variable of type '%s' is not supported",
        //      methName, gBasicTypeStrings[receiverType]);
        // Assume it's a function
        perlCallReceiver = NULL;
      }
    }

    TObject* receiver;
    G__ClassInfo theClass(className);
    G__MethodInfo* mInfo = NULL;
    long offset;
    bool constructor = false;

    if (perlCallReceiver == NULL) { // function
      receiver = 0;
    }
    else if (receiverType == eSTRING) { // class method
      if (strEQ(methName, "new")) {
        // constructor
        methName = (char*)className; // no need to free since className is also a const char*
        constructor = true;
      }
      receiver = 0;
    }
    else {
      --nTObjects; // The invocant isn't used in FindMethodPrototype
      receiver = LobotomizeObject(aTHX_ perlCallReceiver);
    }
    FindMethodPrototype(theClass, mInfo, methName, argTypes, cproto, offset, nTObjects, (perlCallReceiver == NULL ? true : false), constructor);

    if (!mInfo->IsValid() || !mInfo->Name()) { // check for data members or croak
      delete mInfo;
      bool foundDataMember = false;
      SV* retval = &PL_sv_undef;
      // If we have a $obj->Something() or $obj->Something($value), try to find a data member
      if (!constructor && perlCallReceiver != NULL && cproto.size() > 0 && cproto.size() < 3)
        foundDataMember = FindDataMember(aTHX_ c, methName, cproto, nTObjects, retval, perlCallReceiver, args); // FIXME cproto may have been mangled by FindMethodPrototype
      if (!foundDataMember)
        CroakOnInvalidCall(aTHX_ className, methName, c, cproto, false); // FIXME cproto may have been mangled by FindMethodPrototype
      return retval;
    }

    vector<void*> needsCleanup;
    // Determine return type
    char* retTypeStr;
    if (constructor) {
      retTypeStr = (char*)className;
    } else {
      // The strdup is because the method execution may nuke the return type in the method info...
      retTypeStr = strdup((char*)mInfo->Type()->TrueName());
      needsCleanup.push_back((void*)retTypeStr);
    }
/*    cout << "MINFO="<<mInfo.Name() << " " << mInfo.Title() << " " << mInfo.NArg() << " " << mInfo.FileName() << endl;
    cout << "CINFO="<<mInfo.MemberOf()->Name()<< endl;
    cout << retTypeStr << " " << mInfo.Type()->Name() << endl;
*/
    // FIXME ... defies description
    BasicType retType = GuessTypeFromProto(constructor ? (string(className)+string("*")).c_str() : retTypeStr);

    // Prepare CallFunc
    G__CallFunc theFunc;
    theFunc.SetFunc(*mInfo);

    SetMethodArguments(aTHX_ theFunc, args, argTypes, needsCleanup, (perlCallReceiver == NULL ? 0 : 1));

    long addr = 0;
    double addrD = 0;
    if (retType == eFLOAT)
      addrD = theFunc.ExecDouble((void*)((long)receiver + offset));
    else
      addr = theFunc.ExecInt((void*)((long)receiver + offset));

    delete mInfo;

    //cout << "RETVAL INFO FOR " <<  methName << ": cproto=" << retTypeStr << " mytype=" << gBasicTypeStrings[retType] << endl;
    return ProcessReturnValue(aTHX_ retType, addr, addrD, retTypeStr, constructor, needsCleanup);
  }


  bool
  FindDataMember(pTHX_ TClass* theClass, const char* methName,
                 const std::vector<std::string>& cproto,
                 const unsigned int nTObjects, SV*& retval,
                 SV* perlCallReceiver, AV* args)
  {
    TDataMember* dm = theClass->GetDataMember(methName);
    // return if there is no such data member or of it isn't public
    if (!dm || !(dm->Property() & kIsPublic))
      return false;

    void* objAddr = (void*) SOOT::LobotomizeObject(aTHX_ perlCallReceiver);

    bool isGetter = cproto.size() == 1;
    if (isGetter)
      retval = SOOT::InstallDataMemberToPerlConverter(aTHX_ theClass, methName, dm, objAddr, NULL);
    else {
      SV* argument = *av_fetch(args, 1, 0);
      SOOT::InstallDataMemberToPerlConverter(aTHX_ theClass, methName, dm, objAddr, argument);
    }
    return true;
  }


  void
  FindMethodPrototype(G__ClassInfo& theClass, G__MethodInfo*& mInfo,
                      const char* methName, std::vector<BasicType>& proto,
                      std::vector<std::string>& cproto, long int& offset,
                      const unsigned int nTObjects, bool isFunction,
                      bool isConstructor)

  {
    // This comes practically verbatim from RubyROOT because of the reference map algorithm
    // Note: First element in proto is the invocant type. We need to skip it.
    // TODO: Optimize the repeated concatenation (JoinCProto)

    // 2^nobjects == number of combinations of "*" and "&"
    unsigned int bitmap_end = static_cast<unsigned int>( 0x1 << nTObjects );

    // Check for copy constructor. new TSome(TSome*) becomes new TSome(const TSome&)
    if (isConstructor && cproto.size() == 2 && proto[1] == eTOBJECT) {
      string clNameStr = string(theClass.Name());
      if (cproto[1] == clNameStr+string("*"))
        cproto[1] = string("const ") + clNameStr + string("&");
    }

    // Check if method methname with prototype cproto is present in the class
    char* cprotoStr = JoinCProto(cproto, (isFunction ? 0 : 1));
    bool freeCProtoStr = true;
    if (cprotoStr == NULL) {
      cprotoStr = (char*)"";
      freeCProtoStr = false;
    }
    if (isFunction) {
      // FIXME AAAAAAAAAAAAAAAAAAH! This is embarrassing
      TClass c(theClass.Name());
      TMethod* meth = c.GetMethodWithPrototype(methName, cprotoStr);
      if (!meth)
        CroakOnInvalidCall(aTHX_ theClass.Name(), methName, &c, cproto, true);
      void* ptr = meth->InterfaceMethod();
      if (!ptr)
        CroakOnInvalidCall(aTHX_ theClass.Name(), methName, &c, cproto, true);
      delete mInfo;
      mInfo = new G__MethodInfo(theClass);
      bool found = false;
      while (mInfo->Next()) {
        if (ptr == mInfo->InterfaceMethod()) {
          found = true;
          break;
        }
      }
      if (!found)
        CroakOnInvalidCall(aTHX_ theClass.Name(), methName, &c, cproto, true);
    } else {
      delete mInfo;
      mInfo = new G__MethodInfo(theClass.GetMethod(methName, cprotoStr, &offset));
    }
    if (freeCProtoStr)
      free(cprotoStr);

    /* Loop if we have to, i.e. there are T_OBJECTS ^= TObjects and the first
     * combination is not correct.
     */
    if( nTObjects > 0 and !(mInfo->InterfaceMethod()) ) {
      for( unsigned int reference_map=0x1; reference_map < bitmap_end; ++reference_map) {
        TwiddlePointersAndReferences(proto, cproto, reference_map);
        char* cprotoStr = JoinCProto(cproto, (isFunction ? 0 : 1));
        bool freeCProtoStr = true;
        if (cprotoStr == NULL) {
          cprotoStr = (char*)"";
          freeCProtoStr = false;
        }
        delete mInfo;
        mInfo = new G__MethodInfo(theClass.GetMethod(methName, cprotoStr, &offset));
        if (freeCProtoStr)
          free(cprotoStr);
        if (mInfo->InterfaceMethod())
          break;
      }

      // Now with int* => double* if necessary
      if (!(mInfo->InterfaceMethod()) && CProtoIntegerToFloat(cproto)) { // found int* => double*
        for( unsigned int reference_map=0x1; reference_map < bitmap_end; ++reference_map) {
          TwiddlePointersAndReferences(proto, cproto, reference_map);
          char* cprotoStr = JoinCProto(cproto, (isFunction ? 0 : 1));
          bool freeCProtoStr = true;
          if (cprotoStr == NULL) {
            cprotoStr = (char*)"";
            freeCProtoStr = false;
          }
          delete mInfo;
          mInfo = new G__MethodInfo(theClass.GetMethod(methName, cprotoStr, &offset));
          if (freeCProtoStr)
            free(cprotoStr);
          if (mInfo->InterfaceMethod())
            break;
        }
      } // end if need to try int* => double*
    } // end if first guess was bad
  }

  void
  TwiddlePointersAndReferences(std::vector<BasicType>& proto, std::vector<std::string>& cproto,
                               unsigned int reference_map)
  {
    const unsigned int nElems = proto.size();
#define CHECK_BIT(var,pos) ((var)&(1<<(pos)))
    for (unsigned int i = 1; i < nElems; ++i) {
      if (proto[i] == eTOBJECT) {
        std::string& elem = cproto[i];
        if (CHECK_BIT(reference_map, i))
          elem[elem.length()-1] = '&';
        else
          elem[elem.length()-1] = '*';
      }
    }
#undef CHECK_BIT
  }


  SV*
  CallAssignmentOperator(pTHX_ const char* className, SV* receiver, SV* model)
  {
    AV* argAV = newAV();
    av_extend(argAV, 1);
    av_store(argAV, 0, receiver); // FIXME check reference counts?
    av_store(argAV, 1, model);
    SV* retval = CallMethod(aTHX_ className, (char*)className, argAV);
    Safefree(argAV); // FIXME check for memory leaks?
    return retval;
    //return receiver;
  }


  void
  CroakOnInvalidCall(pTHX_ const char* className, const char* methName, TClass* c, const std::vector<std::string>& cproto, bool isFunction = false)
  {
    ostringstream msg;
    char* cprotoStr = JoinCProto(cproto);
    if (cprotoStr == NULL)
      cprotoStr = strdup("void");

    vector<string> candidates;
    TIter next(c->GetListOfAllPublicMethods());
    TFunction* meth;
    while ((meth = (TFunction*)next())) {
      if (strEQ(meth->GetName(), methName)) {
        candidates.push_back(string(meth->GetPrototype()));
      }
    }

    const char* what = (isFunction ? "function" : "method");
    msg << "Can't locate " << what << " \"" << methName << "\" via package \""
        << className << "\". From the arguments you supplied, the following C prototype was calculated:\n  "
        << className << "::" << methName << "(" << cprotoStr << ")";
    free(cprotoStr);
    if (!candidates.empty()) {
      msg << "\nThere were the following class members of the same name, but with a different prototype:";
      for (unsigned int iCand = 0; iCand < candidates.size(); ++iCand) {
        msg << "\n  " << candidates[iCand];
      }
    }
    croak("%s", msg.str().c_str());
  }
} // end namespace SOOT

