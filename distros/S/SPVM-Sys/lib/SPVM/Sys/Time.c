// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <time.h>
#include <sys/time.h>
#include <errno.h>

#ifndef _WIN32
  #include <sys/times.h>
#endif

static const char* FILE_NAME = "Sys/Time.c";

int32_t SPVM__Sys__Time__time(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int64_t epoch = (int64_t)time(NULL);
  
  stack[0].lval = epoch;
  
  return 0;
}

int32_t SPVM__Sys__Time__localtime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e;
  
  time_t time = (time_t)stack[0].lval;
  struct tm* st_tm = env->new_memory_stack(env, stack, sizeof(struct tm));
  
#ifdef _WIN32
  localtime_s(st_tm, &time);
#else
  localtime_r(&time, st_tm);
#endif
  
  void* obj_time_info = env->new_pointer_object_by_name(env, stack, "Sys::Time::Tm", st_tm, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_time_info;
  
  return 0;
}

int32_t SPVM__Sys__Time__gmtime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e;
  
  time_t time = (time_t)stack[0].lval;
  struct tm* st_tm = env->new_memory_stack(env, stack, sizeof(struct tm));
  
#ifdef _WIN32
  gmtime_s(st_tm, &time);
#else
  gmtime_r(&time, st_tm);
#endif
  
  void* obj_time_info = env->new_pointer_object_by_name(env, stack, "Sys::Time::Tm", st_tm, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_time_info;
  
  return 0;
}

int32_t SPVM__Sys__Time__gettimeofday(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  void* obj_tv = stack[0].oval;
  
  struct timeval* st_tv = NULL;
  if (obj_tv) {
    st_tv = env->get_pointer(env, stack, obj_tv);
  }
  
  void* obj_tz = stack[1].oval;
  
  struct timezone* st_tz = NULL;
  if (obj_tz) {
    st_tz = env->get_pointer(env, stack, obj_tz);
  }
  
  int32_t status = gettimeofday(st_tv, st_tz);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]gettimeofday failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Time__clock(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int64_t cpu_time = clock();
  
  if (cpu_time == -1) {
    env->die(env, stack, "[System Error]clock failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].lval = cpu_time;
  
  return 0;
}

int32_t SPVM__Sys__Time__clock_gettime(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t clk_id = stack[0].ival;
  
  void* obj_tp = stack[1].oval;
  
  struct timespec* st_tp = NULL;
  if (obj_tp) {
    st_tp = env->get_pointer(env, stack, obj_tp);
  }
  else {
    return env->die(env, stack, "The $tp must be defined", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t status = clock_gettime(clk_id, st_tp);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]clock_gettime failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Time__clock_getres(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t clk_id = stack[0].ival;
  
  void* obj_res = stack[1].oval;
  
  struct timespec* st_res = NULL;
  if (obj_res) {
    st_res = env->get_pointer(env, stack, obj_res);
  }
  else {
    return env->die(env, stack, "The $res must be defined", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t status = clock_getres(clk_id, st_res);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]clock_getres failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Time__setitimer(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "getitimer is not supported on this system(defined(_WIN32))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  (void)env;
  (void)stack;
  
  int32_t which = stack[0].ival;
  
  void* obj_new_value = stack[1].oval;
  struct itimerval* st_new_value = NULL;
  if (obj_new_value) {
    st_new_value = env->get_pointer(env, stack, obj_new_value);
  }
  else {
    return env->die(env, stack, "The $new_value must be defined", __func__, FILE_NAME, __LINE__);
  }

  void* obj_old_value = stack[1].oval;
  struct itimerval* st_old_value = NULL;
  if (obj_old_value) {
    st_old_value = env->get_pointer(env, stack, obj_old_value);
  }
  
  int32_t status = setitimer(which, st_new_value, st_old_value);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]setitimer failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__getitimer(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "getitimer is not supported on this system(defined(_WIN32))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  (void)env;
  (void)stack;
  
  int32_t which = stack[0].ival;
  
  void* obj_curr_value = stack[1].oval;
  
  struct itimerval* st_curr_value = NULL;
  if (obj_curr_value) {
    st_curr_value = env->get_pointer(env, stack, obj_curr_value);
  }
  else {
    return env->die(env, stack, "The $curr_value must be defined", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t status = getitimer(which, st_curr_value);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]getitimer failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__times(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "times is not supported on this system(defined(_WIN32))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  void* obj_tms = stack[0].oval;
  
  if (!obj_tms) {
    return env->die(env, stack, "The $tms must be defined", __func__, FILE_NAME, __LINE__);
  }
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_tms);
  
  errno = 0;
  int64_t clock_tick = times(st_tms);
  
  if (errno != 0) {
    env->die(env, stack, "[System Error]times failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].lval = clock_tick;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__clock_nanosleep(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef __APPLE__
  env->die(env, stack, "clock_nanosleep is not supported on this system(__APPLE__)", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#elif __FreeBSD__ && !(__FreeBSD__ >= 13)
  env->die(env, stack, "clock_nanosleep is not supported on this system(__FreeBSD__ && !(__FreeBSD__ >= 13))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#elif __OpenBSD__
  env->die(env, stack, "clock_nanosleep is not supported on this system(__OpenBSD__)", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  (void)env;
  (void)stack;
  
  int32_t clockid = stack[0].ival;

  int32_t flags = stack[1].ival;
  
  void* obj_request = stack[2].oval;
  
  struct timespec* st_request = NULL;
  if (obj_request) {
    st_request = env->get_pointer(env, stack, obj_request);
  }
  else {
    return env->die(env, stack, "The $request must be defined", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_remain = stack[3].oval;
  
  struct timespec* st_remain = NULL;
  if (obj_remain) {
    st_remain = env->get_pointer(env, stack, obj_remain);
  }
  
  int32_t ret_errno = clock_nanosleep(clockid, flags, st_request, st_remain);

  if (ret_errno != 0) {
    env->die(env, stack, "[System Error]clock_nanosleep failed:%s.", env->strerror(env, stack, ret_errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = ret_errno;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Time__nanosleep(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  void* obj_rqtp = stack[0].oval;
  
  struct timespec* st_rqtp = NULL;
  if (obj_rqtp) {
    st_rqtp = env->get_pointer(env, stack, obj_rqtp);
  }
  else {
    return env->die(env, stack, "The $rqtp must be defined", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_rmtp = stack[1].oval;
  
  struct timespec* st_rmtp = NULL;
  if (obj_rmtp) {
    st_rmtp = env->get_pointer(env, stack, obj_rmtp);
  }
  
  int32_t status = nanosleep(st_rqtp, st_rmtp);

  if (status == -1) {
    env->die(env, stack, "[System Error]nanosleep failed:%s.", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }

  stack[0].ival = status;
  
  return 0;
}

