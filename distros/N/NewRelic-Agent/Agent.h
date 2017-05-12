#ifndef _Agent_h_
#define _Agent_h_

#include <string>

using namespace std;

class Agent {
  public:
    Agent(
      const char *license_key          = NULL,
      const char *app_name             = NULL,
      const char *app_language         = NULL,
      const char *app_language_version = NULL
    );
    ~Agent() {}
    void embed_collector();
    void init();
    long begin_transaction();
    int set_transaction_name(long transaction_id, const char *name);
    int set_transaction_request_url(long transaction_id, const char *request_url);
    int set_transaction_max_trace_segments(long transaction_id, int max_trace_segments);
    int set_transaction_category(long transaction_id, const char *category);
    int set_transaction_type_web(long transaction_id);
    int set_transaction_type_other(long transaction_id);
    int add_transaction_attribute(long transaction_id, const char *key, const char *value);
    int notice_transaction_error(long transaction_id, const char *exception_type, const char *error_message, const char *stack_trace, const char *stack_frame_delimiter);
    int end_transaction(long transaction_id);
    int record_metric(const char *name, double value);
    int record_cpu_usage(double cpu_user_time_seconds, double cpu_usage_percent);
    int record_memory_usage(double memory_megabyte);
    long begin_generic_segment(long transaction_id, long parent_segment_id, const char *name);
    long begin_datastore_segment(long transaction_id, long parent_segment_id, const char *table, const char *operation, const char *sql, const char *sql_trace_rollup_name);
    long begin_external_segment(long transaction_id, long parent_segment_id, const char *host, const char *name);
    int end_segment(long transaction_id, long segment_id);
    const char* get_license_key();
    const char* get_app_name();
    const char* get_app_language();
    const char* get_app_language_version();

  private:
    string license_key;
    string app_name;
    string app_language;
    string app_language_version;
    bool   config_loaded;
};

#endif

