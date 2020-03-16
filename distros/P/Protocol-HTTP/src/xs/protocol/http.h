#pragma once
#include <xs/uri.h>
#include <panda/protocol/http/RequestParser.h>
#include <panda/protocol/http/ResponseParser.h>

namespace xs { namespace protocol { namespace http {
    using namespace panda::protocol::http;

    void fill (Request*,  const Hash&);
    void fill (Response*, const Hash&);

    void set_headers          (Message*,  const Hash&);
    void set_method           (Request*,  const Sv&);
    void set_request_cookies  (Request*,  const Hash&);
    void set_response_cookies (Response*, const Hash&);

    template <typename T>
    Simple strings_to_sv (const T& v) {
        size_t len = 0;
        for (const auto& s : v) len += s.length();
        if (!len) return Simple::undef;

        auto ret = Simple::create(len);
        char* dest = ret.get<char*>();
        for (const auto& s : v) {
            memcpy(dest, s.data(), s.length());
            dest += s.length();
        }
        *dest = 0;
        ret.length(len);
        return ret;
    }
}}}

namespace xs {

template <>
struct Typemap<panda::protocol::http::State> : TypemapBase<panda::protocol::http::State> {
    using State = panda::protocol::http::State;
    static inline State in  (SV* arg)                     { return (State)SvIV(arg); }
    static inline Sv    out (State var, const Sv& = Sv()) { return Simple((int)var); }
};

template <class TYPE>
struct Typemap<panda::protocol::http::Message*, TYPE> : TypemapObject<panda::protocol::http::Message*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {};

template <class TYPE>
struct Typemap<panda::protocol::http::Request*, TYPE> : Typemap<panda::protocol::http::Message*, TYPE> {
    static panda::string_view package () { return "Protocol::HTTP::Request"; }
};

template <class TYPE>
struct Typemap<panda::protocol::http::RequestSP, panda::iptr<TYPE>> : Typemap<TYPE*> {
    using Super = Typemap<TYPE*>;
    static panda::iptr<TYPE> in (Sv arg) {
        if (arg.is_object_ref()) return Super::in(arg);
        else if (!arg.defined()) return {};
        panda::iptr<TYPE> ret = make_backref<TYPE>();
        xs::protocol::http::fill(ret.get(), arg);
        return ret;
    }
};

template <class TYPE>
struct Typemap<panda::protocol::http::Response*, TYPE> : Typemap<panda::protocol::http::Message*, TYPE> {
    static panda::string_view package () { return "Protocol::HTTP::Response"; }
};

template <class TYPE>
struct Typemap<panda::protocol::http::ResponseSP, panda::iptr<TYPE>> : Typemap<TYPE*> {
    using Super = Typemap<TYPE*>;
    static panda::iptr<TYPE> in (Sv arg) {
        if (arg.is_object_ref()) return Super::in(arg);
        else if (!arg.defined()) return {};
        panda::iptr<TYPE> ret = make_backref<TYPE>();
        xs::protocol::http::fill(ret.get(), arg);
        return ret;
    }
};

template <>
struct Typemap<panda::protocol::http::Response::Cookie> : TypemapBase<panda::protocol::http::Response::Cookie> {
    using Cookie = panda::protocol::http::Response::Cookie;
    static Cookie in  (const Hash& arg);
    static Sv     out (const Cookie&, const Sv& = {});
};

template <class TYPE>
struct Typemap<panda::protocol::http::RequestParser*, TYPE> : TypemapObject<panda::protocol::http::RequestParser*, TYPE, ObjectTypePtr, ObjectStorageMG> {
    static std::string package () { return "Protocol::HTTP::RequestParser"; }
};

template <class TYPE>
struct Typemap<panda::protocol::http::ResponseParser*, TYPE> : TypemapObject<panda::protocol::http::ResponseParser*, TYPE, ObjectTypePtr, ObjectStorageMG> {
    static std::string package () { return "Protocol::HTTP::ResponseParser"; }
};

}
