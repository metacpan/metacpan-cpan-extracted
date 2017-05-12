#pragma once
#include <cstring>
#include <stdint.h>
#include <stddef.h>
#include <panda/lib/hash.h>

namespace panda {
    inline bool likely   (bool expr) { return __builtin_expect(expr,1); }
    inline bool unlikely (bool expr) { return __builtin_expect(expr,0); }
};

namespace panda { namespace lib {

char* itoa (int64_t i);

inline uint64_t string_hash (const char* str, size_t len) { return hash64(str, len); }
inline uint64_t string_hash (const char* str) { return string_hash(str, std::strlen(str)); }

inline uint32_t string_hash32 (const char* str, size_t len) { return hash32(str, len); }
inline uint32_t string_hash32 (const char* str) { return string_hash32(str, std::strlen(str)); }

char* crypt_xor (const char* source, size_t slen, const char* key, size_t klen, char* dest = NULL);

}};
