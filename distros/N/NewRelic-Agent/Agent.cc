#include "Agent.h"

#include "newrelic_common.h"
#include "newrelic_collector_client.h"
#include "newrelic_transaction.h"

#include <string>

using namespace std;

Agent::Agent(
  const char *license_key_,
  const char *app_name_,
  const char *app_language_,
  const char *app_language_version_
)
: license_key(string(license_key_)),
  app_name(string(app_name_)),
  app_language(string(app_language_)),
  app_language_version(string(app_language_version_))
{
  if (!license_key.empty() &&
      !app_name.empty() &&
      !app_language.empty() &&
      !app_language_version.empty())
    config_loaded = true;
}

void Agent::embed_collector() {
  newrelic_register_message_handler(newrelic_message_handler);
}

void Agent::init() {
  newrelic_init(
    license_key.c_str(),
    app_name.c_str(),
    app_language.c_str(),
    app_language_version.c_str()
  );
}

long Agent::begin_transaction() {
  return newrelic_transaction_begin();
}

int Agent::set_transaction_name(long transaction_id, const char *name) {
  return newrelic_transaction_set_name(transaction_id, name);
}

int Agent::set_transaction_request_url(long transaction_id, const char *request_url) {
  return newrelic_transaction_set_request_url(transaction_id, request_url);
}

int Agent::set_transaction_max_trace_segments(long transaction_id, int max_trace_segments) {
  return newrelic_transaction_set_max_trace_segments(transaction_id, max_trace_segments);
}

int Agent::set_transaction_category(long transaction_id, const char *category) {
  return newrelic_transaction_set_category(transaction_id, category);
}

int Agent::set_transaction_type_web(long transaction_id) {
  return newrelic_transaction_set_type_web(transaction_id);
}

int Agent::set_transaction_type_other(long transaction_id) {
  return newrelic_transaction_set_type_other(transaction_id);
}

int Agent::add_transaction_attribute(long transaction_id, const char *key, const char *value) {
  return newrelic_transaction_add_attribute(transaction_id, key, value);
}

int Agent::notice_transaction_error(
  long transaction_id,
  const char *exception_type,
  const char *error_message,
  const char *stack_trace,
  const char *stack_frame_delimiter
) {
  return newrelic_transaction_notice_error(
    transaction_id,
    exception_type,
    error_message,
    stack_trace,
    stack_frame_delimiter
  );
}

int Agent::end_transaction(long transaction_id) {
  return newrelic_transaction_end(transaction_id);
}

int Agent::record_metric(const char *name, double value) {
  return newrelic_record_metric(name, value);
}

int Agent::record_cpu_usage(double cpu_user_time_seconds, double cpu_usage_percent) {
  return newrelic_record_cpu_usage(cpu_user_time_seconds, cpu_usage_percent);
}

int Agent::record_memory_usage(double memory_megabytes) {
  return newrelic_record_memory_usage(memory_megabytes);
}

long Agent::begin_generic_segment(
  long transaction_id,
  long parent_segment_id,
  const char *name) {
  return newrelic_segment_generic_begin(
    transaction_id,
    parent_segment_id,
    name
  );
}

long Agent::begin_datastore_segment(
  long transaction_id,
  long parent_segment_id,
  const char *table,
  const char *operation,
  const char *sql, const char *sql_trace_rollup_name
) {
  return newrelic_segment_datastore_begin(
    transaction_id,
    parent_segment_id,
    table,
    operation,
    sql,
    sql_trace_rollup_name,
    newrelic_basic_literal_replacement_obfuscator
  );
}

long Agent::begin_external_segment(
  long transaction_id,
  long parent_segment_id,
  const char *host,
  const char *name
) {
  return newrelic_segment_external_begin(
    transaction_id,
    parent_segment_id,
    host,
    name
  );
}

int Agent::end_segment(long transaction_id, long segment_id) {
  return newrelic_segment_end(transaction_id, segment_id);
}

const char* Agent::get_license_key() {
  return license_key.c_str();
}

const char* Agent::get_app_name() {
  return app_name.c_str();
}

const char* Agent::get_app_language() {
  return app_language.c_str();
}

const char* Agent::get_app_language_version() {
  return app_language_version.c_str();
}
