// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <assert.h>

static const char* FILE_NAME = "Sys/Socket/Ip_mreq.c";

int32_t SPVM__Sys__Socket__Ip_mreq__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  struct ip_mreq* multi_request = env->new_memory_block(env, stack, sizeof(struct ip_mreq));
  
  void* obj_multi_request = env->new_pointer_object_by_name(env, stack, "Sys::Socket::Ip_mreq", multi_request, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_multi_request;
  
  return 0;
}


int32_t SPVM__Sys__Socket__Ip_mreq__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_multi_request = stack[0].oval;
  
  struct ip_mreq* multi_request = env->get_pointer(env, stack, obj_multi_request);
  
  assert(multi_request);
  
  env->free_memory_block(env, stack, multi_request);
  env->set_pointer(env, stack, obj_multi_request, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq__imr_multiaddr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  struct in_addr address = multi_request->imr_multiaddr;
  
  struct in_addr* address_ret = env->new_memory_block(env, stack, sizeof(struct in_addr));
  *address_ret = address;
  
  void* obj_address_ret = env->new_pointer_object_by_name(env, stack, "Sys::Socket::In_addr", address_ret, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_address_ret;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq__set_imr_multiaddr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  void* obj_address = stack[1].oval;
  struct in_addr* address = env->get_pointer(env, stack, obj_address);
  
  multi_request->imr_multiaddr = *address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq__imr_interface(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  struct in_addr imr_interface = multi_request->imr_interface;
  
  struct in_addr* imr_interface_ret = env->new_memory_block(env, stack, sizeof(struct in_addr));
  *imr_interface_ret = imr_interface;
  
  void* obj_imr_interface_ret = env->new_pointer_object_by_name(env, stack, "Sys::Socket::In_addr", imr_interface_ret, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_imr_interface_ret;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Ip_mreq__set_imr_interface(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct ip_mreq* multi_request = env->get_pointer(env, stack, obj_self);
  
  void* obj_imr_interface = stack[1].oval;
  struct in_addr* imr_interface = env->get_pointer(env, stack, obj_imr_interface);
  
  multi_request->imr_interface = *imr_interface;
  
  return 0;
}
