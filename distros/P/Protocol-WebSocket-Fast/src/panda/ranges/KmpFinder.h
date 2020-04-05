#pragma once
#include <array>
#include <algorithm>

namespace panda { namespace ranges {

template<typename PatternRange, size_t PATTERN_SIZE>
struct KmpFinder {
    KmpFinder (const PatternRange& pattern) : j(0), pattern(pattern) {
        size_t len = 0;
        prefix[0] = 0;

        size_t i = 1;
        while (i < PATTERN_SIZE) {
            if (pattern[i] == pattern[len]) {
                ++len;
                prefix[i] = len;
                ++i;
            }
            else {
                if (len != 0) {
                    len = prefix[len-1];
                } else {
                    prefix[i] = 0;
                    i++;
                }
            }
        }
    }

    template <typename ElementIterator, typename ElementIteratorEnd>
    ElementIterator find (ElementIterator begin, ElementIteratorEnd end) {
        auto iter = begin;
        while (true) {
            if (pattern[j] == *iter) {
                ++j;
                ++iter;
                if (j == PATTERN_SIZE) return iter;
                if (iter == end) break;
            }
            else {
                if (j != 0) j = prefix[j-1];
                else {
                    iter = std::find(iter, end, pattern[0]);
                    if (iter == end) break;
                    ++j;
                    ++iter;
                    if (j == PATTERN_SIZE) return iter;
                    if (iter == end) break;
                }
            }
        }
        return begin;
    }

    template <typename Range>
    auto find (const Range& range) -> decltype(std::begin(range)) {
        return find(std::begin(range), std::end(range));
    }

    void reset () { j = 0; }

private:
    size_t j;
    const PatternRange& pattern;
    size_t prefix[PATTERN_SIZE];
};

template <typename ElementType, size_t SIZE>
KmpFinder<ElementType[SIZE], SIZE> make_kmp_finder (ElementType (&pattern)[SIZE]) {
    return KmpFinder<ElementType[SIZE], SIZE>(pattern);
}

template <size_t SIZE>
KmpFinder<const char[SIZE], SIZE-1> make_kmp_finder (const char (&pattern)[SIZE]) {
    return KmpFinder<const char[SIZE], SIZE-1>(pattern);
}

}}
