// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#if defined(_WIN32)
  #include <winsock2.h>
#else
  #include <sys/ioctl.h>
#endif

static const char* FILE_NAME = "Sys/Ioctl/Constant.c";

int32_t SPVM__Sys__Ioctl__Constant__FIONBIO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef FIONBIO
  stack[0].ival = FIONBIO;
  return 0;
#else
  env->die(env, stack, "FIONBIO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}
