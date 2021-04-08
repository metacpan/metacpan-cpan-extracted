#pragma once
#include <vector>
#include <iosfwd>
#include <panda/string.h>
#include <boost/container/small_vector.hpp>


namespace panda { namespace protocol { namespace http {

struct Body {
    boost::container::small_vector<string, 2> parts;

    Body () {}
    Body (const string& body) { parts.emplace_back(body); }

    Body (const std::initializer_list<string>& l) { for (auto& s : l) parts.push_back(s); }

    Body (const Body&) = default;
    Body (Body&& oth)  = default;

    Body& operator= (const string& str) {
        parts.clear();
        if (str) parts.emplace_back(str);
        return *this;
    }

    Body& operator= (string&& str) {
        parts.clear();
        if (str) parts.emplace_back(std::move(str));
        return *this;
    }

    Body& operator= (const Body&) = default;
    Body& operator= (Body&&)      = default;

    size_t length () const {
        if (!parts.size()) return 0;
        uint64_t size = 0;
        for (auto& s : parts) size += s.length();
        return size;
    }

    string to_string () const;
    bool   empty     () const { return !length(); }

    void clear () { parts.clear(); }
};

std::ostream& operator<< (std::ostream&, const Body&);

}}}
