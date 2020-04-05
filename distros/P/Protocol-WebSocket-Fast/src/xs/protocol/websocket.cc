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

void av_to_vstring (const Array& av, std::vector<string>& v) {
    for (const auto& elem : av) {
        if (!elem.defined()) continue;
        v.push_back(xs::in<string>(elem));
    }
}

ConnectRequestSP make_request(const Hash& params, const ConnectRequestSP& dest) {
    auto ret = dest ? dest : ConnectRequestSP(new ConnectRequest());
    http::fill(ret, params);

    Scalar val;

    if ((val = params.fetch("ws_key")))      ret->ws_key      = xs::in<string>(val);
    if ((val = params.fetch("ws_version")))  ret->ws_version  = SvIV(val);
    if ((val = params.fetch("ws_protocol"))) ret->ws_protocol = xs::in<string>(val);

    if ((val = params.fetch("ws_extensions"))) {
        auto exts_av = xs::in<Array>(val);
        HeaderValues exts;
        if (exts_av) av_to_header_values(exts_av, &exts);
        ret->ws_extensions(exts);
    }
    return ret;
}

ConnectResponseSP make_response(const Hash& params, const ConnectResponseSP& dest) {
    auto ret = dest ? dest : ConnectResponseSP(new ConnectResponse());
    http::fill(ret, params);

    Scalar val;

    if ((val = params.fetch("ws_extensions"))) {
        HeaderValues exts;
        av_to_header_values(xs::in<Array>(val), &exts);
        ret->ws_extensions(exts);
    }

    if ((val = params.fetch("ws_protocol"))) ret->ws_protocol = xs::in<string>(val);

    return ret;
}

}}}
