#pragma once
#include "Body.h"
#include "error.h"
#include "Headers.h"
#include "BodyGuard.h"
#include "compression/Compressor.h"
#include <array>
#include <panda/refcnt.h>

namespace panda { namespace protocol { namespace http {

enum class State {headers, body, chunk, chunk_body, chunk_trailer, done, error};

using compression::Compression;
using compression::is_valid_compression;

struct Message : virtual Refcnt {
    template <class, class> struct Builder;
    using wrapped_chunk = std::array<string, 3>;

    Headers headers;
    Body    body;
    bool    chunked      = false;
    int     http_version = 0;

    struct CompressionParams {
        Compression::Type  type  = Compression::IDENTITY;
        Compression::Level level = Compression::Level::min;
    } compression;

    compression::CompressorPtr compressor;

    Message () {}

    Message (Headers&& headers, Body&& body, bool chunked = false, int http_version = 0) :
        headers(std::move(headers)), body(std::move(body)), chunked(chunked), http_version(http_version)
    {}

    bool keep_alive () const;
    void keep_alive (bool val) { val ? headers.connection("keep-alive") : headers.connection("close"); }


    wrapped_chunk wrap_into_chunk (const string& s) {
        if (!s) return {"", "", ""};
        return {string::from_number(s.length(), 16) + "\r\n", s, "\r\n"};
    }

    wrapped_chunk make_chunk (const string& s) {
        if (!s) return {"", "", ""};
        if(compressor) {
            return wrap_into_chunk(compressor->compress(s));
        } else {
            return wrap_into_chunk(s);
        }
    }

    wrapped_chunk final_chunk () {
        if (compressor) {
            auto chunk = wrap_into_chunk(compressor->flush());
            chunk[2] += "0\r\n\r\n";
            return chunk;
        } else {
            return {"", "","0\r\n\r\n"};
        }
    }

    void compress (Compression::Type type, Compression::Level level = Compression::Level::min) {
        compression = CompressionParams{type, level};
    }

protected:
    static string to_string (const std::vector<string>& pieces);

    inline string _content_encoding(Compression::Type applied_compression) const noexcept {
        string out_compression;
        if (!headers.has("Content-Encoding") && compressor) {
            switch (applied_compression) {
            case Compression::GZIP:    out_compression = "gzip";    break;
            case Compression::DEFLATE: out_compression = "deflate"; break;
            case Compression::BROTLI:  out_compression = "br";      break;
            case Compression::IDENTITY: break;
            }
        }
        return out_compression;
    }

    inline void _compile_prepare () {
        if (chunked) {
            http_version = 11;
            // need set(), not add(), otherwise multiple to_string/to_vector calls would result in multiple TEnc headers
            headers.set("Transfer-Encoding", "chunked");
        }
        // content-length logic is in request/response because it slightly differs
    }


    template <class T>
    inline std::vector<string> _to_vector (Compression::Type applied_compression, const T& f) {
        _prepare_compressor(applied_compression, compression.level);
        auto body_holder = maybe_compress();
        _compile_prepare();
        auto hdr = f();
        if (!body.length()) return {hdr};
        auto sz = body.parts.size();

        std::vector<string> result;
        if (chunked) {
            result.reserve(1 + sz * 3 + 1);
            result.emplace_back(hdr);
            auto append_piecewise = [&](auto& piece) { result.emplace_back(piece); };
            _serialize_body(append_piecewise);
        } else {
            result.reserve(1 + sz);
            result.emplace_back(hdr);
            for (auto& part : body.parts) result.emplace_back(part);
        }

        return result;
    }

private:
    BodyGuard maybe_compress();

    template<typename Fn>
    inline void _append_chunk (wrapped_chunk chunk, Fn&& fn) {
        for (auto& piece : chunk) if (piece) { fn(piece); }
    }

    template<typename Fn>
    inline void _serialize_body (Fn&& fn) {
        for (auto& part : body.parts) {
            _append_chunk(make_chunk(part), fn);
        }
        _append_chunk(final_chunk(), fn);
    }

    inline void _prepare_compressor (Compression::Type applied_compression, Compression::Level level) {
        if (applied_compression == Compression::IDENTITY) return;
        auto it(compression::instantiate(applied_compression));
        if (it) {
            it->prepare_compress(level);
            compressor = std::move(it);
        }
    }

    //friend struct Parser; friend struct RequestParser; friend struct ResponseParser;
};
using MessageSP = iptr<Message>;

template <class T, class MP>
struct Message::Builder {
    T& headers (Headers&& headers) {
        _message->headers = std::move(headers);
        return self();
    }

    T& header (const string& k, const string& v) {
        _message->headers.add(k, v);
        return self();
    }

    T& body (Body&& val, const string& content_type = "") {
        _message->body = std::move(val);
        if (content_type) _message->headers.add("Content-Type", content_type);
        return self();
    }

    T& body (const string& body, const string& content_type = "") {
        _message->body = body;
        if (content_type) _message->headers.add("Content-Type", content_type);
        return self();
    }

    T& http_version (int http_version) {
        _message->http_version = http_version;
        return self();
    }

    T& chunked (const string& content_type = "") {
        _message->chunked = true;
        if (content_type) _message->headers.add("Content-Type", content_type);
        return self();
    }

    T& compress (Compression::Type method, Compression::Level level = Compression::Level::min) {
        _message->compress(method, level);
        return self();
    }

    MP build () { return _message; }

protected:
    MP _message;

    Builder (const MP& msg) : _message(msg) {}

    T& self () { return static_cast<T&>(*this); }
};


}}}
