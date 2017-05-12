#pragma once
#include <panda/string.h>

namespace panda { namespace uri {

static const int UNSAFE_DIGIT      =  1;
static const int UNSAFE_ALPHA      =  2;
static const int UNSAFE_SUBDELIMS  =  4;
static const int UNSAFE_GENDELIMS  =  8;
static const int UNSAFE_RESERVED   = 16;
static const int UNSAFE_UNRESERVED = 32;
static const int UNSAFE_PCHAR      = 64;

extern char unsafe_scheme[256];
extern char unsafe_uinfo[256];
extern char unsafe_host[256];
extern char unsafe_path[256];
extern char unsafe_path_segment[256];
extern char unsafe_query[256];
extern char unsafe_query_component[256];
extern char unsafe_fragment[256];

size_t encode_uri_component (const std::string_view src, char* dest, const char* unsafe = unsafe_query_component);
size_t decode_uri_component (const std::string_view src, char* dest);

inline void encode_uri_component (const std::string_view src, panda::string& dest, const char* unsafe = unsafe_query_component) {
    size_t final_size = encode_uri_component(src, dest.reserve(src.length()*3), unsafe);
    dest.length(final_size);
}

inline void decode_uri_component (const std::string_view src, panda::string& dest) {
    size_t final_size = decode_uri_component(src, dest.reserve(src.length()));
    dest.length(final_size);
}

inline panda::string encode_uri_component (const std::string_view src, const char* unsafe = unsafe_query_component) {
    panda::string ret;
    encode_uri_component(src, ret, unsafe);
    return ret;
}

inline panda::string decode_uri_component (const std::string_view src) {
    panda::string ret;
    decode_uri_component(src, ret);
    return ret;
}

void unsafe_generate (char* unsafe, int flags, const char* chars = NULL);

}}
