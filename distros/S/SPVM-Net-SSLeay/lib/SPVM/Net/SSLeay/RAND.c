// Copyright (c) 2024 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <openssl/rand.h>

static const char* FILE_NAME = "Net/SSLeay/RAND.c";

int32_t SPVM__Net__SSLeay__RAND__seed(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_buf = stack[0].oval;
  
  int32_t num = stack[1].ival;
  
  if (!obj_buf) {
    return env->die(env, stack, "The buffer $buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* buf = env->get_chars(env, stack, obj_buf);
  
  RAND_seed(buf, num);
  
  return 0;
}

int32_t SPVM__Net__SSLeay__RAND__poll(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  RAND_poll();
  
  return 0;
}

int32_t SPVM__Net__SSLeay__RAND__load_file(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_filename = stack[0].oval;
  
  int64_t max_bytes = stack[1].lval;
  
  if (!obj_filename) {
    return env->die(env, stack, "The filename $filename must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* filename = env->get_chars(env, stack, obj_filename);
  
  int32_t read_length = RAND_load_file(filename, max_bytes);
  
  if (!(read_length >= 0)) {
    int64_t ssl_error = ERR_peek_last_error();
    
    char* ssl_error_string = env->get_stack_tmp_buffer(env, stack);
    ERR_error_string_n(ssl_error, ssl_error_string, SPVM_NATIVE_C_STACK_TMP_BUFFER_SIZE);
    
    env->die(env, stack, "[OpenSSL Error]RAND_load_file failed:%s.", ssl_error_string, __func__, FILE_NAME, __LINE__);
    
    int32_t tmp_error_id = env->get_basic_type_id_by_name(env, stack, "Net::SSLeay::Error", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    error_id = tmp_error_id;
    
    return error_id;
  }
  
  stack[0].ival = read_length;
  
  return 0;
}

