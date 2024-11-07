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

int32_t SPVM__Net__SSLeay__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_ssl_ctx = stack[0].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_ssl_ctx);
  
  SSL* ssl = SSL_new(ssl_ctx);
  
  if (!ssl) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char ssl_error_string[256] = {0};
    ERR_error_string_n(ssl_error, ssl_error_string, sizeof(ssl_error_string));
    
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

int32_t SPVM__Net__SSLeay__set_fd(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t fd = stack[1].ival;
  
  SSL* ssl = env->get_pointer(env, stack, obj_self);
  
  ERR_clear_error();
  
  int32_t status = SSL_set_fd(ssl, fd);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char ssl_error_string[256] = {0};
    ERR_error_string_n(ssl_error, ssl_error_string, sizeof(ssl_error_string));
    
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
    
    char ssl_error_string[256] = {0};
    ERR_error_string_n(ssl_error, ssl_error_string, sizeof(ssl_error_string));
    
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
    
    env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    int64_t ssl_error = ERR_peek_last_error();
    
    char ssl_error_string[256] = {0};
    ERR_error_string_n(ssl_error, ssl_error_string, sizeof(ssl_error_string));
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    env->die(env, stack, "[OpenSSL Error]SSL_connect failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
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
    
    env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    int64_t ssl_error = ERR_peek_last_error();
    
    char ssl_error_string[256] = {0};
    ERR_error_string_n(ssl_error, ssl_error_string, sizeof(ssl_error_string));
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    env->die(env, stack, "[OpenSSL Error]SSL_accept failed.", __func__, FILE_NAME, __LINE__);
    
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
    env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    assert(ssl_operation_error != SSL_ERROR_NONE);
    
    int64_t ssl_error = ERR_peek_last_error();
    
    char ssl_error_string[256] = {0};
    ERR_error_string_n(ssl_error, ssl_error_string, sizeof(ssl_error_string));
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    env->die(env, stack, "[OpenSSL Error]SSL_shutdown failed.", __func__, FILE_NAME, __LINE__);
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
    int32_t ssl_error = SSL_get_error(ssl, read_length);
    if (!(ssl_error == SSL_ERROR_ZERO_RETURN)) {
      int32_t ssl_operation_error = SSL_get_error(ssl, read_length);
      env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      int64_t ssl_error = ERR_peek_last_error();
      
      char ssl_error_string[256] = {0};
      ERR_error_string_n(ssl_error, ssl_error_string, sizeof(ssl_error_string));
      
      int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      env->die(env, stack, "[OpenSSL Error]SSL_read failed.", __func__, FILE_NAME, __LINE__);
      return error_id;
    }
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
    int32_t ssl_error = SSL_get_error(ssl, peek_length);
    if (!(ssl_error == SSL_ERROR_ZERO_RETURN)) {
      int32_t ssl_operation_error = SSL_get_error(ssl, peek_length);
      env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      int64_t ssl_error = ERR_peek_last_error();
      
      char ssl_error_string[256] = {0};
      ERR_error_string_n(ssl_error, ssl_error_string, sizeof(ssl_error_string));
      
      int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      env->die(env, stack, "[OpenSSL Error]SSL_peek failed.", __func__, FILE_NAME, __LINE__);
      return error_id;
    }
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
    int32_t ssl_error = SSL_get_error(ssl, write_length);
    if (!(ssl_error == SSL_ERROR_ZERO_RETURN)) {
      int32_t ssl_operation_error = SSL_get_error(ssl, write_length);
      env->set_field_int_by_name(env, stack, obj_self, "operation_error", ssl_operation_error, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      int64_t ssl_error = ERR_peek_last_error();
      
      char ssl_error_string[256] = {0};
      ERR_error_string_n(ssl_error, ssl_error_string, sizeof(ssl_error_string));
      
      int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      env->die(env, stack, "[OpenSSL Error]SSL_write failed.", __func__, FILE_NAME, __LINE__);
      return error_id;
    }
  }
  
  stack[0].ival = write_length;
  
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

