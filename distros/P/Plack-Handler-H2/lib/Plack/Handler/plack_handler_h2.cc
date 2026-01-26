#include <string>
#include <map>
#include <optional>
#include <openssl/ssl.h>
#include <thread.h>
#include <event.h>
#include <event2/event.h>
#include <event2/thread.h>
#include <event2/listener.h>
#include <event2/util.h>
#include <event2/bufferevent_ssl.h>
#include <nghttp2/nghttp2.h>
#include <netinet/tcp.h>

#include "plack_handler_h2.h"
#include <iostream>
#include <algorithm>
#include <vector>
#include <unistd.h>
#include <fcntl.h>
#include <cstring>

#define DEFAULT_MAX_REQUEST_BODY_SIZE (10 * 1024 * 1024) // 10 MB

#define MAKE_NV(NAME, VALUE)                                                   \
  {                                                                            \
    (uint8_t *)NAME,   (uint8_t *)VALUE,     sizeof(NAME) - 1,                 \
    sizeof(VALUE) - 1, NGHTTP2_NV_FLAG_NONE,                                   \
  }

// Threshold for switching from memory to file storage (1 MB)
constexpr size_t BODY_SIZE_THRESHOLD = 1024 * 1024;

// The following static functions are from the nghttp2 example server
static inline uint8_t hex_to_uint(uint8_t c) {
  if ('0' <= c && c <= '9')
  {
    return (uint8_t)(c - '0');
  }
  if ('A' <= c && c <= 'F')
  {
    return (uint8_t)(c - 'A' + 10);
  }
  if ('a' <= c && c <= 'f')
  {
    return (uint8_t)(c - 'a' + 10);
  }
  return 0;
}

static inline char* percent_decode(const uint8_t *value, size_t valuelen) {
  char *res;

  res = static_cast<char*>(std::malloc(valuelen + 1));
  if (valuelen > 3)
  {
    size_t i, j;
    for (i = 0, j = 0; i < valuelen - 2;)
    {
      if (value[i] != '%' || !isxdigit(value[i + 1]) ||
          !isxdigit(value[i + 2])) {
        res[j++] = (char)value[i++];
        continue;
      }
      res[j++] =
        (char)((hex_to_uint(value[i + 1]) << 4) + hex_to_uint(value[i + 2]));
      i += 3;
    }
    memcpy(&res[j], &value[i], 2);
    res[j + 2] = '\0';
  } else {
    memcpy(res, value, valuelen);
    res[valuelen] = '\0';
  }
  return res;
}

static inline int alpn_select_proto_cb(SSL *ssl, const unsigned char **out,
                                unsigned char *outlen, const unsigned char *in,
                                unsigned int inlen, void *arg) {
  (void)ssl;
  (void)arg;
  
#ifdef NGHTTP2_ALPN_H
  int rv = nghttp2_select_alpn(out, outlen, in, inlen);
  if (rv != 1) {
    return SSL_TLSEXT_ERR_NOACK;
  }
  return SSL_TLSEXT_ERR_OK;
#else
  const unsigned char *p = in;
  const unsigned char *end = in + inlen;
  
  while (p < end) {
    unsigned char proto_len = *p++;
    if (p + proto_len > end) {
      break;
    }
    
    // Check if this is "h2"
    if (proto_len == 2 && p[0] == 'h' && p[1] == '2') {
      *out = p;
      *outlen = proto_len;
      return SSL_TLSEXT_ERR_OK;
    }
    
    p += proto_len;
  }
  
  return SSL_TLSEXT_ERR_NOACK;
#endif
}

static SSL_CTX* create_ssl_ctx(const std::string& cert_file, const std::string& key_file) {
  SSL_CTX *ssl_ctx;

  ssl_ctx = SSL_CTX_new(TLS_server_method());
  if (!ssl_ctx)
  {
    croak("Could not create SSL_CTX");
  }
  SSL_CTX_set_options(ssl_ctx, SSL_OP_ALL | SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3 |
                                 SSL_OP_NO_COMPRESSION |
                                 SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION);
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
  if (SSL_CTX_set1_groups_list(ssl_ctx, "P-256") != 1) {
    croak("Could not set ECDH curve");
  }
#else  /* OPENSSL_VERSION_NUMBER < 0x30000000L */
  {
    EC_KEY *ecdh;
    ecdh = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
    if (!ecdh)
    {
      errx(1, "EC_KEY_new_by_curv_name failed: %s",
           ERR_error_string(ERR_get_error(), NULL));
    }
    SSL_CTX_set_tmp_ecdh(ssl_ctx, ecdh);
    EC_KEY_free(ecdh);
  }
#endif /* OPENSSL_VERSION_NUMBER < 0x30000000L */

  if (SSL_CTX_use_PrivateKey_file(ssl_ctx, key_file.c_str(), SSL_FILETYPE_PEM) != 1) {
    croak("Could not read private key file");
  }
  if (SSL_CTX_use_certificate_chain_file(ssl_ctx, cert_file.c_str()) != 1) {
    croak("Could not read certificate file");
  }

  SSL_CTX_set_alpn_select_cb(ssl_ctx, alpn_select_proto_cb, NULL);

  return ssl_ctx;
}

static inline bool ends_with(const std::string& str, const std::string& suffix) {
  if (str.length() < suffix.length()) {
    return false;
  }
  return str.compare(str.length() - suffix.length(), suffix.length(), suffix) == 0;
}

static inline std::string double_dot = "/..";
static inline std::string single_dot = "/.";
static inline int check_path(std::string& path) {
  /* We don't like '\' in url. */
  return path[0] && path[0] == '/' && strchr(path.c_str(), '\\') == NULL &&
         strstr(path.c_str(), double_dot.c_str()) == NULL && strstr(path.c_str(), single_dot.c_str()) == NULL &&
         !ends_with(path, double_dot) && !ends_with(path, single_dot);
}

static inline H2Session* get_session_from_sv_uv(SV* session_sv) {
  if (!SvOK(session_sv) || !SvIOK(session_sv)) {
    warn("Session SV is not OK (undefined or invalid)");
    return nullptr;
  }

  uintptr_t session_ptr = SvUV(session_sv);

  if (session_ptr == 0) {
    warn("Session pointer is null");
    return nullptr;
  }
  
  return reinterpret_cast<H2Session*>(session_ptr);
}

static inline int32_t send_headers_from_av(
    H2Session* session,
    int32_t stream_id,
    SV* status_sv,
    SV* headers_sv,
    bool streaming = false) {
  int status = SvIV(status_sv);
  AV* headers_av = (headers_sv && SvROK(headers_sv)) ? (AV*)SvRV(headers_sv) : nullptr;
  
  auto data_it = std::find_if(session->data.begin(), session->data.end(),
                         [stream_id](H2Data* d) { return d->stream_id == stream_id; });
  if (data_it == session->data.end()) {
    croak("Stream data not found for stream_id %d", stream_id);
  }
  
  H2Data* data = *data_it;
  auto& header_storage = *data->response_headers;
  
  header_storage.clear();
  
  std::vector<nghttp2_nv> nva;

  header_storage.push_back(":status");
  header_storage.push_back(std::to_string(status));

  nghttp2_nv status_header = {
    (uint8_t*)header_storage[header_storage.size()-2].c_str(),
    (uint8_t*)header_storage[header_storage.size()-1].c_str(),
    7,
    header_storage[header_storage.size()-1].length(),
    NGHTTP2_NV_FLAG_NONE
  };
  nva.push_back(status_header);
  
  // Add other headers
  if (headers_av)
  {
    int header_count = av_len(headers_av) + 1;
    for (int i = 0; i < header_count; i += 2)
    {
      SV** name_sv = av_fetch(headers_av, i, 0);
      SV** value_sv = av_fetch(headers_av, i + 1, 0);
      
      if (name_sv && value_sv)
      {
        size_t name_len, value_len;
        const char* name = SvPV(*name_sv, name_len);
        const char* value = SvPV(*value_sv, value_len);
        
        std::string lowercase_name(name, name_len);
        std::transform(lowercase_name.begin(), lowercase_name.end(),
                       lowercase_name.begin(), ::tolower);

        // Skip content-length for streaming responses (when with_end_stream is false)
        // HTTP/2 doesn't need content-length for streaming
        if (streaming && lowercase_name == "content-length")
        {
          continue;
        }

        header_storage.push_back(lowercase_name);
        header_storage.push_back(std::string(value, value_len));

        nghttp2_nv header = {
          (uint8_t*)header_storage[header_storage.size()-2].c_str(),
          (uint8_t*)header_storage[header_storage.size()-1].c_str(),
          lowercase_name.length(),
          value_len,
          NGHTTP2_NV_FLAG_NONE
        };
        nva.push_back(header);
      }
    }
  }

  nghttp2_submit_headers(
    session->session.get(),
    NGHTTP2_FLAG_END_HEADERS,
    stream_id,
    NULL,
    nva.data(),
    nva.size(),
    NULL
  );

  return session->send();
}

static const char RESPONSE_500[] = "<html><head><title>500</title></head><body><h1>500 Internal Server Error</h1></body></html>";
static inline int32_t error_reply(H2Session* session,
                          H2Data* data) {
    int pipefd[2];
    int rv = pipe(pipefd);
    nghttp2_nv hdrs[] = {MAKE_NV(":status", "404")};
    if (rv != 0)
    {
      warn("pipe() failed, errno=%d", errno);
      rv = nghttp2_submit_rst_stream(
          session->session.get(), NGHTTP2_FLAG_NONE, data->stream_id,
          NGHTTP2_INTERNAL_ERROR);
      if (rv != 0)
      {
        warn("nghttp2_submit_rst_stream() failed, rv=%d", rv);
        return -1;
      }
      return NGHTTP2_ERR_CALLBACK_FAILURE;
    }

    ssize_t writelen = write(pipefd[1], RESPONSE_500, sizeof(RESPONSE_500) - 1);
    close(pipefd[1]);

    if (writelen != sizeof(RESPONSE_500) - 1) {
      close(pipefd[0]);
      warn("write() failed, errno=%d", errno);
      return -1;
    }

    data->fd = pipefd[0];

    rv = nghttp2_submit_headers(
        session->session.get(), 0, data->stream_id,
        NULL, hdrs, sizeof(hdrs) / sizeof(hdrs[0]), NULL);
    
    if (rv != 0)
    {
      warn("nghttp2_submit_headers() failed: %s", nghttp2_strerror(rv));
      close(data->fd);
      return -1;
    }

    // Create the data provider
    nghttp2_data_provider data_prd;
    data_prd.source.fd = data->fd;

    rv = nghttp2_submit_data(
        session->session.get(), NGHTTP2_FLAG_END_STREAM, data->stream_id,
        &data_prd
    );

    if (rv != 0)
    {
      warn("nghttp2_submit_data() failed: %s", nghttp2_strerror(rv));
      close(data->fd);
      return -1;
    }

    return 0;
  }

static inline int32_t handle_av_response(
  nghttp2_session* ng_session,
  H2Session* session,
  H2Data* data,
  SV* response) {
  (void)ng_session;

  if (!SvROK(response) || SvTYPE(SvRV(response)) != SVt_PVAV)
  {
    warn("PSGI application did not return an array reference");
    return error_reply(session, data);
  }

  AV* response_av = (AV*)SvRV(response);
  if (av_len(response_av) < 2)
  {
    warn("PSGI response array too short");
    return error_reply(session, data);
  }
  
  SV** status_sv = av_fetch(response_av, 0, 0);
  SV** headers_sv = av_fetch(response_av, 1, 0);
  SV** body_sv = av_fetch(response_av, 2, 0);
  
  if (!status_sv || !headers_sv)
  {
    warn("Invalid response format");
    return error_reply(session, data);
  }
  
  int rv = send_headers_from_av(session, data->stream_id, *status_sv, *headers_sv);
  if (rv != 0)
  {
    warn("Failed to send headers: %s", nghttp2_strerror(rv));
    return error_reply(session, data);
  }
  
  int pipefd[2];
  if (pipe(pipefd) != 0)
  {
    warn("pipe() failed, errno=%d", errno);
    return error_reply(session, data);
  }
  
  if (body_sv && SvROK(*body_sv) && SvTYPE(SvRV(*body_sv)) == SVt_PVAV) {
    AV* body_av = (AV*)SvRV(*body_sv);
    int body_parts = av_len(body_av) + 1;
    for (int i = 0; i < body_parts; i++)
    {
      SV** part_sv = av_fetch(body_av, i, 0);
      if (part_sv)
      {
        STRLEN len;
        const char* str = SvPV(*part_sv, len);
        write(pipefd[1], str, len);
      }
    }
  }
  close(pipefd[1]);
  
  data->fd = pipefd[0];
  
  nghttp2_data_provider data_prd;
  data_prd.source.fd = data->fd;
  data_prd.read_callback = [](nghttp2_session* session,
                              int32_t stream_id,
                              uint8_t* buf,
                              size_t length,
                              uint32_t* data_flags,
                              nghttp2_data_source* source,
                              void* user_data) -> ssize_t
  {
    (void)session;
    (void)stream_id;
    (void)user_data;
    
    int fd = source->fd;
    ssize_t r;
    while ((r = read(fd, buf, length)) == -1 && errno == EINTR);
    if (r == -1) return NGHTTP2_ERR_TEMPORAL_CALLBACK_FAILURE;
    if (r == 0)  *data_flags |= NGHTTP2_DATA_FLAG_EOF;
    return static_cast<ssize_t>(r);
  };
  
  rv = nghttp2_submit_data(
    session->session.get(),
    NGHTTP2_FLAG_END_STREAM,
    data->stream_id,
    &data_prd
  );
  
  if (rv != 0)
  {
    warn("nghttp2_submit_data() failed: %s", nghttp2_strerror(rv));
    close(data->fd);
    return -1;
  }

  session->send();

  return 0;
}

static inline int32_t handle_cv_response(
  nghttp2_session* ng_session,
  SV* env,
  H2Session* session,
  H2Data* data,
  SV* response_sv
) {
  (void)ng_session;
  (void)data;

  int32_t count;

  CV* response_cv = (CV*)SvRV(response_sv);

  if (!response_cv || SvTYPE(response_cv) != SVt_PVCV)
  {
    warn("PSGI application did not return a code reference");
    return error_reply(session, data);
  }

  CV* responder_cv = get_cv("Plack::Handler::H2::_responder", 0);
  SV* responder_cv_sv = (SV*)responder_cv;

  if (!responder_cv || SvTYPE(responder_cv) != SVt_PVCV)
  {
    warn("Could not find Plack::Handler::H2::_responder");
    return error_reply(session, data);
  }

  dSP;
  ENTER;
  SAVETMPS;
  
  SV* session_sv = newSVuv(reinterpret_cast<uintptr_t>(session));
  PUSHMARK(SP);
  XPUSHs(env);
  XPUSHs(session_sv);
  PUTBACK;

  count = call_sv(responder_cv_sv, G_SCALAR);
  
  SPAGAIN;
  if (count != 1)
  {
    warn("Responder did not return a value");
    FREETMPS;
    LEAVE;
    return error_reply(session, data);
  }

  SV* responder_result_cv = POPs;

  PUSHMARK(SP);
  XPUSHs(responder_result_cv);
  PUTBACK;

  call_sv(response_sv, G_SCALAR);

  FREETMPS;
  LEAVE;

  return 0;
}

static inline int32_t on_request(nghttp2_session* ng_session,
                       H2Session* session,
                       H2Data* data) {
  if (!data->path)
  {
    if (error_reply(session, data) != 0)
    {
      return NGHTTP2_ERR_CALLBACK_FAILURE;
    }
    return 0;
  }
  if (!check_path(*data->path))
  {
    if (error_reply(session, data) != 0)
    {
      return NGHTTP2_ERR_CALLBACK_FAILURE;
    }
    return 0;
  }

  dSP;
  
  HV* env = newHV();
  hv_stores(env, "REQUEST_URI", newSVpv(data->uri->c_str(), data->uri->length())); // Not percent decoded
  hv_stores(env, "REQUEST_METHOD", newSVpv(data->method->c_str(), data->method->length()));
  hv_stores(env, "PATH_INFO", newSVpv(data->path->c_str(), data->path->length())); // Percent decoded
  hv_stores(env, "SERVER_PROTOCOL", newSVpvs("HTTP/2"));
  
  std::string server_name = "localhost";
  if (data->authority)
  {
    std::string authority = *data->authority;
    size_t colon_pos = authority.find(':');
    if (colon_pos != std::string::npos)
    {
      server_name = authority.substr(0, colon_pos);
    }
    else
    {
      server_name = authority;
    }
  }
  hv_stores(env, "SERVER_NAME", newSVpv(server_name.c_str(), server_name.length()));
  hv_stores(env, "SCRIPT_NAME", newSVpvs(""));
  hv_stores(env, "SERVER_PORT", newSViv(session->server->get_server_port()));
  hv_stores(env, "REMOTE_ADDR", newSVpv(session->client_address.c_str(), session->client_address.length()));
  hv_stores(env, "QUERY_STRING", newSVpv(
    data->query ? data->query->c_str() : "",
    data->query ? data->query->length() : 0
  ));
  hv_stores(env, "HTTPS", newSVpvs("on"));

  const auto& headers = *data->headers;
  std::string header_prefix = "HTTP_";
  for (const auto& [key, value] : headers)
  {
    std::string header_name = "";
    for (char c : key)
    {
      if (c == '-')
      {
        header_name += '_';
      }
      else
      {
        header_name += std::toupper(c);
      }
    }

    // Plack's convention is to store CONTENT_LENGTH and CONTENT_TYPE without the HTTP_ prefix
    if (header_name != "CONTENT_LENGTH" && header_name != "CONTENT_TYPE")
    {
      header_name = header_prefix + header_name;
    }

    SV* header_value = newSVpv(value.c_str(), value.length());
    hv_store(env, header_name.c_str(), header_name.length(), header_value, 0);
  }

  // Append HTTP/2 pseudo-headers
  {
    SV* header_value;
    std::string h2_header_name = "HTTP_2_";
    std::string authority = data->authority ? *data->authority : "";
    header_value = newSVpv(authority.c_str(), authority.length());
    hv_store(env, (h2_header_name + "AUTHORITY").c_str(),
             (h2_header_name + "AUTHORITY").length(),
             header_value, 0);
    std::string scheme = data->scheme ? *data->scheme : "https";
    header_value = newSVpv(scheme.c_str(), scheme.length());
    hv_store(env, (h2_header_name + "SCHEME").c_str(),
             (h2_header_name + "SCHEME").length(),
             header_value, 0);
    std::string path = data->path ? *data->path : "/";
    header_value = newSVpv(path.c_str(), path.length());
    hv_store(env, (h2_header_name + "PATH").c_str(),
             (h2_header_name + "PATH").length(),
             header_value, 0);
    std::string method = data->method ? *data->method : "GET";
    header_value = newSVpv(method.c_str(), method.length());
    hv_store(env, (h2_header_name + "METHOD").c_str(),
             (h2_header_name + "METHOD").length(),
             header_value, 0);
  }

  AV* version = newAV();
  av_store(version, 0, newSViv(1));
  av_store(version, 1, newSViv(1));
  hv_stores(env, "psgi.version", newRV_noinc((SV*)version));
  hv_stores(env, "psgi.url_scheme", newSVpvs("https"));
  hv_stores(env, "psgi.errors", newRV_inc((SV*)PL_stderrgv));
  hv_stores(env, "psgi.multithread", &PL_sv_no);
  hv_stores(env, "psgi.multiprocess", &PL_sv_yes);
  hv_stores(env, "psgi.run_once", &PL_sv_no);
  hv_stores(env, "psgi.streaming", &PL_sv_yes);
  hv_stores(env, "psgi.nonblocking", &PL_sv_no);
  hv_stores(env, "psgix.h2.stream_id", newSViv(data->stream_id));

  SV* input_sv = nullptr;
  if (data->body_fd != -1)
  {
    lseek(data->body_fd, 0, SEEK_SET);  // Rewind to start
    PerlIO* pio = PerlIO_fdopen(data->body_fd, "r");
    if(pio)
    {
      GV* gv = newGVgen("Plack::Handler::H2");
      IO* io = GvIOn(gv);
      IoIFP(io) = pio;
      IoOFP(io) = pio;
      IoTYPE(io) = IoTYPE_RDONLY;
      input_sv = newRV_noinc((SV*)gv);
      data->body_fd = -1;
    }
    else
    {
      warn("Failed to create PerlIO from fd: %s", strerror(errno));
      input_sv = newSVpvs("");
    }
  }
  else if (data->body_buffer && !data->body_buffer->empty())
  {
    int pipefd[2];
    if (pipe(pipefd) == 0)
    {
      ssize_t written = write(pipefd[1], data->body_buffer->c_str(), data->body_buffer->size());
      close(pipefd[1]);
      if (written == (ssize_t)data->body_buffer->size()) {
        PerlIO* pio = PerlIO_fdopen(pipefd[0], "r");
        if (pio)
        {
          GV* gv = newGVgen("Plack::Handler::H2");
          IO* io = GvIOn(gv);
          IoIFP(io) = pio;
          IoOFP(io) = pio;
          IoTYPE(io) = IoTYPE_RDONLY;
          input_sv = newRV_noinc((SV*)gv);
        }
        else
        {
          close(pipefd[0]);
          input_sv = newSVpvs("");
        }
      }
      else
      {
        close(pipefd[0]);
        input_sv = newSVpvs("");
      }
    }
    else
    {
      input_sv = newSVpvs("");
    }
  }
  else
  {
    int pipefd[2];
    if (pipe(pipefd) == 0) {
      close(pipefd[1]);
      PerlIO* pio = PerlIO_fdopen(pipefd[0], "r");
      if (pio)
      {
        GV* gv = newGVgen("Plack::Handler::H2");
        IO* io = GvIOn(gv);
        IoIFP(io) = pio;
        IoOFP(io) = pio;
        IoTYPE(io) = IoTYPE_RDONLY;
        input_sv = newRV_noinc((SV*)gv);
      } else {
        close(pipefd[0]);
        input_sv = newSVpvs("");
      }
    } else {
      input_sv = newSVpvs("");
    }
  }

  hv_stores(env, "psgi.input", input_sv);

  ENTER;
  SAVETMPS;
  
  SV* env_ref = sv_2mortal(newRV_noinc((SV*)env));
  
  PUSHMARK(SP);
  XPUSHs(env_ref);
  PUTBACK;
  
  int count = call_sv((SV*)session->server->app, G_SCALAR);
  
  SPAGAIN;

  if (count != 1)
  {
    warn("PSGI application did not return exactly one value");
    PUTBACK;
    FREETMPS;
    LEAVE;
    return error_reply(session, data);
  }
  
  SV* response = POPs;

  int32_t rv = 0;
  if (SvROK(response) && SvTYPE(SvRV(response)) == SVt_PVAV)
  {
    rv = handle_av_response(ng_session, session, data, response);
  } 
  else if (SvROK(response) && SvTYPE(SvRV(response)) == SVt_PVCV)
  {
    rv = handle_cv_response(ng_session, env_ref, session, data, response);
  }
  else
  {
    warn("PSGI application did not return a valid response");
    rv = error_reply(session, data);
  }

  PUTBACK;
  FREETMPS;
  LEAVE;

  return rv;
}

static inline int32_t on_data_chunk(nghttp2_session* ng_session,
                                    uint8_t flags,
                                    int32_t stream_id,
                                    const uint8_t* data_chunk,
                                    size_t len,
                                    void* user_data) {
  (void)flags;
  (void)user_data;
  
  auto data = static_cast<H2Data*>(nghttp2_session_get_stream_user_data(ng_session, stream_id));
  if (!data)
  {
    return 0;
  }
  
  data->body_received += len;

  if (data->body_received > BODY_SIZE_THRESHOLD && data->body_fd == -1)
  {
    char temp_template[] = "/tmp/plack_h2_body_XXXXXX";
    data->body_fd = mkstemp(temp_template);
    if (data->body_fd == -1)
    {
      warn("Failed to create temporary file for request body: %s", strerror(errno));
      return NGHTTP2_ERR_CALLBACK_FAILURE;
    }

    if (!data->body_buffer->empty()) {
      ssize_t written = write(data->body_fd, data->body_buffer->c_str(), data->body_buffer->size());
      if (written != (ssize_t)data->body_buffer->size()) {
        warn("Failed to write buffer to temporary file: %s", strerror(errno));
        close(data->body_fd);
        data->body_fd = -1;
        return NGHTTP2_ERR_CALLBACK_FAILURE;
      }
      data->body_buffer->clear();
      data->body_buffer->shrink_to_fit();
    }
    
    unlink(temp_template);
  }
  
  if (data->body_fd != -1)
  {
    ssize_t written = write(data->body_fd, data_chunk, len);
    if (written != (ssize_t)len) {
      warn("Failed to write to temporary file: %s", strerror(errno));
      return NGHTTP2_ERR_CALLBACK_FAILURE;
    }
  } else {
    data->body_buffer->append((const char*)data_chunk, len);
  }
  
  return 0;
}

static inline int32_t on_begin_headers(nghttp2_session* ng_session,
                                       const nghttp2_frame* frame,
                                       void* user_data) {
  H2Session* session = static_cast<H2Session*>(user_data);
  if (frame->hd.type != NGHTTP2_HEADERS ||
      frame->headers.cat != NGHTTP2_HCAT_REQUEST) {
    return 0;
  }

  H2Data* data = new H2Data(session, frame->hd.stream_id);
  session->data.push_back(data);
  nghttp2_session_set_stream_user_data(ng_session, frame->hd.stream_id, data);
  return 0;
}

static inline int32_t on_headers(nghttp2_session* ng_session,
                       const nghttp2_frame* frame,
                       const uint8_t* name,
                       size_t namelen,
                       const uint8_t* value,
                       size_t valuelen,
                       uint8_t flags,
                       void* user_data) {
  (void)flags;
  (void)user_data;

  std::string name_str((const char*)name, namelen);
  if (frame->hd.type == NGHTTP2_HEADERS)
  {
    if (frame->headers.cat != NGHTTP2_HCAT_REQUEST)
    {
      return 0;
    }
    auto data = static_cast<H2Data*>(nghttp2_session_get_stream_user_data(ng_session, frame->hd.stream_id));
    if (!data)
    {
      return 0;
    }

    if (name_str[0] == ':')
    {
      std::string method = ":method";
      std::string path = ":path";
      std::string scheme = ":scheme";
      std::string authority = ":authority";
      if (name_str == path)
      {
        size_t j;
        for (j = 0; j < valuelen; ++j)
        {
          if (value[j] == '?')
          {
            break;
          }
        }
        char* decoded = percent_decode((const uint8_t*)value, j);

        data->path = std::make_unique<std::string>(strdup(decoded), j);
        if (j < valuelen)
        {
          data->query = std::make_unique<std::string>((const char*)value + j + 1, valuelen - j - 1);
        }

        free(decoded);
        
        data->uri = std::make_unique<std::string>((const char*)value, valuelen);
      }
      else if (name_str == method)
      {
        data->method = std::make_unique<std::string>((const char*)value, valuelen);
      }
      else if (name_str == scheme)
      {
        data->scheme = std::make_unique<std::string>((const char*)value, valuelen);
      }
      else if (name_str == authority)
      {
        data->authority = std::make_unique<std::string>((const char*)value, valuelen);
      }
    }
    else 
    {
      auto& headers = *data->headers;
      std::string header_name((const char*)name, namelen);
      std::string header_value((const char*)value, valuelen);

      if (header_name == "content-length")
      {
        data->content_length = std::stoull(header_value);

        auto session = static_cast<H2Session*>(user_data);
        if (data->content_length > session->server->get_max_request_body_size()) {
          warn("Request body too large: %llu bytes", (unsigned long long)data->content_length);
          int rv = nghttp2_submit_rst_stream(
              ng_session, NGHTTP2_FLAG_NONE, data->stream_id,
              NGHTTP2_REFUSED_STREAM);
          if (rv != 0)
          {
            warn("nghttp2_submit_rst_stream() failed, rv=%d", rv);
            return NGHTTP2_ERR_CALLBACK_FAILURE;
          }
          return 0;
        }
      }

      if (headers.find(header_name) != headers.end()) {
        headers[header_name] += ", " + header_value;
      }
      else
      {
        headers[header_name] = header_value;
      }
    }
  }

  return 0;
}

static void server_callback(struct evconnlistener* listener,
                            evutil_socket_t fd,
                            struct sockaddr* addr,
                            int addrlen,
                            void* ctx) {
  H2Server* server = static_cast<H2Server*>(ctx);
  std::optional<H2Session*> session = H2Session::make_session(server, fd, addr, addrlen);
  if (!session.has_value()) {
    warn("Could not create H2 session, most likely SSL setup failed");
    evutil_closesocket(fd);
    return;
  }
  (void)listener;

  auto read_cb = [](struct bufferevent* bev, void* ctx) {
    (void)bev;
    H2Session* session = static_cast<H2Session*>(ctx);
    if (session->recv() != 0) {
      delete session;
    }
  };

  auto write_cb = [](struct bufferevent* bev, void* ctx) {
    H2Session* session = static_cast<H2Session*>(ctx);
    if (evbuffer_get_length(bufferevent_get_output(bev)) == 0) {
      return;
    }
    if (nghttp2_session_want_read(session->session.get()) == 0 &&
        nghttp2_session_want_write(session->session.get()) == 0) {
      delete session;
      return;
    }
    if (session->send() != 0) {
      delete session;
    }
  };

  auto event_cb = [](struct bufferevent* bev, short events, void* ctx) {
    H2Session* session = static_cast<H2Session*>(ctx);
    if (events & BEV_EVENT_CONNECTED)
    {
      const unsigned char* alpn = nullptr;
      unsigned int alpnlen = 0;
      SSL* ssl = bufferevent_openssl_get_ssl(bev);
      SSL_get0_alpn_selected(ssl, &alpn, &alpnlen);

      if (alpn == nullptr || alpnlen == 0 ||
          (alpnlen != 2 || memcmp(alpn, "h2", 2) != 0)) {
        warn("Client from %s does not support the HTTP/2 protocol via ALPN", session->client_address.c_str());
        delete session;
        return;
      }

      nghttp2_session_callbacks* callbacks;
      nghttp2_session_callbacks_new(&callbacks);
      nghttp2_session_callbacks_set_send_callback(callbacks, [](nghttp2_session* session,
                                                  const uint8_t* data,
                                                  size_t length,
                                                  int flags,
                                                  void* user_data) -> ssize_t {
        (void)session;
        (void)flags;
        auto h2session = static_cast<H2Session*>(user_data);
        auto bufferevent = h2session->bufferevent;

        if (evbuffer_get_length(bufferevent_get_output(bufferevent)) + length >
            1 << 16) {
          return NGHTTP2_ERR_WOULDBLOCK;
        }

        bufferevent_write(bufferevent, data, length);
        return (ssize_t) length;
      });

      nghttp2_session_callbacks_set_on_frame_recv_callback(callbacks, [](nghttp2_session* ng_session,
                                                  const nghttp2_frame* frame,
                                                  void* user_data) -> int {
        auto session = static_cast<H2Session*>(user_data);
        switch (frame->hd.type)
        {
          case NGHTTP2_HEADERS:
          case NGHTTP2_DATA:
            if (frame->hd.flags & NGHTTP2_FLAG_END_STREAM)
            {
              auto ret = static_cast<H2Data*>(nghttp2_session_get_stream_user_data(session->session.get(), frame->hd.stream_id));
              if (ret)
              {
                return on_request(ng_session, session, ret);
              }
            }
          default:
            break;
        }
        return 0;
      });

      nghttp2_session_callbacks_set_on_stream_close_callback(callbacks, [](nghttp2_session* ng_session,
                                                  int32_t stream_id,
                                                  uint32_t error_code,
                                                  void* user_data) -> int {
        (void)ng_session;
        (void)error_code;
        auto session = static_cast<H2Session*>(user_data);
        auto data = static_cast<H2Data*>(nghttp2_session_get_stream_user_data(session->session.get(), stream_id));
        if (!data)
        {
          return 0;
        }
        session->data.remove(data);
        delete data;
        return 0;
      });
      nghttp2_session_callbacks_set_on_begin_headers_callback(callbacks, on_begin_headers);
      nghttp2_session_callbacks_set_on_header_callback(callbacks, on_headers);
      nghttp2_session_callbacks_set_on_data_chunk_recv_callback(callbacks, on_data_chunk);

      nghttp2_session* ngh2_session = nullptr;
      nghttp2_session_server_new(&ngh2_session, callbacks, session);
      session->session.reset(ngh2_session);
      nghttp2_session_callbacks_del(callbacks);
    
      if (events & (BEV_EVENT_EOF | BEV_EVENT_ERROR)) {
        warn("Unexpected connection closed from %s", session->client_address.c_str());
        delete session;
        return;
      }

      nghttp2_settings_entry iv[1] = {{NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS, 100}};
      int rv = nghttp2_submit_settings(session->session.get(), NGHTTP2_FLAG_NONE, iv, sizeof(iv) / sizeof(iv[0]));
      if (rv != 0 || session->send() != 0) {
        delete session;
        return;
      }

      return;
    } // if (events & BEV_EVENT_CONNECTED)
    else if (events & (BEV_EVENT_ERROR | BEV_EVENT_TIMEOUT)) {
      warn("Connection closed from %s", session->client_address.c_str());
    }
    delete session;
  };

  bufferevent_setcb(
      (*session)->bufferevent,
      read_cb,
      write_cb,
      event_cb,
      session.value()
    );
}

/* Classes */

H2Data::H2Data(H2Session* session, int32_t stream_id) {
  this->stream_id = stream_id;
  this->fd = -1;
  this->body_fd = -1;
  this->headers = std::make_unique<std::map<std::string, std::string>>();
  this->response_headers = std::make_unique<std::vector<std::string>>();
  this->body_buffer = std::make_unique<std::string>();
  this->content_length = 0;
  this->body_received = 0;
  this->body_complete = false;
}

H2Data::~H2Data() {
  if (fd != -1)
  {
    close(fd);
  }
  if (body_fd != -1)
  {
    close(body_fd);
  }
}

H2Session::H2Session(): bufferevent(nullptr), session(nullptr, nghttp2_session_del) {}

H2Session::~H2Session() {
  SSL* ssl = bufferevent_openssl_get_ssl(this->bufferevent);
  if (ssl)
  {
    SSL_shutdown(ssl);
  }
  bufferevent_free(this->bufferevent);
  for (H2Data* p : this->data)
  {
    close(p->fd);
    delete p;
  }
}

std::optional<H2Session*> H2Session::make_session(H2Server* server,
                        int32_t file_descriptor,
                        struct sockaddr* addr,
                        int addrlen) {
  int rv;
  char host[NI_MAXHOST];
  int32_t val;

  auto session = new H2Session();
  session->server = server;
  auto ssl = SSL_new(server->get_ssl_ctx());
  if (!ssl)
  {
    warn("Could not create SSL object");
    return std::nullopt;
  }
  setsockopt(file_descriptor, IPPROTO_TCP, TCP_NODELAY, (const char*)&val, sizeof(val));
  session->bufferevent = bufferevent_openssl_socket_new(
      server->get_ev_base(),
      file_descriptor,
      ssl,
      BUFFEREVENT_SSL_ACCEPTING,
      BEV_OPT_CLOSE_ON_FREE | BEV_OPT_DEFER_CALLBACKS
    );
  bufferevent_enable(session->bufferevent, EV_READ | EV_WRITE);
  rv = getnameinfo(
      addr,
      addrlen,
      host,
      sizeof(host),
      NULL,
      0,
      NI_NUMERICHOST);
  if (rv != 0)
  {
    session->client_address = "unknown";
  }
  else
  {
    session->client_address = host;
  }

  return session;
}

int32_t H2Session::send() {
  if (nghttp2_session_send(this->session.get()) != 0) {
    warn("nghttp2_session_send() failed");
    return -1;
  }
  return 0;
}

int32_t H2Session::recv() {
  struct evbuffer* input = bufferevent_get_input(this->bufferevent);
  unsigned len = evbuffer_get_length(input);
  unsigned char* data = evbuffer_pullup(input, -1);
  auto rv = nghttp2_session_mem_recv(this->session.get(), data, len);

  if (rv < 0)
  {
    warn("nghttp2_session_mem_recv() returned error: %s", nghttp2_strerror(rv));
    return -1;
  }

  if (evbuffer_drain(input, (size_t)rv) != 0) {
    warn("evbuffer_drain() failed");
    return -1;
  }

  if (this->send() != 0) {
    return -1;
  }

  return 0;
}

inline H2ServerConfig H2ServerConfig::build_config_from_hv(HV* hv) {
  H2ServerConfig config;

  auto ssl_cert_sv = hv_fetchs(hv, "ssl_cert", 0);
  if (ssl_cert_sv && SvOK(*ssl_cert_sv)) {
    config.ssl_cert = SvPV_nolen(*ssl_cert_sv);
  } else {
    croak("ssl_cert is required argument");
  }

  if (hv_fetchs(hv, "ssl_key", 0) && SvOK(*hv_fetchs(hv, "ssl_key", 0))) {
    config.ssl_key = SvPV_nolen(*hv_fetchs(hv, "ssl_key", 0));
  } else {
    croak("ssl_key is required argument");
  }

  if (hv_fetchs(hv, "max_request_body_size", 0) && SvOK(*hv_fetchs(hv, "max_request_body_size", 0))) {
    config.max_request_body_size = SvIV(*hv_fetchs(hv, "max_request_body_size", 0));
  } else {
    config.max_request_body_size = DEFAULT_MAX_REQUEST_BODY_SIZE;
  }

  config.address = SvPV_nolen(*hv_fetchs(hv, "address", 0));
  config.port = SvIV(*hv_fetchs(hv, "port", 0));
  config.timeout = SvIV(*hv_fetchs(hv, "timeout", 0));
  return config;
}

H2Server::H2Server(const H2ServerConfig* config, CV* app)
  : config(std::make_unique<H2ServerConfig>(*config)), app(app), base(event_base_new()), ssl_ctx(create_ssl_ctx(config->ssl_cert, config->ssl_key))
{}

H2Server::~H2Server() {
  if (base)
  {
    event_base_free(base);
  }

  if (ssl_ctx)
  {
    SSL_CTX_free(ssl_ctx);
  }
}

void H2Server::listen() {
  evthread_use_pthreads();

  if (!base)
  {
    croak("Could not initialize libevent when trying to start server!");
  }

  int32_t ret;
  struct addrinfo hints;
  struct addrinfo* res;
  struct addrinfo* rp;

  memset(&hints, 0, sizeof(struct addrinfo));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags = AI_PASSIVE;
#ifdef AI_ADDRCONFIG
  hints.ai_flags |= AI_ADDRCONFIG;
#endif
  ret = getaddrinfo(config->address.c_str(), std::to_string(config->port).c_str(), &hints, &res);

  if (ret != 0)
  {
    croak("failed to getaddrinfo for %s:%d: %s",
          config->address.c_str(), config->port, gai_strerror(ret));
  }

  for (rp = res; rp != NULL; rp = rp->ai_next)
  {
    struct evconnlistener* listener = evconnlistener_new_bind(
        base, server_callback, this,
        LEV_OPT_REUSEABLE | LEV_OPT_CLOSE_ON_FREE, 16,
        rp->ai_addr, (int) rp->ai_addrlen);

    if (listener)
    {
      freeaddrinfo(res);
      break;
    }
  }

  std::cout << "[Plack::Handler::H2] Listening for http2 on https://" << config->address << ":" << config->port << " ..." << std::endl;

  this->run_event_loop();
}

void H2Server::run_event_loop() {
  event_base_loop(this->base, EVLOOP_NO_EXIT_ON_EMPTY);
}

inline SSL_CTX* H2Server::get_ssl_ctx() const {
  return ssl_ctx;
}

inline std::string H2Server::get_server_address() const {
  return config->address;
}

inline int32_t H2Server::get_server_port() const {
  return config->port;
}

inline int64_t H2Server::get_max_request_body_size() const {
  return config->max_request_body_size;
}

inline event_base* H2Server::get_ev_base() const {
  return base;
}

extern "C" {

void ph2_stream_write_headers(SV* env_sv, SV* session_sv, SV* response_sv) {
  H2Session* session = get_session_from_sv_uv(session_sv);
  if (!session) {
    croak("Invalid session parameter");
  }

  if (!SvROK(env_sv) || SvTYPE(SvRV(env_sv)) != SVt_PVHV) {
    croak("Invalid environment hash");
  }
  
  HV* env = (HV*)SvRV(env_sv);
  SV** stream_id_sv = hv_fetchs(env, "psgix.h2.stream_id", 0);
  if (!stream_id_sv)
  {
    croak("Stream ID not found in environment");
  }
  
  int32_t stream_id = SvIV(*stream_id_sv);
  
  H2Data* data = nullptr;
  for (H2Data* d : session->data)
  {
    if (d->stream_id == stream_id)
    {
      data = d;
      break;
    }
  }
  
  if (!data)
  {
    croak("Stream data not found for stream_id %d", stream_id);
  }
  
  if (!SvROK(response_sv) || SvTYPE(SvRV(response_sv)) != SVt_PVAV) {
    croak("Response must be an array reference");
  }
  
  AV* response_av = (AV*)SvRV(response_sv);
  if (av_len(response_av) < 1) {
    croak("Response array must have at least status and headers");
  }
  
  SV** status_sv = av_fetch(response_av, 0, 0);
  SV** headers_sv = av_fetch(response_av, 1, 0);
  
  if (!status_sv || !headers_sv)
  {
    croak("Invalid response format");
  } 

  int rv = send_headers_from_av(session, stream_id, *status_sv, *headers_sv, true);

  if (rv != 0)
  {
    warn("nghttp2_submit_headers() failed: %s", nghttp2_strerror(rv));
    croak("Failed to submit response headers");
  }
  
  session->send();
}

void ph2_stream_write_data(SV* env_sv, SV* session_sv, SV* end_stream_sv, SV* data_chunk_sv) {
  H2Session* session = get_session_from_sv_uv(session_sv);

  if (!session) {
    croak("Invalid session parameter");
  }

  if (!SvROK(env_sv) || SvTYPE(SvRV(env_sv)) != SVt_PVHV) {
    croak("Invalid environment hash");
  }

  HV* env = (HV*)SvRV(env_sv);
  SV** stream_id_sv = hv_fetchs(env, "psgix.h2.stream_id", 0);
  if (!stream_id_sv) {
    croak("Stream ID not found in environment! This should never happen!");
  }
  
  int32_t stream_id = SvIV(*stream_id_sv);
  
  STRLEN data_len;
  const char* data_str = nullptr;
  bool end_stream = SvOK(end_stream_sv) && SvTRUE(end_stream_sv);
  
  if (SvOK(data_chunk_sv)) {
    data_str = SvPV(data_chunk_sv, data_len);
  }
  else {
    data_len = 0;
  }

  if (end_stream) {
    auto data_provider = nghttp2_data_provider{
      .source = { .fd = -1 },
      .read_callback = [](nghttp2_session* session,
                          int32_t stream_id,
                          uint8_t* buf,
                          size_t length,
                          uint32_t* data_flags,
                          nghttp2_data_source* source,
                          void* user_data) -> ssize_t
      {
        (void)session;
        (void)stream_id;
        (void)buf;
        (void)length;
        (void)source;
        (void)user_data;

        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        return 0;
      }
    };

    int rv = nghttp2_submit_data(
      session->session.get(),
      NGHTTP2_FLAG_END_STREAM,
      stream_id,
      &data_provider
    );

    if (rv != 0) {
      warn("nghttp2_submit_data() for end_stream failed: %s", nghttp2_strerror(rv));
      croak("Failed to submit end_stream");
    }

    session->send();

    return;
  }
  
  if (data_len > 0)
  {
    int pipefd[2];
    if (pipe(pipefd) != 0) {
      croak("Failed to create pipe: %s", strerror(errno));
    }
    
    ssize_t written = write(pipefd[1], data_str, data_len);
    close(pipefd[1]);
    
    if (written != (ssize_t)data_len) {
      close(pipefd[0]);
      croak("Failed to write data chunk: %s", strerror(errno));
    }

    nghttp2_data_provider data_prd;
    data_prd.source.fd = pipefd[0];
    data_prd.read_callback = [](nghttp2_session* session,
                                int32_t stream_id,
                                uint8_t* buf,
                                size_t length,
                                uint32_t* data_flags,
                                nghttp2_data_source* source,
                                void* user_data) -> ssize_t
    {
      (void)session;
      (void)stream_id;
      (void)user_data;

      int fd = source->fd;
      ssize_t r;
      while ((r = read(fd, buf, length)) == -1 && errno == EINTR);

      if (r == -1) {
        return NGHTTP2_ERR_TEMPORAL_CALLBACK_FAILURE;
      }

      if (r == 0) {
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        close(fd);
      }

      return static_cast<ssize_t>(r);
    };

    int rv = nghttp2_submit_data(
      session->session.get(),
      0,
      stream_id,
      &data_prd
    );

    if (rv != 0)
    {
      close(pipefd[0]);
      warn("nghttp2_submit_data() failed: %s", nghttp2_strerror(rv));
      croak("Failed to submit data chunk");
    }
  }
  else
  {
    return;
  }
  
  session->send();
}

void ph2_run(SV* self, SV* app, SV* options) {
  if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
    croak("Handler instance is required");
  }

  if (!SvROK(app) || SvTYPE(SvRV(app)) != SVt_PVCV) {
    croak("Application code is required");
  }

  if (!SvROK(options) || SvTYPE(SvRV(options)) != SVt_PVHV) {
    croak("Server options hash is required");
  }

  std::string ssl_cert;
  std::string ssl_key;

  HV* options_hv = (HV*)SvRV(options);
  static H2ServerConfig config = H2ServerConfig::build_config_from_hv(options_hv);
  static H2Server server(&config, (CV*)SvRV(app));
  server.listen();
}

} // extern "C"