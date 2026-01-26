#pragma once

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <list>
#include <string>
#include <memory>
#include <vector>
#include <map>
#include <optional>
#include <openssl/ssl.h>
#include <event.h>
#include <event2/event.h>
#include <event2/thread.h>
#include <event2/listener.h>
#include <event2/util.h>
#include <event2/bufferevent_ssl.h>
#include <nghttp2/nghttp2.h>
#include <netinet/tcp.h>

// H2Data: Represents data for a single HTTP/2 stream
struct H2Data {
  std::unique_ptr<std::map<std::string, std::string>> headers = nullptr;
  std::unique_ptr<std::string> uri = nullptr;
  std::unique_ptr<std::string> path = nullptr;
  std::unique_ptr<std::string> query = nullptr;
  std::unique_ptr<std::string> method = nullptr;
  std::unique_ptr<std::string> scheme = nullptr;
  std::unique_ptr<std::string> authority = nullptr;
  std::unique_ptr<std::string> domain = nullptr;
  std::unique_ptr<std::vector<std::string>> response_headers = nullptr;
  
  std::unique_ptr<std::string> body_buffer = nullptr;
  int32_t body_fd = -1;
  unsigned long long content_length = 0;
  unsigned long long body_received = 0;
  bool body_complete = false;

  int32_t stream_id;
  int32_t fd;  // Response body fd

  ~H2Data();
  H2Data(struct H2Session* session, int32_t stream_id);
  
  H2Data(H2Data&& other) = default;
  H2Data& operator=(H2Data&& other) = default;
  
  H2Data(const H2Data&) = delete;
  H2Data& operator=(const H2Data&) = delete;
};

// H2ServerConfig: Configuration for the HTTP/2 server
struct H2ServerConfig {
  std::string ssl_cert;
  std::string ssl_key;
  std::string address;
  int64_t max_request_body_size;
  int32_t port;
  int32_t timeout;
  int32_t read_timeout;
  int32_t write_timeout;
  int32_t request_timeout;

  static H2ServerConfig build_config_from_hv(HV* hv);
};

// H2Server: Main HTTP/2 server class
class H2Server {
public:
  H2Server(const H2ServerConfig* config, CV* app);
  ~H2Server();

  void listen();
  void run_event_loop();

  int get_server_port() const;
  int64_t get_max_request_body_size() const;
  std::string get_server_address() const;
  SSL_CTX* get_ssl_ctx() const;
  event_base* get_ev_base() const;

  CV* app;

private:
  std::unique_ptr<H2ServerConfig> config;
  SSL_CTX* ssl_ctx;
  event_base* base;
};

// H2Session: Represents an HTTP/2 connection session
struct H2Session {
  std::list<H2Data*> data;
  H2Server* server;
  struct bufferevent* bufferevent;
  std::unique_ptr<nghttp2_session, decltype(&nghttp2_session_del)> session;
  std::string client_address;

  H2Session();
  ~H2Session();

  static std::optional<H2Session*> make_session(
    class H2Server* server,
    int32_t file_descriptor,
    struct sockaddr* addr,
    int addrlen
  );

  int32_t send();
  int32_t recv();
};

// C interface for XS binding
extern "C" {
  void ph2_stream_write_headers(SV* env, SV* session, SV* response);
  void ph2_stream_write_data(SV* env, SV* session, SV* end_stream, SV* data);
  void ph2_run(SV* self, SV* app, SV* options);
}