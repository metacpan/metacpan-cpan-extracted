// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <assert.h>

#if defined(_WIN32)
#else
  #include <sys/un.h>
#endif

const char* FILE_NAME = "Sys/Socket/Sockaddr/Un.c";

int32_t SPVM__Sys__Socket__Sockaddr__Un__new(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"new\" method in the class \"Sys::Socket::Sockaddr::Un\" is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  int32_t e = 0;
  
  struct sockaddr_un* socket_address = env->new_memory_stack(env, stack, sizeof(struct sockaddr_un));

  void* obj_socket_address = env->new_pointer_object_by_name(env, stack, "Sys::Socket::Sockaddr::Un", socket_address, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_socket_address;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"DESTROY\" method in the class \"Sys::Socket::Sockaddr::Un\" is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_socket_address = stack[0].oval;
  
  struct sockaddr_un* socket_address = env->get_pointer(env, stack, obj_socket_address);
  
  assert(socket_address);
  
  env->free_memory_stack(env, stack, socket_address);
  env->set_pointer(env, stack, obj_socket_address, NULL);
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__sun_family(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"sun_family\" method in the class \"Sys::Socket::Sockaddr::Un\" is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_un* socket_address = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = socket_address->sun_family;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__set_sun_family(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"set_sun_family\" method in the class \"Sys::Socket::Sockaddr::Un\" is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_un* socket_address = env->get_pointer(env, stack, obj_self);
  
  socket_address->sun_family = stack[1].ival;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__copy_sun_path(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"sun_path\" method in the class \"Sys::Socket::Sockaddr::Un\" is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_un* socket_address = env->get_pointer(env, stack, obj_self);
  
  void* obj_path;
  
  obj_path = env->new_string(env, stack, socket_address->sun_path, strlen(socket_address->sun_path));
  
  stack[0].oval = obj_path;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__set_sun_path(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"set_sun_path\" method in the class \"Sys::Socket::Sockaddr::Un\" is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_un* socket_address = env->get_pointer(env, stack, obj_self);
  
  void* obj_path = stack[1].oval;

  if (!obj_path) {
    return env->die(env, stack, "The sun_path must be be defined", __func__, FILE_NAME, __LINE__);
  }
  
  const char* path = env->get_chars(env, stack, obj_path);
  int32_t path_length = env->length(env, stack, obj_path);
  
  memset(socket_address->sun_path, 0, strlen(socket_address->sun_path));
  memcpy(socket_address->sun_path, path, path_length);
  
  return 0;
#endif
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__sizeof(SPVM_ENV* env, SPVM_VALUE* stack) {
#if defined(_WIN32)
  env->die(env, stack, "The \"sizeof\" method in the class \"Sys::Socket::Sockaddr::Un\" is not supported on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#else
  
  void* obj_self = stack[0].oval;
  
  stack[0].ival = sizeof(struct sockaddr_un);
  
  return 0;
#endif
}
