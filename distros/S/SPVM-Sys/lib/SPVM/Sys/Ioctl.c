// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "spvm_socket_util.h"

#if defined(_WIN32)
  #include <winsock2.h>
  #define ioctl ioctlsocket
#else
  #include <sys/ioctl.h>
#endif

#include <errno.h>

static const char* FILE_NAME = "Sys/Ioctl.c";

int32_t SPVM__Sys__Ioctl__ioctl(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "Sys::IO#ioctl method is not supported in this system(defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  int32_t error_id = 0;
  
  int32_t fd = stack[0].ival;
  
  int32_t request = stack[1].ival;
  
  int32_t ret;

  void* obj_request_arg_ref = stack[2].oval;
  
  if (!obj_request_arg_ref) {
    ret = ioctl(fd, request, NULL);
  }
  else {
    // byte[]
    if (env->is_type(env, stack, obj_request_arg_ref, env->get_basic_type_by_id(env, stack, SPVM_NATIVE_C_BASIC_TYPE_ID_BYTE),  1)) {
      int8_t* request_arg_ref = env->get_elems_byte(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // short[]
    else if (env->is_type(env, stack, obj_request_arg_ref, env->get_basic_type_by_id(env, stack, SPVM_NATIVE_C_BASIC_TYPE_ID_SHORT),  1)) {
      int16_t* request_arg_ref = env->get_elems_short(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // int[]
    else if (env->is_type(env, stack, obj_request_arg_ref, env->get_basic_type_by_id(env, stack, SPVM_NATIVE_C_BASIC_TYPE_ID_INT),  1)) {
      int32_t* request_arg_ref = env->get_elems_int(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // long[]
    else if (env->is_type(env, stack, obj_request_arg_ref, env->get_basic_type_by_id(env, stack, SPVM_NATIVE_C_BASIC_TYPE_ID_LONG),  1)) {
      int64_t* request_arg_ref = env->get_elems_long(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // float[]
    else if (env->is_type(env, stack, obj_request_arg_ref, env->get_basic_type_by_id(env, stack, SPVM_NATIVE_C_BASIC_TYPE_ID_FLOAT),  1)) {
      float* request_arg_ref = env->get_elems_float(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // double[]
    else if (env->is_type(env, stack, obj_request_arg_ref, env->get_basic_type_by_id(env, stack, SPVM_NATIVE_C_BASIC_TYPE_ID_DOUBLE),  1)) {
      double* request_arg_ref = env->get_elems_double(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // A pointer class
    else if (env->is_pointer_class(env, stack, obj_request_arg_ref)) {
      void* request_arg_ref = env->get_pointer(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, request_arg_ref);
    }
    else {
      return env->die(env, stack, "The array $request_arg_ref for input or output of an ioctl argument must be an byte[]/short[]/int[]/long[]/float[]/double[] type object or the object that is a pointer class.", __func__, FILE_NAME, __LINE__);
    }
  }
  
  if (ret == -1) {
    env->die(env, stack, "[System Error]ioctl() failed:%s.", env->strerror_nolen(env, stack, errno), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = ret;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Ioctl__ioctlsocket(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !defined(_WIN32)
  env->die(env, stack, "Sys::IO#ioctlsocket method is not supported in this system(!defined(_WIN32)).", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else

  int32_t error_id = 0;
  
  int32_t fd = stack[0].ival;
  
  int32_t request = stack[1].ival;
  
  int32_t ret;
  
  void* obj_request_arg_ref = stack[2].oval;
  
  if (!obj_request_arg_ref) {
    ret = ioctlsocket(fd, request, NULL);
  }
  else {
    int32_t* request_arg_ref = env->get_elems_int(env, stack, obj_request_arg_ref);
    ret = ioctlsocket(fd, request, (u_long*)request_arg_ref);
  }
  
  if (ret == -1) {
    env->die(env, stack, "[System Error]ioctlsocket() failed:%s.", spvm_socket_strerror(env, stack, spvm_socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_SYSTEM_CLASS;
  }
  
  stack[0].ival = ret;
  
  return 0;
#endif
}
