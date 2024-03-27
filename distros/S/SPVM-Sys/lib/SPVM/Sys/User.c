// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <unistd.h>
#include <assert.h>
#include <errno.h>

#if defined(_WIN32)
  
#else
  #include <pwd.h>
  #include <grp.h>
#endif

static const char* FILE_NAME = "Sys/User.c";

int32_t SPVM__Sys__User__getuid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "getuid is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t uid = getuid();
  
  stack[0].ival = uid;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__geteuid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "geteuid is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t euid = geteuid();
  
  stack[0].ival  = euid;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__getgid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "getgid is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t gid = getgid();
  
  stack[0].ival = gid;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__getegid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "getegid is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t egid = getegid();
  
  stack[0].ival = egid;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__setuid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "setuid is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t uid = stack[0].ival;
  int32_t status = setuid(uid);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]setuid failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__seteuid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "seteuid is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t euid = stack[0].ival;
  int32_t status = seteuid(euid);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]seteuid failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__setgid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "setgid is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t gid = stack[0].ival;
  int32_t status = setgid(gid);

  if (status == -1) {
    env->die(env, stack, "[System Error]seteuid failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }

  stack[0].ival = status;

  return 0;
#endif
}

int32_t SPVM__Sys__User__setegid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "setegid is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t egid = stack[0].ival;
  int32_t status = setegid(egid);

  if (status == -1) {
    env->die(env, stack, "[System Error]setegid failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__setpwent(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(_WIN32)
  env->die(env, stack, "setpwent is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  setpwent();
  
  return 0;
#endif
}


int32_t SPVM__Sys__User__endpwent(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(_WIN32)
  env->die(env, stack, "endpwent is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  endpwent();
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__getpwent(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "getpwent is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  errno = 0;
  struct passwd* pwent = getpwent();
  
  if (errno != 0) {
    env->die(env, stack, "[System Error]getpwent failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  if (pwent == NULL) {
    stack[0].oval = NULL;
  }
  else {
    void* obj_sys_ent_passwd = env->new_pointer_object_by_name(env, stack, "Sys::User::Passwd", pwent, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_sys_ent_passwd;
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__setgrent(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "setgrent is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  setgrent();
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__endgrent(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "endgrent is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  endgrent();
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__getgrent(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "getgrent is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  errno = 0;
  struct group* grent = getgrent();
  
  if (errno != 0) {
    env->die(env, stack, "[System Error]getgrent failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  if (grent == NULL) {
    stack[0].oval = NULL;
  }
  else {
    void* obj_sys_ent_group = env->new_pointer_object_by_name(env, stack, "Sys::User::Group", grent, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_sys_ent_group;
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__getgroups(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "getgroups is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t size = stack[0].ival;
  
  if (!(size >= 0)) {
    return env->die(env, stack, "$size must be greater than or equal to 0.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_list = stack[1].oval;
  
  if (obj_list) {
    int32_t list_length = env->length(env, stack, obj_list);
    if (!(size == list_length)) {
      return env->die(env, stack, "If $list is defined, $size must the length of $list.", __func__, FILE_NAME, __LINE__);
    }
  }
  
  int32_t* list = env->get_elems_int(env, stack, obj_list);
  
  assert(sizeof(gid_t) == sizeof(int32_t));
  
  int32_t list_length = getgroups(size, (gid_t*)list);
  if (list_length == -1) {
    env->die(env, stack, "[System Error]getgroups failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = list_length;
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__setgroups(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "setgroups is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  assert(sizeof(gid_t) == sizeof(int32_t));
  
  void* obj_groups = stack[0].oval;
  if (!obj_groups) {
    return env->die(env, stack, "$groups must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t* groups = env->get_elems_int(env, stack, obj_groups);
  int32_t groups_length = env->length(env, stack, obj_groups);
  
  assert(sizeof(gid_t) == sizeof(int32_t));
  
  int32_t status = setgroups(groups_length, (gid_t*)groups);
  if (status == -1) {
    env->die(env, stack, "[System Error]setgroups failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  stack[0].ival = status;
  return 0;
#endif
}

int32_t SPVM__Sys__User__getpwuid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "getpwuid is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  int32_t uid = stack[0].ival;
  
  errno = 0;
  struct passwd* pwent = getpwuid(uid);
  
  if (errno != 0) {
    env->die(env, stack, "[System Error]getpwuid failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  if (pwent == NULL) {
    stack[0].oval = NULL;
  }
  else {
    void* obj_sys_ent_passwd = env->new_pointer_object_by_name(env, stack, "Sys::User::Passwd", pwent, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_sys_ent_passwd;
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__getpwnam(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "getpwnam is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_pwnam = stack[0].oval;
  
  if (!obj_pwnam) {
    return env->die(env, stack, "$pwnam must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* pwnam = env->get_chars(env, stack, obj_pwnam);
  
  errno = 0;
  struct passwd* pwent = getpwnam(pwnam);
  
  if (errno != 0) {
    env->die(env, stack, "[System Error]getpwnam failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  if (pwent == NULL) {
    stack[0].oval = NULL;
  }
  else {
    void* obj_sys_ent_passwd = env->new_pointer_object_by_name(env, stack, "Sys::User::Passwd", pwent, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_sys_ent_passwd;
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__getgrgid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "getgrgid is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  int32_t gid = stack[0].ival;
  
  errno = 0;
  struct group* grent = getgrgid(gid);
  
  if (errno != 0) {
    env->die(env, stack, "[System Error]getgrgid failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  if (grent == NULL) {
    stack[0].oval = NULL;
  }
  else {
    void* obj_sys_ent_group = env->new_pointer_object_by_name(env, stack, "Sys::User::Group", grent, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_sys_ent_group;
  }
  
  return 0;
#endif
}

int32_t SPVM__Sys__User__getgrnam(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  env->die(env, stack, "getgrnam is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  void* obj_grnam = stack[0].oval;
  
  if (!obj_grnam) {
    return env->die(env, stack, "$grnam must be defined.", __func__, FILE_NAME, __LINE__);
  }
  const char* grnam = env->get_chars(env, stack, obj_grnam);
  
  errno = 0;
  struct group* grent = getgrnam(grnam);
  
  if (errno != 0) {
    env->die(env, stack, "[System Error]getgrnam failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  if (grent == NULL) {
    stack[0].oval = NULL;
  }
  else {
    void* obj_sys_ent_group = env->new_pointer_object_by_name(env, stack, "Sys::User::Group", grent, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    stack[0].oval = obj_sys_ent_group;
  }
  
  return 0;
#endif
}
