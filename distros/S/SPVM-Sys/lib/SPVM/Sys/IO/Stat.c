#include "spvm_native.h"

#include <assert.h>
#include <sys/stat.h>

const char* FILE_NAME = "Sys/IO/Stat.c";

int32_t SPVM__Sys__IO__Stat__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  // sizeof(struct stat) is maybe right, but Ubuntu/Linux 32bit doesn't work well in this setting.
  // So sizeof(struct stat) * 2 is allocated.
  struct stat* st_stat = env->new_memory_stack(env, stack, sizeof(struct stat) * 2);
  
  void* obj_stat = env->new_pointer_by_name(env, stack, "Sys::IO::Stat", st_stat, &e, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_stat;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  assert(st_stat);
  
  env->free_memory_stack(env, stack, st_stat);

  env->set_pointer(env, stack, obj_stat, NULL);
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_dev(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].ival = st_stat->st_dev;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_ino(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].ival = st_stat->st_ino;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_mode(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].ival = st_stat->st_mode;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_nlink(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"st_nlink\" method in the class \"Sys::IO::Stat\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].ival = st_stat->st_nlink;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Stat__st_size(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].lval = st_stat->st_size;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_blksize(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"st_blksize\" method in the class \"Sys::IO::Stat\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].lval = st_stat->st_blksize;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Stat__st_blocks(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The \"st_blocks\" method in the class \"Sys::IO::Stat\" is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].lval = st_stat->st_blocks;
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Stat__st_uid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].ival = st_stat->st_uid;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_gid(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].ival = st_stat->st_gid;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_rdev(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].ival = st_stat->st_rdev;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_mtime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].lval = st_stat->st_mtime;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_atime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].lval = st_stat->st_atime;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_ctime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].lval = st_stat->st_ctime;
  
  return 0;
}

