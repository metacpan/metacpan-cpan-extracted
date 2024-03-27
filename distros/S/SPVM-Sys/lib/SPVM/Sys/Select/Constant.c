// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#if defined(_WIN32)
  #include <winsock2.h>
#else
  #include <sys/select.h>
#endif

static const char* FILE_NAME = "Sys/Select/Constant.c";

int32_t SPVM__Sys__Select__Constant__FD_SETSIZE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef FD_SETSIZE
  stack[0].ival = FD_SETSIZE;
  return 0;
#else
  env->die(env, stack, "FD_SETSIZE is not defined in this system.", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}
