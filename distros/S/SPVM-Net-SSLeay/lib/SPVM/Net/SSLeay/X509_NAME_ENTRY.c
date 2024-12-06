// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/X509_NAME_ENTRY.c";

int32_t SPVM__Net__SSLeay__X509_NAME_ENTRY__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  X509_NAME_ENTRY* self = X509_NAME_ENTRY_new();
  
  if (!self) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_NAME_ENTRY_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::X509_NAME_ENTRY", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_NAME_ENTRY__get_data(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_NAME_ENTRY* self = env->get_pointer(env, stack, obj_self);
  
  ASN1_STRING* asn1_string_tmp = X509_NAME_ENTRY_get_data(self);
  
  ASN1_STRING* asn1_string = ASN1_STRING_dup(asn1_string_tmp);
  
  void* obj_address_asn1_string = env->new_pointer_object_by_name(env, stack, "Address", asn1_string, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_asn1_string;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::ASN1_STRING", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);  
  if (error_id) { return error_id; }
  void* obj_asn1_string = stack[0].oval;
  
  stack[0].oval = obj_asn1_string;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_NAME_ENTRY__get_object(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_NAME_ENTRY* self = env->get_pointer(env, stack, obj_self);
  
  ASN1_OBJECT* asn1_object = X509_NAME_ENTRY_get_object(self);
  
  void* obj_address_asn1_object = env->new_pointer_object_by_name(env, stack, "Address", asn1_object, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_asn1_object;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::ASN1_OBJECT", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);  
  if (error_id) { return error_id; }
  void* obj_asn1_object = stack[0].oval;
  env->set_no_free(env, stack, obj_asn1_object, 1);
  
  stack[0].oval = obj_asn1_object;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_NAME_ENTRY__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_NAME_ENTRY* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_NAME_ENTRY_free(self);
  }
  
  return 0;
}

