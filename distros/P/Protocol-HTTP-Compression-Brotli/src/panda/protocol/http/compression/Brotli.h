#pragma once

#include <panda/protocol/http/compression/Compressor.h>
#include "brotli/decode.h"
#include "brotli/encode.h"

namespace panda { namespace protocol { namespace http { namespace compression {

struct Brotli: Compressor {
    Brotli():decoder{nullptr}, encoder{nullptr}{}
    ~Brotli() override;

    void prepare_uncompress(size_t& max_body_size) noexcept override;
    void prepare_compress(Compression::Level level) noexcept override;

    std::error_code uncompress(const string& piece, Body& body) noexcept override;
    string compress(const string& piece) noexcept override;
    string flush() noexcept override;

    virtual void reset() noexcept override;

    static bool register_factory();
private:
    ::BrotliDecoderState* decoder;
    ::BrotliEncoderState* encoder;
    size_t total_out;
};

}}}}
