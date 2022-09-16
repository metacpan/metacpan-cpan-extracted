#include "spvm_native.h"

#include <assert.h>

#ifdef _WIN32
# include <ws2tcpip.h>
# include <winsock2.h>
# include <io.h>
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#endif

static int32_t FIELD_INDEX_ADDRINFO_MEMORY_ALLOCATED = 0;

static int32_t ADDRINFO_MEMORY_ALLOCATED_BY_NEW = 1;
static int32_t ADDRINFO_MEMORY_ALLOCATED_BY_GETADDRINFO = 2;

static const char* FILE_NAME = "Sys/Socket/Addrinfo.c";

int32_t SPVM__Sys__Socket__Addrinfo__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t e = 0;
  
  struct addrinfo* addrinfo = env->new_memory_stack(env, stack, sizeof(struct addrinfo*));

  int32_t fields_length = 1;
  void* obj_addrinfo = env->new_pointer_with_fields_by_name(env, stack, "Sys::Socket::Addrinfo", addrinfo, fields_length, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  env->set_pointer_field_int(env, stack, obj_addrinfo, FIELD_INDEX_ADDRINFO_MEMORY_ALLOCATED, ADDRINFO_MEMORY_ALLOCATED_BY_NEW);
  
  return 0;
}

int32_t SPVM__Sys__Socket__Addrinfo__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {

  // Dir handle
  void* obj_addrinfo = stack[0].oval;
  
  struct addrinfo* st_addrinfo = env->get_pointer(env, stack, obj_addrinfo);
  
  assert(st_addrinfo);
  
  int32_t memory_allocated_way = (intptr_t)env->get_pointer_field_int(env, stack, obj_addrinfo, FIELD_INDEX_ADDRINFO_MEMORY_ALLOCATED);
  if (memory_allocated_way == ADDRINFO_MEMORY_ALLOCATED_BY_NEW) {
    env->free_memory_stack(env, stack, st_addrinfo);
  }
  else if (memory_allocated_way == ADDRINFO_MEMORY_ALLOCATED_BY_GETADDRINFO) {
    freeaddrinfo(st_addrinfo);
  }
  else {
    assert(0);
  }
  
  env->set_pointer(env, stack, obj_addrinfo, NULL);
  
  return 0;
}

