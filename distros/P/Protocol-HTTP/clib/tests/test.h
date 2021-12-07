#pragma once
#include <panda/protocol/http.h>
#include <catch2/catch_test_macros.hpp>
#include <catch2/generators/catch_generators.hpp>
#include <catch2/matchers/catch_matchers_string.hpp>

using namespace panda;
using namespace panda::protocol::http;
using Catch::Matchers::StartsWith;

using panda::date::Date;
using Method = Request::Method;
