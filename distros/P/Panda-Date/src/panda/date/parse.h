#pragma once
#include <panda/date/inc.h>
#include <panda/string_view.h>

namespace panda { namespace date {

using std::string_view;
using panda::time::Timezone;
using panda::time::datetime;

err_t parse               (string_view, datetime*, const Timezone**);
err_t parse_iso           (string_view, datetime*, const Timezone**);
err_t parse_iso8601       (string_view, datetime*, const Timezone**);
err_t parse_relative      (string_view, datetime*);
bool  looks_like_relative (string_view);

}}
