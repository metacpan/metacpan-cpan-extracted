#ifndef PERL_RSTATS_UTIL_H
#define PERL_RSTATS_UTIL_H

#include <limits>
#include "Rstats_Main.h"

namespace Rstats {
  namespace Util {
    Rstats::Logical is_perl_number(SV*);
    SV* cross_product(SV*);
    SV* pos_to_index(SV*, SV*);
    SV* index_to_pos(SV*, SV*);
    SV* looks_like_complex(SV*);
    SV* looks_like_logical(SV*);
    SV* looks_like_na(SV*);
    SV* looks_like_integer(SV*);
    SV* looks_like_double(SV*);
    Rstats::Double pi();
    Rstats::Double Inf();
    Rstats::Double NaN();
    Rstats::Logical is_Inf(Rstats::Double);
    Rstats::Logical is_NaN(Rstats::Double);
  }
}

#endif
