// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <assert.h>

#if defined(_WIN32)

#define UNIX_PATH_MAX 108

typedef struct sockaddr_un {
  ADDRESS_FAMILY sun_family;
  char sun_path[UNIX_PATH_MAX];
};

#else
  #include <sys/un.h>
#endif

static const char* FILE_NAME = "Sys/Socket/Sockaddr/Un.c";

int32_t SPVM__Sys__Socket__Sockaddr__Un__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  struct sockaddr_un* socket_address = env->new_memory_block(env, stack, sizeof(struct sockaddr_un));
  
  void* obj_socket_address = env->new_pointer_object_by_name(env, stack, "Sys::Socket::Sockaddr::Un", socket_address, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_socket_address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_socket_address = stack[0].oval;
  
  struct sockaddr_un* socket_address = env->get_pointer(env, stack, obj_socket_address);
  
  assert(socket_address);
  
  env->free_memory_block(env, stack, socket_address);
  env->set_pointer(env, stack, obj_socket_address, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__sun_family(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_un* socket_address = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = socket_address->sun_family;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__set_sun_family(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_un* socket_address = env->get_pointer(env, stack, obj_self);
  
  socket_address->sun_family = stack[1].ival;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__sun_path(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_un* socket_address = env->get_pointer(env, stack, obj_self);
  
  void* obj_path;
  
  obj_path = env->new_string(env, stack, socket_address->sun_path, strlen(socket_address->sun_path));
  
  stack[0].oval = obj_path;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__set_sun_path(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_un* socket_address = env->get_pointer(env, stack, obj_self);
  
  void* obj_path = stack[1].oval;
  
  if (!obj_path) {
    return env->die(env, stack, "The sun_path must be be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const char* path = env->get_chars(env, stack, obj_path);
  int32_t path_length = env->length(env, stack, obj_path);
  
  memset(socket_address->sun_path, 0, strlen(socket_address->sun_path));
  memcpy(socket_address->sun_path, path, path_length);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__Un__size(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  stack[0].ival = sizeof(struct sockaddr_un);
  
  return 0;
}
