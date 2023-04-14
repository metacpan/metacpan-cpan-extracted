// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <assert.h>

const char* FILE_NAME = "Sys/Socket/Sockaddr/Storage.c";

int32_t SPVM__Sys__Socket__Sockaddr__Storage__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  struct sockaddr_storage* socket_address = env->new_memory_stack(env, stack, sizeof(struct sockaddr_storage));

  void* obj_socket_address = env->new_pointer_object_by_name(env, stack, "Sys::Socket::Sockaddr::Storage", socket_address, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_socket_address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__Storage__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_socket_address = stack[0].oval;
  
  struct sockaddr_storage* socket_address = env->get_pointer(env, stack, obj_socket_address);
  
  assert(socket_address);
  
  env->free_memory_stack(env, stack, socket_address);
  env->set_pointer(env, stack, obj_socket_address, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__Storage__ss_family(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_storage* socket_address = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = socket_address->ss_family;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__Storage__set_ss_family(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr_storage* socket_address = env->get_pointer(env, stack, obj_self);
  
  socket_address->ss_family = stack[1].ival;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__Storage__sizeof(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  stack[0].ival = sizeof(struct sockaddr_storage);
  
  return 0;
}

