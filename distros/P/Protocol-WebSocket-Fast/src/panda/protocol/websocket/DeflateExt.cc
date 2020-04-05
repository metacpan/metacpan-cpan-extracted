#include "DeflateExt.h"
#include <panda/from_chars.h>
#include <panda/encode/base64.h>
#include <panda/log.h>

namespace panda { namespace protocol { namespace websocket {

const char* DeflateExt::extension_name = "permessage-deflate";

static const int   UNCOMPRESS_PREALLOCATE_RATIO = 10;
static const float COMPRESS_PREALLOCATE_RATIO   = 1;
static const float GROW_RATIO                   = 1.5;

static const char PARAM_SERVER_NO_CONTEXT_TAKEOVER[] = "server_no_context_takeover";
static const char PARAM_CLIENT_NO_CONTEXT_TAKEOVER[] = "client_no_context_takeover";
static const char PARAM_SERVER_MAX_WINDOW_BITS[] = "server_max_window_bits";
static const char PARAM_CLIENT_MAX_WINDOW_BITS[] = "client_max_window_bits";

panda::optional<panda::string> DeflateExt::bootstrap() {
    using result_t = panda::optional<panda::string>;
    panda::string compiled_verison{ZLIB_VERSION};
    panda::string loaded_version{zlibVersion()};

    if (compiled_verison != loaded_version) {
        panda::string err = "zlib version mismatch, loaded: " + loaded_version + ", compiled" + compiled_verison;
        return result_t{err};
    }
    return  result_t{}; // all OK
}

void DeflateExt::request(HeaderValues& ws_extensions, const Config& cfg) {
    auto iter = std::find_if(ws_extensions.begin(), ws_extensions.end(), [](const HeaderValue& cur) {
        return cur.name == extension_name;
    });
    if (iter != ws_extensions.end()) {
        return;
    }

    HeaderValueParams params;
    params.emplace(PARAM_SERVER_MAX_WINDOW_BITS, panda::to_string(cfg.server_max_window_bits));
    params.emplace(PARAM_CLIENT_MAX_WINDOW_BITS, panda::to_string(cfg.client_max_window_bits));
    if(cfg.server_no_context_takeover) params.emplace(PARAM_SERVER_NO_CONTEXT_TAKEOVER, "");
    if(cfg.client_no_context_takeover) params.emplace(PARAM_CLIENT_NO_CONTEXT_TAKEOVER, "");

    string name{extension_name};
    HeaderValue hv {name, std::move(params)};
    ws_extensions.emplace_back(std::move(hv));
}


static bool get_window_bits(const string& value, std::uint8_t& bits) {
    auto res = from_chars(value.data(), value.data() + value.size(), bits, 10);
    return !res.ec && (bits >= 9) && (bits <= 15);
}

DeflateExt::EffectiveConfig DeflateExt::select(const HeaderValues& values, const Config& cfg, Role role) {
    for(auto& header: values) {
        if (header.name == extension_name) {
            EffectiveConfig ecfg(cfg, EffectiveConfig::NegotiationsResult::ERROR);
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
                ecfg.result = EffectiveConfig::NegotiationsResult::SUCCESS;
                return ecfg;
            }
            else if (role == Role::CLIENT) {
                // first fail (and terminate connection)
                return ecfg;
            }

        }
    }
    return EffectiveConfig(EffectiveConfig::NegotiationsResult::NOT_FOUND);
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
    extensions.emplace_back(HeaderValue{string(extension_name), params});
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
        throw std::runtime_error(err);
    }

    tx_stream.next_in = Z_NULL;
    tx_stream.avail_in = 0;
    tx_stream.zalloc = Z_NULL;
    tx_stream.zfree = Z_NULL;
    tx_stream.opaque = Z_NULL;

    // -1 is used as "raw deflate", i.e. do not emit header/trailers
    r = deflateInit2(&tx_stream, cfg.compression_level, Z_DEFLATED, -1 * tx_window , cfg.mem_level, cfg.strategy);
    if (r != Z_OK) {
        panda::string err = "zlib::deflateInit2 error";
        if (rx_stream.msg) err.append(panda::string(" : ") + rx_stream.msg);
        throw std::runtime_error(err);
    }

    reset_after_tx =
               (role == Role::CLIENT && cfg.client_no_context_takeover)
            || (role == Role::SERVER && cfg.server_no_context_takeover);
    reset_after_rx =
               (role == Role::CLIENT && cfg.server_no_context_takeover)
            || (role == Role::SERVER && cfg.client_no_context_takeover);
}

void DeflateExt::reset_tx() {
    if (!tx_stream.next_in) return;
    tx_stream.next_in = Z_NULL;

    if (deflateReset(&tx_stream) != Z_OK) {
        panda::string err = panda::string("zlib::deflateEnd error ");
        if (tx_stream.msg) {
            err += tx_stream.msg;
        }
        throw std::runtime_error(err);
    }
}

void DeflateExt::reset_rx() {
    if (!rx_stream.next_in) return;
    rx_stream.next_in = Z_NULL;

    if (inflateReset(&rx_stream) != Z_OK) {
        panda::string err = panda::string("zlib::inflateEnd error ");
        if(rx_stream.msg) {
            err += rx_stream.msg;
        }
    }
}


DeflateExt::~DeflateExt(){
    if (deflateEnd(&tx_stream) != Z_OK) {
        panda::string err = panda::string("zlib::deflateEnd error ");
        if (tx_stream.msg) {
            err += tx_stream.msg;
        }
        assert(err.c_str());
    }
    if (inflateEnd(&rx_stream) != Z_OK) {
        panda::string err = panda::string("zlib::inflateEnd error ");
        if(rx_stream.msg) {
            err += rx_stream.msg;
        }
        assert(err.c_str());
    }
}


string& DeflateExt::compress(string& str, bool final) {
    string in = str;
    tx_stream.next_in = (Bytef*)(in.data());
    tx_stream.avail_in = static_cast<uInt>(in.length());
    str = string(in.length() * COMPRESS_PREALLOCATE_RATIO); // detach and realloc for result here
    tx_stream.next_out = reinterpret_cast<Bytef*>(str.buf()); // buf would not detach, we just created new string and refcnt == 1
    auto sz = str.capacity();
    str.length(sz);
    tx_stream.avail_out = static_cast<uInt>(sz);

    deflate_iteration(Z_SYNC_FLUSH, [&](){
        sz += reserve_for_trailer(str);
    });

    sz -= tx_stream.avail_out;

    if (final) {
        sz -= TRAILER_SIZE; // remove tail empty-frame 0x00 0x00 0xff 0xff for final messages only
        if (reset_after_tx) reset_tx();
    }
    str.length(sz);

    return str;
}

bool DeflateExt::uncompress(Frame& frame) {
    bool r;
    if (frame.error) r = false;
    else if (frame.is_control()) {
        frame.error = errc::control_frame_compression;
        r = false;
    }
    else if (frame.payload_length() == 0) r = true;
    else {
        r = uncompress_impl(frame);
    }
    // reset stream in case of a) error and b) when it was last frame of message
    // and there was setting to do not use
    if(!r || (frame.final() && reset_after_rx)) reset_rx();
    if (frame.final()) message_size = 0;
    return r;
}

bool DeflateExt::uncompress_check_overflow(Frame& frame, const string& acc) {
    auto unpacked_frame_size = acc.capacity() - rx_stream.avail_out;
    auto unpacked_message_size = message_size + unpacked_frame_size;
    if (unpacked_message_size > max_message_size) {
        frame.error = errc::max_message_size;
        return false;
    }
    return true;
}

void DeflateExt::rx_increase_buffer(string& acc) {
    auto prev_sz = acc.capacity();
    size_t new_sz = prev_sz * GROW_RATIO;
    acc.length(prev_sz);
    acc.reserve(new_sz);
    rx_stream.next_out = reinterpret_cast<Bytef*>(acc.buf() + prev_sz);
    rx_stream.avail_out = static_cast<uInt>(new_sz - prev_sz);
}


bool DeflateExt::uncompress_impl(Frame& frame) {
    using It = decltype(frame.payload)::iterator;

    bool final = frame.final();
    It it_in = frame.payload.begin();
    It end = frame.payload.end();

    string acc;
    acc.reserve(frame.payload_length() * UNCOMPRESS_PREALLOCATE_RATIO);

    rx_stream.next_out = reinterpret_cast<Bytef*>(acc.buf());
    rx_stream.avail_out = static_cast<uInt>(acc.capacity());

    do {
        string& chunk_in = *it_in;
        It it_next = ++it_in;
        if (it_next == end && final) {
            // append empty-frame 0x00 0x00 0xff 0xff
            unsigned char trailer[TRAILER_SIZE] = { 0x00,  0x00, 0xFF, 0xFF };
            chunk_in.append(reinterpret_cast<char*>(trailer), TRAILER_SIZE);
            rx_stream.avail_in += TRAILER_SIZE;
        }
        // std::cout << "[debug] b64 payload: " << encode::encode_base64(chunk_in) << "\n";
        rx_stream.next_in = reinterpret_cast<Bytef*>(chunk_in.buf());
        rx_stream.avail_in = static_cast<uInt>(chunk_in.length());
        auto flush = (it_next == end) ? Z_SYNC_FLUSH : Z_NO_FLUSH;
        bool has_more_output = true;
        do {
            has_more_output = !rx_stream.avail_out;
            auto r = inflate(&rx_stream, flush);
            switch (r) {
            case Z_OK:
                if (max_message_size && !uncompress_check_overflow(frame, acc)) return false;
                if (!rx_stream.avail_out) {
                    rx_increase_buffer(acc);
                    has_more_output = true;
                } else {
                    has_more_output = false;
                }
                break;
            case Z_BUF_ERROR:
                /* it is non-fatal error. It is unavoidable, if we unpacked the payload which
                 * fits into accumulator acc exactly, i.e. on the previous iteration it was
                 * rx_stream.avail_out == 0 and it is not known, whether there is still some
                 * output or no. If there is no output, than this error code is returned
                 */
                has_more_output = false;
                break;
            default:
                string err = "zlib::inflate error ";
                if (rx_stream.msg) err += rx_stream.msg;
                else err += to_string(r);
                panda_mlog_info(pwslog, err);
                frame.error = errc::inflate_error;
                return false;
            }
        } while(has_more_output);
        it_in = it_next;
    } while(it_in != end);

    acc.length(acc.capacity() - rx_stream.avail_out);
    message_size += acc.length();

    if (acc) {
        frame.payload.resize(1);
        frame.payload[0] = std::move(acc);
    }
    else frame.payload.clear(); // remove empty string from payload if no data

    return true;
}

}}}
