#include "DeflateExt.h"
#include <panda/from_chars.h>
#include <panda/encode/base64.h>

namespace panda { namespace protocol { namespace websocket {

static const char extension_name[] = "permessage-deflate";

static const int   UNCOMPRESS_PREALLOCATE_RATIO = 10;
static const float GROW_RATIO                   = 1.5;

static const char PARAM_SERVER_NO_CONTEXT_TAKEOVER[] = "server_no_context_takeover";
static const char PARAM_CLIENT_NO_CONTEXT_TAKEOVER[] = "client_no_context_takeover";
static const char PARAM_SERVER_MAX_WINDOW_BITS[] = "server_max_window_bits";
static const char PARAM_CLIENT_MAX_WINDOW_BITS[] = "client_max_window_bits";

unsigned char _TRAILER[] = {0x00,  0x00, 0xFF, 0xFF};
static const string TRAILER((char*)_TRAILER, 4);

panda::string DeflateExt::bootstrap() {
    auto compiled_verison = string(ZLIB_VERSION);
    auto loaded_version   = string(zlibVersion());

    if (compiled_verison != loaded_version) {
        return string("zlib version mismatch, loaded: ") + loaded_version + string(", compiled") + compiled_verison;
    }
    return {};
}

void DeflateExt::request(HeaderValues& ws_extensions, const Config& cfg) {
    auto iter = std::find_if(ws_extensions.begin(), ws_extensions.end(), [](const HeaderValue& cur) {
        return cur.name == extension_name;
    });
    if (iter != ws_extensions.end()) {
        return;
    }

    HeaderValueParams params = {
        {PARAM_SERVER_MAX_WINDOW_BITS, panda::to_string(cfg.server_max_window_bits)},
        {PARAM_CLIENT_MAX_WINDOW_BITS, panda::to_string(cfg.client_max_window_bits)},
    };
    if(cfg.server_no_context_takeover) params.emplace(PARAM_SERVER_NO_CONTEXT_TAKEOVER, "");
    if(cfg.client_no_context_takeover) params.emplace(PARAM_CLIENT_NO_CONTEXT_TAKEOVER, "");

    ws_extensions.emplace_back(HeaderValue{extension_name, std::move(params)});
}


static bool get_window_bits(const string& value, std::uint8_t& bits) {
    auto res = from_chars(value.data(), value.data() + value.size(), bits, 10);
    return !res.ec && (bits >= 9) && (bits <= 15);
}

DeflateExt::EffectiveConfig DeflateExt::select(const HeaderValues& values, const Config& cfg, Role role) {
    for(auto& header: values) {
        if (header.name != extension_name) continue;
        EffectiveConfig ecfg(cfg, EffectiveConfig::NegotiationsResult::Error);
        bool params_correct = true;
        for(auto it = begin(header.params); params_correct && it != end(header.params); ++it) {
            auto& param_name = it->first;
            auto& param_value = it->second;
            if (param_name == PARAM_SERVER_NO_CONTEXT_TAKEOVER) {
                ecfg.flags |= EffectiveConfig::HAS_SERVER_NO_CONTEXT_TAKEOVER;
                ecfg.cfg.server_no_context_takeover = true;
            }
            else if (param_name == PARAM_CLIENT_NO_CONTEXT_TAKEOVER) {
                ecfg.flags |= EffectiveConfig::HAS_CLIENT_NO_CONTEXT_TAKEOVER;
                ecfg.cfg.client_no_context_takeover = true;
            }
            else if (param_name == PARAM_SERVER_MAX_WINDOW_BITS) {
                ecfg.flags |= EffectiveConfig::HAS_SERVER_MAX_WINDOW_BITS;
                std::uint8_t bits;
                params_correct = get_window_bits(param_value, bits);
                if (params_correct) {
                    ecfg.cfg.server_max_window_bits = bits;
                    if (role == Role::CLIENT) {
                        params_correct = bits == cfg.server_max_window_bits;
                    } else {
                        params_correct = bits <= cfg.server_max_window_bits;
                    }
                }
            }
            else if (param_name == PARAM_CLIENT_MAX_WINDOW_BITS) {
                ecfg.flags |= EffectiveConfig::HAS_CLIENT_MAX_WINDOW_BITS;
                std::uint8_t bits;
                // value is optional
                if (param_value) {
                    params_correct = get_window_bits(param_value, bits);
                    ecfg.cfg.client_max_window_bits = bits;
                    params_correct = params_correct && (
                            (role == Role::CLIENT) ? bits == cfg.client_max_window_bits
                                                   : bits <= cfg.client_max_window_bits
                        );
                } else {
                    ecfg.cfg.client_max_window_bits = 15;
                    // the value must be supplied in server response, otherwise (for client) it is invalid
                    params_correct = role == Role::SERVER;
                }
            } else { params_correct = false; }  // unknown parameter
        }
        if (params_correct) {
            // first best match wins (for server & client)
            ecfg.result = EffectiveConfig::NegotiationsResult::Success;
            return ecfg;
        }
        else if (role == Role::CLIENT) {
            // first fail (and terminate connection)
            return ecfg;
        }
    }
    return EffectiveConfig(EffectiveConfig::NegotiationsResult::NotFound);
}

DeflateExt* DeflateExt::uplift(const EffectiveConfig& ecfg, HeaderValues& extensions, Role role) {
    HeaderValueParams params;
    if (ecfg.flags & EffectiveConfig::HAS_SERVER_NO_CONTEXT_TAKEOVER) {
        params.emplace(PARAM_SERVER_NO_CONTEXT_TAKEOVER, "");
    }
    if (ecfg.flags & EffectiveConfig::HAS_CLIENT_NO_CONTEXT_TAKEOVER) {
        params.emplace(PARAM_CLIENT_NO_CONTEXT_TAKEOVER, "");
    }
    if (ecfg.flags & EffectiveConfig::HAS_SERVER_MAX_WINDOW_BITS) {
        params.emplace(PARAM_SERVER_MAX_WINDOW_BITS, to_string(ecfg.cfg.server_max_window_bits));
    }
    if (ecfg.flags & EffectiveConfig::HAS_CLIENT_MAX_WINDOW_BITS) {
        params.emplace(PARAM_CLIENT_MAX_WINDOW_BITS, to_string(ecfg.cfg.client_max_window_bits));
    }
    extensions.emplace_back(HeaderValue{extension_name, params});
    return new DeflateExt(ecfg.cfg, role);
}


DeflateExt::DeflateExt(const DeflateExt::Config& cfg, Role role): effective_cfg{cfg}, message_size{0}, max_message_size{cfg.max_message_size} {
    auto rx_window = role == Role::CLIENT ? cfg.server_max_window_bits : cfg.client_max_window_bits;
    auto tx_window = role == Role::CLIENT ? cfg.client_max_window_bits : cfg.server_max_window_bits;

    rx_stream.next_in = Z_NULL;
    rx_stream.avail_in = 0;
    rx_stream.zalloc = Z_NULL;
    rx_stream.zfree = Z_NULL;
    rx_stream.opaque = Z_NULL;

    // -1 is used as "raw deflate", i.e. do not emit header/trailers
    auto r = inflateInit2(&rx_stream, -1 * rx_window);
    if (r != Z_OK) {
        panda::string err = "zlib::inflateInit2 error";
        if (rx_stream.msg) err.append(panda::string(" : ") + rx_stream.msg);
        throw Error(err);
    }

    tx_stream.next_in = Z_NULL;
    tx_stream.avail_in = 0;
    tx_stream.zalloc = Z_NULL;
    tx_stream.zfree = Z_NULL;
    tx_stream.opaque = Z_NULL;

    // -1 is used as "raw deflate", i.e. do not emit header/trailers
    r = deflateInit2(&tx_stream, cfg.compression_level, Z_DEFLATED, -1 * tx_window, cfg.mem_level, cfg.strategy);
    if (r != Z_OK) {
        panda::string err = "zlib::deflateInit2 error";
        if (rx_stream.msg) err.append(panda::string(" : ") + rx_stream.msg);
        throw Error(err);
    }

    reset_after_tx =
               (role == Role::CLIENT && cfg.client_no_context_takeover)
            || (role == Role::SERVER && cfg.server_no_context_takeover);
    reset_after_rx =
               (role == Role::CLIENT && cfg.server_no_context_takeover)
            || (role == Role::SERVER && cfg.client_no_context_takeover);
}

DeflateExt::~DeflateExt(){
    auto zerr1 = deflateEnd(&tx_stream);
    auto zerr2 = inflateEnd(&rx_stream);
    if (zerr1 != Z_OK && zerr1 != Z_DATA_ERROR) panda_log_error("zlib::deflateEnd error msg='" << (tx_stream.msg ? tx_stream.msg : "<null>") << "' code=" << zerr1);
    if (zerr2 != Z_OK && zerr2 != Z_DATA_ERROR) panda_log_error("zlib::inflateEnd error msg='" << (rx_stream.msg ? rx_stream.msg : "<null>") << "' code=" << zerr2);
}

static inline void grow (string& dest, z_stream& stream) {
    auto prev_sz = dest.capacity();
    size_t new_sz = prev_sz * GROW_RATIO;
    dest.length(prev_sz);
    auto buf = dest.reserve(new_sz);
    stream.next_out = (Bytef*)buf + prev_sz;
    stream.avail_out = new_sz - prev_sz;
    assert(stream.avail_out > 0);
}

void DeflateExt::_compress (string_view src, string& dest, int flush) {
    tx_stream.next_in = (Bytef*)src.data();
    tx_stream.avail_in = static_cast<uInt>(src.length());
    tx_stream.next_out = (Bytef*)dest.buf() + dest.length();
    tx_stream.avail_out = static_cast<uInt>(dest.capacity() - dest.length());

    auto has_trailer = [](const string& s) -> bool {
        if (s.length() < TRAILER_SIZE) return false;
        return s.substr(s.length() - TRAILER_SIZE, TRAILER_SIZE) == TRAILER;
    };

    while (tx_stream.avail_in || flush == Z_SYNC_FLUSH) {
        if (!tx_stream.avail_out) grow(dest, tx_stream);
        auto r = deflate(&tx_stream, flush);
        assert(r >= 0); (void)r;
        dest.length(dest.capacity() - tx_stream.avail_out);
        if (tx_stream.avail_out || has_trailer(dest)) break;
    }

}

void DeflateExt::uncompress (Frame& frame) {
    bool final = frame.final();
    auto plen  = frame.payload_length();
    if (!plen && !final) return;

    // if no data arrived, force at least SSO capacity (by passing X>0)
    // CAN'T BE ZERO because otherwise capacity will be 0 and inflate will finish with error
    string acc;
    acc.reserve(plen ? plen * UNCOMPRESS_PREALLOCATE_RATIO : 1);

    rx_stream.next_out = reinterpret_cast<Bytef*>(acc.buf());
    rx_stream.avail_out = static_cast<uInt>(acc.capacity());

    auto inflate_impl = [&](string& dest, const string& src, int flush) -> bool {
        rx_stream.next_in = (Bytef*)src.data();
        rx_stream.avail_in = static_cast<uInt>(src.length());
        while (1) {
            auto r = inflate(&rx_stream, flush);
            if (r != Z_OK) {
                panda_log_warning("zlib::inflate error msg='" << rx_stream.msg << "' code=" << r);
                frame.error(errc::inflate_error);
                return false;
            }
            if (max_message_size && (message_size + (dest.capacity() - rx_stream.avail_out) > max_message_size)) {
                frame.error(errc::max_message_size);
                return false;
            }
            if (!rx_stream.avail_in) return true; // no more input
            assert(!rx_stream.avail_out); // the only case we're here is we're ran out of buffer
            grow(dest, rx_stream);
        }
        return true;
    };

    // reset stream in case of a) error and b) when it was last frame of message and there was setting to do so

    auto npayloads = frame.payload.size();
    for (size_t i = 0; i < npayloads; ++i) {
        auto flush = ((i == npayloads - 1) && !final) ? Z_SYNC_FLUSH : Z_NO_FLUSH;
        auto res = inflate_impl(acc, frame.payload[i], flush);
        if (!res) return reset_rx();
    }

    if (final) {
        auto res = inflate_impl(acc, TRAILER, Z_SYNC_FLUSH);
        if (!res) return reset_rx();
        message_size = 0;
        if (reset_after_rx) reset_rx();
    }

    acc.length(acc.capacity() - rx_stream.avail_out);

    if (acc) {
        message_size += acc.length();
        frame.payload.resize(1);
        frame.payload[0] = std::move(acc);
    }
    else frame.payload.clear(); // remove empty string from payload if no data
}

void DeflateExt::reset_tx() {
    if (!tx_stream.next_in) return;
    tx_stream.next_in = Z_NULL;
    auto zerr = deflateReset(&tx_stream);
    if (zerr != Z_OK) panda_log_error("zlib::deflateReset error msg='" << tx_stream.msg << "' code=" << zerr);
}

void DeflateExt::reset_rx() {
    if (!rx_stream.next_in) return;
    rx_stream.next_in = Z_NULL;
    auto zerr = inflateReset(&rx_stream);
    if (zerr != Z_OK) panda_log_error("zlib::inflateReset error msg='" << rx_stream.msg << "' code=" << zerr);
}

}}}
