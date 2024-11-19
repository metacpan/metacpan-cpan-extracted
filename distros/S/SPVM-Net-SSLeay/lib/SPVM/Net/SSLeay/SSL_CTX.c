// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/SSL_CTX.c";

__thread SPVM_ENV* thread_env;

int32_t SPVM__Net__SSLeay__SSL_CTX__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_ssl_method = stack[0].oval;
  
  SSL_METHOD* ssl_method = env->get_pointer(env, stack, obj_ssl_method);
  
  SSL_CTX* ssl_ctx = SSL_CTX_new(ssl_method);
  
  if (!ssl_ctx) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  // OpenSSL 1.1+ default
  SSL_CTX_set_mode(ssl_ctx, SSL_MODE_AUTO_RETRY);
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::SSL_CTX", ssl_ctx, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  env->call_instance_method_by_name(env, stack, "init", 0, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  thread_env = env;
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_mode(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int64_t mode = stack[1].lval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int64_t new_mode = SSL_CTX_set_mode(ssl_ctx, mode);
  
  stack[0].lval = new_mode;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_verify(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t mode = stack[1].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  SSL_CTX_set_verify(ssl_ctx, mode, NULL);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__get0_param(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  X509_VERIFY_PARAM* x509_verify_param = SSL_CTX_get0_param(ssl_ctx);
  
  void* obj_address_x509_verify_param = env->new_pointer_object_by_name(env, stack, "Address", x509_verify_param, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_x509_verify_param;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_VERIFY_PARAM", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_x509_verify_param = stack[0].oval;
  
  env->set_no_free(env, stack, obj_x509_verify_param, 1);
  
  stack[0].oval = obj_x509_verify_param;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_default_verify_paths(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_set_default_verify_paths(ssl_ctx);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_load_verify_locations failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__use_certificate_file(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_file = stack[1].oval;
  
  if (!obj_file) {
    return env->die(env, stack, "The file $file must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* file = (char*)env->get_chars(env, stack, obj_file);
  int32_t file_length = env->length(env, stack, obj_file);
  
  int32_t type = stack[2].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_use_certificate_file(ssl_ctx, file, type);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_load_verify_locations failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__use_certificate_chain_file(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_file = stack[1].oval;
  
  if (!obj_file) {
    return env->die(env, stack, "The file $file must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* file = (char*)env->get_chars(env, stack, obj_file);
  int32_t file_length = env->length(env, stack, obj_file);
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_use_certificate_chain_file(ssl_ctx, file);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_load_verify_locations failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__use_PrivateKey_file(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_file = stack[1].oval;
  
  if (!obj_file) {
    return env->die(env, stack, "The file $file must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* file = (char*)env->get_chars(env, stack, obj_file);
  int32_t file_length = env->length(env, stack, obj_file);
  
  int32_t type = stack[2].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_use_PrivateKey_file(ssl_ctx, file, type);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_use_PrivateKey_file failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_cipher_list(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_str = stack[1].oval;
  
  if (!obj_str) {
    return env->die(env, stack, "The cipher list $str must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* str = (char*)env->get_chars(env, stack, obj_str);
  int32_t str_length = env->length(env, stack, obj_str);
  
  int32_t type = stack[2].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_set_cipher_list(ssl_ctx, str);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_load_verify_locations failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_ciphersuites(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !(OPENSSL_VERSION_NUMBER >= 0x10100000)
  env->die(env, stack, "The set_ciphersuites method in the Net::SSLeay::SSL_CTX class is not supported in this system(!(OPENSSL_VERSION_NUMBER >= 0x10100000))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_str = stack[1].oval;
  
  if (!obj_str) {
    return env->die(env, stack, "The ciphersuites $str must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* str = (char*)env->get_chars(env, stack, obj_str);
  int32_t str_length = env->length(env, stack, obj_str);
  
  int32_t type = stack[2].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_set_ciphersuites(ssl_ctx, str);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_load_verify_locations failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Net__SSLeay__SSL_CTX__load_verify_locations(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  void* obj_file = stack[1].oval;
  char* file = (char*)env->get_chars(env, stack, obj_file);
  
  void* obj_path = stack[2].oval;
  char* path = (char*)env->get_chars(env, stack, obj_path);
  
  int32_t status = SSL_CTX_load_verify_locations(ssl_ctx, file, path);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_load_verify_locations failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__get_cert_store(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  X509_STORE* x509_store = SSL_CTX_get_cert_store(ssl_ctx);
  
  void* obj_address_x509_store = env->new_pointer_object_by_name(env, stack, "Address", x509_store, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_x509_store;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_STORE", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_x509_store = stack[0].oval;
  
  env->set_no_free(env, stack, obj_x509_store, 1);
  
  stack[0].oval = obj_x509_store;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_options(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int64_t options = stack[1].lval;
  
  int64_t ret = SSL_CTX_set_options(ssl_ctx, options);
  
  stack[0].lval = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__get_options(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int64_t ret = SSL_CTX_get_options(ssl_ctx);
  
  stack[0].lval = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__clear_options(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int64_t options = stack[1].lval;
  
  int64_t ret = SSL_CTX_clear_options(ssl_ctx, options);
  
  stack[0].lval = ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_alpn_protos(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_protos = stack[1].oval;
  
  if (!obj_protos) {
    return env->die(env, stack, "The protocols $protos must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* protos = env->get_chars(env, stack, obj_protos);
  
  int32_t protos_len = stack[2].ival;
  
  if (protos_len < 0) {
    protos_len = env->length(env, stack, obj_protos);
  }
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_set_alpn_protos(ssl_ctx, protos, protos_len);
  
  if (!(status == 0)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_set_alpn_protos failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_tmp_ecdh(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_ecdh = stack[1].oval;
  
  if (!obj_ecdh) {
    return env->die(env, stack, "The ECDH parameters $ecdh must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  EC_KEY* ecdh = env->get_pointer(env, stack, obj_ecdh);
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int64_t status = SSL_CTX_set_tmp_ecdh(ssl_ctx, ecdh);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_set_tmp_ecdh failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].lval = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set1_groups_list(SPVM_ENV* env, SPVM_VALUE* stack) {

#if !(OPENSSL_VERSION_NUMBER >= 0x30000000L)
  env->die(env, stack, "SSL_CTX_set1_groups_list is not supported on this system(!(OPENSSL_VERSION_NUMBER >= 0x30000000L))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_list = stack[1].oval;
  
  if (!obj_list) {
    return env->die(env, stack, "The group list $list must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* list = env->get_chars(env, stack, obj_list);
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int64_t status = SSL_CTX_set1_groups_list(ssl_ctx, list);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_set1_groups_list failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].lval = status;
  
  return 0;
#endif
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set1_curves_list(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_list = stack[1].oval;
  
  if (!obj_list) {
    return env->die(env, stack, "The group list $list must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* list = env->get_chars(env, stack, obj_list);
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int64_t status = SSL_CTX_set1_curves_list(ssl_ctx, list);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_set1_curves_list failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].lval = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_session_cache_mode(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int64_t mode = stack[1].lval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int64_t ret_mode = SSL_CTX_set_session_cache_mode(ssl_ctx, mode);
  
  stack[0].lval = ret_mode;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_ecdh_auto(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t state = stack[1].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int64_t status = SSL_CTX_set_ecdh_auto(ssl_ctx, state);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_set_ecdh_auto failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].lval = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_tmp_dh(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_dh = stack[1].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  if (!obj_dh) {
    return env->die(env, stack, "The DH object $dh must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  DH* dh = env->get_pointer(env, stack, obj_dh);
  
  int64_t status = SSL_CTX_set_tmp_dh(ssl_ctx, dh);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_set_tmp_dh failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].lval = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_post_handshake_auth(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t val = stack[1].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  SSL_CTX_set_post_handshake_auth(ssl_ctx, val);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__use_PrivateKey(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_evp_pkey = stack[1].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  if (!obj_evp_pkey) {
    return env->die(env, stack, "The EVP_PKEY object $pkey must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  EVP_PKEY* evp_pkey = env->get_pointer(env, stack, obj_evp_pkey);
  
  int32_t status = SSL_CTX_use_PrivateKey(ssl_ctx, evp_pkey);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_use_PrivateKey failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  // SSL_CTX_use_PrivateKey increments the reference count of evp_pkey.
  {
    void* obj_pkeys_list = env->get_field_object_by_name(env, stack, obj_self, "pkeys_list", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    stack[0].oval = obj_pkeys_list;
    stack[1].oval = obj_evp_pkey;
    env->call_instance_method_by_name(env, stack, "push", 2, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_session_id_context(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_sid_ctx = stack[1].oval;
  
  if (!obj_sid_ctx) {
    return env->die(env, stack, "The context $sid_ctx must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* sid_ctx = env->get_chars(env, stack, obj_sid_ctx);
  
  int32_t sid_ctx_len = stack[2].ival;
  
  if (sid_ctx_len < 0) {
    sid_ctx_len = env->length(env, stack, obj_sid_ctx);
  }
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_set_session_id_context(ssl_ctx, sid_ctx, sid_ctx_len);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_set_session_id_context failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_min_proto_version(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t version = stack[1].ival;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t status = SSL_CTX_set_min_proto_version(ssl_ctx, version);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_set_min_proto_version failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_client_CA_list(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_list = stack[1].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  if (!obj_list) {
    return env->die(env, stack, "The list $list must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  STACK_OF(X509_NAME)* sk_x509_name = sk_X509_NAME_new_null();
  
  int32_t list_length = env->length(env, stack, obj_list);
  
  for (int32_t i = 0; i < list_length; i++) {
    void* obj_x509_name = env->get_elem_object(env, stack, obj_list, i);
    X509_NAME* x509_name = env->get_pointer(env, stack, obj_x509_name);
    sk_X509_NAME_push(sk_x509_name, x509_name);
  }
  
  SSL_CTX_set_client_CA_list(ssl_ctx, sk_x509_name);
  
  sk_X509_NAME_free(sk_x509_name);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__add_client_CA(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_x509 = stack[1].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  if (!obj_x509) {
    return env->die(env, stack, "The X509 object $cacert must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  X509* x509 = env->get_pointer(env, stack, obj_x509);
  
  int32_t status = SSL_CTX_add_client_CA(ssl_ctx, x509);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_set_min_proto_version failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__add_extra_chain_cert(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_x509 = stack[1].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  if (!obj_x509) {
    return env->die(env, stack, "The X509 object $x509 must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  X509* x509 = env->get_pointer(env, stack, obj_x509);
  
  int32_t status = SSL_CTX_add_extra_chain_cert(ssl_ctx, x509);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_add_extra_chain_cert failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  env->set_no_free(env, stack, obj_x509, 1);
  
  stack[0].ival = status;
  
  return 0;
}

static int tlsext_servername_callback(SSL *ssl, int *al, void *arg) {
  
  int32_t error_id = 0;
  
  SPVM_ENV* env = (SPVM_ENV*)((void**)arg)[0];
  
  SPVM_VALUE* stack = (SPVM_VALUE*)((void**)arg)[1];
  
  void* obj_cb = ((void**)arg)[2];
  
  void* obj_arg = ((void**)arg)[3];
  
  void* obj_address_ssl = env->new_pointer_object_by_name(env, stack, "Address", ssl, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_ssl;
  env->call_class_method_by_name(env, stack, "Net::SSLeay", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_ssl = stack[0].oval;
  
  env->set_no_free(env, stack, obj_ssl, 1);
  
  stack[0].oval = obj_cb;
  stack[1].oval = obj_ssl;
  int32_t al_tmp = 0;
  stack[2].iref = &al_tmp;
  stack[3].oval = obj_arg;
  
  env->call_instance_method_by_name(env, stack, "", 4, &error_id, __func__, FILE_NAME, __LINE__);
  int32_t ret = stack[0].ival;
  
  *al = al_tmp;
  
  if (error_id) {
    fprintf(env->spvm_stderr(env, stack), "[An exception is converted to a warning in native tlsext_servername_callback function]");
    env->print_stderr(env, stack, env->get_exception(env, stack));
  }
  
  return ret;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_tlsext_servername_callback(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_cb = stack[1].oval;
  
  void* obj_arg = stack[2].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int (*native_cb)(SSL *s, int *al, void *arg) = NULL;
  
  if (obj_cb) {
    native_cb = &tlsext_servername_callback;
    
    void* native_args[4] = {0};
    native_args[0] = env;
    native_args[1] = stack;
    native_args[2] = obj_cb;
    native_args[3] = obj_arg;
    SSL_CTX_set_tlsext_servername_arg(ssl_ctx, native_args);
  }
  
  int64_t status = SSL_CTX_set_tlsext_servername_callback(ssl_ctx, native_cb);
  
  assert(status == 1);
  
  stack[0].lval = status;
  
  return 0;
}

static int tlsext_status_cb(SSL *ssl, void *arg) {
  
  int32_t error_id = 0;
  
  SPVM_ENV* env = (SPVM_ENV*)((void**)arg)[0];
  
  SPVM_VALUE* stack = (SPVM_VALUE*)((void**)arg)[1];
  
  void* obj_cb = ((void**)arg)[2];
  
  void* obj_arg = ((void**)arg)[3];
  
  void* obj_address_ssl = env->new_pointer_object_by_name(env, stack, "Address", ssl, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_ssl;
  env->call_class_method_by_name(env, stack, "Net::SSLeay", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_ssl = stack[0].oval;
  
  env->set_no_free(env, stack, obj_ssl, 1);
  
  stack[0].oval = obj_cb;
  stack[1].oval = obj_ssl;
  stack[2].oval = obj_arg;
  
  env->call_instance_method_by_name(env, stack, "", 3, &error_id, __func__, FILE_NAME, __LINE__);
  int32_t ret = stack[0].ival;
  
  if (error_id) {
    fprintf(env->spvm_stderr(env, stack), "[An exception is converted to a warning in native tlsext_status_cb function]");
    env->print_stderr(env, stack, env->get_exception(env, stack));
  }
  
  return ret;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_tlsext_status_cb(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_cb = stack[1].oval;
  
  void* obj_arg = stack[2].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  int (*native_cb)(SSL *s, void *arg) = NULL;
  
  if (obj_cb) {
    native_cb = &tlsext_status_cb;
    
    void* native_args[4] = {0};
    native_args[0] = env;
    native_args[1] = stack;
    native_args[2] = obj_cb;
    native_args[3] = obj_arg;
    SSL_CTX_set_tlsext_status_arg(ssl_ctx, native_args);
  }
  
  int64_t status = SSL_CTX_set_tlsext_status_cb(ssl_ctx, native_cb);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_set_tlsext_status_cb failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].lval = status;
  
  return 0;
}

static int default_passwd_cb(char *buf, int size, int rwflag, void *arg) {
  
  int32_t error_id = 0;
  
  SPVM_ENV* env = (SPVM_ENV*)((void**)arg)[0];
  
  SPVM_VALUE* stack = (SPVM_VALUE*)((void**)arg)[1];
  
  void* obj_cb = ((void**)arg)[2];
  
  void* obj_arg = ((void**)arg)[3];
  
  void* obj_buf = env->new_string(env, stack, buf, size);
  
  stack[0].oval = obj_cb;
  stack[1].oval = obj_buf;
  stack[2].ival = size;
  stack[3].ival = rwflag;
  stack[4].oval = obj_arg;
  
  env->call_instance_method_by_name(env, stack, "", 4, &error_id, __func__, FILE_NAME, __LINE__);
  int32_t ret = stack[0].ival;
  
  memcpy(buf, env->get_chars(env, stack, obj_buf), size);
  
  if (error_id) {
    fprintf(env->spvm_stderr(env, stack), "[An exception is converted to a warning in native default_passwd_cb function]");
    env->print_stderr(env, stack, env->get_exception(env, stack));
  }
  
  return ret;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_default_passwd_cb(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_cb = stack[1].oval;
  
  void* obj_arg = stack[2].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  pem_password_cb* native_cb = NULL;
  
  if (obj_cb) {
    native_cb = &default_passwd_cb;
    
    void* native_args[4] = {0};
    native_args[0] = env;
    native_args[1] = stack;
    native_args[2] = obj_cb;
    native_args[3] = obj_arg;
    SSL_CTX_set_default_passwd_cb_userdata(ssl_ctx, native_args);
  }
  
  SSL_CTX_set_default_passwd_cb(ssl_ctx, native_cb);
  
  return 0;
}

static unsigned int psk_client_callback(SSL *ssl, const char *hint, char *identity, unsigned int max_identity_len, unsigned char *psk, unsigned int max_psk_len) {
  
  int32_t error_id = 0;
  
  SPVM_ENV* env = thread_env;
  
  SPVM_VALUE* stack = env->new_stack(env);
  
  SSL_CTX* ssl_ctx = SSL_get_SSL_CTX(ssl);
  
  int32_t ret = 0;
  if (!ssl_ctx) {
    env->die(env, stack, "SSL_get_SSL_CTX(ssl) failed.", __func__, FILE_NAME, __LINE__);
    
    void* obj_exception = env->get_exception(env, stack);
    const char* exception = env->get_chars(env, stack, obj_exception);
    
    fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "[An exception thrown in native psk_client_callback function is converted to a warning]\n");
    
    env->print_stderr(env, stack, obj_exception);
    
    fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "\n");
  }
  else {
    char* tmp_buffer = env->get_stack_tmp_buffer(env, stack);
    snprintf(tmp_buffer, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE, "%p", ssl_ctx);
    stack[0].oval = env->new_string(env, stack, tmp_buffer, strlen(tmp_buffer));
    env->call_instance_method_by_name(env, stack, "get_psk_client_cb", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      void* obj_exception = env->get_exception(env, stack);
      const char* exception = env->get_chars(env, stack, obj_exception);
      
      fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "[An exception thrown in native psk_client_callback function is converted to a warning]\n");
      
      env->print_stderr(env, stack, obj_exception);
      
      fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "\n");
    }
    else {
      // Return value of get_psk_client_cb method
      void* obj_cb = stack[0].oval;
      
      if (!obj_cb) {
        env->die(env, stack, "get_psk_client_cb method returns undef.", __func__, FILE_NAME, __LINE__);
        
        void* obj_exception = env->get_exception(env, stack);
        const char* exception = env->get_chars(env, stack, obj_exception);
        
        fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "[An exception thrown in native psk_client_callback function is converted to a warning]\n");
        
        env->print_stderr(env, stack, obj_exception);
        
        fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "\n");
      }
      else {
        void* obj_identity = env->new_string(env, stack, identity, max_identity_len);
        
        void* obj_psk = env->new_string(env, stack, psk, max_psk_len);
        
        stack[0].oval = obj_cb;
        stack[1].oval = obj_identity;
        stack[2].ival = max_identity_len;
        stack[3].oval = psk;
        stack[4].ival = max_psk_len;
        
        env->call_instance_method_by_name(env, stack, "", 5, &error_id, __func__, FILE_NAME, __LINE__);
        if (error_id) {
          void* obj_exception = env->get_exception(env, stack);
          const char* exception = env->get_chars(env, stack, obj_exception);
          
          fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "[An exception thrown in native psk_client_callback function is converted to a warning]\n");
          
          env->print_stderr(env, stack, obj_exception);
          
          fprintf(env->api->runtime->get_spvm_stderr(env->runtime), "\n");
        }
        
        int32_t ret = stack[0].ival;
        
        memcpy(identity, env->get_chars(env, stack, obj_identity), max_identity_len);
        
        memcpy(psk, env->get_chars(env, stack, obj_psk), max_psk_len);
      }
    }
  }
  
  env->free_stack(env, stack);
  
  return ret;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__set_psk_client_callback(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_cb = stack[1].oval;
  
  void* obj_arg = stack[2].oval;
  
  SSL_CTX* ssl_ctx = env->get_pointer(env, stack, obj_self);
  
  unsigned int (*native_cb)(SSL *ssl, const char *hint, char *identity, unsigned int max_identity_len, unsigned char *psk, unsigned int max_psk_len) = NULL;
  
  if (obj_cb) {
    native_cb = &psk_client_callback;
  }
  
  stack[0].oval = obj_self;
  char* tmp_buffer = env->get_stack_tmp_buffer(env, stack);
  snprintf(tmp_buffer, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE, "%p", ssl_ctx);
  stack[1].oval = env->new_string(env, stack, tmp_buffer, strlen(tmp_buffer));
  stack[2].oval = obj_cb;
  env->call_instance_method_by_name(env, stack, "set_psk_client_cb", 3, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  SSL_CTX_set_psk_client_callback(ssl_ctx, native_cb);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_CTX__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  SSL_CTX* pointer = env->get_pointer(env, stack, obj_self);
  
  stack[0].oval = obj_self;
  char* tmp_buffer = env->get_stack_tmp_buffer(env, stack);
  snprintf(tmp_buffer, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE, "%p", pointer);
  stack[1].oval = env->new_string(env, stack, tmp_buffer, strlen(tmp_buffer));
  env->call_instance_method_by_name(env, stack, "delete_psk_client_cb", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  if (!env->no_free(env, stack, obj_self)) {
    SSL_CTX_free(pointer);
  }
  
  return 0;
}

