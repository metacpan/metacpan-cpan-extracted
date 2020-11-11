#pragma once
#include "Response.h"
#include <panda/memory.h>
#include <panda/string_map.h>

namespace panda { namespace protocol { namespace http {


struct Request : Message, AllocatedObject<Request> {
    enum class Method {unspecified, OPTIONS, GET, HEAD, POST, PUT, DELETE, TRACE, CONNECT};
    enum class EncType {MULTIPART, URLENCODED, disabled};
    enum class FormStreaming { none, started, file, done };

    static inline string method_str(Request::Method rm) noexcept {
        using Method = Request::Method;
        switch (rm) {
            case Method::unspecified : return "[unspecified]";
            case Method::OPTIONS     : return "OPTIONS";
            case Method::GET         : return "GET";
            case Method::HEAD        : return "HEAD";
            case Method::POST        : return "POST";
            case Method::PUT         : return "PUT";
            case Method::DELETE      : return "DELETE";
            case Method::TRACE       : return "TRACE";
            case Method::CONNECT     : return "CONNECT";
            default: return "[UNKNOWN]";
        }
    }

    struct Builder; template <class, class> struct BuilderImpl;
    using Cookies = Fields<string, true, 3>;

    struct NamedString {
        string value;
        string name;
        string content_type;
    };

    struct Form: string_multimap<string, NamedString> {

        Form(EncType enc_type = EncType::disabled) noexcept :_enc_type(enc_type){}

        void enc_type (const EncType value) noexcept { _enc_type = value; }
        EncType enc_type () const noexcept { return _enc_type; }

        operator bool () const noexcept { return _enc_type != EncType::disabled; }

        void add(const string& key, const string& value, const string& filename = "", const string content_type = "") {
            insert({key, NamedString{value, filename, content_type}});
        }

    private:
        const URI* to_body (Body& body, uri::URI &uri, const URISP original_uri, const string& boundary) const noexcept;
        void to_uri  (URI& uri, const URISP original_uri) const ;
        EncType _enc_type = EncType::MULTIPART;
        friend struct Request;
    };


    URISP   uri;
    Cookies cookies;
    Form    form;

    compression::storage_t compression_prefs = Compression::IDENTITY;

    Request () {}

    Request (Method method, const URISP& uri, Headers&& header = Headers(), Body&& body = Body(), bool chunked = false, int http_version = 0) :
        Message(std::move(header), std::move(body), chunked, http_version), uri(uri), _method(method)
    {
    }

    bool expects_continue () const;

    std::vector<string> to_vector () const;
    string              to_string () const { return Message::to_string(to_vector()); }

    virtual ResponseSP new_response () const { return make_iptr<Response>(); }


    template <typename...PrefN>
    void allow_compression (PrefN... prefn) {
        return _allow_compression(prefn...);
    }

    Method method()     const noexcept;
    Method method_raw() const noexcept { return _method; }

    void   method_raw(Method value) noexcept { _method = value; }

    std::uint8_t allowed_compression (bool inverse = false) const noexcept;

    void form_stream() {
        if (_form_streaming == FormStreaming::none) {
            _form_streaming = FormStreaming::started;
            form._enc_type = EncType::MULTIPART;
            _form_boundary = _generate_boundary();
        }
        else if (_form_streaming != FormStreaming::started) {
            throw "invalid state for form streaming";
        }
    }

    bool form_streaming() noexcept { return  _form_streaming == FormStreaming::started; }

    wrapped_chunk form_finish();
    wrapped_chunk form_field(const string& name, const string& content, const string& filename = "", const string& mime_type = "");
    wrapped_chunk form_file(const string& name, const string filename = "", const string& mime_type = "application/octet-stream");
    wrapped_chunk form_data(const string& data);

protected:
    struct SerializationContext: Message::SerializationContext {
        const URI* uri;
    };

    string form_trailer(const string& boundary) const noexcept {
        auto sz = boundary.size() + 6;
        string r(sz);
        r += "--";
        r += boundary;
        r += "--\r\n";
        return r;
    }

    Method  _method = Method::unspecified;
    FormStreaming _form_streaming = FormStreaming::none;
    string _form_boundary;

    template<typename... PrefN>
    void _allow_compression (Compression::Type p, PrefN... prefn) {
        compression::pack(this->compression_prefs, p);
        return _allow_compression(prefn...);
    }
    void _allow_compression () {}
    void form_file_finalize(string& out) noexcept;

    ~Request () {} // restrict stack allocation

private:
    friend struct RequestParser;

    static Method deduce_method (bool has_form, EncType form_enc, Method _method) noexcept;
    string _http_header (SerializationContext &ctx) const;
    static string _generate_boundary() noexcept;
};
using RequestSP = iptr<Request>;

template <class T, class R>
struct Request::BuilderImpl : Message::Builder<T, R> {
    using Message::Builder<T, R>::Builder;

    T& method (Request::Method method) {
        this->_message->method_raw(method);
        return this->self();
    }

    T& uri (const string& uri) {
        this->_message->uri = new URI(uri);
        return this->self();
    }

    T& uri (const URISP& uri) {
        this->_message->uri = uri;
        return this->self();
    }

    T& cookie (const string& name, const string& value) {
        this->_message->cookies.add(name, value);
        return this->self();
    }

    template<typename... PrefN>
    T& allow_compression(PrefN... prefn) {
        this->_message->allow_compression(prefn...);
        return this->self();
    }

    template<typename Form>
    T& form(Form&& form) {
        this->_message->form = std::forward<Form>(form);
        return this->self();
    }

    T& form_stream() {
        this->_message->form_stream();
        return this->self();
    }
};

struct Request::Builder : Request::BuilderImpl<Builder, RequestSP> {
    Builder () : BuilderImpl(new Request()) {}
};

}}}
