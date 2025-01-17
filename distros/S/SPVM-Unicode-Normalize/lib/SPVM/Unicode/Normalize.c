// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include "utf8proc.h"

static const char* FILE_NAME = "Unicode/Normalize.c";

int32_t SPVM__Unicode__Normalize__NFC(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_string = stack[0].oval;
  
  if (!obj_string) {
    return env->die(env, stack, "The string $string must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* string = env->get_chars(env, stack, obj_string);
  
  utf8proc_uint8_t *string_ret_tmp;
  
  int32_t string_ret_length = utf8proc_map(string, 0, &string_ret_tmp, UTF8PROC_NULLTERM | UTF8PROC_STABLE |
    UTF8PROC_COMPOSE);
  
  if (string_ret_length < 0) {
    return env->die(env, stack, "utf8proc_map failed.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_string_ret = env->new_string(env, stack, NULL, string_ret_length);
  
  char* string_ret = (char*)env->get_chars(env, stack, obj_string_ret);
  
  memcpy(string_ret, string_ret_tmp, string_ret_length);
  
  free(string_ret_tmp);
  
  stack[0].oval = obj_string_ret;
  
  return 0;
}

int32_t SPVM__Unicode__Normalize__NFD(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_string = stack[0].oval;
  
  if (!obj_string) {
    return env->die(env, stack, "The string $string must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* string = env->get_chars(env, stack, obj_string);
  
  utf8proc_uint8_t *string_ret_tmp;
  
  int32_t string_ret_length = utf8proc_map(string, 0, &string_ret_tmp, UTF8PROC_NULLTERM | UTF8PROC_STABLE |
    UTF8PROC_DECOMPOSE);
  
  if (string_ret_length < 0) {
    return env->die(env, stack, "utf8proc_map failed.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_string_ret = env->new_string(env, stack, NULL, string_ret_length);
  
  char* string_ret = (char*)env->get_chars(env, stack, obj_string_ret);
  
  memcpy(string_ret, string_ret_tmp, string_ret_length);
  
  free(string_ret_tmp);
  
  stack[0].oval = obj_string_ret;
  
  return 0;
}

int32_t SPVM__Unicode__Normalize__NFKC(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_string = stack[0].oval;
  
  if (!obj_string) {
    return env->die(env, stack, "The string $string must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* string = env->get_chars(env, stack, obj_string);
  
  utf8proc_uint8_t *string_ret_tmp;
  
  int32_t string_ret_length = utf8proc_map(string, 0, &string_ret_tmp, UTF8PROC_NULLTERM | UTF8PROC_STABLE |
    UTF8PROC_COMPOSE | UTF8PROC_COMPAT);
  
  if (string_ret_length < 0) {
    return env->die(env, stack, "utf8proc_map failed.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_string_ret = env->new_string(env, stack, NULL, string_ret_length);
  
  char* string_ret = (char*)env->get_chars(env, stack, obj_string_ret);
  
  memcpy(string_ret, string_ret_tmp, string_ret_length);
  
  free(string_ret_tmp);
  
  stack[0].oval = obj_string_ret;
  
  return 0;
}

int32_t SPVM__Unicode__Normalize__NFKD(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_string = stack[0].oval;
  
  if (!obj_string) {
    return env->die(env, stack, "The string $string must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* string = env->get_chars(env, stack, obj_string);
  
  utf8proc_uint8_t *string_ret_tmp;
  
  int32_t string_ret_length = utf8proc_map(string, 0, &string_ret_tmp, UTF8PROC_NULLTERM | UTF8PROC_STABLE |
    UTF8PROC_DECOMPOSE | UTF8PROC_COMPAT);
  
  if (string_ret_length < 0) {
    return env->die(env, stack, "utf8proc_map failed.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_string_ret = env->new_string(env, stack, NULL, string_ret_length);
  
  char* string_ret = (char*)env->get_chars(env, stack, obj_string_ret);
  
  memcpy(string_ret, string_ret_tmp, string_ret_length);
  
  free(string_ret_tmp);
  
  stack[0].oval = obj_string_ret;
  
  return 0;
}

