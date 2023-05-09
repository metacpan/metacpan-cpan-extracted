// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#if defined(_WIN32)
  #include <winsock2.h>
  #define ioctl ioctlsocket
#else
  #include <sys/ioctl.h>
#endif

#include <errno.h>

const char* FILE_NAME = "Sys/Ioctl.c";

// static functions are copied from Sys/Socket.c
static int32_t socket_errno (void) {
#if defined(_WIN32)
  return WSAGetLastError();
#else
  return errno;
#endif
}

#if defined(_WIN32)
static void* socket_strerror_string_win (SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length) {
  char* error_message = NULL;
  FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, 
                 NULL, error_number,
                 MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US),
                 (LPSTR)&error_message, length, NULL);
  
  void* obj_error_message = env->new_string(env, stack, error_message, strlen(error_message));
  
  LocalFree(error_message);
  
  return obj_error_message;
}
#endif

static void* socket_strerror_string (SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length) {
  void*
#if defined(_WIN32)
  obj_strerror_value = socket_strerror_string_win(env, stack, error_number, length);
#else
  obj_strerror_value = env->strerror_string(env, stack, error_number, length);
#endif
  return obj_strerror_value;
}


static const char* socket_strerror(SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length) {
  void* obj_socket_strerror = socket_strerror_string(env, stack, error_number, length);
  
  const char* ret_socket_strerror = NULL;
  if (obj_socket_strerror) {
    ret_socket_strerror = env->get_chars(env, stack, obj_socket_strerror);
  }
  
  return ret_socket_strerror;
}

int32_t SPVM__Sys__Ioctl__ioctl(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t e = 0;
  
  int32_t fd = stack[0].ival;
  
  int32_t request = stack[1].ival;
  
  int32_t ret;

  void* obj_request_arg_ref = stack[2].oval;
  
  if (!obj_request_arg_ref) {
    ret = ioctl(fd, request, NULL);
  }
  else {
    // byte[]
    if (env->is_type(env, stack, obj_request_arg_ref, SPVM_NATIVE_C_BASIC_TYPE_ID_BYTE,  1)) {
      int8_t* request_arg_ref = env->get_elems_byte(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // short[]
    else if (env->is_type(env, stack, obj_request_arg_ref, SPVM_NATIVE_C_BASIC_TYPE_ID_SHORT,  1)) {
      int16_t* request_arg_ref = env->get_elems_short(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // int[]
    else if (env->is_type(env, stack, obj_request_arg_ref, SPVM_NATIVE_C_BASIC_TYPE_ID_INT,  1)) {
      int32_t* request_arg_ref = env->get_elems_int(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // long[]
    else if (env->is_type(env, stack, obj_request_arg_ref, SPVM_NATIVE_C_BASIC_TYPE_ID_LONG,  1)) {
      int64_t* request_arg_ref = env->get_elems_long(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // float[]
    else if (env->is_type(env, stack, obj_request_arg_ref, SPVM_NATIVE_C_BASIC_TYPE_ID_FLOAT,  1)) {
      float* request_arg_ref = env->get_elems_float(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // double[]
    else if (env->is_type(env, stack, obj_request_arg_ref, SPVM_NATIVE_C_BASIC_TYPE_ID_DOUBLE,  1)) {
      double* request_arg_ref = env->get_elems_double(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, &request_arg_ref);
    }
    // A pointer class
    else if (env->is_pointer_class(env, stack, obj_request_arg_ref)) {
      void* request_arg_ref = env->get_pointer(env, stack, obj_request_arg_ref);
      ret = ioctl(fd, request, request_arg_ref);
    }
    else {
      return env->die(env, stack, "The $request_arg_ref must be an byte[]/short[]/int[]/long[]/float[]/double[] type object or the object that is a pointer class", __func__, FILE_NAME, __LINE__);
    }
  }
  
  if (ret == -1) {
    env->die(env, stack, "[System Error]ioctl failed: %s", socket_strerror(env, stack, socket_errno(), 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = ret;
  
  return 0;
}
