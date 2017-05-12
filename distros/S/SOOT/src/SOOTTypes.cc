
#include "SOOTTypes.h"
#include "SOOTDebug.h"

#include <string>
#include <iostream>
#include <sstream>
#include <cstring>
#include <cstdlib>

using namespace SOOT;
using namespace std;

namespace SOOT {
  const char* gBasicTypeStrings[13] = {
    "UNDEF",
    "INTEGER",
    "FLOAT",
    "STRING",
    "INTEGER_ARRAY",
    "FLOAT_ARRAY",
    "STRING_ARRAY",
    "INVALID_ARRAY",
    "HASH",
    "CODE",
    "REF",
    "TOBJECT",
    "INVALID",
  };


  /* Lifted from autobox. My eternal gratitude goes to the
   * ever impressive Chocolateboy!
   */
  SOOT::BasicType
  GuessType(pTHX_ SV* const sv)
  {
    switch (SvTYPE(sv)) {
      case SVt_NULL:
        return eUNDEF;
      case SVt_IV:
        if (SvROK(sv))
          goto DEFAULT; // sue me, this is a 5.12 fix (FIXME refactor)
        else
          return eINTEGER;
      case SVt_PVIV:
        if (SvIOK(sv))
          return eINTEGER;
        else
          return eSTRING;
      case SVt_NV:
        if (SvIOK(sv))
          return eINTEGER;
        else
          return eFLOAT;
      case SVt_PVNV:
        if (SvIOK(sv))
          return eINTEGER;
        else if (SvNOK(sv))
          return eFLOAT;
        else
          return eSTRING;
#ifdef SVt_RV /* no longer defined by default if PERL_CORE is defined */
#if (SVt_RV != SVt_IV)
      case SVt_RV:
#endif
#endif
      case SVt_PV:
#ifdef SvVOK
        if (SvVOK(sv))
          return eINVALID; // VSTRING
#endif
        if (SvROK(sv)) {
#ifdef SOOT_DEBUG
          cout << "Svt_PV && SvROK" << endl;
#endif
          return eREF;
        } else {
          return eSTRING;
        }
      case SVt_PVMG:
#ifdef SvVOK
        if (SvVOK(sv))
          return eINVALID; // VSTRING
#endif
        if (SvROK(sv)) {
#ifdef SOOT_DEBUG
          cout << "Svt_PVMG && SvROK && (IsTObject(aTHX_ sv) ? eTOBJECT : eREF)" << endl;
#endif
          return IsTObject(aTHX_ sv) ? eTOBJECT : eREF;
        } else {
          return eSTRING;
        }
      case SVt_PVLV:
        if (SvROK(sv)) {
#ifdef SOOT_DEBUG
          cout << "Svt_PVLV && SvROK && (IsTObject(aTHX_ sv) ? eTOBJECT : eREF)" << endl;
#endif
          return IsTObject(aTHX_ sv) ? eTOBJECT : eREF;
        }
        else if (LvTYPE(sv) == 't' || LvTYPE(sv) == 'T') { /* tied lvalue */
          if (SvIOK(sv))
            return eINTEGER;
          else if (SvNOK(sv))
            return eFLOAT;
          else
            return eSTRING;
        } else {
#ifdef SOOT_DEBUG
          cout << "lval"<<endl;
#endif
          return eINVALID; // LVALUE
        }
      case SVt_PVAV:
      case SVt_PVHV:
      case SVt_PVCV:
        //return eARRAY;
        //return eHASH;
        //return eCODE;
        return eINVALID;
      case SVt_PVGV: // GLOB
      case SVt_PVFM: // FORMAT
      case SVt_PVIO: // IO
        return eINVALID;
#ifdef SVt_BIND
      case SVt_BIND:
        return eINVALID; // BIND
#endif
#ifdef SVt_REGEXP
      case SVt_REGEXP:
        return eINVALID; // REGEXP
#endif
DEFAULT:
      default:
        if (SvROK(sv)) {
          if (IsTObject(aTHX_ sv))
            return eTOBJECT;
          switch (SvTYPE(SvRV(sv))) {
            case SVt_PVAV:
              return _GuessCompositeType(aTHX_ sv);
            case SVt_PVHV:
              return eHASH;
            case SVt_PVCV:
              return eCODE;
            default:
#ifdef SOOT_DEBUG
              cout << "SvROK && SvRV => default ("<<SvTYPE(SvRV(sv))<< ")"<< endl;
              do_sv_dump(0, Perl_debug_log, sv, 0, 4, false, 4);
#endif
              return eREF;
          }
        } else {
          return eINVALID; // UNKNOWN
        }
    }
  }


  SOOT::BasicType
  _GuessCompositeType(pTHX_ SV* const sv)
  {
    // sv is known to be an RV to an AV
    // We'll base the array type on the FIRST element of the
    // array only. After all we can (potentially with warnings) convert
    // any of the basic types to any other.
    AV* av = (AV*)SvRV(sv);
    const int lastElem = av_len(av);
    if (lastElem < 0) // empty
      return eARRAY_INVALID;
    SV** elem = av_fetch(av, 0, 0);
    if (elem == NULL)
      return eARRAY_INVALID;
    switch (GuessType(aTHX_ *elem)) {
      case eINTEGER:
        return eARRAY_INTEGER;
      case eFLOAT:
        return eARRAY_FLOAT;
      case eSTRING:
        return eARRAY_STRING;
      default:
        return eARRAY_INVALID;
    }
  }

  std::string
  CProtoFromType(pTHX_ SV* const sv)
  {
    return CProtoFromType(aTHX_ sv, GuessType(aTHX_ sv));
  }

  std::string
  CProtoFromType(pTHX_ SV* const sv, BasicType type)
  {
    // TODO figure out references vs. pointers
    switch (type) {
      case eTOBJECT:
        return std::string(sv_reftype(SvRV(sv), TRUE)) + std::string("*");
      case eINTEGER:
        return std::string("int");
      case eFLOAT:
        return std::string("double");
      case eSTRING:
        return std::string("char*");
      case eARRAY_INTEGER:
        return std::string("int*");
      case eARRAY_FLOAT:
        return std::string("double*");
      case eARRAY_STRING:
        return std::string("char**");
      default:
        return std::string("");
    }
  }

  std::vector<BasicType>
  GuessTypes(pTHX_ AV* av)
  {
    vector<BasicType> types;
    const unsigned int nElem = (unsigned int)(av_len(av)+1);
    for (unsigned int iElem = 0; iElem < nElem; ++iElem) {
      SV* const* elem = av_fetch(av, iElem, 0);
      if (elem == NULL)
        croak("av_fetch failed. Severe error.");
      types.push_back(GuessType(aTHX_ *elem));
    }
    return types;
  }


  char*
  CProtoFromAV(pTHX_ AV* av, const unsigned int nSkip = 1)
  {
    vector<string> protos;
    SV** elem;
    STRLEN len;
    unsigned int totalLen = 0;

    // convert the elements into C prototype strings
    const unsigned int nElem = (unsigned int)(av_len(av)+1);
    if (nSkip >= nElem)
      return NULL;
    for (unsigned int iElem = nSkip; iElem < nElem; ++iElem) {
      elem = av_fetch(av, iElem, 0);
      if (elem == NULL)
        croak("av_fetch failed. Severe error.");
      std::string thisCProto = CProtoFromType(aTHX_ *elem);
      //cout << thisCProto<<endl;
      protos.push_back(thisCProto);
      totalLen += thisCProto.length();
      //cout << len << endl;
    }
    
    char* cproto = (char*)malloc(totalLen);
    // doesn't work: ?
    //Newx((void*)cproto, totalLen, char);
    unsigned int pos = 0;
    for (unsigned int iElem = 0; iElem < protos.size(); ++iElem) {
      len = protos[iElem].length();
      strncpy((char*)(cproto+pos), protos[iElem].c_str(), len);
      pos += len;
      cproto[pos] = ',';
      ++pos;
    }
    cproto[pos-1] = '\0';
    return cproto;
  }


  unsigned int
  CProtoAndTypesFromAV(pTHX_ AV* av, std::vector<BasicType>& avtypes,
                       std::vector<std::string>& cproto, const unsigned int nSkip)
  {
    SV** elem;
    unsigned int nTObjects = 0;
    // convert the elements into C prototype strings
    const unsigned int nElem = (unsigned int)(av_len(av)+1);
    if (nSkip >= nElem)
      return 0;
    //cout << "TYPES..."<<endl;
    //for (unsigned int i = nSkip; i< nElem; ++i) {
    //  cout << "- "<< gBasicTypeStrings[GuessType(aTHX_ *av_fetch(av, i, 0))] << " " << *av_fetch(av, i, 0) << endl;
    //}
    for (unsigned int iElem = nSkip; iElem < nElem; ++iElem) {
      elem = av_fetch(av, iElem, 0);
      if (elem == NULL)
        croak("av_fetch failed. Severe error.");
      BasicType type = GuessType(aTHX_ *elem);
      if (type == eTOBJECT)
        ++nTObjects;
      avtypes.push_back(type);
      std::string thisCproto = CProtoFromType(aTHX_ *elem, type);
      if (thisCproto.length() == 0) {
#ifdef SOOT_DEBUG
        cout << "types so far: ";
        for (unsigned int i = 0; i < cproto.size(); i++)
          cout << cproto[i] << ",";
        cout << endl;
#endif
        croak("Invalid type '%s'", gBasicTypeStrings[type]);
      }
      cproto.push_back(thisCproto);
    }
    return nTObjects;
  }


  char*
  JoinCProto(const std::vector<std::string>& cproto, const unsigned int nSkip)
  {
    const unsigned int n = cproto.size();
    if (nSkip >= n)
      return NULL;
    ostringstream str;
    for (unsigned int i = nSkip; i < n; i++) {
      str << cproto[i];
      if (i != n-1)
         str << ",";
    }
    return strdup(str.str().c_str());
  }

  /* Heavily inspired by RubyROOT! */
  BasicType
  GuessTypeFromProto(const char* proto)
  {
    char* typestr = strdup(proto);
    char* ptr = typestr;
    int ptr_level = 0;
    BasicType type;

    while (*(ptr++)) {
      if (*ptr == '*')
        ptr_level++;
    }

    ptr--;

    // FIXME I think this can break on stuff like
    //       char* const* where the *'s aren't all at the end
    if (ptr_level > 0)
        *(ptr - ptr_level) = '\0';

    if (!strncmp(ptr-3, "int", 3) ||
        !strncmp(ptr-4, "long", 4) ||
        !strncmp(ptr-5, "short", 5)) {
      if (ptr_level)
        type = eARRAY_INTEGER;
      else
        type = eINTEGER;
    }
    else if (!strncmp(ptr-6, "double", 6) ||
             !strncmp(ptr-5, "float", 5)) {
      if (ptr_level)
        type = eARRAY_FLOAT;
      else
        type = eFLOAT;
    }
    else if (!strncmp(ptr-5, "char", 4)) {
      if (ptr_level == 1)
        type = eSTRING;
      else if (ptr_level == 2)
        type = eARRAY_STRING;
      else
        type = eINTEGER;
    }
    else if (!strncmp(ptr-4, "void", 4))
      type = eUNDEF; // FIXME check validity
    else if (!strncmp(ptr-4, "bool", 4))
      type = eINTEGER; // FIXME Do we need a eBOOL type?
    else
      type = eTOBJECT;
    /*else if (ptr_level)
      type = eTOBJECT; // FIXME, umm, really?
    else if (!strncmp(ptr-13, "TFitResultPtr", 13))
      type = eTOBJECT;
    else
      type = eINVALID;
    */

    free(typestr);

    return type;
  }

  bool
  CProtoIntegerToFloat(std::vector<std::string>& cproto)
  {
    const unsigned int nprotos = cproto.size();
    bool changed = false;
    for (unsigned int i = 0; i < nprotos; ++i) {
      // This is ugly because we want to preserve pointers/references
      if (cproto[i].length() == 4 && strnEQ(cproto[i].data(), "int", 3)) {
        cproto[i] = string("double").append((const char*)cproto[i].data()+3, 1);
        changed = true;
      }
    }
    return changed;
  }


} // end namespace SOOT

