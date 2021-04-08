#pragma once
#include "Frame.h"
#include "HeaderValueParamsParser.h"
#include <cassert>
#include <panda/refcnt.h>
#include <panda/optional.h>
#include <zlib.h>

namespace panda { namespace protocol { namespace websocket {

struct DeflateExt {
    struct Config {
        bool client_no_context_takeover = false;    // sent is only, when it is true; always parsed
        bool server_no_context_takeover = false;    // sent is only, when it is true; always parsed
        std::uint8_t server_max_window_bits = 15;
        std::uint8_t client_max_window_bits = 15;

        // copied from parser config, no direct usage
        size_t max_message_size = 0;
        // non-negotiatiable settings
        int mem_level = 8;
        int compression_level = Z_DEFAULT_COMPRESSION;
        int strategy = Z_DEFAULT_STRATEGY;
        size_t compression_threshold = 1410;  // try to fit into TCP frame
    };

    struct EffectiveConfig {
        static const constexpr int HAS_CLIENT_NO_CONTEXT_TAKEOVER = 1 << 0;
        static const constexpr int HAS_SERVER_NO_CONTEXT_TAKEOVER = 1 << 1;
        static const constexpr int HAS_SERVER_MAX_WINDOW_BITS     = 1 << 2;
        static const constexpr int HAS_CLIENT_MAX_WINDOW_BITS     = 1 << 3;
        enum class NegotiationsResult { Success, NotFound, Error };

        EffectiveConfig(const Config& cfg_, NegotiationsResult result_): cfg{cfg_}, result{result_} {}
        EffectiveConfig(NegotiationsResult result_): result{result_} {}

        explicit operator bool() const { return result == NegotiationsResult::Success; }

        Config cfg;
        int flags = 0;
        NegotiationsResult result;
    };

    struct NegotiationsResult {
        enum class Result { Success, NotFound, Error };

        Config cfg;
        int flags = 0;
        Result result = Result::Error;
    };

    enum class Role { CLIENT, SERVER };

    static string bootstrap();

    static EffectiveConfig select(const HeaderValues& values, const Config& cfg, Role role);
    static void request(HeaderValues& ws_extensions, const Config& cfg);
    static DeflateExt* uplift(const EffectiveConfig& cfg, HeaderValues& extensions, Role role);

    ~DeflateExt();

    void reset_tx();
    void reset_rx();

    void reset() {
        reset_rx();
        reset_tx();
    }

    string compress (string_view src, IsFinal final) {
        string ret(src.length() + TRAILER_SIZE);
        _compress(src, ret, Z_SYNC_FLUSH);
        if (final == IsFinal::YES) finalize_message(ret);
        return ret;
    }

    template<typename It>
    string compress (It&& payload_begin, It&& payload_end, IsFinal final) {
        size_t plen = 0;
        for (auto it = payload_begin; it != payload_end; ++it) plen += it->length();

        string ret(plen + TRAILER_SIZE);
        if (plen) {
            for (auto it = payload_begin; it != payload_end; ++it) {
                _compress(*it, ret, (it + 1 == payload_end) ? Z_SYNC_FLUSH : Z_NO_FLUSH);
            }
        }
        else _compress("", ret, Z_SYNC_FLUSH);

        if (final == IsFinal::YES) finalize_message(ret);
        return ret;
    }


    void uncompress (Frame& frame);

    const Config& effective_config() const { return effective_cfg; }

private:
    static const constexpr unsigned TRAILER_SIZE = 4; // tail empty frame 0x00 0x00 0xff 0xff

    Config effective_cfg;
    size_t message_size;
    size_t max_message_size;
    z_stream rx_stream;
    z_stream tx_stream;
    bool reset_after_tx;
    bool reset_after_rx;

    DeflateExt(const Config& cfg, Role role);

    void _compress (string_view src, string& dest, int flush);

    void finalize_message (string& str) {
        assert(str.length() >= TRAILER_SIZE);
        str.length(str.length() - TRAILER_SIZE);
        if (reset_after_tx) reset_tx();
    }
};

}}}
