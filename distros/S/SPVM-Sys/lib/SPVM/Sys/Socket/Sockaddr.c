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

static const char* FILE_NAME = "Sys/Socket/Sockaddr.c";

int32_t SPVM__Sys__Socket__Sockaddr__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  struct sockaddr* socket_address = env->new_memory_block(env, stack, sizeof(struct sockaddr));
  
  void* obj_socket_address = env->new_pointer_object_by_name(env, stack, "Sys::Socket::Sockaddr", socket_address, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_socket_address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_socket_address = stack[0].oval;
  
  struct sockaddr* socket_address = env->get_pointer(env, stack, obj_socket_address);
  
  assert(socket_address);
  
  env->free_memory_block(env, stack, socket_address);
  env->set_pointer(env, stack, obj_socket_address, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__sa_family(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr* socket_address = env->get_pointer(env, stack, obj_self);
  
  stack[0].ival = socket_address->sa_family;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__set_sa_family(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct sockaddr* socket_address = env->get_pointer(env, stack, obj_self);
  
  socket_address->sa_family = stack[1].ival;
  
  return 0;
}

int32_t SPVM__Sys__Socket__Sockaddr__upgrade(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t error_id = 0;
  
  void* obj_addr = stack[0].oval;
  
  if (!obj_addr) {
    return env->die(env, stack, "$addr must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  const struct sockaddr* addr = env->get_pointer(env, stack, obj_addr);
  
  int32_t sa_family = addr->sa_family;
  
  void* obj_addr_child = NULL;
  
  switch (sa_family) {
    case AF_INET: {
      struct sockaddr_in* addr_in = env->new_memory_block(env, stack, sizeof(struct sockaddr_in));
      memcpy(addr_in, addr, sizeof(struct sockaddr_in));
      obj_addr_child = env->new_pointer_object_by_name(env, stack, "Sys::Socket::Sockaddr::In", addr_in, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      break;
    }
    case AF_INET6: {
      struct sockaddr_in6* addr_in6 = env->new_memory_block(env, stack, sizeof(struct sockaddr_in6));
      memcpy(addr_in6, addr, sizeof(struct sockaddr_in6));
      obj_addr_child = env->new_pointer_object_by_name(env, stack, "Sys::Socket::Sockaddr::In6", addr_in6, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      break;
    }
    case AF_UNIX: {
      struct sockaddr_un* addr_un = env->new_memory_block(env, stack, sizeof(struct sockaddr_un));
      memcpy(addr_un, addr, sizeof(struct sockaddr_un));
      obj_addr_child = env->new_pointer_object_by_name(env, stack, "Sys::Socket::Sockaddr::Un", addr_un, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      break;
    }
    default: {
      return env->die(env, stack, "The address family %d is not available.", sa_family, __func__, FILE_NAME, __LINE__);
    }
  }
  
  stack[0].oval = obj_addr_child;
  
  return 0;
}
