
#ifndef __CPerlTypeConversion_h_
#define __CPerlTypeConversion_h_

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
  SV*
  FloatVecToAV(pTHX_ const T* vec, const unsigned int nItems)
  {
    if (vec == NULL)
      return &PL_sv_undef;

    AV* av = newAV();
    av_extend(av, nItems-1);
    for (unsigned int i = 0; i < nItems; ++i)
    av_store(av, i, newSVnv(vec[i]));
    return newRV_noinc((SV*)av);
  }


  template <typename T>
  SV*
  FloatVecToAV(pTHX_ const std::vector<T>& vec)
  { return FloatVecToAV<T>(aTHX_ &vec.front(), vec.size()); }


  template <typename T>
  SV*
  IntegerVecToAV(pTHX_ const T* vec, const unsigned int nItems)
  {
    if (vec == NULL)
      return &PL_sv_undef;

    AV* av = newAV();
    av_extend(av, nItems-1);
    for (unsigned int i = 0; i < nItems; ++i)
    av_store(av, i, newSViv(vec[i]));
    return newRV_noinc((SV*)av);
  }


  template <typename T>
  SV*
  UIntegerVecToAV(pTHX_ const T* vec, const unsigned int nItems)
  {
    if (vec == NULL)
      return &PL_sv_undef;

    AV* av = newAV();
    av_extend(av, nItems-1);
    for (unsigned int i = 0; i < nItems; ++i)
    av_store(av, i, newSVuv(vec[i]));
    return newRV_noinc((SV*)av);
  }


  template <typename T>
  SV*
  IntegerVecToAV(pTHX_ const std::vector<T>& vec)
  { return IntegerVecToAV<T>(aTHX_ &vec.front(), vec.size()); }


  SV* CStringVecToAV(pTHX_ const char* const* vec, const unsigned int nItems);
  SV* CStringVecToAV(pTHX_ const std::vector<char*>& vec);
  SV* CStringVecToAV(pTHX_ const std::vector<const char*>& vec);


  template <typename T>
  SV*
  StringVecToAV(pTHX_ T* vec, const unsigned int nItems)
  {
    if (vec == NULL)
      return &PL_sv_undef;

    AV* av = newAV();
    av_extend(av, nItems-1);
    for (unsigned int i = 0; i < nItems; ++i)
    av_store(av, i, newSVpv(vec[i].c_str(), vec[i].length()));
    return newRV_noinc((SV*)av);
  }


  SV* StringVecToAV(pTHX_ const std::vector<std::string>& vec);

} // end namespace SOOT

#endif

