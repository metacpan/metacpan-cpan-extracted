// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

#include <cstddef>
#include <iostream>
#include <string>

#include "third_party/protobuf/perl/protoc/generator.h"
#include "upb/mem/arena.h"

#ifdef GOOGLE3
#include "third_party/protobuf/compiler/perl/plugin.upb.h"
#else
#include "google/protobuf/compiler/plugin.upb.h"
#endif

#if defined(_WIN32) || defined(_WIN64) || defined(MSWin32)
#include <fcntl.h>
#include <io.h>
#endif

int main(int argc, char** argv) {
#if defined(_WIN32) || defined(_WIN64) || defined(MSWin32)
  _setmode(_fileno(stdin), _O_BINARY);
  _setmode(_fileno(stdout), _O_BINARY);
#endif
  upb_Arena* arena = upb_Arena_New();

  std::string input;
  char buffer[4096];
  while (std::cin.read(buffer, sizeof(buffer))) {
    input.append(buffer, std::cin.gcount());
  }
  input.append(buffer, std::cin.gcount());

  proto2_compiler_CodeGeneratorRequest* request =
      proto2_compiler_CodeGeneratorRequest_parse(input.data(), input.length(),
                                                 arena);

  if (!request) {
    std::cerr << "Failed to parse CodeGeneratorRequest\n";
    upb_Arena_Free(arena);
    return 1;
  }

  google::protobuf::compiler::perl::PerlCodeGenerator generator(request, arena);
  proto2_compiler_CodeGeneratorResponse* response = generator.Generate();

  size_t size;
  char* buf =
      proto2_compiler_CodeGeneratorResponse_serialize(response, arena, &size);
  std::cout.write(buf, size);

  upb_Arena_Free(arena);
  return 0;
}
