// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <time.h>
#include <sys/time.h>

static const char* FILE_NAME = "Sys/Time/Constant.c";

int32_t SPVM__Sys__Time__Constant__CLOCKS_PER_SEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCKS_PER_SEC
  stack[0].ival = CLOCKS_PER_SEC;
  return 0;
#else
  env->die(env, stack, "CLOCKS_PER_SEC is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_BOOTTIME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_BOOTTIME
  stack[0].ival = CLOCK_BOOTTIME;
  return 0;
#else
  env->die(env, stack, "CLOCK_BOOTTIME is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_HIGHRES(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_HIGHRES
  stack[0].ival = CLOCK_HIGHRES;
  return 0;
#else
  env->die(env, stack, "CLOCK_HIGHRES is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_MONOTONIC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_MONOTONIC
  stack[0].ival = CLOCK_MONOTONIC;
  return 0;
#else
  env->die(env, stack, "CLOCK_MONOTONIC is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_MONOTONIC_COARSE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_MONOTONIC_COARSE
  stack[0].ival = CLOCK_MONOTONIC_COARSE;
  return 0;
#else
  env->die(env, stack, "CLOCK_MONOTONIC_COARSE is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_MONOTONIC_FAST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_MONOTONIC_FAST
  stack[0].ival = CLOCK_MONOTONIC_FAST;
  return 0;
#else
  env->die(env, stack, "CLOCK_MONOTONIC_FAST is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_MONOTONIC_PRECISE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_MONOTONIC_PRECISE
  stack[0].ival = CLOCK_MONOTONIC_PRECISE;
  return 0;
#else
  env->die(env, stack, "CLOCK_MONOTONIC_PRECISE is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_MONOTONIC_RAW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_MONOTONIC_RAW
  stack[0].ival = CLOCK_MONOTONIC_RAW;
  return 0;
#else
  env->die(env, stack, "CLOCK_MONOTONIC_RAW is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_PROCESS_CPUTIME_ID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_PROCESS_CPUTIME_ID
  stack[0].ival = CLOCK_PROCESS_CPUTIME_ID;
  return 0;
#else
  env->die(env, stack, "CLOCK_PROCESS_CPUTIME_ID is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_PROF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_PROF
  stack[0].ival = CLOCK_PROF;
  return 0;
#else
  env->die(env, stack, "CLOCK_PROF is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_REALTIME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_REALTIME
  stack[0].ival = CLOCK_REALTIME;
  return 0;
#else
  env->die(env, stack, "CLOCK_REALTIME is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_REALTIME_COARSE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_REALTIME_COARSE
  stack[0].ival = CLOCK_REALTIME_COARSE;
  return 0;
#else
  env->die(env, stack, "CLOCK_REALTIME_COARSE is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_REALTIME_FAST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_REALTIME_FAST
  stack[0].ival = CLOCK_REALTIME_FAST;
  return 0;
#else
  env->die(env, stack, "CLOCK_REALTIME_FAST is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_REALTIME_PRECISE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_REALTIME_PRECISE
  stack[0].ival = CLOCK_REALTIME_PRECISE;
  return 0;
#else
  env->die(env, stack, "CLOCK_REALTIME_PRECISE is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_REALTIME_RAW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_REALTIME_RAW
  stack[0].ival = CLOCK_REALTIME_RAW;
  return 0;
#else
  env->die(env, stack, "CLOCK_REALTIME_RAW is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_SECOND(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_SECOND
  stack[0].ival = CLOCK_SECOND;
  return 0;
#else
  env->die(env, stack, "CLOCK_SECOND is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_SOFTTIME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_SOFTTIME
  stack[0].ival = CLOCK_SOFTTIME;
  return 0;
#else
  env->die(env, stack, "CLOCK_SOFTTIME is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_THREAD_CPUTIME_ID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_THREAD_CPUTIME_ID
  stack[0].ival = CLOCK_THREAD_CPUTIME_ID;
  return 0;
#else
  env->die(env, stack, "CLOCK_THREAD_CPUTIME_ID is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_TIMEOFDAY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_TIMEOFDAY
  stack[0].ival = CLOCK_TIMEOFDAY;
  return 0;
#else
  env->die(env, stack, "CLOCK_TIMEOFDAY is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_UPTIME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_UPTIME
  stack[0].ival = CLOCK_UPTIME;
  return 0;
#else
  env->die(env, stack, "CLOCK_UPTIME is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_UPTIME_COARSE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_UPTIME_COARSE
  stack[0].ival = CLOCK_UPTIME_COARSE;
  return 0;
#else
  env->die(env, stack, "CLOCK_UPTIME_COARSE is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_UPTIME_FAST(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_UPTIME_FAST
  stack[0].ival = CLOCK_UPTIME_FAST;
  return 0;
#else
  env->die(env, stack, "CLOCK_UPTIME_FAST is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_UPTIME_PRECISE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_UPTIME_PRECISE
  stack[0].ival = CLOCK_UPTIME_PRECISE;
  return 0;
#else
  env->die(env, stack, "CLOCK_UPTIME_PRECISE is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_UPTIME_RAW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_UPTIME_RAW
  stack[0].ival = CLOCK_UPTIME_RAW;
  return 0;
#else
  env->die(env, stack, "CLOCK_UPTIME_RAW is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__CLOCK_VIRTUAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CLOCK_VIRTUAL
  stack[0].ival = CLOCK_VIRTUAL;
  return 0;
#else
  env->die(env, stack, "CLOCK_VIRTUAL is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__ITIMER_PROF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ITIMER_PROF
  stack[0].ival = ITIMER_PROF;
  return 0;
#else
  env->die(env, stack, "ITIMER_PROF is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__ITIMER_REAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ITIMER_REAL
  stack[0].ival = ITIMER_REAL;
  return 0;
#else
  env->die(env, stack, "ITIMER_REAL is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__ITIMER_REALPROF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ITIMER_REALPROF
  stack[0].ival = ITIMER_REALPROF;
  return 0;
#else
  env->die(env, stack, "ITIMER_REALPROF is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__ITIMER_VIRTUAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef ITIMER_VIRTUAL
  stack[0].ival = ITIMER_VIRTUAL;
  return 0;
#else
  env->die(env, stack, "ITIMER_VIRTUAL is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Sys__Time__Constant__TIMER_ABSTIME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef TIMER_ABSTIME
  stack[0].ival = TIMER_ABSTIME;
  return 0;
#else
  env->die(env, stack, "TIMER_ABSTIME is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}