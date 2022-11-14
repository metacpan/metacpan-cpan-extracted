#include "spvm_native.h"

#include <assert.h>
#include <errno.h>
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

int32_t SPVM__Sys__IO__Stat__stat_raw(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t e = 0;
  
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "The $path must be defined", FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);
  
  void* obj_stat = stack[1].oval;
  if (!obj_stat) {
    return env->die(env, stack, "The $stat must be defined", FILE_NAME, __LINE__);
  }
  
  struct stat* stat_buf = env->get_pointer(env, stack, obj_stat);
  
  errno = 0;
  int32_t status = stat(path, stat_buf);

  stack[0].ival = status;
  
  return 0;
}


int32_t SPVM__Sys__IO__Stat__stat(SPVM_ENV* env, SPVM_VALUE* stack) {

  SPVM__Sys__IO__Stat__stat_raw(env, stack);
  
  int32_t status = stack[0].ival;

  if (status == -1) {
    env->die(env, stack, "[System Error]stat failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__lstat_raw(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  return env->die(env, stack, "lstat is not supported on this system(_WIN32)", FILE_NAME, __LINE__);
#else

  int32_t e = 0;
  
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "The $path must be defined", FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);
  
  void* obj_lstat = stack[1].oval;
  if (!obj_lstat) {
    return env->die(env, stack, "The $lstat must be defined", FILE_NAME, __LINE__);
  }
  
  struct stat* stat_buf = env->get_pointer(env, stack, obj_lstat);
  
  errno = 0;
  int32_t status = lstat(path, stat_buf);
  
  stack[0].ival = status;
  
  return 0;
#endif
}


int32_t SPVM__Sys__IO__Stat__lstat(SPVM_ENV* env, SPVM_VALUE* stack) {

  SPVM__Sys__IO__Stat__lstat_raw(env, stack);
  
  int32_t status = stack[0].ival;

  if (status == -1) {
    env->die(env, stack, "[System Error]lstat failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__fstat_raw(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t e = 0;
  
  int32_t fd = stack[0].ival;
  
  void* obj_stat = stack[1].oval;
  
  if (!obj_stat) {
    return env->die(env, stack, "The $stat must be defined", FILE_NAME, __LINE__);
  }
  
  struct stat* stat_buf = env->get_pointer(env, stack, obj_stat);
  
  int32_t status = fstat(fd, stat_buf);

  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__fstat(SPVM_ENV* env, SPVM_VALUE* stack) {

  SPVM__Sys__IO__Stat__fstat_raw(env, stack);
  
  int32_t status = stack[0].ival;

  if (status == -1) {
    env->die(env, stack, "[System Error]fstat failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_dev(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].lval = st_stat->st_dev;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_ino(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].lval = st_stat->st_ino;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_mode(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].ival = st_stat->st_mode;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_nlink(SPVM_ENV* env, SPVM_VALUE* stack) {
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
  stack[0].lval = st_stat->st_nlink;
  
  return 0;
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
  
  stack[0].lval = st_stat->st_rdev;
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_atime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
#ifdef __APPLE__
  stack[0].lval = st_stat->st_atimespec.tv_sec;
#else
  stack[0].lval = st_stat->st_atime;
#endif

  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_mtime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
#ifdef __APPLE__
  stack[0].lval = st_stat->st_mtimespec.tv_sec;
#else
  stack[0].lval = st_stat->st_mtime;
#endif
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_ctime(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
#ifdef __APPLE__
  stack[0].lval = st_stat->st_ctimespec.tv_sec;
#else
  stack[0].lval = st_stat->st_ctime;
#endif
  
  return 0;
}

int32_t SPVM__Sys__IO__Stat__st_atim_tv_nsec(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The st_atim_tv_nsec method in the Sys::IO::Stat is not supported on this system(_WIN32)", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#elif defined(__solaris) || defined(__sun)
  env->die(env, stack, "The st_atim_tv_nsec method in the Sys::IO::Stat is not supported on this system(__solaris or __sun)", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);

#ifdef __APPLE__
  stack[0].lval = st_stat->st_atimespec.tv_nsec;
#else
  stack[0].lval = st_stat->st_atim.tv_nsec;
#endif

  return 0;
#endif
}

int32_t SPVM__Sys__IO__Stat__st_mtim_tv_nsec(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The st_mtim_tv_nsec method in the Sys::IO::Stat is not supported on this system(_WIN32)", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#elif defined(__solaris) || defined(__sun)
  env->die(env, stack, "The st_mtim_tv_nsec method in the Sys::IO::Stat is not supported on this system(__solaris or __sun)", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
#ifdef __APPLE__
  stack[0].lval = st_stat->st_mtimespec.tv_nsec;
#else
  stack[0].lval = st_stat->st_mtim.tv_nsec;
#endif
  
  return 0;
#endif
}

int32_t SPVM__Sys__IO__Stat__st_ctim_tv_nsec(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "The st_ctim_tv_nsec method in the Sys::IO::Stat is not supported on this system(_WIN32)", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#elif defined(__solaris) || defined(__sun)
  env->die(env, stack, "The st_ctim_tv_nsec method in the Sys::IO::Stat is not supported on this system(__solaris or __sun)", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_stat = stack[0].oval;
  
  struct stat* st_stat = env->get_pointer(env, stack, obj_stat);
  
#ifdef __APPLE__
  stack[0].lval = st_stat->st_ctimespec.tv_nsec;
#else
  stack[0].lval = st_stat->st_ctim.tv_nsec;
#endif
  
  return 0;
#endif
}
