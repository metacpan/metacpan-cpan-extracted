#pragma once
#include <iosfwd>
#include <panda/string.h>
#include <range/v3/core.hpp>
#include <range/v3/view/filter.hpp>
#include <range/v3/view/transform.hpp>
#include <boost/container/small_vector.hpp>

namespace panda { namespace protocol { namespace http {

inline bool iequals (string_view a, string_view b) {
    auto sz = a.length();
    if (sz != b.length()) return false;

    const char* ap = a.data();
    const char* bp = b.data();
    size_t l = sz / 8;
    const char* e = ap + l*8;
    for (; ap != e; ap += 8, bp += 8) {
        uint64_t av, bv;
        memcpy(&av, ap, 8);
        memcpy(&bv, bp, 8);
        if ((av|0x2020202020202020ULL) != (bv|0x2020202020202020ULL)) return false;
    }

    auto left = sz - l*8;
    if (left & 4) {
        unsigned int av, bv;
        memcpy(&av, ap, 4);
        memcpy(&bv, bp, 4);
        if ((av|0x20202020) != (bv|0x20202020)) return false;
        ap += 4;
        bp += 4;
    }

    if (left & 2) {
        unsigned short av, bv;
        memcpy(&av, ap, 2);
        memcpy(&bv, bp, 2);
        if ((av|0x2020) != (bv|0x2020)) return false;
        ap += 2;
        bp += 2;
    }

    if (left & 1) return (*ap|0x20) == (*bp|0x20);

    return true;
}

template <class T, bool CASE_SENSITIVE, size_t PRERESERVE>
struct Fields {
    struct Field {
        string name;
        T      value;
        Field (const string& k, const T& v) : name(k), value(v) {}

        bool matches (string_view key) const {
            return CASE_SENSITIVE ? (this->name == key) : iequals(this->name, key);
        }

        Field (const Field&)            = default;
        Field (Field&&)                 = default;
        Field& operator= (const Field&) = default;
        Field& operator= (Field&&)      = default;

        bool operator== (const Field& oth) const { return matches(oth.name) && value == oth.value; }
    };
    using Container = boost::container::small_vector<Field, PRERESERVE>;

    Container fields;

    Fields () {}
    Fields (const Fields& fields) = default;
    Fields (Fields&& fields)      = default;

    Fields (const std::initializer_list<Field>& l) {
        for (auto& f : l) fields.emplace_back(f.name, f.value);
    }

    Fields (std::initializer_list<Field>&& l) {
        for (auto& f : l) fields.emplace_back(std::move(f.name), std::move(f.value));
    }

    Fields& operator= (const Fields&) = default;
    Fields& operator= (Fields&&)      = default;

    bool has (string_view key) const {
        for (const auto& f : fields) if (f.matches(key)) return true;
        return false;
    }

    const T& get (string_view key, const T& defval = T()) const {
        auto it = find(key);
        return it == fields.cend() ? defval : it->value;
    }

    void add (const string& key, const T& value) {
        fields.emplace_back(key, value);
    }

    void set (const string& key, const T& value) {
        bool replaced = false;
        for (auto it = fields.begin(); it != fields.end();) {
            if (it->matches(key)) {
                if (replaced) it = fields.erase(it);
                else {
                    replaced = true;
                    it->name  = key;
                    it->value = value;
                    ++it;
                }
            }
            else ++it;
        }
        if (!replaced) add(key, value);
    }

    void remove (string_view key) {
        for (auto it = fields.cbegin(); it != fields.cend();) {
            if (it->matches(key)) it = fields.erase(it);
            else ++it;
        }
    }

    bool   empty () const { return fields.empty(); }
    size_t size  () const { return fields.size(); }

    void clear () { fields.clear(); }

    typename Container::const_iterator find (string_view key) const {
        auto end = fields.crend();
        for (auto it = fields.crbegin(); it != end; ++it) {
            if (it->matches(key)) return it.base()-1;
        }
        return fields.cend();
    }

    typename Container::iterator find (string_view key) {
        auto end = fields.rend();
        for (auto it = fields.rbegin(); it != end; ++it) {
            if (it->matches(key)) return it.base()-1;
        }
        return fields.end();
    }

    auto get_multi (const string_view& key) const {
        return fields | ::ranges::view::filter([key](const Field& f) {return f.matches(key);})
                      | ::ranges::view::transform([](const Field& f) -> const string& {return f.value; });
    }

    typename Container::iterator       begin  ()       { return fields.begin(); }
    typename Container::const_iterator begin  () const { return fields.cbegin(); }
    typename Container::const_iterator cbegin () const { return fields.cbegin(); }
    typename Container::iterator       end    ()       { return fields.end(); }
    typename Container::const_iterator end    () const { return fields.cend(); }
    typename Container::const_iterator cend   () const { return fields.cend(); }
};





}}}
