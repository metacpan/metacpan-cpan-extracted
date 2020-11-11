#include "inc.h"
#include "utils.h"
#include "iterator.h"
#include <map>
#include <iostream>

namespace panda { namespace protocol { namespace websocket {

union _check_endianess { unsigned x; unsigned char c; };
static const bool am_i_little = (_check_endianess{1}).c;

string StringPairIterator::global_empty = "";

// case-insensitive jenkins_one_at_a_time_hash
uint32_t string_hash32_ci (const char *key, size_t len) {
    uint32_t hash, i;
    for (hash = i = 0; i < len; ++i) {
        hash += std::tolower(key[i]);
        hash += (hash << 10);
        hash ^= (hash >> 6);
    }
    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);
    return hash;
}

static inline uint32_t rotate_shift (uint32_t x, unsigned shift) {
    if (shift % 32 == 0) return x;
    return am_i_little ? ((x >> shift) | (x << (sizeof(x)*8 - shift))) :
                         ((x << shift) | (x >> (sizeof(x)*8 - shift)));
}

void crypt_mask (char* str, size_t len, uint32_t mask, uint64_t bytes_received) {
    mask = rotate_shift(mask, (bytes_received & 3)*8);
    const uint64_t mask64 = ((uint64_t)mask << 32) | mask;
    auto str64 = (uint64_t*)str;
    auto end64 = str64 + (len / 8);

    while (str64 != end64) *str64++ ^= mask64;

    auto cstr  = (unsigned char*)str64;
    auto cmask = (const unsigned char*)&mask64;
    switch (len & 7) {
        case 7: *cstr++ ^= *cmask++; // fallthrough
        case 6: *cstr++ ^= *cmask++; // fallthrough
        case 5: *cstr++ ^= *cmask++; // fallthrough
        case 4: *cstr++ ^= *cmask++; // fallthrough
        case 3: *cstr++ ^= *cmask++; // fallthrough
        case 2: *cstr++ ^= *cmask++; // fallthrough
        case 1: *cstr++ ^= *cmask++;
    };
}

static std::map<uint16_t, string> close_messages = {
    {CloseCode::NOERR            , "no error"},
    {CloseCode::DONE             , "Done"},
    {CloseCode::AWAY             , "Away"},
    {CloseCode::PROTOCOL_ERROR   , "WS Protocol Error"},
    {CloseCode::INVALID_DATA     , "WS Invalid Data"},
    {CloseCode::UNKNOWN          , "WS Unknown"},
    {CloseCode::ABNORMALLY       , "Abnormally"},
    {CloseCode::INVALID_TEXT     , "Invalid Text"},
    {CloseCode::BAD_REQUEST      , "Bad Request"},
    {CloseCode::MAX_SIZE         , "Max Size"},
    {CloseCode::EXTENSION_NEEDED , "Extension Needed"},
    {CloseCode::INTERNAL_ERROR   , "Internal Error"},
    {CloseCode::TLS              , "TLS error"}
};

string close_message(uint16_t code) {
    auto iter = close_messages.find(code);
    if (iter == close_messages.end()) {
        return to_string(code);
    } else {
        return iter->second;
    }

}

bool register_close_codes(std::initializer_list<std::pair<uint16_t, string> > pairs) {
    for (const auto& p : pairs) {
        close_messages.insert({p.first, p.second});
    }
    return true;
}

std::ostream& operator<< (std::ostream& s, const ccfmt& cc) {
    s << cc.code << ": " << cc.msg ? cc.msg : close_message(cc.code);
    return s;
}

}}}
