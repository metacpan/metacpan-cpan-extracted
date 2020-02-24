#include<neo4j-client.h>

// this is lifted from
// https://github.com/cleishm/libneo4j-client/blob/master/lib/src/client_config.h

struct neo4j_config
{
  struct neo4j_logger_provider *logger_provider;
  struct neo4j_connection_factory *connection_factory;
  struct neo4j_memory_allocator *allocator;
  unsigned int mpool_block_size;
  char *username;
  char *password;
  neo4j_basic_auth_callback_t basic_auth_callback;
  void *basic_auth_callback_userdata;
  const char *client_id;
  unsigned int so_rcvbuf_size;
  unsigned int so_sndbuf_size;
  time_t connect_timeout;
  size_t io_rcvbuf_size;
  size_t io_sndbuf_size;
  uint16_t snd_min_chunk_size;
  uint16_t snd_max_chunk_size;
  unsigned int session_request_queue_size;
  unsigned int max_pipelined_requests;
#ifdef HAVE_TLS
  char *tls_private_key_file;
  neo4j_password_callback_t tls_pem_pw_callback;
  void *tls_pem_pw_callback_userdata;
  char *tls_ca_file;
  char *tls_ca_dir;
#endif
  bool trust_known;
  char *known_hosts_file;
  neo4j_unverified_host_callback_t unverified_host_callback;
  void *unverified_host_callback_userdata;
  uint_fast32_t render_flags;
  unsigned int render_inspect_rows;
  const struct neo4j_results_table_colors *results_table_colors;
  const struct neo4j_plan_table_colors *plan_table_colors;
};
