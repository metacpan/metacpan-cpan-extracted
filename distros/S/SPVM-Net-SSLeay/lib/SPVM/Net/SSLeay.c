// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <assert.h>

static const char* FILE_NAME = "Net/SSLeay.c";

int32_t SPVM__Net__SSLeay___print_version_text(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  char *version = OPENSSL_VERSION_TEXT;
  fprintf(stderr, "OpenSSL version: %s\n", version);
    
  return 0;
}

int32_t SPVM__Net__SSLeay__init(SPVM_ENV* env, SPVM_VALUE* stack) {

#if !(defined(OPENSSL_VERSION_NUMBER) && OPENSSL_VERSION_NUMBER >= 0x10100000)
  // SSL_library_init is deprecated in OpenSSL 1.1+.
  SSL_library_init();
  
  // SSL_load_error_strings is deprecated OpenSSL in 1.1+.
  SSL_load_error_strings();
  
  // OpenSSL_add_all_algorithms is deprecated in OpenSSL 1.1+.
  OpenSSL_add_all_algorithms();
  
#endif
  
  return 0;
}

// Class Methods
int32_t SPVM__Net__SSLeay__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_ssl_ctx = stack[0].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_ssl_ctx);
  
  SSL* ssl = SSL_new(ssl_ctx);
  
  if (!ssl) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    env->die(env, stack, "[OpenSSL Error]SSL_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay", ssl, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  env->set_field_object_by_name(env, stack, obj_self, "ssl_ctx", obj_ssl_ctx, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__library_init(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t status = SSL_library_init();
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__load_error_strings(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SSL_load_error_strings();
  
  return 0;
}

int32_t SPVM__Net__SSLeay__alert_desc_string_long(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int32_t type = stack[0].ival;
  
  const char* desc = SSL_alert_desc_string_long(type);
  
  assert(desc);
  
  void* obj_desc = env->new_string_nolen(env, stack, desc);
  
  stack[0].oval = obj_desc;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__load_client_CA_file(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_file = stack[0].oval;
  
  if (!obj_file) {
    return env->die(env, stack, "The file $file must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* file = env->get_chars(env, stack, obj_file);
  
  STACK_OF(X509_NAME)* stack_of_x509_name = SSL_load_client_CA_file(file);
  
  if (!stack_of_x509_name) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    env->die(env, stack, "[OpenSSL Error]SSL_load_client_CA_file failed.", __func__, FILE_NAME, __LINE__);
    return error_id;
  }
  
  int32_t length = sk_X509_NAME_num(stack_of_x509_name);
  void* obj_x509_names = env->new_object_array_by_name(env, stack, "Net::SSLeay::X509_NAME", length, &error_id, __func__, FILE_NAME, __LINE__);
  
  for (int32_t i = 0; i < length; i++) {
    X509_NAME* x509_name = sk_X509_NAME_value(stack_of_x509_name, i);
    
    void* obj_address_x509_name = env->new_pointer_object_by_name(env, stack, "Address", x509_name, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_address_x509_name;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_NAME", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    void* obj_x509_name = stack[0].oval;
    
    env->set_elem_object(env, stack, obj_x509_names, i, obj_x509_name);
  }
  
  stack[0].oval = obj_x509_names;
  
  return 0;
}

// Instance Methods
int32_t SPVM__Net__SSLeay__set_fd(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t fd = stack[1].ival;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  ERR_clear_error();
  
  int32_t status = SSL_set_fd(ssl, fd);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    env->die(env, stack, "[OpenSSL Error]SSL_set_fd failed.", __func__, FILE_NAME, __LINE__);
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__set_tlsext_host_name(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_name = stack[1].oval;
  
  if (!obj_name) {
    return env->die(env, stack, "The host name $name must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* name = env->get_chars(env, stack, obj_name);
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  ERR_clear_error();
  
  int32_t status = SSL_set_tlsext_host_name(ssl, name);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    env->die(env, stack, "[OpenSSL Error]SSL_set_tlsext_host_name failed.", __func__, FILE_NAME, __LINE__);
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__connect(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  ERR_clear_error();
  
  int32_t status = SSL_connect(ssl);
  
  if (!(status == 1)) {
    int32_t ssl_operation_error = SSL_get_error(ssl, status);
    
    assert(ssl_operation_error != SSL_ERROR_NONE);
    
    env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_connect failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__accept(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  ERR_clear_error();
  
  int32_t status = SSL_accept(ssl);
  
  if (!(status == 1)) {
    int32_t ssl_operation_error = SSL_get_error(ssl, status);
    
    assert(ssl_operation_error != SSL_ERROR_NONE);
    
    env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_accept failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__shutdown(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  ERR_clear_error();
  
  int32_t status = SSL_shutdown(ssl);
  
  if (status < 0) {
    int32_t ssl_operation_error = SSL_get_error(ssl, status);
    
    assert(ssl_operation_error != SSL_ERROR_NONE);
    
    env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_shutdown failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__read(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The buffer $buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t num = stack[2].ival;
  
  if (num < 0) {
    num = buf_length;
  }
  
  int32_t offset = stack[3].ival;
  
  if (!(offset >= 0)) {
    return env->die(env, stack, "The offset $offset must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(offset + num <= buf_length)) {
    return env->die(env, stack, "The offset $offset + $num must be lower than or equal to the length of the buffer $buf.", __func__, FILE_NAME, __LINE__);
  }
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  ERR_clear_error();
  
  int32_t read_length = SSL_read(ssl, buf + offset, num);
  
  if (!(read_length > 0)) {
    int32_t ssl_operation_error = SSL_get_error(ssl, read_length);
    
    assert(ssl_operation_error != SSL_ERROR_NONE);
    
    env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_read failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = read_length;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__peek(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The buffer $buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t num = stack[2].ival;
  
  if (num < 0) {
    num = buf_length;
  }
  
  int32_t offset = stack[3].ival;
  
  if (!(offset >= 0)) {
    return env->die(env, stack, "The offset $offset must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(offset + num <= buf_length)) {
    return env->die(env, stack, "The offset $offset + $num must be lower than or equal to the length of the buffer $buf.", __func__, FILE_NAME, __LINE__);
  }
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  ERR_clear_error();
  
  int32_t peek_length = SSL_peek(ssl, buf + offset, num);
  
  if (!(peek_length > 0)) {
    int32_t ssl_operation_error = SSL_get_error(ssl, peek_length);
    
    assert(ssl_operation_error != SSL_ERROR_NONE);
    
    env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_peek failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = peek_length;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__write(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The buffer $buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t num = stack[2].ival;
  
  if (num < 0) {
    num = buf_length;
  }
  
  int32_t offset = stack[3].ival;
  
  if (!(offset >= 0)) {
    return env->die(env, stack, "The offset $offset must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(offset + num <= buf_length)) {
    return env->die(env, stack, "The offset $offset + $num must be lower than or equal to the length of the buffer $buf.", __func__, FILE_NAME, __LINE__);
  }
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  ERR_clear_error();
  
  int32_t write_length = SSL_write(ssl, buf + offset, num);
  
  if (!(write_length > 0)) {
    int32_t ssl_operation_error = SSL_get_error(ssl, write_length);
    
    assert(ssl_operation_error != SSL_ERROR_NONE);
    
    env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_write failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = write_length;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__get_servername(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t type = stack[1].ival;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  const char* servername = SSL_get_servername(ssl, type);
  
  void* obj_servername = NULL;
  if (servername) {
    obj_servername = env->new_string_nolen(env , stack, servername);
  }
  
  stack[0].oval = obj_servername;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__set_tlsext_status_type(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t type = stack[1].ival;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  int64_t status = SSL_set_tlsext_status_type(ssl, type);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_set_tlsext_status_type failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  return 0;
}

int32_t SPVM__Net__SSLeay__set_SSL_CTX(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_ssl_ctx = stack[1].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  SSL_CTX* ctx = env->get_pointer(env, stack, obj_ssl_ctx);
  
  void* ret_ctx = SSL_set_SSL_CTX(ssl, ctx);
  
  if (!ret_ctx) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_set_SSL_CTX failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  void* obj_address_ret_ctx = env->new_pointer_object_by_name(env, stack, "Address", ret_ctx, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_ret_ctx;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::SSL_CTX", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_ret_ctx = stack[0].oval;
  
  env->set_field_object_by_name(env, stack, obj_self, "ssl_ctx", obj_ret_ctx, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  return 0;
}

int32_t SPVM__Net__SSLeay__set_mode(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  int64_t mode = stack[1].lval;
  
  int64_t ret = SSL_set_mode(ssl, mode);
  
  stack[0].lval = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__clear_mode(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  int64_t mode = stack[1].lval;
  
  int64_t ret = SSL_clear_mode(ssl, mode);
  
  stack[0].lval = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__get_mode(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  int64_t ret = SSL_get_mode(ssl);
  
  stack[0].lval = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__version(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  int32_t version = SSL_version(ssl);
  
  stack[0].ival = version;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__session_reused(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  int32_t ret = SSL_session_reused(ssl);
  
  stack[0].ival = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__get_cipher(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  const char* name = SSL_get_cipher(ssl);
  
  assert(name);
  
  void* obj_name = env->new_string_nolen(env, stack, name);
  
  stack[0].oval = obj_name;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__get_peer_certificate(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  X509* x509 = SSL_get_peer_certificate(ssl);
  
  void* obj_x509 = NULL;
  
  if (x509) {
    void* obj_address_x509 = env->new_pointer_object_by_name(env, stack, "Address", x509, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_address_x509;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::X509", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    obj_x509 = stack[0].oval;
  }
  
  stack[0].oval = obj_x509;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__get_shutdown(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  int32_t ret = SSL_get_shutdown(ssl);
  
  stack[0].ival = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__pending(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  int32_t ret = SSL_pending(ssl);
  
  stack[0].ival = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__get1_session(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  SSL_SESSION* ssl_session = SSL_get1_session(ssl);
  
  void* obj_ssl_session = NULL;
  
  if (ssl_session) {
    void* obj_address_ssl_session = env->new_pointer_object_by_name(env, stack, "Address", ssl_session, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_address_ssl_session;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::SSL_SESSION", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    obj_ssl_session = stack[0].oval;
  }
  
  stack[0].oval = obj_ssl_session;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__set_session(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_ssl_session = stack[1].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  SSL_SESSION* ssl_session = env->get_pointer(env, stack, obj_ssl_session);
  
  int32_t status = SSL_set_session(ssl, ssl_session);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_set_session failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  // SSL_SESSION_free is called in SSL_set_session
  env->set_no_free(env, stack, obj_ssl_session, 1);
  
  env->set_field_object_by_name(env, stack, obj_self, "ssl_session", obj_ssl_session, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  return 0;
}

int32_t SPVM__Net__SSLeay__get_certificate(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  X509* x509 = SSL_get_certificate(ssl);
  
  void* obj_x509 = NULL;
  
  if (x509) {
    void* obj_address_x509 = env->new_pointer_object_by_name(env, stack, "Address", x509, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_address_x509;
    env->call_class_method_by_name(env, stack, "Net::SSLeay::X509", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    obj_x509 = stack[0].oval;
    
    env->set_no_free(env, stack, obj_x509, 1);
  }
  
  stack[0].oval = obj_x509;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__get0_next_proto_negotiated(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_data_ref = stack[1].oval;
  
  int32_t* len_ref = stack[2].iref;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  if (!obj_data_ref) {
    return env->die(env, stack, "The data reference $data_ref must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t data_ref_length = env->length(env, stack, obj_data_ref);
  
  if (!(data_ref_length == 1)) {
    return env->die(env, stack, "The length of the data reference $data_ref must be 1.", __func__, FILE_NAME, __LINE__);
  }
  
  const unsigned char* data_ref_tmp[1] = {0};
  unsigned len_ref_tmp = -1;
  SSL_get0_next_proto_negotiated(ssl, data_ref_tmp, &len_ref_tmp);
  
  if (data_ref_tmp) {
    void* obj_data = env->new_string_nolen(env, stack, data_ref_tmp[0]);
    
    env->set_elem_object(env, stack, obj_data_ref, 0, obj_data);
  }
  
  *len_ref = len_ref_tmp;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__get0_alpn_selected(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_data_ref = stack[1].oval;
  
  int32_t* len_ref = stack[2].iref;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  if (!obj_data_ref) {
    return env->die(env, stack, "The data reference $data_ref must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t data_ref_length = env->length(env, stack, obj_data_ref);
  
  if (!(data_ref_length == 1)) {
    return env->die(env, stack, "The length of the data reference $data_ref must be 1.", __func__, FILE_NAME, __LINE__);
  }
  
  const unsigned char* data_ref_tmp[1] = {0};
  unsigned int len_ref_tmp = -1;
  SSL_get0_alpn_selected(ssl, data_ref_tmp, &len_ref_tmp);
  
  if (data_ref_tmp) {
    void* obj_data = env->new_string_nolen(env, stack, data_ref_tmp[0]);
    
    env->set_elem_object(env, stack, obj_data_ref, 0, obj_data);
  }
  
  *len_ref = len_ref_tmp;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__get_peer_cert_chain(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  STACK_OF(X509)* stack_of_x509 = SSL_get_peer_cert_chain(ssl);
  
  void* obj_x509s = NULL;
  
  if (stack_of_x509) {
    int32_t length = sk_X509_num(stack_of_x509);
    obj_x509s = env->new_object_array_by_name(env, stack, "Net::SSLeay::X509", length, &error_id, __func__, FILE_NAME, __LINE__);
    
    for (int32_t i = 0; i < length; i++) {
      X509* x509 = sk_X509_value(stack_of_x509, i);
      X509_up_ref(x509);
      
      void* obj_address_x509 = env->new_pointer_object_by_name(env, stack, "Address", x509, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      stack[0].oval = obj_address_x509;
      env->call_class_method_by_name(env, stack, "Net::SSLeay::X509", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      void* obj_x509 = stack[0].oval;
      
      env->set_elem_object(env, stack, obj_x509s, i, obj_x509);
    }
  }
  
  stack[0].oval = obj_x509s;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    SSL_free(ssl);
  }
  
  return 0;
}

