// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/x509_vfy.h>

static const char* FILE_NAME = "Net/SSLeay/X509_STORE.c";

int32_t SPVM__Net__SSLeay__X509_STORE__add_cert(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  X509_STORE* x509_store = env->get_pointer(env, stack, obj_self);
  
  void* obj_x509 = stack[1].oval;
  X509* x509 = env->get_pointer(env, stack, obj_x509);
  
  int32_t status = X509_STORE_add_cert(x509_store, x509);
  
  if (!(status == 1)) {
    return env->die(env, stack, "X509_STORE_add_cert failed.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_certs_list = env->get_field_object_by_name(env, stack, obj_self, "certs_list", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_certs_list;
  stack[1].oval = obj_x509;
  env->call_instance_method_by_name(env, stack, "push", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE__set_flags(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  X509_STORE* x509_store = env->get_pointer(env, stack, obj_self);
  
  int64_t flags = stack[1].lval;
  
  int32_t status = X509_STORE_set_flags(x509_store, flags);
  
  if (!(status == 1)) {
    return env->die(env, stack, "X509_STORE_set_flags failed.", __func__, FILE_NAME, __LINE__);
  }
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE__add_crl(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  X509_STORE* x509_store = env->get_pointer(env, stack, obj_self);
  
  void* obj_x509_crl = stack[1].oval;
  X509_CRL* x509_crl = env->get_pointer(env, stack, obj_x509_crl);
  
  int32_t status = X509_STORE_add_crl(x509_store, x509_crl);
  
  if (!(status == 1)) {
    return env->die(env, stack, "X509_STORE_add_crl failed.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_crls_list = env->get_field_object_by_name(env, stack, obj_self, "crls_list", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_crls_list;
  stack[1].oval = obj_x509_crl;
  env->call_instance_method_by_name(env, stack, "push", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_STORE__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_STORE* x509_store = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_STORE_free(x509_store);
  }
  
  return 0;
}

