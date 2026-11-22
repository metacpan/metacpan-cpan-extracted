// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

#ifndef THIRD_PARTY_PROTOBUF_COMPILER_PERL_HELPERS_H__
#define THIRD_PARTY_PROTOBUF_COMPILER_PERL_HELPERS_H__

#include <string>
#include <vector>

#if !defined(GOOGLE3)
#include <string_view>
namespace absl {
using string_view = std::string_view;

namespace internal_strcat {
inline void AppendPiece(std::string* out, string_view piece) {
  out->append(piece.data(), piece.size());
}
}  // namespace internal_strcat

template <typename... Pieces>
inline std::string StrCat(const Pieces&... pieces) {
  std::string out;
  size_t total = 0;
  ((total += string_view(pieces).size()), ...);
  out.reserve(total);
  (internal_strcat::AppendPiece(&out, string_view(pieces)), ...);
  return out;
}

template <typename... Pieces>
inline void StrAppend(std::string* out, const Pieces&... pieces) {
  size_t add = 0;
  ((add += string_view(pieces).size()), ...);
  out->reserve(out->size() + add);
  (internal_strcat::AppendPiece(out, string_view(pieces)), ...);
}
}  // namespace absl
#else
#include "third_party/absl/strings/str_cat.h"
#include "third_party/absl/strings/string_view.h"
#endif

namespace google {
namespace protobuf {
namespace compiler {
namespace perl {

// Custom string helpers to avoid Abseil library dependencies
bool ConsumePrefix(absl::string_view* s, absl::string_view prefix);
std::vector<absl::string_view> SplitString(absl::string_view s, char delim);

// Converts a string to CamelCase, with custom mappings for known words.
std::string ToCamelCase(absl::string_view s);

// Converts a CamelCase string to snake_case.
std::string ToSnakeCase(absl::string_view s);

// Extracts the default host for standard Google Cloud APIs based on the package
// prefix.
std::string GetDefaultHost(absl::string_view proto_pkg);

// Capitalizes each segment of a package name (e.g. foo.bar -> Foo.Bar), with
// custom mappings.
std::string CapitalizePackage(absl::string_view s);

}  // namespace perl
}  // namespace compiler
}  // namespace protobuf
}  // namespace google

#endif  // THIRD_PARTY_PROTOBUF_COMPILER_PERL_HELPERS_H__
