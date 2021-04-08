#pragma once
#include <xs.h>
#include <xs/protocol/http.h>
#include <panda/protocol/websocket.h>

namespace xs { namespace protocol { namespace websocket {

using namespace panda::protocol::websocket;

struct XSFrameIterator : FrameIterator {
    XSFrameIterator (Parser* parser, const FrameSP& start_frame) : FrameIterator(parser, start_frame), nexted(false) { parser->retain(); }
    XSFrameIterator (const XSFrameIterator& oth)                 : FrameIterator(oth), nexted(oth.nexted)            { parser->retain(); }
    XSFrameIterator (const FrameIterator& oth)                   : FrameIterator(oth), nexted(false)                 { parser->retain(); }

    FrameSP next () {
        if (nexted) operator++();
        else nexted = true;
        return cur;
    }

    ~XSFrameIterator () { parser->release(); }
private:
    bool nexted;
};

struct XSMessageIterator : MessageIterator {
    XSMessageIterator (Parser* parser, const MessageSP& start_msg) : MessageIterator(parser, start_msg), nexted(false) { parser->retain(); }
    XSMessageIterator (const XSMessageIterator& oth)               : MessageIterator(oth), nexted(oth.nexted)          { parser->retain(); }
    XSMessageIterator (const MessageIterator& oth)                 : MessageIterator(oth), nexted(false)               { parser->retain(); }

    MessageSP next () {
        if (nexted) operator++();
        else nexted = true;
        return cur;
    }

    ~XSMessageIterator () { parser->release(); }
private:
    bool nexted;
};

struct XSFrameSender : FrameSender {
    XSFrameSender (FrameSender&& fb): FrameSender(std::move(fb)) {
        // keep link to make XSFrameSender perl-safe
        _parser.retain();
    }
    ~XSFrameSender () { _parser.release(); }
};

void  av_to_header_values (const Array& av, HeaderValues* vals);
Array header_values_to_av (const HeaderValues& vals);

ConnectRequestSP  make_request  (const Hash& params, const ConnectRequestSP& = {});
ConnectResponseSP make_response (const Hash& params, const ConnectResponseSP& = {});

void parser_config_in   (Parser::Config&, const Hash&);
Hash parser_config_out  (Parser::Config& cfg);
void deflate_config_in  (DeflateExt::Config&, const Hash&);
Sv   deflate_config_out (const DeflateExt::Config&);

}}}

namespace xs {

    template <class TYPE>
    struct Typemap<panda::protocol::websocket::Parser*, TYPE> : TypemapObject<panda::protocol::websocket::Parser*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMG> {};

    template <class TYPE>
    struct Typemap<panda::protocol::websocket::ClientParser*, TYPE> : Typemap<panda::protocol::websocket::Parser*, TYPE> {
        static std::string package () { return "Protocol::WebSocket::Fast::ClientParser"; }
    };

    template <class TYPE>
    struct Typemap<panda::protocol::websocket::ServerParser*, TYPE> : Typemap<panda::protocol::websocket::Parser*, TYPE> {
        static std::string package () { return "Protocol::WebSocket::Fast::ServerParser"; }
    };

    template <class TYPE>
    struct Typemap<panda::protocol::websocket::ConnectRequest*, TYPE> : Typemap<panda::protocol::http::Request*, TYPE> {
        static std::string package () { return "Protocol::WebSocket::Fast::ConnectRequest"; }
    };

    template <class TYPE>
    struct Typemap<panda::protocol::websocket::ConnectRequestSP, panda::iptr<TYPE>> : Typemap<TYPE*> {
        using Super = Typemap<TYPE*>;
        static panda::iptr<TYPE> in (Sv arg) {
            if (!arg.is_object_ref()) arg = Super::default_stash().call("new", arg);
            return Super::in(arg);
        }
    };

    template <class TYPE>
    struct Typemap<panda::protocol::websocket::ConnectResponse*, TYPE> : Typemap<panda::protocol::http::Response*, TYPE> {
        static std::string package () { return "Protocol::WebSocket::Fast::ConnectResponse"; }
    };

    template <class TYPE>
    struct Typemap<panda::protocol::websocket::ConnectResponseSP, panda::iptr<TYPE>> : Typemap<TYPE*> {
        using Super = Typemap<TYPE*>;
        static panda::iptr<TYPE> in (Sv arg) {
            if (!arg.is_object_ref()) arg = Super::default_stash().call("new", arg);
            return Super::in(arg);
        }
    };

    template <class TYPE>
    struct Typemap<panda::protocol::websocket::Frame*, TYPE> : TypemapObject<panda::protocol::websocket::Frame*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMG> {
        static std::string package () { return "Protocol::WebSocket::Fast::Frame"; }
    };

    template <class TYPE>
    struct Typemap<panda::protocol::websocket::Message*, TYPE> : TypemapObject<panda::protocol::websocket::Message*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMG> {
        static std::string package () { return "Protocol::WebSocket::Fast::Message"; }
    };

    template <class TYPE>
    struct Typemap<xs::protocol::websocket::XSFrameIterator*, TYPE> : TypemapObject<xs::protocol::websocket::XSFrameIterator*, TYPE, ObjectTypePtr, ObjectStorageMG> {
        static std::string package () { return "Protocol::WebSocket::Fast::FrameIterator"; }
    };

    template <class TYPE>
    struct Typemap<xs::protocol::websocket::XSMessageIterator*, TYPE> : TypemapObject<xs::protocol::websocket::XSMessageIterator*, TYPE, ObjectTypePtr, ObjectStorageMG> {
        static std::string package () { return "Protocol::WebSocket::Fast::MessageIterator"; }
    };

    template <class TYPE>
    struct Typemap<xs::protocol::websocket::XSFrameSender*, TYPE> : TypemapObject<xs::protocol::websocket::XSFrameSender*, TYPE, ObjectTypePtr, ObjectStorageMG> {
        static std::string package () { return "Protocol::WebSocket::Fast::FrameSender"; }
    };

    template <class TYPE> struct Typemap<panda::protocol::websocket::DeflateExt::Config, TYPE> : TypemapBase<panda::protocol::websocket::DeflateExt::Config, TYPE> {
        static TYPE in (SV* arg) {
            TYPE cfg;
            xs::protocol::websocket::deflate_config_in(cfg, arg);
            return cfg;
        }

        static Sv out (TYPE var, const Sv& = Sv()) { return xs::protocol::websocket::deflate_config_out(var); }
    };

    template <class TYPE> struct Typemap<panda::protocol::websocket::Parser::Config, TYPE> : TypemapBase<panda::protocol::websocket::Parser::Config, TYPE> {
        static TYPE in (SV* arg) {
            TYPE cfg;
            xs::protocol::websocket::parser_config_in(cfg, arg);
            return cfg;
        }

        static Sv out (TYPE var, const Sv& = Sv()) { return Ref::create(xs::protocol::websocket::parser_config_out(var)); }
    };

    template <> struct Typemap<panda::protocol::websocket::IsFinal> : TypemapBase<panda::protocol::websocket::IsFinal> {
        static panda::protocol::websocket::IsFinal in (SV* arg) {
            return SvTRUE(arg) ? panda::protocol::websocket::IsFinal::YES : panda::protocol::websocket::IsFinal::NO;
        }
    };
}
