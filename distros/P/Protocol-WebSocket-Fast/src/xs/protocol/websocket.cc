#include "websocket.h"

namespace xs { namespace protocol { namespace websocket {

void av_to_header_values (const Array& av, HeaderValues* vals) {
    if (!av.size()) return;
    vals->reserve(av.size());
    for (const auto& sv : av) {
        const Array subav(sv);
        if (!subav) continue;
        auto namesv = subav.fetch(0);
        if (!namesv) continue;
        HeaderValue elem;
        elem.name = xs::in<string>(namesv);
        Hash args = subav.fetch(1);
        if (args) for (const auto& row : args) elem.params.emplace(string(row.key()), xs::in<string>(row.value()));
        vals->push_back(std::move(elem));
    }
}

Array header_values_to_av (const HeaderValues& vals) {
    if (!vals.size()) return Array();
    auto ret = Array::create(vals.size());
    for (const auto& elem : vals) {
        auto elemav = Array::create(2);
        elemav.push(xs::out(elem.name));
        if (elem.params.size()) {
            auto args = Hash::create(elem.params.size());
            for (const auto& param : elem.params) {
                args.store(param.first, xs::out(param.second));
            }
            elemav.push(Ref::create(args));
        }
        ret.push(Ref::create(elemav));
    }
    return ret;
}

ConnectRequestSP make_request (const Hash& params, const ConnectRequestSP& dest) {
    auto ret = dest ? dest : ConnectRequestSP(new ConnectRequest());
    http::fill(ret, params);

    Scalar val;

    if ((val = params.fetch("ws_key")))      ret->ws_key(xs::in<string>(val));
    if ((val = params.fetch("ws_version")))  ret->ws_version(SvIV(val));
    if ((val = params.fetch("ws_protocol"))) ret->ws_protocol(xs::in<string>(val));

    if ((val = params.fetch("ws_extensions"))) {
        auto exts_av = xs::in<Array>(val);
        HeaderValues exts;
        if (exts_av) av_to_header_values(exts_av, &exts);
        ret->ws_extensions(exts);
    }
    return ret;
}

ConnectResponseSP make_response (const Hash& params, const ConnectResponseSP& dest) {
    auto ret = dest ? dest : ConnectResponseSP(new ConnectResponse());
    http::fill(ret, params);

    Scalar val;

    if ((val = params.fetch("ws_extensions"))) {
        HeaderValues exts;
        av_to_header_values(xs::in<Array>(val), &exts);
        ret->ws_extensions(exts);
    }

    if ((val = params.fetch("ws_protocol"))) ret->ws_protocol(xs::in<string>(val));

    return ret;
}

void parser_config_in (Parser::Config& cfg, const Hash& h) {
    Scalar val;
    if ((val = h.fetch("max_frame_size")))     cfg.max_frame_size     = val.number();
    if ((val = h.fetch("max_message_size")))   cfg.max_message_size   = val.number();
    if ((val = h.fetch("max_handshake_size"))) cfg.max_handshake_size = val.number();
    if ((val = h.fetch("check_utf8")))         cfg.check_utf8         = val.is_true();

    if(h.exists("deflate")) cfg.deflate.reset();
    Hash deflate_settings = h.fetch("deflate");
    if (deflate_settings) {
        auto dcfg = xs::in<panda::protocol::websocket::DeflateExt::Config>(deflate_settings);
        cfg.deflate = dcfg;
    }
}

Hash parser_config_out (Parser::Config& cfg) {
    auto ret = Hash {
        {"max_frame_size", xs::out(cfg.max_frame_size)},
        {"max_message_size", xs::out(cfg.max_message_size)},
        {"max_handshake_size", xs::out(cfg.max_handshake_size)},
        {"check_utf8", xs::out(cfg.check_utf8)},
    };
    if (cfg.deflate) {
        ret.store("deflate", deflate_config_out(cfg.deflate.value()));
    }
    return  ret;
}

void deflate_config_in (DeflateExt::Config& cfg, const Hash& h) {
    Scalar val;
    if ((val = h.fetch("server_max_window_bits")))     cfg.server_max_window_bits     = val.number();
    if ((val = h.fetch("client_max_window_bits")))     cfg.client_max_window_bits     = val.number();
    if ((val = h.fetch("client_no_context_takeover"))) cfg.client_no_context_takeover = SvTRUE(val);
    if ((val = h.fetch("server_no_context_takeover"))) cfg.server_no_context_takeover = SvTRUE(val);
    if ((val = h.fetch("mem_level")))                  cfg.mem_level                  = val.number();
    if ((val = h.fetch("compression_level")))          cfg.compression_level          = val.number();
    if ((val = h.fetch("strategy")))                   cfg.strategy                   = val.number();
    if ((val = h.fetch("compression_threshold")))      cfg.compression_threshold      = val.number();
}

Sv deflate_config_out (const DeflateExt::Config& cfg) {
    Hash settings = Hash::create();
    settings.store("server_max_window_bits",     Simple(cfg.server_max_window_bits));
    settings.store("client_max_window_bits",     Simple(cfg.client_max_window_bits));
    settings.store("client_no_context_takeover", Simple(cfg.client_no_context_takeover));
    settings.store("server_no_context_takeover", Simple(cfg.server_no_context_takeover));
    settings.store("mem_level",                  Simple(cfg.mem_level));
    settings.store("compression_level",          Simple(cfg.compression_level));
    settings.store("strategy",                   Simple(cfg.strategy));
    settings.store("compression_threshold",      Simple(cfg.compression_threshold));
    return Ref::create(settings);
}

}}}
