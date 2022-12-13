#include "spvm_native.h"
#include "spvm_socket_util.h"

#include <assert.h>

const char* FILE_NAME = "Sys/Socket/In6_addr.c";

int32_t SPVM__Sys__Socket__In6_addr__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  struct in6_addr* address = env->new_memory_stack(env, stack, sizeof(struct in6_addr));

  void* obj_address = env->new_pointer_by_name(env, stack, "Sys::Socket::In6_addr", address, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_address;
  
  return 0;
}

int32_t SPVM__Sys__Socket__In6_addr__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_address = stack[0].oval;
  
  struct in6_addr* address = env->get_pointer(env, stack, obj_address);
  
  assert(address);
  
  env->free_memory_stack(env, stack, address);
  env->set_pointer(env, stack, obj_address, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Socket__In6_addr__s6_addr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_address = stack[0].oval;
  
  struct in6_addr* address = env->get_pointer(env, stack, obj_address);
  
  assert(address);
  
  void* obj_s6_addr = env->new_string(env, stack, (char*)&address->s6_addr, 16);
  
  stack[0].oval = obj_s6_addr;
  
  return 0;
}

int32_t SPVM__Sys__Socket__In6_addr__set_s6_addr(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_address = stack[0].oval;
  
  struct in6_addr* address = env->get_pointer(env, stack, obj_address);
  
  assert(address);

  void* obj_s6_addr = stack[1].oval;
  
  if (!obj_s6_addr) {
    return env->die(env, stack, "The address must be defined", FILE_NAME, __LINE__);
  }
  
  int32_t s6_addr_length = env->length(env, stack, obj_s6_addr);
  
  if (!(s6_addr_length < 16)) {
    return env->die(env, stack, "The length of the address must be less than 16", FILE_NAME, __LINE__);
  }
  
  const char* chp_s6_addr = env->get_chars(env, stack, obj_s6_addr);
  
  memset(&address->s6_addr, '\0', 16);
  memcpy(&address->s6_addr, chp_s6_addr, s6_addr_length);
  
  return 0;
}
