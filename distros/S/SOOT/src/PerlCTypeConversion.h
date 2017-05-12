
#ifndef __PerlCTypeConversion_h_
#define __PerlCTypeConversion_h_

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
#include <string>

// This contains various conversion functions for
// copying a C-level structure to Perl structures and vice versa

namespace SOOT {
  template <typename T>
  T*
  AVToFloatVec(pTHX_ AV* av, size_t& len)
  {
    len = av_len(av)+1;
    if (len == 0)
      return NULL;
    SV** elem;
    T* retval = (T*)malloc(len*sizeof(T));
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      retval[i] = SvNV(*elem);
    }
    return retval;
  }


  template <typename T>
  std::vector<T>
  AVToFloatVec(pTHX_ AV* av)
  {
    size_t len = av_len(av)+1;
    if (len == 0)
      return NULL;
    SV** elem;
    std::vector<T> retval(len);
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      retval[i] = SvNV(*elem);
    }
    return retval;
  }


  template <typename T>
  void
  AVToFloatVecInPlace(pTHX_ AV* av, size_t& len, T* address, size_t maxNElems)
  {
    len = av_len(av)+1;
    if (maxNElems < len)
      len = maxNElems;
    else if (maxNElems > len)
      Zero( (void*)(address+len), maxNElems-len, T );
    SV** elem;
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      address[i] = SvNV(*elem);
    }
  }


  template <typename T>
  T*
  AVToIntegerVec(pTHX_ AV* av, size_t& len)
  {
    len = av_len(av)+1;
    if (len == 0)
      return NULL;
    SV** elem;
    T* retval = (T*)malloc(len*sizeof(T));
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      retval[i] = SvIV(*elem);
    }
    return retval;
  }


  template <typename T>
  void
  AVToIntegerVecInPlace(pTHX_ AV* av, size_t& len, T* address, size_t maxNElems)
  {
    len = av_len(av)+1;
    if (maxNElems < len)
      len = maxNElems;
    else if (maxNElems > len)
      Zero( (void*)(address+len), maxNElems-len, T );
    SV** elem;
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      address[i] = SvIV(*elem);
    }
  }


  template <typename T>
  T*
  AVToUIntegerVec(pTHX_ AV* av, size_t& len)
  {
    len = av_len(av)+1;
    if (len == 0)
      return NULL;
    SV** elem;
    T* retval = (T*)malloc(len*sizeof(T));
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      retval[i] = SvUV(*elem);
    }
    return retval;
  }


  template <typename T>
  void
  AVToUIntegerVecInPlace(pTHX_ AV* av, size_t& len, T* address, size_t maxNElems)
  {
    len = av_len(av)+1;
    if (maxNElems < len)
      len = maxNElems;
    else if (maxNElems > len)
      Zero( (void*)(address+len), maxNElems-len, T );
    SV** elem;
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      address[i] = SvUV(*elem);
    }
  }


  template <typename T>
  std::vector<T>
  AVToIntegerVec(pTHX_ AV* av)
  {
    size_t len = av_len(av)+1;
    if (len == 0)
      return NULL;
    SV** elem;
    std::vector<T> retval(len);
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      retval[i] = SvIV(*elem);
    }
    return retval;
  }


  template <typename T>
  std::vector<T>
  AVToUIntegerVec(pTHX_ AV* av)
  {
    size_t len = av_len(av)+1;
    if (len == 0)
      return NULL;
    SV** elem;
    std::vector<T> retval(len);
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      retval[i] = SvUV(*elem);
    }
    return retval;
  }


  char** AVToCStringVec(pTHX_ AV* av, size_t& len);
  std::vector<char*> AVToCStringVec(pTHX_ AV* av);
  std::vector<std::string> AVToStringVec(pTHX_ AV* av);


} // end namespace SOOT

#endif

