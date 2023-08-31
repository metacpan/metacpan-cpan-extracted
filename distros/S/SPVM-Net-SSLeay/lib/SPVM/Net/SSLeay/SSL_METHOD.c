// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>

static const char* FILE_NAME = "Net/SSLeay/SSL_METHOD.c";



int32_t SPVM__Net__SSLeay__SSL_METHOD__SSLv23_client_method(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  const SSL_METHOD* ssl_method = SSLv23_client_method();
  
  void* obj_ssl_method = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::SSL_METHOD", (void*)ssl_method, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_ssl_method;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_METHOD__SSLv23_server_method(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  const SSL_METHOD* ssl_method = SSLv23_server_method();
  
  void* obj_ssl_method = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::SSL_METHOD", (void*)ssl_method, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_ssl_method;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__SSL_METHOD__TLS_client_method(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !(OPENSSL_VERSION_NUMBER >= 0x10100000)
  env->die(env, stack, "The TLS_client_method method in the Net::SSLeay::SSL_METHOD class is not supported in this system(!(OPENSSL_VERSION_NUMBER >= 0x10100000))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  const SSL_METHOD* ssl_method = TLS_client_method();
  
  void* obj_ssl_method = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::SSL_METHOD", (void*)ssl_method, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_ssl_method;
  
  return 0;
#endif
}

int32_t SPVM__Net__SSLeay__SSL_METHOD__TLS_server_method(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !(OPENSSL_VERSION_NUMBER >= 0x10100000)
  env->die(env, stack, "The TLS_server_method method in the Net::SSLeay::SSL_METHOD class is not supported in this system(!(OPENSSL_VERSION_NUMBER >= 0x10100000))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  const SSL_METHOD* ssl_method = TLS_server_method();
  
  void* obj_ssl_method = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::SSL_METHOD", (void*)ssl_method, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_ssl_method;
  
  return 0;
#endif
}
