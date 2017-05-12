
#include "CPerlTypeConversion.h"
#include "SOOTDebug.h"


using namespace SOOT;
using namespace std;

namespace SOOT {
  SV*
  CStringVecToAV(pTHX_ const char* const* vec, const unsigned int nItems)
  {
    if (vec == NULL)
      return &PL_sv_undef;

    AV* av = newAV();
    av_extend(av, nItems-1);
    for (unsigned int i = 0; i < nItems; ++i)
    av_store(av, i, newSVpv(vec[i], 0));
    return newRV_noinc((SV*)av);
  }

  SV*
  CStringVecToAV(pTHX_ const std::vector<char*>& vec)
  { return CStringVecToAV(aTHX_ &vec.front(), vec.size()); }

  SV*
  CStringVecToAV(pTHX_ const std::vector<const char*>& vec)
  { return CStringVecToAV(aTHX_ &vec.front(), vec.size()); }

  SV* StringVecToAV(pTHX_ const std::vector<std::string>& vec)
  { return StringVecToAV<const std::string>(aTHX_ (const std::string*)&(vec.front()), vec.size()); }
} // end namespace SOOT

