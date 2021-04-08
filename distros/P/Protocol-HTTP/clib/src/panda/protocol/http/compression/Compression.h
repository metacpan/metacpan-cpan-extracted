#pragma once
#include <cstdint>

namespace panda { namespace protocol { namespace http { namespace compression {

struct Compression {
    enum Type : std::uint8_t {
        GZIP     = 1 << 0,
        DEFLATE  = 1 << 1,
        BROTLI   = 1 << 2,
        IDENTITY = 1 << 3,
        LAST     = IDENTITY,
    };

    enum class Level { min = 0, optimal, max };
};

bool is_valid_compression (std::uint8_t) noexcept;

using storage_t = std::uint64_t;
constexpr std::uint64_t ITEM_MASK = 0b11111111ull;
constexpr std::uint64_t ITEM_VALUE_MASK = 0b00111111ull;
constexpr std::uint64_t FILLED_MASK = 0b11111111ull << (7 * 8);

template<typename F>
void for_each (storage_t ordered_prefs, F&& fn) noexcept {
    for(int i = sizeof (storage_t) - 1; i >= 0; --i) {
        auto mask = ITEM_MASK << (i * 8);
        auto item_shifted = (ordered_prefs & mask);
        if (!item_shifted) { continue; }
        auto item = item_shifted >> (i * 8);
        bool negation = false;
        if (item > Compression::LAST) {
            item = ~item & ITEM_VALUE_MASK;
            negation = true;
        }
        fn(item, negation);
    }
}

bool inline pack (storage_t& ordered_prefs, Compression::Type value) {
    if (ordered_prefs & FILLED_MASK) return false;
    ordered_prefs = (ordered_prefs << 8) | (value & ITEM_MASK);
    return true;
}

}}}}
