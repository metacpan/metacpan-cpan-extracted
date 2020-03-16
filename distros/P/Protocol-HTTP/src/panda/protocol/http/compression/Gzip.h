#pragma once
#include "Compressor.h"
#include <zlib.h>

namespace panda { namespace protocol { namespace http { namespace compression {

struct Gzip: Compressor {
    Gzip() {}
    ~Gzip() override;

    void prepare_uncompress(size_t& max_body_size) noexcept override;
    void prepare_compress(Compression::Level level) noexcept override;

    std::error_code uncompress(const string& piece, Body& body) noexcept override;
    string compress(const string& piece) noexcept override;
    string flush() noexcept override;

    virtual void reset() noexcept override;
private:
    z_stream stream;
};

}}}}
