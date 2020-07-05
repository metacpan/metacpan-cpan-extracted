#pragma once
#include "Body.h"
#include "error.h"
#include "Headers.h"
#include "compression/Compressor.h"
#include <array>
#include <panda/refcnt.h>
#include <panda/uri/URI.h>

namespace panda { namespace protocol { namespace http {

enum class State {headers, body, chunk, chunk_body, chunk_trailer, done, error};

using compression::Compression;
using compression::is_valid_compression;

struct Request;
using panda::uri::URI;
using panda::uri::URISP;

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

    struct SerializationContext {
        int                         http_version;
        const Body*                 body;
        GenericHeaders<2>           handled_headers;
        Compression::Type           compression;
        compression::CompressorPtr  compressor;
        const Request*              request;
        const URI*                  uri;
    };

    compression::CompressorPtr compressor;

    Message () {}

    Message (Headers&& headers, Body&& body, bool chunked = false, int http_version = 0) :
        headers(std::move(headers)), body(std::move(body)), chunked(chunked), http_version(http_version)
    {}

    bool keep_alive () const;
    void keep_alive (bool val) { val ? headers.connection("keep-alive") : headers.connection("close"); }

    void compress (Compression::Type type, Compression::Level level = Compression::Level::min) {
        compression = CompressionParams{type, level};
    }

    wrapped_chunk make_chunk (const string& s) const { return make_chunk(s, compressor); }
    wrapped_chunk final_chunk () const { return final_chunk(compressor); }

protected:
    static string to_string (const std::vector<string>& pieces);

    inline string _content_encoding(const SerializationContext& ctx) const noexcept {
        string out_compression;
        if (!headers.has("Content-Encoding") && ctx.compressor) {
            switch (ctx.compression) {
            case Compression::GZIP:    out_compression = "gzip";    break;
            case Compression::DEFLATE: out_compression = "deflate"; break;
            case Compression::BROTLI:  out_compression = "br";      break;
            case Compression::IDENTITY: break;
            }
        }
        return out_compression;
    }

    inline void _compile_prepare (SerializationContext& ctx) const {
        if (chunked) {
            ctx.http_version = 11;
            // special header, to prevent multiple TEnc headers
            ctx.handled_headers.set("Transfer-Encoding", "chunked");
        } else {
            ctx.http_version = http_version;
        }

        // content-length logic is in request/response because it slightly differs
    }


    template <typename PrepareHeaders, typename CompileHeaders>
    inline std::vector<string> _to_vector (SerializationContext& ctx, PrepareHeaders&& prepare, CompileHeaders&& compile) const {
        _prepare_compressor(ctx, compression.level);

        Body mutable_body;
        if (ctx.compressor && !chunked) {
            compress_body(*ctx.compressor, *ctx.body, mutable_body);
            ctx.body = &mutable_body;
        }

        prepare();
        auto compiled_headers = compile();
        if (!ctx.body->length()) return  {compiled_headers};
        auto sz = ctx.body->parts.size();

        std::vector<string> result;
        if (chunked) {
            result.reserve(1 + sz * 3 + 1);
            result.emplace_back(compiled_headers);
            auto append_piecewise = [&](auto& piece) { result.emplace_back(piece); };
            _serialize_body(ctx, append_piecewise);
        } else {
            result.reserve(1 + sz);
            result.emplace_back(compiled_headers);
            for (auto& part : ctx.body->parts) result.emplace_back(part);
        }

        return result;
    }

private:
    inline wrapped_chunk wrap_into_chunk (const string& s) const {
        if (!s) return {"", "", ""};
        return {string::from_number(s.length(), 16) + "\r\n", s, "\r\n"};
    }

    inline wrapped_chunk make_chunk (const string& s, const compression::CompressorPtr& compr) const {
        if (!s) return {"", "", ""};
        if(compr) {
            return wrap_into_chunk(compr->compress(s));
        } else {
            return wrap_into_chunk(s);
        }
    }

    inline wrapped_chunk final_chunk (const compression::CompressorPtr& compr) const {
        if (compr) {
            auto chunk = wrap_into_chunk(compr->flush());
            chunk[2] += "0\r\n\r\n";
            return chunk;
        } else {
            return {"", "","0\r\n\r\n"};
        }
    }

    void compress_body(compression::Compressor& compressor, const Body& src, Body& dst) const;

    template<typename Fn>
    inline void _append_chunk (wrapped_chunk chunk, Fn&& fn) const {
        for (auto& piece : chunk) if (piece) { fn(piece); }
    }

    template<typename Fn>
    inline void _serialize_body (SerializationContext& ctx, Fn&& fn) const {
        for (auto& part : ctx.body->parts) {
            _append_chunk(make_chunk(part, ctx.compressor), fn);
        }
        _append_chunk(final_chunk(ctx.compressor), fn);
    }

    inline void _prepare_compressor (SerializationContext& ctx, Compression::Level level) const {
        if (ctx.compression != Compression::IDENTITY) {
            auto compressor = compression::instantiate(ctx.compression);
            if (compressor) {
                compressor->prepare_compress(level);
                ctx.compressor = std::move(compressor);
                return;
            }
            // reset to identity
            ctx.compression = Compression::IDENTITY;
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
