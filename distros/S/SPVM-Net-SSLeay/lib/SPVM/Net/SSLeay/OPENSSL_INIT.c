// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <assert.h>

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/crypto.h>

static const char* FILE_NAME = "Net/SSLeay/OPENSSL_INIT.c";

int32_t SPVM__Net__SSLeay__OPENSSL_INIT__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  OPENSSL_INIT_SETTINGS* self = OPENSSL_INIT_new();
  
  assert(self);
  
  void* obj_address_self = env->new_pointer_object_by_name(env, stack, "Address", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_self;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::OPENSSL_INIT_SETTINGS", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_self = stack[0].oval;
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__OPENSSL_INIT__set_config_filename(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !(OPENSSL_VERSION_NUMBER >= 0x1010102fL && !defined(LIBRESSL_VERSION_NUMBER))
  env->die(env, stack, "Net::SSLeay::OPENSSL_INIT#set_config_filename method is not supported on this system(!(OPENSSL_VERSION_NUMBER >= 0x1010102fL && !defined(LIBRESSL_VERSION_NUMBER)))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_filename = stack[1].oval;
  
  if (!obj_self) {
    return env->die(env, stack, "The OPENSSL_INIT_SETTINGS object $init must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OPENSSL_INIT_SETTINGS* self = env->get_pointer(env, stack, obj_self);
  
  if (!obj_filename) {
    return env->die(env, stack, "The file name $filename must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* filename = env->get_chars(env, stack, obj_filename);
  
  int32_t status = OPENSSL_INIT_set_config_filename(self, filename);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OPENSSL_INIT_set_config_filename failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Net__SSLeay__OPENSSL_INIT__set_config_file_flags(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !(OPENSSL_VERSION_NUMBER >= 0x30000000L && !defined(LIBRESSL_VERSION_NUMBER))
  env->die(env, stack, "Net::SSLeay::OPENSSL_INIT#set_config_file_flags method is not supported on this system(!(OPENSSL_VERSION_NUMBER >= 0x30000000L && !defined(LIBRESSL_VERSION_NUMBER)))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int64_t flags = stack[1].lval;
  
  if (!obj_self) {
    return env->die(env, stack, "The OPENSSL_INIT_SETTINGS object $init must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OPENSSL_INIT_SETTINGS* self = env->get_pointer(env, stack, obj_self);
  
  OPENSSL_INIT_set_config_file_flags(self, flags);
  
  return 0;
#endif
}

int32_t SPVM__Net__SSLeay__OPENSSL_INIT__set_config_appname(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !(OPENSSL_VERSION_NUMBER >= 0x1010102fL && !defined(LIBRESSL_VERSION_NUMBER))
  env->die(env, stack, "Net::SSLeay::OPENSSL_INIT#set_config_filename method is not supported on this system(!(OPENSSL_VERSION_NUMBER >= 0x1010102fL && !defined(LIBRESSL_VERSION_NUMBER)))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_name = stack[1].oval;
  
  if (!obj_self) {
    return env->die(env, stack, "The OPENSSL_INIT_SETTINGS object $init must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  OPENSSL_INIT_SETTINGS* self = env->get_pointer(env, stack, obj_self);
  
  if (!obj_name) {
    return env->die(env, stack, "The app name $name must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* name = env->get_chars(env, stack, obj_name);
  
  int32_t status = OPENSSL_INIT_set_config_appname(self, name);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]OPENSSL_INIT_set_config_appname failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}
