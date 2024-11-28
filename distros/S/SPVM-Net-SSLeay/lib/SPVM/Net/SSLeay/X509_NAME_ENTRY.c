// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/X509_NAME_ENTRY.c";

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

