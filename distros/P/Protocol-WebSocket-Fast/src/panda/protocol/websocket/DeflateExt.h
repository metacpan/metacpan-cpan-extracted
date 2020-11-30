#pragma once
#include "Frame.h"
#include "HeaderValueParamsParser.h"
#include <cassert>
#include <panda/refcnt.h>
#include <panda/optional.h>
#include <zlib.h>

namespace panda { namespace protocol { namespace websocket {

class DeflateExt {
private:
    // tail empty frame 0x00 0x00 0xff 0xff
    static const constexpr unsigned TRAILER_SIZE = 4;

    // zlib doc:
    // In the case of a Z_FULL_FLUSH or Z_SYNC_FLUSH, make sure that avail_out is greater than six
    // to avoid repeated flush markers due to avail_out == 0 on return.
    static const constexpr unsigned TRAILER_RESERVED = TRAILER_SIZE + 3;

public:

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

    static const char* extension_name;

    static panda::optional<panda::string> bootstrap();

    static EffectiveConfig select(const HeaderValues& values, const Config& cfg, Role role);
    static void request(HeaderValues& ws_extensions, const Config& cfg);
    static DeflateExt* uplift(const EffectiveConfig& cfg, HeaderValues& extensions, Role role);

    ~DeflateExt();

    void reset_tx();
    void reset() {
        reset_rx();
        reset_tx();
    }
    string& compress(string& str, bool final);

    template<typename It>
    It compress(It payload_begin, It payload_end, bool final) {
        // we should not try to compress empty last piece
        assert(!(final && (payload_begin == payload_end)));

        It it_in = payload_begin;
        It it_out = payload_begin;
        tx_stream.avail_out = 0;

        string* chunk_out = nullptr;
        while(it_in != payload_end) {
            auto it_next = it_in + 1;
            string chunk_in = *it_in;
            tx_stream.next_in = (Bytef*)(chunk_in.data());
            tx_stream.avail_in = static_cast<uInt>(chunk_in.length());
            // for last fragment we either complete frame(Z_SYNC_FLUSH) or message(flush_policy())
            // otherwise no flush it perfromed
            auto flush = (it_next == payload_end) ? Z_SYNC_FLUSH : Z_NO_FLUSH;
            auto avail_out = tx_stream.avail_out;
            do {
                deflate_iteration(flush, [&](){
                    bool reserve_something = false;
                    // the current chunk is already filled, try the next one
                    if (it_out < it_next) {
                        if (chunk_out) {
                            auto tx_out = avail_out - tx_stream.avail_out;
                            chunk_out->length(chunk_out->length() + tx_out);
                        }
                        chunk_out = &(*it_out++);
                        *chunk_out = string(chunk_out->length());
                        tx_stream.next_out = reinterpret_cast<Bytef*>(chunk_out->buf());
                        avail_out = tx_stream.avail_out = static_cast<uInt>(chunk_out->capacity());
                        reserve_something = avail_out < TRAILER_RESERVED;
                    }
                    else {
                        // there are no more chunks, resize the last/current one
                        reserve_something = true;
                    }
                    if (reserve_something) {
                        avail_out = reserve_for_trailer(*chunk_out);
                    }
                });
            } while(tx_stream.avail_in);
            auto tx_out = avail_out - tx_stream.avail_out;
            if (chunk_out) { chunk_out->length(chunk_out->length() + tx_out); }
            it_in = it_next;
        }
        if(final) {
            size_t tail_left = TRAILER_SIZE;
            while(tail_left){
                --it_out;
                string& chunk = *it_out;
                int delta = chunk.length() - tail_left;
                if (delta >= 0) {
                    chunk.length(delta);
                    tail_left = 0;
                }
                else {
                    tail_left -= chunk.length();
                    chunk.length(0);
                }
            }
            ++it_out;
            if(reset_after_tx) reset_tx();
        }
        return it_out;
    }

    bool uncompress(Frame& frame);

    const Config& effective_config() const { return effective_cfg; }

private:

    template<typename F>
    inline void deflate_iteration(int flush, F&& drain) {
        do {
            if (!tx_stream.avail_in && flush == Z_NO_FLUSH) return;
            size_t min_out_sz = flush == Z_SYNC_FLUSH ? TRAILER_RESERVED : 1;
            if (tx_stream.avail_out < min_out_sz) drain();
            assert(tx_stream.avail_out > 0);
            assert(!(flush == Z_SYNC_FLUSH && tx_stream.avail_out < TRAILER_RESERVED));
            auto r = deflate(&tx_stream, flush);
            // no known cases, when user input data might lead to the error
            assert(r >= 0);
            (void)r;
        } while (tx_stream.avail_out == 0);
    }

    unsigned reserve_for_trailer(string &buff) {
        auto length = buff.capacity();
        buff.reserve(length + TRAILER_RESERVED);
        buff.length(length);
        tx_stream.next_out = reinterpret_cast<Bytef*>(buff.buf() + length);
        tx_stream.avail_out += TRAILER_RESERVED;
        return TRAILER_RESERVED;
    }


    void reset_rx();
    bool uncompress_impl(Frame& frame);
    bool uncompress_check_overflow(Frame& frame, const string& acc);
    void rx_increase_buffer(string& acc);

    DeflateExt(const Config& cfg, Role role);
    Config effective_cfg;
    size_t message_size;
    size_t max_message_size;
    z_stream rx_stream;
    z_stream tx_stream;
    bool reset_after_tx;
    bool reset_after_rx;
};

}}}
