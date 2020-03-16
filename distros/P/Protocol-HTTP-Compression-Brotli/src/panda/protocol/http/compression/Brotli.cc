#include "Brotli.h"
#include "panda/protocol/http/error.h"

namespace panda { namespace protocol { namespace http { namespace compression {

Brotli::~Brotli() {
    if (mode == Mode::uncompress) {
        ::BrotliDecoderDestroyInstance(decoder);
    }
    else if (mode == Mode::compress) {
        ::BrotliEncoderDestroyInstance(encoder);
    }
}

void Brotli::prepare_uncompress(size_t& max_body_size_) noexcept {
    assert(mode == Mode::none);
    max_body_size = &max_body_size_;

    decoder = ::BrotliDecoderCreateInstance(nullptr, nullptr, nullptr);
    assert(decoder);
    mode = Mode::uncompress;
}

void Brotli::prepare_compress(Compression::Level level) noexcept {
    assert(mode == Mode::none);

    encoder = ::BrotliEncoderCreateInstance(nullptr, nullptr, nullptr);
    assert(encoder);

    uint32_t b_level = 2;
    switch (level) {
        case Compression::Level::min:     b_level = 2; break;
        case Compression::Level::max:     b_level = 9; break;
        case Compression::Level::optimal: b_level = 5; break;
    }
    auto r = ::BrotliEncoderSetParameter(encoder, BROTLI_PARAM_QUALITY, b_level);
    assert(r == BROTLI_TRUE);

    mode = Mode::compress;
}

void Brotli::reset() noexcept {
    if (mode == Mode::uncompress) {
        rx_done = false;
        total_out = 0;
        ::BrotliDecoderDestroyInstance(decoder);
        decoder = ::BrotliDecoderCreateInstance(nullptr, nullptr, nullptr);
        assert(decoder);
    }
}

std::error_code Brotli::uncompress(const string& piece, Body& body) noexcept  {
    assert(mode == Mode::uncompress);
    if (rx_done) { return errc::uncompression_failure; }

    size_t avail_out = piece.size() * RX_BUFF_SCALE;

    string acc;
    acc.reserve(avail_out);

    size_t avail_in = piece.size();
    const uint8_t* next_in = (const uint8_t*)piece.data();
    uint8_t* next_out = (uint8_t*)acc.data();

    std::error_code errc;
    size_t consumed_bytes = 0;
    auto consume_buff = [&](bool final){
        if (total_out >= *max_body_size) {
            errc = errc::body_too_large;
            return false;
        }

        acc.length(acc.capacity() - avail_out);
        body.parts.emplace_back(std::move(acc));
        consumed_bytes += (piece.size() - avail_in);
        if (!final) {
            acc.clear();
            acc.reserve(piece.size() * RX_BUFF_SCALE);
            next_out = (uint8_t*)acc.data();
            avail_out = acc.capacity();
        }
        return true;
    };

    bool enough = false;
    do {
        auto r = ::BrotliDecoderDecompressStream(decoder, &avail_in, &next_in, &avail_out, &next_out, &total_out);
        switch (r) {
        case ::BROTLI_DECODER_RESULT_SUCCESS:
            if (!consume_buff(true)) { break; }
            if (consumed_bytes != piece.size()) { errc = errc::uncompression_failure; }
            else                                { rx_done = true; }
            enough = true;
            break;
        case ::BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT:
            if (!consume_buff(false)) { break; }
            continue;
        case ::BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT:
            if (!consume_buff(false)) { break; }
            enough = true;
            break;
        default:
            /*
            auto code = BrotliDecoderGetErrorCode(decoder);
            auto err = BrotliDecoderErrorString(code);
            assert(err);
            */
            errc = errc::uncompression_failure;
            break;
        }
    } while (!errc && !enough);
    return  errc;
}

string Brotli::compress(const string& piece) noexcept {
    assert(mode == Mode::compress);
    string acc(TX_CHUNK_SCALE);
    if (piece.size() == 0) { return acc; }

    const auto size_step = std::max(acc.capacity(), piece.size() / TX_CHUNK_SCALE);
    auto acc_size = size_step;
    acc.reserve(size_step);

    size_t avail_in = piece.size();
    const uint8_t* next_in = (const uint8_t*)piece.data();
    size_t avail_out = size_step;
    uint8_t* next_out = (uint8_t*)acc.data();

    do {
        auto r = ::BrotliEncoderCompressStream(encoder, ::BROTLI_OPERATION_PROCESS, &avail_in, &next_in, &avail_out, &next_out, nullptr);
        switch(r) {
        case BROTLI_TRUE:
            assert(avail_in == 0);
            break;
        case BROTLI_FALSE:
            avail_out = size_step;
            acc.reserve(acc_size + size_step);
            next_out = (uint8_t*)(acc.buf() + acc_size);
            acc_size += size_step;
            break;
        }
    } while (avail_in > 0);

    auto produced_out = acc_size - avail_out;
    if (produced_out > 0) {
        acc.length(produced_out);
    }
    return acc;
}

string Brotli::flush() noexcept {
    assert(mode == Mode::compress);

    string acc(TX_CHUNK_SCALE);
    const auto size_step = acc.capacity();
    size_t acc_size = size_step;
    size_t avail_out = size_step;
    uint8_t* next_out = (uint8_t*)acc.buf();
    size_t avail_in = 0;
    const uint8_t* next_in = nullptr;

    auto r = ::BrotliEncoderCompressStream(encoder, ::BROTLI_OPERATION_FINISH, &avail_in, &next_in, &avail_out, &next_out, nullptr);
    if (r == BROTLI_FALSE) { std::abort(); }
    acc.length(acc_size - avail_out);
    avail_out = 0; /* consume all the rest */
    auto tail = ::BrotliEncoderTakeOutput(encoder, &avail_out);

    acc += string((const char*)tail, avail_out);

    ::BrotliEncoderDestroyInstance(encoder);
    mode = Mode::none;
    return acc;
}


static Compressor* create_brotli_compressor() noexcept { return new Brotli(); }

static const CompressorFactory brotli_factory = create_brotli_compressor;

bool Brotli::register_factory() {
    return panda::protocol::http::compression::register_factory(Compression::BROTLI, brotli_factory);
}


}}}}
