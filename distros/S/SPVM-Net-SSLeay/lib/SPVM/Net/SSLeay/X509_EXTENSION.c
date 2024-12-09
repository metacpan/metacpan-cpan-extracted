// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/X509_EXTENSION.c";

int32_t SPVM__Net__SSLeay__X509_EXTENSION__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  X509_EXTENSION* self = X509_EXTENSION_new();
  
  if (!self) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_EXTENSION_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::X509_EXTENSION", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_EXTENSION__get_data(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_EXTENSION* self = env->get_pointer(env, stack, obj_self);
  
  ASN1_OCTET_STRING* asn1_string_tmp = X509_EXTENSION_get_data(self);
  
  ASN1_OCTET_STRING* asn1_string = ASN1_OCTET_STRING_dup(asn1_string_tmp);
  
  void* obj_address_asn1_string = env->new_pointer_object_by_name(env, stack, "Address", asn1_string, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_asn1_string;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::ASN1_OCTET_STRING", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);  
  if (error_id) { return error_id; }
  void* obj_asn1_string = stack[0].oval;
  
  stack[0].oval = obj_asn1_string;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_EXTENSION__get_object(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_EXTENSION* self = env->get_pointer(env, stack, obj_self);
  
  ASN1_OBJECT* asn1_object = X509_EXTENSION_get_object(self);
  
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

int32_t SPVM__Net__SSLeay__X509_EXTENSION__get_critical(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_EXTENSION* self = env->get_pointer(env, stack, obj_self);
  
  int32_t critical = X509_EXTENSION_get_critical(self);
  
  stack[0].ival = critical;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_EXTENSION__set_object(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_object = stack[1].oval;
  
  X509_EXTENSION* self = env->get_pointer(env, stack, obj_self);
  
  if (!obj_object) {
    return env->die(env, stack, "The ASN1_OBJECT object $obj must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  ASN1_OBJECT* object = env->get_pointer(env, stack, obj_object);
  
  int32_t status = X509_EXTENSION_set_object(self, object);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_EXTENSION_set_object failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_EXTENSION__set_critical(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t critical = stack[1].ival;
  
  X509_EXTENSION* self = env->get_pointer(env, stack, obj_self);
  
  int32_t status = X509_EXTENSION_set_critical(self, critical);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_EXTENSION_set_critical failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_EXTENSION__set_data(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_data = stack[1].oval;
  
  X509_EXTENSION* self = env->get_pointer(env, stack, obj_self);
  
  if (!obj_data) {
    return env->die(env, stack, "The ASN1_OCTET_STRING object $data must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  ASN1_OCTET_STRING* data = env->get_pointer(env, stack, obj_data);
  
  int32_t status = X509_EXTENSION_set_data(self, data);
  
  if (!(status == 1)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_EXTENSION_set_data failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_EXTENSION__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_EXTENSION* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_EXTENSION_free(self);
  }
  
  return 0;
}

