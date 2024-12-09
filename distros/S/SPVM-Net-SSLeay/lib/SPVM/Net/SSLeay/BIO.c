// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/bio.h>
#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/BIO.c";

int32_t SPVM__Net__SSLeay__BIO__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  BIO* self = BIO_new(BIO_s_mem());
  
  if (!self) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]BIO_new failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::BIO", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__BIO__read(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_data = stack[1].oval;
  
  if (!obj_data) {
    return env->die(env, stack, "The data $data must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* data = (char*)env->get_chars(env, stack, obj_data);
  int32_t data_length = env->length(env, stack, obj_data);
  
  int32_t dlen = stack[2].ival;
  
  if (dlen < 0) {
    dlen = data_length;
  }
  
  if (!(dlen <= data_length)) {
    return env->die(env, stack, "The length $dlen must be lower than or equal to the length of the data $data.", __func__, FILE_NAME, __LINE__);
  }
  
  BIO* self = env->get_pointer(env, stack, obj_self);
  
  int32_t read_length = BIO_read(self, data, dlen);
  
  if (read_length < 0) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]BIO_read failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = read_length;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__BIO__write(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_data = stack[1].oval;
  
  if (!obj_data) {
    return env->die(env, stack, "The data $data must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* data = (char*)env->get_chars(env, stack, obj_data);
  int32_t data_length = env->length(env, stack, obj_data);
  
  int32_t dlen = stack[2].ival;
  
  if (dlen < 0) {
    dlen = data_length;
  }
  
  if (!(dlen <= data_length)) {
    return env->die(env, stack, "The length $dlen must be lower than or equal to the length of the data $data.", __func__, FILE_NAME, __LINE__);
  }
  
  BIO* self = env->get_pointer(env, stack, obj_self);
  
  int32_t write_length = BIO_write(self, data, dlen);
  
  if (write_length < 0) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]BIO_write failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = write_length;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__BIO__new_file(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_filename = stack[0].oval;
  
  void* obj_mode = stack[1].oval;
  
  if (!obj_filename) {
    return env->die(env, stack, "The file name $filename must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* filename = env->get_chars(env, stack, obj_filename);
  
  if (!obj_mode) {
    return env->die(env, stack, "The mode $mode must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* mode = env->get_chars(env, stack, obj_mode);
  
  BIO* self = BIO_new_file(filename, mode);
  
  if (!self) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]BIO_new_file failed:%s. $filename:%s.", ssl_error_string, filename, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::BIO", self, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__BIO__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  BIO* self = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    BIO_free(self);
  }
  
  return 0;
}

