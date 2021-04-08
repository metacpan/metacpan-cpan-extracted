#include "Gzip.h"
#include <iostream>
#include "../error.h"
#include <system_error>

/* we need inflateReset2, which was added in 1.2.3.4, according to
 * https://www.zlib.net/ChangeLog.txt
 */

#if ZLIB_VER_MAJOR != 1
#if ZLIB_VER_MINOR != 2
#if ZLIB_VER_REVISION < 3

#error "minimum zlib version is 1.2.3.4"

#elif ZLIB_VER_REVISION 3

#if ZLIB_VER_SUBREVISION < 4
#error "minimum zlib version is 1.2.3.4"
#endif

#endif
#endif
#endif


namespace panda { namespace protocol { namespace http { namespace compression {


static bool check_zlib(){
    string compiled_verison{ZLIB_VERSION};
    string loaded_version{zlibVersion()};

    if (compiled_verison != loaded_version) {
        std::cerr << "zlib version mismatch, loaded: "  << loaded_version << ", compiled" << compiled_verison << "\n";
        std::abort();
    }
    return true;
}

static bool initialized = check_zlib();

Gzip::~Gzip() {
    int err = Z_OK;
    if (mode == Mode::uncompress) {
        err = inflateEnd(&stream);
    } else if (mode ==Mode::compress) {
        err = deflateEnd(&stream);
    }
    assert(err == Z_OK);
}

void Gzip::prepare_uncompress(size_t& max_body_size_) noexcept {
    assert(mode == Mode::none);
    max_body_size = &max_body_size_;
    stream.total_out = 0;
    stream.total_in = 0;
    stream.avail_in = 0;
    stream.next_in = Z_NULL;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;
    // https://stackoverflow.com/questions/1838699/how-can-i-decompress-a-gzip-stream-with-zlib
    int err = inflateInit2(&stream, 16 + MAX_WBITS);
    assert(err == Z_OK);
    mode = Mode::uncompress;
}

void Gzip::prepare_compress(Compression::Level level) noexcept {
    stream.total_out = 0;
    stream.total_in = 0;
    stream.avail_in = 0;
    stream.next_in = Z_NULL;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;

    int z_level = Z_BEST_SPEED;
    switch (level) {
        case Compression::Level::min:     z_level = Z_BEST_SPEED;          break;
        case Compression::Level::max:     z_level = Z_BEST_COMPRESSION;    break;
        case Compression::Level::optimal: z_level = Z_DEFAULT_COMPRESSION; break;
    }

    int err = deflateInit2(&stream, z_level, Z_DEFLATED, 16 + MAX_WBITS, 9 /* max speed */, Z_DEFAULT_STRATEGY);
    assert(err == Z_OK);
    mode = Mode::compress;
}


std::error_code Gzip::uncompress(const string& piece, Body& body) noexcept {
    using Error = panda::protocol::http::errc;
    assert(mode == Mode::uncompress);
    if (rx_done) { return Error::uncompression_failure; }
    string acc;
    acc.reserve(piece.size() * RX_BUFF_SCALE);

    stream.next_out = reinterpret_cast<Bytef*>(acc.buf());
    stream.avail_out = static_cast<uInt>(acc.capacity());
    stream.avail_in = static_cast<uInt>(piece.size());
    stream.next_in = (Bytef*)(piece.data());

    std::error_code errc;
    auto consume_buff = [&](bool final){
        if (stream.total_out >= *max_body_size) {
            errc = Error::body_too_large;
            return false;
        }

        acc.length(acc.capacity() - stream.avail_out);
        body.parts.emplace_back(std::move(acc));
        if (!final) {
            acc.clear();
            acc.reserve(piece.size() * RX_BUFF_SCALE);
            stream.next_out = reinterpret_cast<Bytef*>(acc.buf());
            stream.avail_out = static_cast<uInt>(acc.capacity());
        }
        return true;
    };

    bool enough = false;
    do {
        int r = ::inflate(&stream, Z_SYNC_FLUSH);
        switch (r) {
        case Z_STREAM_END:
            if (!consume_buff(true))  { break; }
            if (stream.avail_in != 0) { errc = Error::uncompression_failure; }
            else                      { rx_done = true; }
            enough = true;
            break;
        case Z_OK:
            if (!consume_buff(false)) { break; }
            continue;
        case Z_BUF_ERROR:
            if (stream.avail_out != acc.capacity()) {
                if (!consume_buff(false)) { break; }
                continue;
            } else {
                assert(!stream.avail_in);
                enough = true;
                break;
            }
        default:
            errc = Error::uncompression_failure;
            break;
        }
    } while (!errc && !enough);
    return  errc;
}

void Gzip::reset() noexcept {
    if (mode == Mode::uncompress) {
        rx_done = false;
        stream.total_out = 0;
        stream.total_in = 0;
        stream.avail_in = 0;

        int err = inflateReset2(&stream, 16 + MAX_WBITS);
        assert(err == Z_OK);
    }
}

string Gzip::compress(const string& piece) noexcept {
    assert(mode == Mode::compress);
    string acc(TX_CHUNK_SCALE);
    if (piece.size() == 0) { return acc; }

    const auto size_step = std::max(acc.capacity(), piece.size() / TX_CHUNK_SCALE);
    auto acc_size = size_step;
    acc.reserve(size_step);

    stream.avail_in = static_cast<uInt>(piece.size());
    stream.next_in = (Bytef*)(piece.data());
    stream.next_out = reinterpret_cast<Bytef*>(acc.buf());
    stream.avail_out = static_cast<uInt>(size_step);

    do {
        int r = deflate(&stream, Z_NO_FLUSH);
        switch(r) {
        case Z_OK:
            break;
        case Z_BUF_ERROR:
            stream.avail_out = static_cast<uInt>(size_step);
            acc.reserve(acc_size + size_step);
            stream.next_out = reinterpret_cast<Bytef*>(acc.buf() + acc_size);
            acc_size += size_step;
            break;
        default:
            std::abort();
        }
    } while (stream.avail_in > 0);

    auto produced_out = acc_size - stream.avail_out;
    if (produced_out > 0) {
        acc.length(produced_out);
    }
    return acc;
}

string Gzip::flush() noexcept {
    assert(mode == Mode::compress);
    assert(stream.avail_in == 0);

    string acc(TX_CHUNK_SCALE);
    const auto size_step = acc.capacity();
    size_t acc_size = size_step;
    stream.next_out = reinterpret_cast<Bytef*>(acc.buf());
    stream.avail_out = static_cast<uInt>(size_step);

    bool done = false;
    int err;
    do {
        err = deflate(&stream, Z_FINISH);
        switch (err) {
        case Z_STREAM_END:
            done = true;
            break;
        case Z_OK:
            acc.length(acc_size);
            acc.reserve(acc_size * 2);
            stream.avail_out = static_cast<uInt>(acc_size);
            stream.next_out = reinterpret_cast<Bytef*>(acc.buf() + acc_size);
            acc_size *= 2;
            break;
        default:
            std::abort();
        }
    } while (!done);
    auto produced_out = acc_size - stream.avail_out;
    acc.length(produced_out);

    err = deflateReset(&stream);
    assert(err == Z_OK);
    return acc;
}


}}}}
