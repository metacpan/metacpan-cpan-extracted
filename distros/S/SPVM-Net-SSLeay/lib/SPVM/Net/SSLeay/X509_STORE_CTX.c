// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>

static const char* FILE_NAME = "Net/SSLeay/X509_STORE_CTX.c";

// Instance Methods
int32_t SPVM__Net__SSLeay__X509_STORE_CTX__set_error(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t s = stack[1].ival;
  
  X509_STORE_CTX* x509_store_ctx = env->get_pointer(env, stack, obj_self);
  
  X509_STORE_CTX_set_error(x509_store_ctx, s);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE_CTX__get_error(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_STORE_CTX* x509_store_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t error = X509_STORE_CTX_get_error(x509_store_ctx);
  
  stack[0].ival = error;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE_CTX__get_error_depth(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_STORE_CTX* x509_store_ctx = env->get_pointer(env, stack, obj_self);
  
  int32_t error_depth = X509_STORE_CTX_get_error_depth(x509_store_ctx);
  
  stack[0].ival = error_depth;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE_CTX__get_current_cert(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_STORE_CTX* x509_store_ctx = env->get_pointer(env, stack, obj_self);
  
  X509* x509 = X509_STORE_CTX_get_current_cert(x509_store_ctx);
  
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

int32_t SPVM__Net__SSLeay__X509_STORE_CTX__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_STORE_CTX* x509_store_ctx = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_STORE_CTX_free(x509_store_ctx);
  }
  
  return 0;
}
