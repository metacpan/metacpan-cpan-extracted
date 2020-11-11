#pragma once
#include <system_error>
#include <functional>
#include "Compression.h"
#include "panda/string.h"
#include "../Body.h"
#include <panda/refcnt.h>

namespace panda { namespace protocol { namespace http { namespace compression {

enum class Mode { none = 0, compress, uncompress };

struct Compressor: Refcnt {
    static const constexpr std::size_t RX_BUFF_SCALE = 10;
    static const constexpr std::size_t TX_CHUNK_SCALE = 5;

    Compressor(){}
    Compressor(const Compressor& ) = delete;
    Compressor(Compressor&& ) = delete;

    virtual void prepare_uncompress(size_t& max_body_size) noexcept = 0;
    virtual void prepare_compress(Compression::Level level) noexcept = 0;
    virtual void reset() noexcept = 0;

    virtual std::error_code uncompress(const string& piece, Body& body) noexcept = 0;
    virtual string compress(const string& piece) noexcept = 0;

    bool eof() noexcept  { return rx_done ;}
    virtual string flush() noexcept = 0;

    virtual ~Compressor() {}

protected:
    size_t* max_body_size = nullptr;
    Mode mode = Mode::none;
    bool rx_done = false;
};

using CompressorFactory = Compressor*(*)();
using CompressorPtr = iptr<Compressor>;

bool register_factory(Compression::Type compression, const CompressorFactory& factory);
CompressorPtr instantiate(Compression::Type compression) noexcept;


}}}};
