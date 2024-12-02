// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/X509_NAME.c";

int32_t SPVM__Net__SSLeay__X509_NAME__oneline(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_NAME* self = env->get_pointer(env, stack, obj_self);
  
  char* ret = X509_NAME_oneline(self, NULL, 0);
  
  if (!ret) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_NAME_oneline failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
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
  
  X509_NAME* self = env->get_pointer(env, stack, obj_self);
  
  int32_t length = X509_NAME_get_text_by_NID(self, nid, buf, len);
  
  stack[0].ival = length;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_NAME__get_entry(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t loc = stack[1].ival;
  
  X509_NAME* self = env->get_pointer(env, stack, obj_self);
  
  X509_NAME_ENTRY* name_entry = X509_NAME_get_entry(self, loc);
  
  if (!name_entry) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]X509_NAME_get_entry failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_address_name_entry = env->new_pointer_object_by_name(env, stack, "Address", name_entry, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  stack[0].oval = obj_address_name_entry;
  env->call_class_method_by_name(env, stack, "Net::SSLeay::X509_NAME_ENTRY", "new_with_pointer", 1, &error_id, __func__, FILE_NAME, __LINE__);  
  if (error_id) { return error_id; }
  void* obj_name_entry = stack[0].oval;
  env->set_no_free(env, stack, obj_name_entry, 1);
  
  env->set_field_object_by_name(env, stack, obj_name_entry, "ref_x509_name", obj_self, &error_id, __func__, FILE_NAME, __LINE__); 
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_name_entry;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_NAME__get_index_by_NID(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t nid = stack[1].ival;
  
  int32_t lastpos = stack[2].ival;
  
  X509_NAME* self = env->get_pointer(env, stack, obj_self);
  
  int32_t index = X509_NAME_get_index_by_NID(self, nid, lastpos);
  
  stack[0].ival = index;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_NAME__entry_count(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t nid = stack[1].ival;
  
  int32_t lastpos = stack[2].ival;
  
  X509_NAME* self = env->get_pointer(env, stack, obj_self);
  
  int32_t entry_count = X509_NAME_entry_count(self);
  
  stack[0].ival = entry_count;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_NAME__get_index_by_OBJ(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_obj = stack[1].oval;
  
  int32_t lastpos = stack[2].ival;
  
  X509_NAME* self = env->get_pointer(env, stack, obj_self);
  
  ASN1_OBJECT* obj = env->get_pointer(env, stack, obj_obj);
  
  int32_t index = X509_NAME_get_index_by_OBJ(self, obj, lastpos);
  
  stack[0].ival = index;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__X509_NAME__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  X509_NAME* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    X509_NAME_free(self);
  }
  
  return 0;
}

