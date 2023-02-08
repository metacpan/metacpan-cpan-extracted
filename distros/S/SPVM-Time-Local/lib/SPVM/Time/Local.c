#include "spvm_native.h"

#include <time.h>

static const char* FILE_NAME = "SPVM/Time/Local.c";

int32_t SPVM__Time__Local__timelocal(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  
  void* obj_time_info = stack[0].oval;
  if (!obj_time_info) { return env->die(env, stack,  "Time::Info object must be defined", __func__, FILE_NAME, __LINE__); }
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_time_info);
  
  // mktime is equal to timelocal
  int64_t time = (int64_t)mktime(st_tm);
  
  stack[0].lval = time;
  
  return 0;
}

int32_t SPVM__Time__Local__timegm(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t e;
  
  void* obj_time_info = stack[0].oval;
  if (!obj_time_info) { return env->die(env, stack,  "Time::Info object must be defined", __func__, FILE_NAME, __LINE__); }
  
  struct tm* st_tm = env->get_pointer(env, stack, obj_time_info);
  
#ifdef _WIN32
  int64_t time = (int64_t)_mkgmtime(st_tm);
#else
  int64_t time = (int64_t)timegm(st_tm);
#endif
  
  stack[0].lval = time;
  
  return 0;
}
