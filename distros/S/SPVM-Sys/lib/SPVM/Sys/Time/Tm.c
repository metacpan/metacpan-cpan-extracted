// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <time.h>

static const char* FILE_NAME = "Sys/Time/Tm.c";

int32_t SPVM__Sys__Time__Tm__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  struct tm* st_tm = env->new_memory_block(env, stack, sizeof(struct tm));
  
  void* obj_tm = env->new_pointer_object_by_name(env, stack, "Sys::Time::Tm", st_tm, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_tm;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  env->free_memory_block(env, stack, st_tm);
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__tm_sec(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  stack[0].ival = st_tm->tm_sec;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__tm_min(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  stack[0].ival = st_tm->tm_min;
  
  return 0;
}
int32_t SPVM__Sys__Time__Tm__tm_hour(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  stack[0].ival = st_tm->tm_hour;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__tm_mday(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  stack[0].ival = st_tm->tm_mday;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__tm_mon(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  stack[0].ival = st_tm->tm_mon;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__tm_year(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  stack[0].ival = st_tm->tm_year;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__tm_wday(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  stack[0].ival = st_tm->tm_wday;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__tm_yday(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  stack[0].ival = st_tm->tm_yday;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__tm_isdst(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  stack[0].ival = st_tm->tm_isdst;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__set_tm_sec(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  int32_t tm_sec = stack[1].ival;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  st_tm->tm_sec = tm_sec;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__set_tm_min(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  int32_t tm_min = stack[1].ival;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  st_tm->tm_min = tm_min;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__set_tm_hour(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  int32_t tm_hour = stack[1].ival;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  st_tm->tm_hour = tm_hour;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__set_tm_mday(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  int32_t tm_mday = stack[1].ival;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  st_tm->tm_mday = tm_mday;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__set_tm_mon(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  int32_t tm_mon = stack[1].ival;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  st_tm->tm_mon = tm_mon;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__set_tm_year(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  int32_t tm_year = stack[1].ival;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  st_tm->tm_year = tm_year;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__set_tm_wday(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  int32_t tm_wday = stack[1].ival;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  st_tm->tm_wday = tm_wday;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__set_tm_yday(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  int32_t tm_yday = stack[1].ival;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  st_tm->tm_yday = tm_yday;
  
  return 0;
}

int32_t SPVM__Sys__Time__Tm__set_tm_isdst(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_tm = stack[0].oval;
  
  int32_t tm_isdst = stack[1].ival;
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_tm);
  
  st_tm->tm_isdst = tm_isdst;
  
  return 0;
}
