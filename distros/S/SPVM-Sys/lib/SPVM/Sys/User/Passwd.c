#include "spvm_native.h"

#ifndef _WIN32

#include <pwd.h>

#endif

static const char* FILE_NAME = "Sys/User/Passwd.c";

int32_t SPVM__Sys__User__Passwd__pw_name(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#ifdef _WIN32
  env->die(env, stack, "The method \"pw_name\" in the class \"Sys::User::Passwd\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].oval = env->new_string(env, stack, st_passwd->pw_name, strlen(st_passwd->pw_name));
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_passwd(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#ifdef _WIN32
  env->die(env, stack, "The method \"pw_passwd\" in the class \"Sys::User::Passwd\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].oval = env->new_string(env, stack, st_passwd->pw_passwd, strlen(st_passwd->pw_passwd));
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_uid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#ifdef _WIN32
  env->die(env, stack, "The method \"pw_uid\" in the class \"Sys::User::Passwd\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].ival = st_passwd->pw_uid;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_gid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#ifdef _WIN32
  env->die(env, stack, "The method \"pw_gid\" in the class \"Sys::User::Passwd\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].ival = st_passwd->pw_gid;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_gecos(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#ifdef _WIN32
  env->die(env, stack, "The method \"pw_gecos\" in the class \"Sys::User::Passwd\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].oval = env->new_string(env, stack, st_passwd->pw_gecos, strlen(st_passwd->pw_gecos));
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_dir(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#ifdef _WIN32
  env->die(env, stack, "The method \"pw_dir\" in the class \"Sys::User::Passwd\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].oval = env->new_string(env, stack, st_passwd->pw_dir, strlen(st_passwd->pw_dir));
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__Passwd__pw_shell(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#ifdef _WIN32
  env->die(env, stack, "The method \"pw_shell\" in the class \"Sys::User::Passwd\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_passwd = stack[0].oval;
  
  struct passwd* st_passwd = env->get_pointer(env, stack, obj_passwd);
  
  stack[0].oval = env->new_string(env, stack, st_passwd->pw_shell, strlen(st_passwd->pw_shell));
  
  return 0;
#endif
}
