#pragma once
#include <panda/time/timezone.h>

namespace panda { namespace time {

using std::string_view;

bool tzparse      (const string_view&, Timezone*);
bool tzparse_rule (const string_view&, Timezone::Rule*);

}}
