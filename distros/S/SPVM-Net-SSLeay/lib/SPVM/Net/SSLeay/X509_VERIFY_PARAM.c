// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/X509_VERIFY_PARAM.c";

int32_t SPVM__Net__SSLeay__X509_VERIFY_PARAM__set_hostflags(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t flags = stack[1].ival;
  
  X509_VERIFY_PARAM* self = env->get_pointer(env, stack, obj_self);
  
  X509_VERIFY_PARAM_set_hostflags(self, flags);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_VERIFY_PARAM__set1_host(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_name = stack[1].oval;
  
  if (!obj_name) {
    return env->die(env, stack, "The host name $name must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t namelen = stack[2].ival;
  
  int32_t name_length = env->length(env, stack, obj_name);
    
  if (namelen == 0) {
    namelen = name_length;
  }
  
  if (!(namelen <= name_length)) {
    return env->die(env, stack, "The length $namelen must be greater than or equal to the length of the host name $name.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* name = env->get_chars(env, stack, obj_name);
  
  X509_VERIFY_PARAM* self = env->get_pointer(env, stack, obj_self);
  
  int32_t status = X509_VERIFY_PARAM_set1_host(self, name, namelen);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_VERIFY_PARAM_set1_host failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_VERIFY_PARAM__set_flags(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int64_t flags = stack[1].lval;
  
  X509_VERIFY_PARAM* self = env->get_pointer(env, stack, obj_self);
  
  int32_t status = X509_VERIFY_PARAM_set_flags(self, flags);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_VERIFY_PARAM_set_flags failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_VERIFY_PARAM__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_VERIFY_PARAM* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_VERIFY_PARAM_free(self);
  }
  
  return 0;
}
