#pragma once
#include <map>
#include <xs/xs.h>

namespace xs { namespace lib {

SV* clone (pTHX_ SV* source, bool cross = false);

}}
