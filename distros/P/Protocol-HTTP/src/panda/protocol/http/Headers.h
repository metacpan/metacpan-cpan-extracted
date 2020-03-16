#pragma once
#include "Fields.h"

namespace panda { namespace protocol { namespace http {

struct Headers : Fields<string, false, 15> {
    using Fields::Fields;
    using Fields::operator=;

    Headers& add (const string& key, const string& value) & {
        Fields::add(key, value);
        return *this;
    }

    Headers&& add (const string& key, const string& value) && {
        Fields::add(key, value);
        return std::move(*this);
    }

    uint32_t length () const {
        uint32_t ret = 0;
        for (auto& field : fields) ret += field.name.length() + 2 + field.value.length() + 2;
        return ret;
    }

    string connection () const { return get("Connection", ""); }
    string date       () const { return get("Date", ""); }
    string host       () const { return get("Host", ""); }
    string location   () const { return get("Location", ""); }

    Headers&  connection      (const string& ctype) &     { return add("Connection", ctype); }
    Headers&& connection      (const string& ctype) &&    { return std::move(*this).add("Connection", ctype); }
    Headers&  date            (const string& date) &      { return add("Date", date); }
    Headers&& date            (const string& date) &&     { return std::move(*this).add("Date", date); }
    Headers&  host            (const string& host) &      { return add("Host", host); }
    Headers&& host            (const string& host) &&     { return std::move(*this).add("Host", host); }
    Headers&  location        (const string& location) &  { return add("Location", location); }
    Headers&& location        (const string& location) && { return std::move(*this).add("Location", location); }
    Headers&  chunked         () &                        { return add("Transfer-Encoding", "chunked"); }
    Headers&& chunked         () &&                       { return std::move(*this).add("Transfer-Encoding", "chunked"); }
    Headers&  expect_continue () &                        { return add("Expect", "100-continue"); }
    Headers&& expect_continue () &&                       { return std::move(*this).add("Expect", "100-continue"); }
};

}}}
