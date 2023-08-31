// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <openssl/ssl.h>

#include <openssl/err.h>

static const char* FILE_NAME = "Net/SSLeay/ERR.c";

int32_t SPVM__Net__SSLeay__ERR__error_string_n(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  int64_t e = stack[0].lval;
  
  void* obj_buf = stack[1].oval;
  
  if (!obj_buf) {
    return env->die(env, stack, "The $buf must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t len = stack[2].ival;
  
  if (len < 0) {
    len = buf_length;
  }
  
  if (!(len <= buf_length)) {
    return env->die(env, stack, "The $len must be less than or equal to the length of the $buf.", __func__, FILE_NAME, __LINE__);
  }
  
  ERR_error_string_n(e, buf, len);
  
  return 0;
}
