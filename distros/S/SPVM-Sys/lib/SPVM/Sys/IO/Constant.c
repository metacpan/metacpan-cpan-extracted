// Copyright (c) 2023 Yuki Kimoto
// MIT License

// Windows 8.1+
#define _WIN32_WINNT 0x0603

#include "spvm_native.h"

#include <unistd.h>
#include <stdio.h>
#include <sys/fcntl.h>
#include <sys/stat.h>
#include <sys/file.h>

static const char* FILE_NAME = "Sys/IO/Constant.c";

int32_t SPVM__Sys__IO__Constant__AT_EMPTY_PATH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AT_EMPTY_PATH
  stack[0].ival = AT_EMPTY_PATH;
  return 0;
#else
  env->die(env, stack, "AT_EMPTY_PATH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__AT_FDCWD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AT_FDCWD
  stack[0].ival = AT_FDCWD;
  return 0;
#else
  env->die(env, stack, "AT_FDCWD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__AT_NO_AUTOMOUNT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AT_NO_AUTOMOUNT
  stack[0].ival = AT_NO_AUTOMOUNT;
  return 0;
#else
  env->die(env, stack, "AT_NO_AUTOMOUNT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__AT_SYMLINK_FOLLOW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AT_SYMLINK_FOLLOW
  stack[0].ival = AT_SYMLINK_FOLLOW;
  return 0;
#else
  env->die(env, stack, "AT_SYMLINK_FOLLOW is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__AT_SYMLINK_NOFOLLOW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AT_SYMLINK_NOFOLLOW
  stack[0].ival = AT_SYMLINK_NOFOLLOW;
  return 0;
#else
  env->die(env, stack, "AT_SYMLINK_NOFOLLOW is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__CAP_CHOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CAP_CHOWN
  stack[0].ival = CAP_CHOWN;
  return 0;
#else
  env->die(env, stack, "CAP_CHOWN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__CAP_DAC_READ_SEARCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CAP_DAC_READ_SEARCH
  stack[0].ival = CAP_DAC_READ_SEARCH;
  return 0;
#else
  env->die(env, stack, "CAP_DAC_READ_SEARCH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__CAP_FOWNER(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CAP_FOWNER
  stack[0].ival = CAP_FOWNER;
  return 0;
#else
  env->die(env, stack, "CAP_FOWNER is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__CAP_FSETID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CAP_FSETID
  stack[0].ival = CAP_FSETID;
  return 0;
#else
  env->die(env, stack, "CAP_FSETID is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__CAP_LEASE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CAP_LEASE
  stack[0].ival = CAP_LEASE;
  return 0;
#else
  env->die(env, stack, "CAP_LEASE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__CAP_SYS_RESOURCE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef CAP_SYS_RESOURCE
  stack[0].ival = CAP_SYS_RESOURCE;
  return 0;
#else
  env->die(env, stack, "CAP_SYS_RESOURCE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__DN_ACCESS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef DN_ACCESS
  stack[0].ival = DN_ACCESS;
  return 0;
#else
  env->die(env, stack, "DN_ACCESS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__DN_ATTRIB(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef DN_ATTRIB
  stack[0].ival = DN_ATTRIB;
  return 0;
#else
  env->die(env, stack, "DN_ATTRIB is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__DN_CREATE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef DN_CREATE
  stack[0].ival = DN_CREATE;
  return 0;
#else
  env->die(env, stack, "DN_CREATE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__DN_DELETE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef DN_DELETE
  stack[0].ival = DN_DELETE;
  return 0;
#else
  env->die(env, stack, "DN_DELETE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__DN_MODIFY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef DN_MODIFY
  stack[0].ival = DN_MODIFY;
  return 0;
#else
  env->die(env, stack, "DN_MODIFY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__DN_MULTISHOT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef DN_MULTISHOT
  stack[0].ival = DN_MULTISHOT;
  return 0;
#else
  env->die(env, stack, "DN_MULTISHOT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__DN_RENAME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef DN_RENAME
  stack[0].ival = DN_RENAME;
  return 0;
#else
  env->die(env, stack, "DN_RENAME is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__EOF(SPVM_ENV* env, SPVM_VALUE* stack) {

  stack[0].ival = EOF;
  
  return 0;
}

int32_t SPVM__Sys__IO__Constant__FD_CLOEXEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef FD_CLOEXEC
  stack[0].ival = FD_CLOEXEC;
  return 0;
#else
  env->die(env, stack, "FD_CLOEXEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_ADD_SEALS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_ADD_SEALS
  stack[0].ival = F_ADD_SEALS;
  return 0;
#else
  env->die(env, stack, "F_ADD_SEALS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_DUPFD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_DUPFD
  stack[0].ival = F_DUPFD;
  return 0;
#else
  env->die(env, stack, "F_DUPFD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_DUPFD_CLOEXEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_DUPFD_CLOEXEC
  stack[0].ival = F_DUPFD_CLOEXEC;
  return 0;
#else
  env->die(env, stack, "F_DUPFD_CLOEXEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GETFD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GETFD
  stack[0].ival = F_GETFD;
  return 0;
#else
  env->die(env, stack, "F_GETFD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GETFL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GETFL
  stack[0].ival = F_GETFL;
  return 0;
#else
  env->die(env, stack, "F_GETFL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GETLEASE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GETLEASE
  stack[0].ival = F_GETLEASE;
  return 0;
#else
  env->die(env, stack, "F_GETLEASE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GETLK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GETLK
  stack[0].ival = F_GETLK;
  return 0;
#else
  env->die(env, stack, "F_GETLK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GETLK64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GETLK64
  stack[0].ival = F_GETLK64;
  return 0;
#else
  env->die(env, stack, "F_GETLK64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GETOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GETOWN
  stack[0].ival = F_GETOWN;
  return 0;
#else
  env->die(env, stack, "F_GETOWN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GETOWN_EX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GETOWN_EX
  stack[0].ival = F_GETOWN_EX;
  return 0;
#else
  env->die(env, stack, "F_GETOWN_EX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GETPIPE_SZ(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GETPIPE_SZ
  stack[0].ival = F_GETPIPE_SZ;
  return 0;
#else
  env->die(env, stack, "F_GETPIPE_SZ is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GETSIG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GETSIG
  stack[0].ival = F_GETSIG;
  return 0;
#else
  env->die(env, stack, "F_GETSIG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GET_FILE_RW_HINT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GET_FILE_RW_HINT
  stack[0].ival = F_GET_FILE_RW_HINT;
  return 0;
#else
  env->die(env, stack, "F_GET_FILE_RW_HINT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GET_RW_HINT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GET_RW_HINT
  stack[0].ival = F_GET_RW_HINT;
  return 0;
#else
  env->die(env, stack, "F_GET_RW_HINT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_GET_SEALS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_GET_SEALS
  stack[0].ival = F_GET_SEALS;
  return 0;
#else
  env->die(env, stack, "F_GET_SEALS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_NOTIFY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_NOTIFY
  stack[0].ival = F_NOTIFY;
  return 0;
#else
  env->die(env, stack, "F_NOTIFY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_OFD_GETLK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_OFD_GETLK
  stack[0].ival = F_OFD_GETLK;
  return 0;
#else
  env->die(env, stack, "F_OFD_GETLK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_OFD_SETLK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_OFD_SETLK
  stack[0].ival = F_OFD_SETLK;
  return 0;
#else
  env->die(env, stack, "F_OFD_SETLK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_OFD_SETLKW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_OFD_SETLKW
  stack[0].ival = F_OFD_SETLKW;
  return 0;
#else
  env->die(env, stack, "F_OFD_SETLKW is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_OWNER_PGRP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_OWNER_PGRP
  stack[0].ival = F_OWNER_PGRP;
  return 0;
#else
  env->die(env, stack, "F_OWNER_PGRP is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_OWNER_PID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_OWNER_PID
  stack[0].ival = F_OWNER_PID;
  return 0;
#else
  env->die(env, stack, "F_OWNER_PID is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_OWNER_TID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_OWNER_TID
  stack[0].ival = F_OWNER_TID;
  return 0;
#else
  env->die(env, stack, "F_OWNER_TID is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_RDLCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_RDLCK
  stack[0].ival = F_RDLCK;
  return 0;
#else
  env->die(env, stack, "F_RDLCK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SEAL_FUTURE_WRITE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SEAL_FUTURE_WRITE
  stack[0].ival = F_SEAL_FUTURE_WRITE;
  return 0;
#else
  env->die(env, stack, "F_SEAL_FUTURE_WRITE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SEAL_GROW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SEAL_GROW
  stack[0].ival = F_SEAL_GROW;
  return 0;
#else
  env->die(env, stack, "F_SEAL_GROW is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SEAL_SEAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SEAL_SEAL
  stack[0].ival = F_SEAL_SEAL;
  return 0;
#else
  env->die(env, stack, "F_SEAL_SEAL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SEAL_SHRINK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SEAL_SHRINK
  stack[0].ival = F_SEAL_SHRINK;
  return 0;
#else
  env->die(env, stack, "F_SEAL_SHRINK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SEAL_WRITE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SEAL_WRITE
  stack[0].ival = F_SEAL_WRITE;
  return 0;
#else
  env->die(env, stack, "F_SEAL_WRITE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETFD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETFD
  stack[0].ival = F_SETFD;
  return 0;
#else
  env->die(env, stack, "F_SETFD is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETFL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETFL
  stack[0].ival = F_SETFL;
  return 0;
#else
  env->die(env, stack, "F_SETFL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETLEASE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETLEASE
  stack[0].ival = F_SETLEASE;
  return 0;
#else
  env->die(env, stack, "F_SETLEASE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETLK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETLK
  stack[0].ival = F_SETLK;
  return 0;
#else
  env->die(env, stack, "F_SETLK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETLK64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETLK64
  stack[0].ival = F_SETLK64;
  return 0;
#else
  env->die(env, stack, "F_SETLK64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETLKW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETLKW
  stack[0].ival = F_SETLKW;
  return 0;
#else
  env->die(env, stack, "F_SETLKW is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETLKW64(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETLKW64
  stack[0].ival = F_SETLKW64;
  return 0;
#else
  env->die(env, stack, "F_SETLKW64 is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETOWN
  stack[0].ival = F_SETOWN;
  return 0;
#else
  env->die(env, stack, "F_SETOWN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETOWN_EX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETOWN_EX
  stack[0].ival = F_SETOWN_EX;
  return 0;
#else
  env->die(env, stack, "F_SETOWN_EX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETPIPE_SZ(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETPIPE_SZ
  stack[0].ival = F_SETPIPE_SZ;
  return 0;
#else
  env->die(env, stack, "F_SETPIPE_SZ is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SETSIG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SETSIG
  stack[0].ival = F_SETSIG;
  return 0;
#else
  env->die(env, stack, "F_SETSIG is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SET_FILE_RW_HINT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SET_FILE_RW_HINT
  stack[0].ival = F_SET_FILE_RW_HINT;
  return 0;
#else
  env->die(env, stack, "F_SET_FILE_RW_HINT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_SET_RW_HINT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_SET_RW_HINT
  stack[0].ival = F_SET_RW_HINT;
  return 0;
#else
  env->die(env, stack, "F_SET_RW_HINT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_UNLCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_UNLCK
  stack[0].ival = F_UNLCK;
  return 0;
#else
  env->die(env, stack, "F_UNLCK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_WRLCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_WRLCK
  stack[0].ival = F_WRLCK;
  return 0;
#else
  env->die(env, stack, "F_WRLCK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_APPEND(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_APPEND
  stack[0].ival = O_APPEND;
  return 0;
#else
  env->die(env, stack, "O_APPEND is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_ASYNC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_ASYNC
  stack[0].ival = O_ASYNC;
  return 0;
#else
  env->die(env, stack, "O_ASYNC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_CLOEXEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_CLOEXEC
  stack[0].ival = O_CLOEXEC;
  return 0;
#else
  env->die(env, stack, "O_CLOEXEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_CREAT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_CREAT
  stack[0].ival = O_CREAT;
  return 0;
#else
  env->die(env, stack, "O_CREAT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_DIRECT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_DIRECT
  stack[0].ival = O_DIRECT;
  return 0;
#else
  env->die(env, stack, "O_DIRECT is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_DIRECTORY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_DIRECTORY
  stack[0].ival = O_DIRECTORY;
  return 0;
#else
  env->die(env, stack, "O_DIRECTORY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_DSYNC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_DSYNC
  stack[0].ival = O_DSYNC;
  return 0;
#else
  env->die(env, stack, "O_DSYNC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_EXCL(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_EXCL
  stack[0].ival = O_EXCL;
  return 0;
#else
  env->die(env, stack, "O_EXCL is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_EXEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_EXEC
  stack[0].ival = O_EXEC;
  return 0;
#else
  env->die(env, stack, "O_EXEC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_LARGEFILE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_LARGEFILE
  stack[0].ival = O_LARGEFILE;
  return 0;
#else
  env->die(env, stack, "O_LARGEFILE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_NDELAY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_NDELAY
  stack[0].ival = O_NDELAY;
  return 0;
#else
  env->die(env, stack, "O_NDELAY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_NOATIME(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_NOATIME
  stack[0].ival = O_NOATIME;
  return 0;
#else
  env->die(env, stack, "O_NOATIME is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_NOCTTY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_NOCTTY
  stack[0].ival = O_NOCTTY;
  return 0;
#else
  env->die(env, stack, "O_NOCTTY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_NOFOLLOW(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_NOFOLLOW
  stack[0].ival = O_NOFOLLOW;
  return 0;
#else
  env->die(env, stack, "O_NOFOLLOW is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_NONBLOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_NONBLOCK
  stack[0].ival = O_NONBLOCK;
  return 0;
#else
  env->die(env, stack, "O_NONBLOCK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_PATH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_PATH
  stack[0].ival = O_PATH;
  return 0;
#else
  env->die(env, stack, "O_PATH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_RDONLY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_RDONLY
  stack[0].ival = O_RDONLY;
  return 0;
#else
  env->die(env, stack, "O_RDONLY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_RDWR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_RDWR
  stack[0].ival = O_RDWR;
  return 0;
#else
  env->die(env, stack, "O_RDWR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_RSYNC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_RSYNC
  stack[0].ival = O_RSYNC;
  return 0;
#else
  env->die(env, stack, "O_RSYNC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_SYNC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_SYNC
  stack[0].ival = O_SYNC;
  return 0;
#else
  env->die(env, stack, "O_SYNC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_TMPFILE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_TMPFILE
  stack[0].ival = O_TMPFILE;
  return 0;
#else
  env->die(env, stack, "O_TMPFILE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_TRUNC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_TRUNC
  stack[0].ival = O_TRUNC;
  return 0;
#else
  env->die(env, stack, "O_TRUNC is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__O_WRONLY(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef O_WRONLY
  stack[0].ival = O_WRONLY;
  return 0;
#else
  env->die(env, stack, "O_WRONLY is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__SEEK_CUR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SEEK_CUR
  stack[0].ival = SEEK_CUR;
  return 0;
#else
  env->die(env, stack, "SEEK_CUR is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__SEEK_DATA(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SEEK_DATA
  stack[0].ival = SEEK_DATA;
  return 0;
#else
  env->die(env, stack, "SEEK_DATA is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__SEEK_END(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SEEK_END
  stack[0].ival = SEEK_END;
  return 0;
#else
  env->die(env, stack, "SEEK_END is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__SEEK_HOLE(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SEEK_HOLE
  stack[0].ival = SEEK_HOLE;
  return 0;
#else
  env->die(env, stack, "SEEK_HOLE is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__SEEK_SET(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef SEEK_SET
  stack[0].ival = SEEK_SET;
  return 0;
#else
  env->die(env, stack, "SEEK_SET is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__R_OK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef R_OK
  stack[0].ival = R_OK;
  return 0;
#else
  env->die(env, stack, "R_OK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__W_OK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef W_OK
  stack[0].ival = W_OK;
  return 0;
#else
  env->die(env, stack, "W_OK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__X_OK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef X_OK
  stack[0].ival = X_OK;
  return 0;
#else
  env->die(env, stack, "X_OK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__F_OK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef F_OK
  stack[0].ival = F_OK;
  return 0;
#else
  env->die(env, stack, "F_OK is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif
  
}

int32_t SPVM__Sys__IO__Constant__S_CDF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_CDF
  stack[0].ival = S_CDF;
  return 0;
#else
  return env->die(env, stack, "S_CDF is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ENFMT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ENFMT
  stack[0].ival = S_ENFMT;
  return 0;
#else
  return env->die(env, stack, "S_ENFMT is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IF
  stack[0].ival = S_IF;
  return 0;
#else
  return env->die(env, stack, "S_IF is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFBLK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFBLK
  stack[0].ival = S_IFBLK;
  return 0;
#else
  return env->die(env, stack, "S_IFBLK is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFCHR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFCHR
  stack[0].ival = S_IFCHR;
  return 0;
#else
  return env->die(env, stack, "S_IFCHR is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFCMP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFCMP
  stack[0].ival = S_IFCMP;
  return 0;
#else
  return env->die(env, stack, "S_IFCMP is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFDIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFDIR
  stack[0].ival = S_IFDIR;
  return 0;
#else
  return env->die(env, stack, "S_IFDIR is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFDOOR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFDOOR
  stack[0].ival = S_IFDOOR;
  return 0;
#else
  return env->die(env, stack, "S_IFDOOR is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFIFO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFIFO
  stack[0].ival = S_IFIFO;
  return 0;
#else
  return env->die(env, stack, "S_IFIFO is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFLNK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFLNK
  stack[0].ival = S_IFLNK;
  return 0;
#else
  return env->die(env, stack, "S_IFLNK is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFMPB(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFMPB
  stack[0].ival = S_IFMPB;
  return 0;
#else
  return env->die(env, stack, "S_IFMPB is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFMPC(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFMPC
  stack[0].ival = S_IFMPC;
  return 0;
#else
  return env->die(env, stack, "S_IFMPC is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFMT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFMT
  stack[0].ival = S_IFMT;
  return 0;
#else
  return env->die(env, stack, "S_IFMT is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFNAM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFNAM
  stack[0].ival = S_IFNAM;
  return 0;
#else
  return env->die(env, stack, "S_IFNAM is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFNWK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFNWK
  stack[0].ival = S_IFNWK;
  return 0;
#else
  return env->die(env, stack, "S_IFNWK is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFREG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFREG
  stack[0].ival = S_IFREG;
  return 0;
#else
  return env->die(env, stack, "S_IFREG is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFSHAD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFSHAD
  stack[0].ival = S_IFSHAD;
  return 0;
#else
  return env->die(env, stack, "S_IFSHAD is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFSOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFSOCK
  stack[0].ival = S_IFSOCK;
  return 0;
#else
  return env->die(env, stack, "S_IFSOCK is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IFWHT(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IFWHT
  stack[0].ival = S_IFWHT;
  return 0;
#else
  return env->die(env, stack, "S_IFWHT is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_INSEM(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_INSEM
  stack[0].ival = S_INSEM;
  return 0;
#else
  return env->die(env, stack, "S_INSEM is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_INSHD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_INSHD
  stack[0].ival = S_INSHD;
  return 0;
#else
  return env->die(env, stack, "S_INSHD is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IREAD(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IREAD
  stack[0].ival = S_IREAD;
  return 0;
#else
  return env->die(env, stack, "S_IREAD is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IRGRP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IRGRP
  stack[0].ival = S_IRGRP;
  return 0;
#else
  return env->die(env, stack, "S_IRGRP is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IROTH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IROTH
  stack[0].ival = S_IROTH;
  return 0;
#else
  return env->die(env, stack, "S_IROTH is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IRUSR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IRUSR
  stack[0].ival = S_IRUSR;
  return 0;
#else
  return env->die(env, stack, "S_IRUSR is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IRWXG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IRWXG
  stack[0].ival = S_IRWXG;
  return 0;
#else
  return env->die(env, stack, "S_IRWXG is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IRWXO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IRWXO
  stack[0].ival = S_IRWXO;
  return 0;
#else
  return env->die(env, stack, "S_IRWXO is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IRWXU(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IRWXU
  stack[0].ival = S_IRWXU;
  return 0;
#else
  return env->die(env, stack, "S_IRWXU is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ISBLK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ISBLK
  stack[0].ival = S_ISBLK(stack[0].ival);
  return 0;
#else
  return env->die(env, stack, "S_ISBLK is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ISCHR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ISCHR
  stack[0].ival = S_ISCHR(stack[0].ival);
  return 0;
#else
  return env->die(env, stack, "S_ISCHR is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ISDIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ISDIR
  stack[0].ival = S_ISDIR(stack[0].ival);
  return 0;
#else
  return env->die(env, stack, "S_ISDIR is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ISFIFO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ISFIFO
  stack[0].ival = S_ISFIFO(stack[0].ival);
  return 0;
#else
  return env->die(env, stack, "S_ISFIFO is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ISGID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ISGID
  stack[0].ival = S_ISGID;
  return 0;
#else
  return env->die(env, stack, "S_ISGID is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ISLNK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ISLNK
  stack[0].ival = S_ISLNK(stack[0].ival);
  return 0;
#else
  return env->die(env, stack, "S_ISLNK is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ISREG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ISREG
  stack[0].ival = S_ISREG(stack[0].ival);
  return 0;
#else
  return env->die(env, stack, "S_ISREG is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ISSOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ISSOCK
  stack[0].ival = S_ISSOCK(stack[0].ival);
  return 0;
#else
  return env->die(env, stack, "S_ISSOCK is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ISUID(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ISUID
  stack[0].ival = S_ISUID;
  return 0;
#else
  return env->die(env, stack, "S_ISUID is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_ISVTX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_ISVTX
  stack[0].ival = S_ISVTX;
  return 0;
#else
  return env->die(env, stack, "S_ISVTX is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IWGRP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IWGRP
  stack[0].ival = S_IWGRP;
  return 0;
#else
  return env->die(env, stack, "S_IWGRP is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IWOTH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IWOTH
  stack[0].ival = S_IWOTH;
  return 0;
#else
  return env->die(env, stack, "S_IWOTH is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IWUSR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IWUSR
  stack[0].ival = S_IWUSR;
  return 0;
#else
  return env->die(env, stack, "S_IWUSR is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IXGRP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IXGRP
  stack[0].ival = S_IXGRP;
  return 0;
#else
  return env->die(env, stack, "S_IXGRP is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IXOTH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IXOTH
  stack[0].ival = S_IXOTH;
  return 0;
#else
  return env->die(env, stack, "S_IXOTH is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__S_IXUSR(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef S_IXUSR
  stack[0].ival = S_IXUSR;
  return 0;
#else
  return env->die(env, stack, "S_IXUSR is not defined on this system", __func__, FILE_NAME, __LINE__);
#endif

}

int32_t SPVM__Sys__IO__Constant__LOCK_SH(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef LOCK_SH
  stack[0].ival = LOCK_SH;
  return 0;
#else
  env->die(env, stack, "LOCK_SH is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__IO__Constant__LOCK_EX(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef LOCK_EX
  stack[0].ival = LOCK_EX;
  return 0;
#else
  env->die(env, stack, "LOCK_EX is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__IO__Constant__LOCK_UN(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef LOCK_UN
  stack[0].ival = LOCK_UN;
  return 0;
#else
  env->die(env, stack, "LOCK_UN is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__IO__Constant__AT_EACCESS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef AT_EACCESS
  stack[0].ival = AT_EACCESS;
  return 0;
#else
  env->die(env, stack, "AT_EACCESS is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__IO__Constant__STDIN_FILENO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef STDIN_FILENO
  stack[0].ival = STDIN_FILENO;
  return 0;
#else
  env->die(env, stack, "STDIN_FILENO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__IO__Constant__STDOUT_FILENO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef STDOUT_FILENO
  stack[0].ival = STDOUT_FILENO;
  return 0;
#else
  env->die(env, stack, "STDOUT_FILENO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__IO__Constant__STDERR_FILENO(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef STDERR_FILENO
  stack[0].ival = STDERR_FILENO;
  return 0;
#else
  env->die(env, stack, "STDERR_FILENO is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__IO__Constant__BUFSIZ(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef BUFSIZ
  stack[0].ival = BUFSIZ;
  return 0;
#else
  env->die(env, stack, "BUFSIZ is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__IO__Constant___IONBF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef _IONBF
  stack[0].ival = _IONBF;
  return 0;
#else
  env->die(env, stack, "_IONBF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__IO__Constant___IOLBF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef _IOLBF
  stack[0].ival = _IOLBF;
  return 0;
#else
  env->die(env, stack, "_IOLBF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__IO__Constant___IOFBF(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef _IOFBF
  stack[0].ival = _IOFBF;
  return 0;
#else
  env->die(env, stack, "_IOFBF is not defined on this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}
