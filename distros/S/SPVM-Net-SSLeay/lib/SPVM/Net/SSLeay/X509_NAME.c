// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/X509_NAME.c";

int32_t SPVM__Net__SSLeay__X509_NAME__oneline(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_NAME* x509_name = env->get_pointer(env, stack, obj_self);
  
  char* ret = X509_NAME_oneline(x509_name, NULL, 0);
  
  if (!ret) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]SSL_CTX_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  void* obj_ret = env->new_string_nolen(env, stack, ret);
  
  free(ret);
  
  stack[0].oval = obj_ret;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_NAME__get_text_by_NID(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t nid = stack[1].ival;
  
  void* obj_buf = stack[2].oval;
  
  char* buf = NULL;
  if (!obj_buf) {
    buf = (char*)env->get_chars(env, stack, obj_buf);
  }
  
  int32_t len = stack[3].ival;
  
  if (obj_buf && len < 0) {
    len = env->length(env, stack, obj_buf);
  }
  
  X509_NAME* x509_name = env->get_pointer(env, stack, obj_self);
  
  int32_t length = X509_NAME_get_text_by_NID(x509_name, nid, buf, len);
  
  stack[0].ival = length;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_NAME__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_NAME* x509_name = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_NAME_free(x509_name);
  }
  
  return 0;
}

