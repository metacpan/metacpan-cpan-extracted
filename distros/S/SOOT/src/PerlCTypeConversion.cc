
#include "PerlCTypeConversion.h"
#include "SOOTDebug.h"


using namespace SOOT;
using namespace std;

namespace SOOT {
  char**
  AVToCStringVec(pTHX_ AV* av, size_t& len)
  {
    len = av_len(av)+1;
    if (len == 0)
      return NULL;
    SV** elem;
    char** retval = (char**)malloc(len*sizeof(char*));
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      retval[i] = strdup(SvPV_nolen(*elem));
    }
    return retval;
  }

  
  std::vector<char*>
  AVToCStringVec(pTHX_ AV* av)
  {
    size_t len = av_len(av)+1;
    if (len == 0)
      return vector<char*>();
    SV** elem;
    vector<char*> retval(len);
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      retval[i] = strdup(SvPV_nolen(*elem));
    }
    return retval;
  }


  std::vector<std::string>
  AVToStringVec(pTHX_ AV* av)
  {
    size_t len = av_len(av)+1;
    if (len == 0)
      return vector<string>(0);
    SV** elem;
    vector<string> retval(len);
    for (unsigned int i = 0; i < len; ++i) {
      elem = av_fetch(av, i, 0);
      if (elem == NULL)
        croak("Bad AV element. Severe error");
      STRLEN l;
      char* str = SvPV(*elem, l);
      retval[i] = string(str, l);
    }
    return retval;
  }
} // end namespace SOOT

