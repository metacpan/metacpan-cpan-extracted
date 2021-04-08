#include "inc.h"
#include "utils.h"
#include <map>
#include <iostream>

namespace panda { namespace protocol { namespace websocket {

union _check_endianess { unsigned x; unsigned char c; };
static const bool am_i_little = (_check_endianess{1}).c;

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
    if (!shift) return x;
    shift *= 8;
    return am_i_little ? ((x >> shift) | (x << (sizeof(x)*8 - shift))) :
                         ((x << shift) | (x >> (sizeof(x)*8 - shift)));
}

void crypt_mask (const char* str, char* dst, size_t len, uint32_t mask, uint64_t bytes_received) {
    mask = rotate_shift(mask, bytes_received & 3);
    const uint64_t mask64 = ((uint64_t)mask << 32) | mask;
    auto str64 = (const uint64_t*)str;
    auto dst64 = (uint64_t*)dst;
    auto end64 = str64 + (len / 8);

    while (str64 != end64) *dst64++ = *str64++ ^ mask64;

    auto cstr  = (const unsigned char*)str64;
    auto cdst  = (unsigned char*)dst64;
    auto cmask = (const unsigned char*)&mask64;
    switch (len & 7) {
        case 7: *cdst++ = *cstr++ ^ *cmask++; // fall through
        case 6: *cdst++ = *cstr++ ^ *cmask++; // fall through
        case 5: *cdst++ = *cstr++ ^ *cmask++; // fall through
        case 4: *cdst++ = *cstr++ ^ *cmask++; // fall through
        case 3: *cdst++ = *cstr++ ^ *cmask++; // fall through
        case 2: *cdst++ = *cstr++ ^ *cmask++; // fall through
        case 1: *cdst++ = *cstr++ ^ *cmask++;
    }
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
    s << cc.code << ": " << (cc.msg.empty() ? close_message(cc.code) : cc.msg);
    return s;
}

}}}
