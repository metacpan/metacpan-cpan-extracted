#pragma once
#include <iosfwd>
#include "Fields.h"

namespace panda { namespace protocol { namespace http {

template <size_t PRERESERVE>
struct GenericHeaders : Fields<string, false, PRERESERVE> {
    using Super = Fields<string, false, PRERESERVE>;

    using Super::Super;
    using Super::operator=;

    GenericHeaders& add (const string& key, const string& value) & {
        Super::add(key, value);
        return *this;
    }

    GenericHeaders&& add (const string& key, const string& value) && {
        Super::add(key, value);
        return std::move(*this);
    }

    uint32_t length () const {
        uint32_t ret = 0;
        for (auto& field : this->fields) ret += field.name.length() + 2 + field.value.length() + 2;
        return ret;
    }

    string connection () const { return this->get("Connection", ""); }
    string date       () const { return this->get("Date", ""); }
    string host       () const { return this->get("Host", ""); }
    string location   () const { return this->get("Location", ""); }

    GenericHeaders&  connection      (const string& ctype) &     { return add("Connection", ctype); }
    GenericHeaders&& connection      (const string& ctype) &&    { return std::move(*this).add("Connection", ctype); }
    GenericHeaders&  date            (const string& date) &      { return add("Date", date); }
    GenericHeaders&& date            (const string& date) &&     { return std::move(*this).add("Date", date); }
    GenericHeaders&  host            (const string& host) &      { return add("Host", host); }
    GenericHeaders&& host            (const string& host) &&     { return std::move(*this).add("Host", host); }
    GenericHeaders&  location        (const string& location) &  { return add("Location", location); }
    GenericHeaders&& location        (const string& location) && { return std::move(*this).add("Location", location); }
    GenericHeaders&  chunked         () &                        { return add("Transfer-Encoding", "chunked"); }
    GenericHeaders&& chunked         () &&                       { return std::move(*this).add("Transfer-Encoding", "chunked"); }
    GenericHeaders&  expect_continue () &                        { return add("Expect", "100-continue"); }
    GenericHeaders&& expect_continue () &&                       { return std::move(*this).add("Expect", "100-continue"); }
};

using Headers = GenericHeaders<15>;

bool operator== (const Headers&, const Headers&);
inline bool operator!= (const Headers& lhs, const Headers& rhs) { return !operator==(lhs, rhs); }

std::ostream& operator<< (std::ostream&, const Headers::Field&);

}}}
