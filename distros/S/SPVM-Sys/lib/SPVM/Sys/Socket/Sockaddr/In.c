// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <assert.h>

static const char* FILE_NAME = "Sys/Socket/Sockaddr/In.c";

int32_t SPVM__Sys__Socket__Sockaddr__In__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  struct sockaddr_in* socket_address = env->new_memory_block(env, stack, sizeof(struct sockaddr_in));
  
  void* obj_socket_address = env->new_pointer_object_by_name(env, stack, "Sys::Socket::Sockaddr::In", socket_address, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_socket_address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__In__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_socket_address = stack[0].oval;
  
  struct sockaddr_in* socket_address = env->get_pointer(env, stack, obj_socket_address);
  
  assert(socket_address);
  
  env->free_memory_block(env, stack, socket_address);
  env->set_pointer(env, stack, obj_socket_address, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__In__sin_family(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_in* socket_address = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = socket_address->sin_family;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__In__set_sin_family(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_in* socket_address = env->get_pointer(env, stack, obj_self);
  
  socket_address->sin_family = stack[1].ival;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__In__sin_addr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_in* socket_address = env->get_pointer(env, stack, obj_self);
  
  struct in_addr address = socket_address->sin_addr;
  
  struct in_addr* address_ret = env->new_memory_block(env, stack, sizeof(struct in_addr));
  *address_ret = address;
  
  void* obj_address_ret = env->new_pointer_object_by_name(env, stack, "Sys::Socket::In_addr", address_ret, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_address_ret;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__In__set_sin_addr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_in* socket_address = env->get_pointer(env, stack, obj_self);
  
  void* obj_address = stack[1].oval;
  
  if (!obj_address) {
    return env->die(env, stack, "The address must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  struct in_addr* address = env->get_pointer(env, stack, obj_address);
  
  socket_address->sin_addr = *address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__In__sin_port(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_in* socket_address = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = socket_address->sin_port;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__In__set_sin_port(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_in* socket_address = env->get_pointer(env, stack, obj_self);
  
  socket_address->sin_port = stack[1].ival;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__In__size(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  stack[0].ival = sizeof(struct sockaddr_in);
  
  return 0;
}
