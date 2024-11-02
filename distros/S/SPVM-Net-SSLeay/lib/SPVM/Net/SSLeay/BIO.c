// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/bio.h>

static const char* FILE_NAME = "Net/SSLeay/BIO.c";

int32_t SPVM__Net__SSLeay__BIO__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  BIO* bio = BIO_new(BIO_s_mem());
  
  void* obj_bio = env->new_pointer_object_by_name(env, stack, "Net::SSLeay::BIO", bio, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_bio;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__BIO__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  BIO* bio = env->get_pointer(env, stack, obj_self);
  
  if (!env->no_free(env, stack, obj_self)) {
    BIO_free(bio);
  }
  
  return 0;
}

int32_t SPVM__Net__SSLeay__BIO__read(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_data = stack[1].oval;
  
  if (!obj_data) {
    return env->die(env, stack, "The $data must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* data = (char*)env->get_chars(env, stack, obj_data);
  int32_t data_length = env->length(env, stack, obj_data);
  
  int32_t dlen = stack[2].ival;
  
  if (dlen < 0) {
    dlen = data_length;
  }
  
  if (!(dlen <= data_length)) {
    return env->die(env, stack, "The $dlen must be lower than or equal to the length of the $data.", __func__, FILE_NAME, __LINE__);
  }
  
  BIO* bio = env->get_pointer(env, stack, obj_self);
  
  int32_t read_length = BIO_read(bio, data, dlen);
  
  if (read_length < 0) {
    return env->die(env, stack, "BIO_read failed.", __func__, FILE_NAME, __LINE__);
  }
  
  stack[0].ival = read_length;
  
  return 0;
}

int32_t SPVM__Net__SSLeay__BIO__write(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_data = stack[1].oval;
  
  if (!obj_data) {
    return env->die(env, stack, "The $data must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* data = (char*)env->get_chars(env, stack, obj_data);
  int32_t data_length = env->length(env, stack, obj_data);
  
  int32_t dlen = stack[2].ival;
  
  if (dlen < 0) {
    dlen = data_length;
  }
  
  if (!(dlen <= data_length)) {
    return env->die(env, stack, "The $dlen must be lower than or equal to the length of the $data.", __func__, FILE_NAME, __LINE__);
  }
  
  BIO* bio = env->get_pointer(env, stack, obj_self);
  
  int32_t write_length = BIO_write(bio, data, dlen);
  
  if (write_length < 0) {
    return env->die(env, stack, "BIO_write failed.", __func__, FILE_NAME, __LINE__);
  }
  
  stack[0].ival = write_length;
  
  return 0;
}
