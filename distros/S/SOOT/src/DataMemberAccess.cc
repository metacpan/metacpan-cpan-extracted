
#include "DataMemberAccess.h"
#include "CPerlTypeConversion.h"
#include "PerlCTypeConversion.h"
#include "SOOTDebug.h"

#include "SOOT_RTXS.h"
#include "SOOT_RTXS_ExternalXSUBs.h"


using namespace SOOT;
using namespace std;

namespace SOOT {

// FIXME check mortalization of return value!
#define SOOT_AccessIntegerValue(type) case k##type: \
  INSTALL_NEW_CV_ARRAY_OBJ(fullMemberName.c_str(), SOOT_RTXS_SUBNAME(access_struct_##type), offset); \
  if (argument == NULL) /*getter*/ \
    return newSViv((IV) *((type*)dataAddr)); \
  else { \
    *((type*)dataAddr) = (type)SvIV(argument); \
    return NULL; \
  }

#define SOOT_AccessUIntegerValue(type) case k##type: \
  INSTALL_NEW_CV_ARRAY_OBJ(fullMemberName.c_str(), SOOT_RTXS_SUBNAME(access_struct_##type), offset); \
  if (argument == NULL) /*getter*/ \
    return newSVuv((UV) *((type*)dataAddr)); \
  else { \
    *((type*)dataAddr) = (type)SvUV(argument); \
    return NULL; \
  }

#define SOOT_AccessFloatValue(type) case k##type: \
  INSTALL_NEW_CV_ARRAY_OBJ(fullMemberName.c_str(), SOOT_RTXS_SUBNAME(access_struct_##type), offset); \
  if (argument == NULL) /*getter*/ \
    return newSVnv((NV) *((type*)dataAddr)); \
  else { \
    *((type*)dataAddr) = (type)SvNV(argument); \
    return NULL; \
  }

  SV*
  InstallDataMemberToPerlConverter(pTHX_ TClass* theClass, const char* methName,
                                   TDataMember* dm, void* baseAddr, SV* argument)
  {
    int aryDim = dm->GetArrayDim();
    if (aryDim > 1)
      croak("Invalid array dimension: We only support "
            "direct access to simple types and 1-dim. arrays");
    else if (aryDim == 1)
      return InstallArrayDataMemberToPerlConverter(aTHX_ theClass, methName, dm, baseAddr, argument);

    Long_t offset = dm->GetOffset();
    EDataType type = (EDataType)dm->GetDataType()->GetType();
    void* dataAddr = (void*) ((Long_t)baseAddr + offset);
    char* buf;
    
    const string fullMemberName = string(theClass->GetName()) + string("::") + string(methName);

    switch (type) {
      SOOT_AccessIntegerValue(Bool_t);
      SOOT_AccessIntegerValue(Char_t);
      SOOT_AccessUIntegerValue(UChar_t);
      SOOT_AccessIntegerValue(Short_t);
      SOOT_AccessUIntegerValue(UShort_t);
      SOOT_AccessIntegerValue(Int_t);
      SOOT_AccessUIntegerValue(UInt_t);
      SOOT_AccessIntegerValue(Long_t);
      SOOT_AccessUIntegerValue(ULong_t);
      SOOT_AccessIntegerValue(Long64_t);
      SOOT_AccessUIntegerValue(ULong64_t);
      SOOT_AccessFloatValue(Float_t);
      SOOT_AccessFloatValue(Double_t);
      case kCharStar:
        INSTALL_NEW_CV_ARRAY_OBJ(fullMemberName.c_str(), SOOT_RTXS_SUBNAME(access_struct_CharStar), offset);
        if (argument == NULL)
          return newSVpvn(*((char**)dataAddr), strlen(*((char**)dataAddr))); // FIXME check mortalization
        else {
          free(*((char**)dataAddr));
          buf = strdup(SvPV_nolen(argument));
          dataAddr = (void*)&buf;
          return NULL;
        }
      default:
        croak("Invalid data member type");
    };
    return &PL_sv_undef;
  }
#undef SOOT_AccessIntegerValue
#undef SOOT_AccessUIntegerValue
#undef SOOT_AccessFloatValue

#define SOOT_AccessArrayIntegerValue(type) case k##type: \
  INSTALL_NEW_CV_HASH_OBJ(fullMemberName.c_str(), fullMemberName.length(), \
                          SOOT_RTXS_SUBNAME(access_struct_array_##type), offset, maxIndex); \
  if (argument == NULL) /*getter*/ \
    return SOOT::IntegerVecToAV<type>(aTHX_ (type*)dataAddr, maxIndex); \
  else { \
    *((type*)dataAddr) = (type)SvIV(argument); \
    return NULL; \
  }

#define SOOT_AccessArrayUIntegerValue(type) case k##type: \
  INSTALL_NEW_CV_HASH_OBJ(fullMemberName.c_str(), fullMemberName.length(), \
                          SOOT_RTXS_SUBNAME(access_struct_array_##type), offset, maxIndex); \
  if (argument == NULL) /*getter*/ \
    return SOOT::UIntegerVecToAV<type>(aTHX_ (type*)dataAddr, maxIndex); \
  else { \
    *((type*)dataAddr) = (type)SvUV(argument); \
    return NULL; \
  }

#define SOOT_AccessArrayFloatValue(type) case k##type: \
  INSTALL_NEW_CV_HASH_OBJ(fullMemberName.c_str(), fullMemberName.length(), \
                          SOOT_RTXS_SUBNAME(access_struct_array_##type), offset, maxIndex); \
  if (argument == NULL) /*getter*/ \
    return SOOT::FloatVecToAV<type>(aTHX_ (type*)dataAddr, maxIndex); \
  else { \
    *((type*)dataAddr) = (type)SvNV(argument); \
    return NULL; \
  }
  SV*
  InstallArrayDataMemberToPerlConverter(pTHX_ TClass* theClass, const char* methName,
                                        TDataMember* dm, void* baseAddr, SV* argument)
  {
    Long_t offset = dm->GetOffset();
    int maxIndex = dm->GetMaxIndex(0);
    EDataType type = (EDataType)dm->GetDataType()->GetType();
    void* dataAddr = (void*) ((Long_t)baseAddr + offset);
    char* buf;
    size_t len;
    
    const string fullMemberName = string(theClass->GetName()) + string("::") + string(methName);

    switch (type) {
      SOOT_AccessArrayIntegerValue(Bool_t);
      //SOOT_AccessArrayIntegerValue(Char_t);
      case kChar_t:
        // FIXME SUB INSTALLATION HERE!!!
        if (argument == NULL)
          return newSVpvn((char*)dataAddr, maxIndex);
        else {
          // FIXME investigate null-padding issues. In general the Char_t[5] thingies might not need it
          buf = SvPV(argument, len);
          if (maxIndex < (int)len)
            len = maxIndex;
          strncpy( (char*)dataAddr, buf, len );
          ((char*)dataAddr)[len] = '\0'; // FIXME is this right?
          return NULL;
        }
      SOOT_AccessArrayUIntegerValue(UChar_t);
      SOOT_AccessArrayIntegerValue(Short_t);
      SOOT_AccessArrayUIntegerValue(UShort_t);
      SOOT_AccessArrayIntegerValue(Int_t);
      SOOT_AccessArrayUIntegerValue(UInt_t);
      SOOT_AccessArrayIntegerValue(Long_t);
      SOOT_AccessArrayUIntegerValue(ULong_t);
      SOOT_AccessArrayIntegerValue(Long64_t);
      SOOT_AccessArrayUIntegerValue(ULong64_t);
      SOOT_AccessArrayFloatValue(Float_t);
      SOOT_AccessArrayFloatValue(Double_t);
    default:
      croak("Invalid type of array for member");
      return &PL_sv_undef; // not reached!
    };
    return &PL_sv_undef; // not reached!
  }
#undef SOOT_AccessArrayIntegerValue
#undef SOOT_AccessArrayUIntegerValue
#undef SOOT_AccessArrayFloatValue


} // end namespace SOOT

