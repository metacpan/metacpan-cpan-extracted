#pragma once
#include <xs/xs.h>

namespace xs { namespace lib {

bool hv_compare (pTHX_ HV*, HV*);
bool av_compare (pTHX_ AV*, AV*);
bool sv_compare (pTHX_ SV*, SV*);

}}
