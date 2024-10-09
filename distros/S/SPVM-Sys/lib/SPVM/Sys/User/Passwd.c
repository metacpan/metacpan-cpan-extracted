// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#ifndef _WIN32

#include <pwd.h>

#endif

static const char* FILE_NAME = "Sys/User/Passwd.c";

int32_t SPVM__Sys__User__Passwd__pw_name(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "Sys::User::Passwd#pw_name method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].oval = env->new_string(env, stack, st_passwd->pw_name, strlen(st_passwd->pw_name));
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_passwd(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "Sys::User::Passwd#pw_passwd method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].oval = env->new_string(env, stack, st_passwd->pw_passwd, strlen(st_passwd->pw_passwd));
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_uid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "Sys::User::Passwd#pw_uid method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].ival = st_passwd->pw_uid;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_gid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "Sys::User::Passwd#pw_gid method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].ival = st_passwd->pw_gid;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_gecos(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "Sys::User::Passwd#pw_gecos method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].oval = env->new_string(env, stack, st_passwd->pw_gecos, strlen(st_passwd->pw_gecos));
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_dir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "Sys::User::Passwd#pw_dir method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].oval = env->new_string(env, stack, st_passwd->pw_dir, strlen(st_passwd->pw_dir));
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_shell(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "Sys::User::Passwd#pw_shell method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].oval = env->new_string(env, stack, st_passwd->pw_shell, strlen(st_passwd->pw_shell));
  
  return 0;
#endif
}
