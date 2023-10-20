// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <errno.h>

#if defined(_WIN32)
# include <winsock2.h>
#endif

const char* FILE_NAME = "Sys/Errno.c";

int32_t SPVM__Errno__errno(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  stack[0].ival = errno;
  
  return 0;
}

int32_t SPVM__Errno__set_errno(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  errno = stack[0].ival;
  
  return 0;
}

int32_t SPVM__Errno__E2BIG(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(E2BIG)
  stack[0].ival = E2BIG;
  return 0;
#else
  env->die(env, stack, "E2BIG is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EACCES(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EACCES)
  stack[0].ival = EACCES;
  return 0;
#else
  env->die(env, stack, "EACCES is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EADDRINUSE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EADDRINUSE)
  stack[0].ival = EADDRINUSE;
  return 0;
#else
  env->die(env, stack, "EADDRINUSE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EADDRNOTAVAIL(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EADDRNOTAVAIL)
  stack[0].ival = EADDRNOTAVAIL;
  return 0;
#else
  env->die(env, stack, "EADDRNOTAVAIL is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EAFNOSUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EAFNOSUPPORT)
  stack[0].ival = EAFNOSUPPORT;
  return 0;
#else
  env->die(env, stack, "EAFNOSUPPORT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EAGAIN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EAGAIN)
  stack[0].ival = EAGAIN;
  return 0;
#else
  env->die(env, stack, "EAGAIN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EALREADY(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EALREADY)
  stack[0].ival = EALREADY;
  return 0;
#else
  env->die(env, stack, "EALREADY is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EBADE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EBADE)
  stack[0].ival = EBADE;
  return 0;
#else
  env->die(env, stack, "EBADE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EBADF(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EBADF)
  stack[0].ival = EBADF;
  return 0;
#else
  env->die(env, stack, "EBADF is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EBADFD(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EBADFD)
  stack[0].ival = EBADFD;
  return 0;
#else
  env->die(env, stack, "EBADFD is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EBADMSG(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EBADMSG)
  stack[0].ival = EBADMSG;
  return 0;
#else
  env->die(env, stack, "EBADMSG is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EBADR(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EBADR)
  stack[0].ival = EBADR;
  return 0;
#else
  env->die(env, stack, "EBADR is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EBADRQC(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EBADRQC)
  stack[0].ival = EBADRQC;
  return 0;
#else
  env->die(env, stack, "EBADRQC is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EBADSLT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EBADSLT)
  stack[0].ival = EBADSLT;
  return 0;
#else
  env->die(env, stack, "EBADSLT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EBUSY(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EBUSY)
  stack[0].ival = EBUSY;
  return 0;
#else
  env->die(env, stack, "EBUSY is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ECANCELED(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ECANCELED)
  stack[0].ival = ECANCELED;
  return 0;
#else
  env->die(env, stack, "ECANCELED is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ECHILD(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ECHILD)
  stack[0].ival = ECHILD;
  return 0;
#else
  env->die(env, stack, "ECHILD is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ECHRNG(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ECHRNG)
  stack[0].ival = ECHRNG;
  return 0;
#else
  env->die(env, stack, "ECHRNG is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ECOMM(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ECOMM)
  stack[0].ival = ECOMM;
  return 0;
#else
  env->die(env, stack, "ECOMM is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ECONNABORTED(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ECONNABORTED)
  stack[0].ival = ECONNABORTED;
  return 0;
#else
  env->die(env, stack, "ECONNABORTED is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ECONNREFUSED(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ECONNREFUSED)
  stack[0].ival = ECONNREFUSED;
  return 0;
#else
  env->die(env, stack, "ECONNREFUSED is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ECONNRESET(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ECONNRESET)
  stack[0].ival = ECONNRESET;
  return 0;
#else
  env->die(env, stack, "ECONNRESET is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EDEADLK(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EDEADLK)
  stack[0].ival = EDEADLK;
  return 0;
#else
  env->die(env, stack, "EDEADLK is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EDEADLOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EDEADLOCK)
  stack[0].ival = EDEADLOCK;
  return 0;
#else
  env->die(env, stack, "EDEADLOCK is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EDESTADDRREQ(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EDESTADDRREQ)
  stack[0].ival = EDESTADDRREQ;
  return 0;
#else
  env->die(env, stack, "EDESTADDRREQ is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EDOM(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EDOM)
  stack[0].ival = EDOM;
  return 0;
#else
  env->die(env, stack, "EDOM is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EDQUOT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EDQUOT)
  stack[0].ival = EDQUOT;
  return 0;
#else
  env->die(env, stack, "EDQUOT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EEXIST(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EEXIST)
  stack[0].ival = EEXIST;
  return 0;
#else
  env->die(env, stack, "EEXIST is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EFAULT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EFAULT)
  stack[0].ival = EFAULT;
  return 0;
#else
  env->die(env, stack, "EFAULT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EFBIG(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EFBIG)
  stack[0].ival = EFBIG;
  return 0;
#else
  env->die(env, stack, "EFBIG is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EHOSTDOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EHOSTDOWN)
  stack[0].ival = EHOSTDOWN;
  return 0;
#else
  env->die(env, stack, "EHOSTDOWN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EHOSTUNREACH(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EHOSTUNREACH)
  stack[0].ival = EHOSTUNREACH;
  return 0;
#else
  env->die(env, stack, "EHOSTUNREACH is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EIDRM(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EIDRM)
  stack[0].ival = EIDRM;
  return 0;
#else
  env->die(env, stack, "EIDRM is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EILSEQ(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EILSEQ)
  stack[0].ival = EILSEQ;
  return 0;
#else
  env->die(env, stack, "EILSEQ is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EINPROGRESS(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EINPROGRESS)
  stack[0].ival = EINPROGRESS;
  return 0;
#else
  env->die(env, stack, "EINPROGRESS is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EINTR(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EINTR)
  stack[0].ival = EINTR;
  return 0;
#else
  env->die(env, stack, "EINTR is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EINVAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EINVAL)
  stack[0].ival = EINVAL;
  return 0;
#else
  env->die(env, stack, "EINVAL is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EIO(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EIO)
  stack[0].ival = EIO;
  return 0;
#else
  env->die(env, stack, "EIO is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EISCONN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EISCONN)
  stack[0].ival = EISCONN;
  return 0;
#else
  env->die(env, stack, "EISCONN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EISDIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EISDIR)
  stack[0].ival = EISDIR;
  return 0;
#else
  env->die(env, stack, "EISDIR is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EISNAM(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EISNAM)
  stack[0].ival = EISNAM;
  return 0;
#else
  env->die(env, stack, "EISNAM is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EKEYEXPIRED(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EKEYEXPIRED)
  stack[0].ival = EKEYEXPIRED;
  return 0;
#else
  env->die(env, stack, "EKEYEXPIRED is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EKEYREJECTED(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EKEYREJECTED)
  stack[0].ival = EKEYREJECTED;
  return 0;
#else
  env->die(env, stack, "EKEYREJECTED is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EKEYREVOKED(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EKEYREVOKED)
  stack[0].ival = EKEYREVOKED;
  return 0;
#else
  env->die(env, stack, "EKEYREVOKED is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EL2HLT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EL2HLT)
  stack[0].ival = EL2HLT;
  return 0;
#else
  env->die(env, stack, "EL2HLT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EL2NSYNC(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EL2NSYNC)
  stack[0].ival = EL2NSYNC;
  return 0;
#else
  env->die(env, stack, "EL2NSYNC is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EL3HLT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EL3HLT)
  stack[0].ival = EL3HLT;
  return 0;
#else
  env->die(env, stack, "EL3HLT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EL3RST(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EL3RST)
  stack[0].ival = EL3RST;
  return 0;
#else
  env->die(env, stack, "EL3RST is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ELIBACC(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ELIBACC)
  stack[0].ival = ELIBACC;
  return 0;
#else
  env->die(env, stack, "ELIBACC is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ELIBBAD(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ELIBBAD)
  stack[0].ival = ELIBBAD;
  return 0;
#else
  env->die(env, stack, "ELIBBAD is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ELIBMAX(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ELIBMAX)
  stack[0].ival = ELIBMAX;
  return 0;
#else
  env->die(env, stack, "ELIBMAX is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ELIBSCN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ELIBSCN)
  stack[0].ival = ELIBSCN;
  return 0;
#else
  env->die(env, stack, "ELIBSCN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ELIBEXEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ELIBEXEC)
  stack[0].ival = ELIBEXEC;
  return 0;
#else
  env->die(env, stack, "ELIBEXEC is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ELOOP(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ELOOP)
  stack[0].ival = ELOOP;
  return 0;
#else
  env->die(env, stack, "ELOOP is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EMEDIUMTYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EMEDIUMTYPE)
  stack[0].ival = EMEDIUMTYPE;
  return 0;
#else
  env->die(env, stack, "EMEDIUMTYPE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EMFILE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EMFILE)
  stack[0].ival = EMFILE;
  return 0;
#else
  env->die(env, stack, "EMFILE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EMLINK(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EMLINK)
  stack[0].ival = EMLINK;
  return 0;
#else
  env->die(env, stack, "EMLINK is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EMSGSIZE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EMSGSIZE)
  stack[0].ival = EMSGSIZE;
  return 0;
#else
  env->die(env, stack, "EMSGSIZE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EMULTIHOP(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EMULTIHOP)
  stack[0].ival = EMULTIHOP;
  return 0;
#else
  env->die(env, stack, "EMULTIHOP is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENAMETOOLONG(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENAMETOOLONG)
  stack[0].ival = ENAMETOOLONG;
  return 0;
#else
  env->die(env, stack, "ENAMETOOLONG is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENETDOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENETDOWN)
  stack[0].ival = ENETDOWN;
  return 0;
#else
  env->die(env, stack, "ENETDOWN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENETRESET(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENETRESET)
  stack[0].ival = ENETRESET;
  return 0;
#else
  env->die(env, stack, "ENETRESET is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENETUNREACH(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENETUNREACH)
  stack[0].ival = ENETUNREACH;
  return 0;
#else
  env->die(env, stack, "ENETUNREACH is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENFILE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENFILE)
  stack[0].ival = ENFILE;
  return 0;
#else
  env->die(env, stack, "ENFILE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOBUFS(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOBUFS)
  stack[0].ival = ENOBUFS;
  return 0;
#else
  env->die(env, stack, "ENOBUFS is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENODATA(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENODATA)
  stack[0].ival = ENODATA;
  return 0;
#else
  env->die(env, stack, "ENODATA is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENODEV(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENODEV)
  stack[0].ival = ENODEV;
  return 0;
#else
  env->die(env, stack, "ENODEV is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOENT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOENT)
  stack[0].ival = ENOENT;
  return 0;
#else
  env->die(env, stack, "ENOENT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOEXEC(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOEXEC)
  stack[0].ival = ENOEXEC;
  return 0;
#else
  env->die(env, stack, "ENOEXEC is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOKEY(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOKEY)
  stack[0].ival = ENOKEY;
  return 0;
#else
  env->die(env, stack, "ENOKEY is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOLCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOLCK)
  stack[0].ival = ENOLCK;
  return 0;
#else
  env->die(env, stack, "ENOLCK is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOLINK(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOLINK)
  stack[0].ival = ENOLINK;
  return 0;
#else
  env->die(env, stack, "ENOLINK is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOMEDIUM(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOMEDIUM)
  stack[0].ival = ENOMEDIUM;
  return 0;
#else
  env->die(env, stack, "ENOMEDIUM is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOMEM(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOMEM)
  stack[0].ival = ENOMEM;
  return 0;
#else
  env->die(env, stack, "ENOMEM is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOMSG(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOMSG)
  stack[0].ival = ENOMSG;
  return 0;
#else
  env->die(env, stack, "ENOMSG is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENONET(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENONET)
  stack[0].ival = ENONET;
  return 0;
#else
  env->die(env, stack, "ENONET is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOPKG(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOPKG)
  stack[0].ival = ENOPKG;
  return 0;
#else
  env->die(env, stack, "ENOPKG is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOPROTOOPT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOPROTOOPT)
  stack[0].ival = ENOPROTOOPT;
  return 0;
#else
  env->die(env, stack, "ENOPROTOOPT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOSPC(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOSPC)
  stack[0].ival = ENOSPC;
  return 0;
#else
  env->die(env, stack, "ENOSPC is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOSR(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOSR)
  stack[0].ival = ENOSR;
  return 0;
#else
  env->die(env, stack, "ENOSR is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOSTR(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOSTR)
  stack[0].ival = ENOSTR;
  return 0;
#else
  env->die(env, stack, "ENOSTR is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOSYS(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOSYS)
  stack[0].ival = ENOSYS;
  return 0;
#else
  env->die(env, stack, "ENOSYS is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOTBLK(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOTBLK)
  stack[0].ival = ENOTBLK;
  return 0;
#else
  env->die(env, stack, "ENOTBLK is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOTCONN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOTCONN)
  stack[0].ival = ENOTCONN;
  return 0;
#else
  env->die(env, stack, "ENOTCONN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOTDIR(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOTDIR)
  stack[0].ival = ENOTDIR;
  return 0;
#else
  env->die(env, stack, "ENOTDIR is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOTEMPTY(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOTEMPTY)
  stack[0].ival = ENOTEMPTY;
  return 0;
#else
  env->die(env, stack, "ENOTEMPTY is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOTSOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOTSOCK)
  stack[0].ival = ENOTSOCK;
  return 0;
#else
  env->die(env, stack, "ENOTSOCK is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOTSUP(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOTSUP)
  stack[0].ival = ENOTSUP;
  return 0;
#else
  env->die(env, stack, "ENOTSUP is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOTTY(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOTTY)
  stack[0].ival = ENOTTY;
  return 0;
#else
  env->die(env, stack, "ENOTTY is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENOTUNIQ(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENOTUNIQ)
  stack[0].ival = ENOTUNIQ;
  return 0;
#else
  env->die(env, stack, "ENOTUNIQ is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ENXIO(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ENXIO)
  stack[0].ival = ENXIO;
  return 0;
#else
  env->die(env, stack, "ENXIO is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EOPNOTSUPP(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EOPNOTSUPP)
  stack[0].ival = EOPNOTSUPP;
  return 0;
#else
  env->die(env, stack, "EOPNOTSUPP is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EOVERFLOW(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EOVERFLOW)
  stack[0].ival = EOVERFLOW;
  return 0;
#else
  env->die(env, stack, "EOVERFLOW is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EPERM(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EPERM)
  stack[0].ival = EPERM;
  return 0;
#else
  env->die(env, stack, "EPERM is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EPFNOSUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EPFNOSUPPORT)
  stack[0].ival = EPFNOSUPPORT;
  return 0;
#else
  env->die(env, stack, "EPFNOSUPPORT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EPIPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EPIPE)
  stack[0].ival = EPIPE;
  return 0;
#else
  env->die(env, stack, "EPIPE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EPROTO(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EPROTO)
  stack[0].ival = EPROTO;
  return 0;
#else
  env->die(env, stack, "EPROTO is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EPROTONOSUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EPROTONOSUPPORT)
  stack[0].ival = EPROTONOSUPPORT;
  return 0;
#else
  env->die(env, stack, "EPROTONOSUPPORT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EPROTOTYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EPROTOTYPE)
  stack[0].ival = EPROTOTYPE;
  return 0;
#else
  env->die(env, stack, "EPROTOTYPE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ERANGE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ERANGE)
  stack[0].ival = ERANGE;
  return 0;
#else
  env->die(env, stack, "ERANGE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EREMCHG(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EREMCHG)
  stack[0].ival = EREMCHG;
  return 0;
#else
  env->die(env, stack, "EREMCHG is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EREMOTE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EREMOTE)
  stack[0].ival = EREMOTE;
  return 0;
#else
  env->die(env, stack, "EREMOTE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EREMOTEIO(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EREMOTEIO)
  stack[0].ival = EREMOTEIO;
  return 0;
#else
  env->die(env, stack, "EREMOTEIO is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ERESTART(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ERESTART)
  stack[0].ival = ERESTART;
  return 0;
#else
  env->die(env, stack, "ERESTART is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EROFS(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EROFS)
  stack[0].ival = EROFS;
  return 0;
#else
  env->die(env, stack, "EROFS is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ESHUTDOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ESHUTDOWN)
  stack[0].ival = ESHUTDOWN;
  return 0;
#else
  env->die(env, stack, "ESHUTDOWN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ESPIPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ESPIPE)
  stack[0].ival = ESPIPE;
  return 0;
#else
  env->die(env, stack, "ESPIPE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ESOCKTNOSUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ESOCKTNOSUPPORT)
  stack[0].ival = ESOCKTNOSUPPORT;
  return 0;
#else
  env->die(env, stack, "ESOCKTNOSUPPORT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ESRCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ESRCH)
  stack[0].ival = ESRCH;
  return 0;
#else
  env->die(env, stack, "ESRCH is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ESTALE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ESTALE)
  stack[0].ival = ESTALE;
  return 0;
#else
  env->die(env, stack, "ESTALE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ESTRPIPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ESTRPIPE)
  stack[0].ival = ESTRPIPE;
  return 0;
#else
  env->die(env, stack, "ESTRPIPE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ETIME(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ETIME)
  stack[0].ival = ETIME;
  return 0;
#else
  env->die(env, stack, "ETIME is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ETIMEDOUT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ETIMEDOUT)
  stack[0].ival = ETIMEDOUT;
  return 0;
#else
  env->die(env, stack, "ETIMEDOUT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__ETXTBSY(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(ETXTBSY)
  stack[0].ival = ETXTBSY;
  return 0;
#else
  env->die(env, stack, "ETXTBSY is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EUCLEAN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EUCLEAN)
  stack[0].ival = EUCLEAN;
  return 0;
#else
  env->die(env, stack, "EUCLEAN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EUNATCH(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EUNATCH)
  stack[0].ival = EUNATCH;
  return 0;
#else
  env->die(env, stack, "EUNATCH is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EUSERS(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EUSERS)
  stack[0].ival = EUSERS;
  return 0;
#else
  env->die(env, stack, "EUSERS is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EWOULDBLOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EWOULDBLOCK)
  stack[0].ival = EWOULDBLOCK;
  return 0;
#else
  env->die(env, stack, "EWOULDBLOCK is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EXDEV(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EXDEV)
  stack[0].ival = EXDEV;
  return 0;
#else
  env->die(env, stack, "EXDEV is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__EXFULL(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(EXFULL)
  stack[0].ival = EXFULL;
  return 0;
#else
  env->die(env, stack, "EXFULL is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif
  
}

int32_t SPVM__Errno__WSAEACCES(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEACCES)
  stack[0].ival = WSAEACCES;
  return 0;
#else
  env->die(env, stack, "WSAEACCES is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEADDRINUSE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEADDRINUSE)
  stack[0].ival = WSAEADDRINUSE;
  return 0;
#else
  env->die(env, stack, "WSAEADDRINUSE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEADDRNOTAVAIL(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEADDRNOTAVAIL)
  stack[0].ival = WSAEADDRNOTAVAIL;
  return 0;
#else
  env->die(env, stack, "WSAEADDRNOTAVAIL is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEAFNOSUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEAFNOSUPPORT)
  stack[0].ival = WSAEAFNOSUPPORT;
  return 0;
#else
  env->die(env, stack, "WSAEAFNOSUPPORT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEALREADY(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEALREADY)
  stack[0].ival = WSAEALREADY;
  return 0;
#else
  env->die(env, stack, "WSAEALREADY is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEBADF(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEBADF)
  stack[0].ival = WSAEBADF;
  return 0;
#else
  env->die(env, stack, "WSAEBADF is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAECANCELLED(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAECANCELLED)
  stack[0].ival = WSAECANCELLED;
  return 0;
#else
  env->die(env, stack, "WSAECANCELLED is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAECONNABORTED(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAECONNABORTED)
  stack[0].ival = WSAECONNABORTED;
  return 0;
#else
  env->die(env, stack, "WSAECONNABORTED is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAECONNREFUSED(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAECONNREFUSED)
  stack[0].ival = WSAECONNREFUSED;
  return 0;
#else
  env->die(env, stack, "WSAECONNREFUSED is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAECONNRESET(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAECONNRESET)
  stack[0].ival = WSAECONNRESET;
  return 0;
#else
  env->die(env, stack, "WSAECONNRESET is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEDESTADDRREQ(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEDESTADDRREQ)
  stack[0].ival = WSAEDESTADDRREQ;
  return 0;
#else
  env->die(env, stack, "WSAEDESTADDRREQ is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEDISCON(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEDISCON)
  stack[0].ival = WSAEDISCON;
  return 0;
#else
  env->die(env, stack, "WSAEDISCON is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEDQUOT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEDQUOT)
  stack[0].ival = WSAEDQUOT;
  return 0;
#else
  env->die(env, stack, "WSAEDQUOT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEFAULT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEFAULT)
  stack[0].ival = WSAEFAULT;
  return 0;
#else
  env->die(env, stack, "WSAEFAULT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEHOSTDOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEHOSTDOWN)
  stack[0].ival = WSAEHOSTDOWN;
  return 0;
#else
  env->die(env, stack, "WSAEHOSTDOWN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEHOSTUNREACH(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEHOSTUNREACH)
  stack[0].ival = WSAEHOSTUNREACH;
  return 0;
#else
  env->die(env, stack, "WSAEHOSTUNREACH is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEINPROGRESS(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEINPROGRESS)
  stack[0].ival = WSAEINPROGRESS;
  return 0;
#else
  env->die(env, stack, "WSAEINPROGRESS is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEINTR(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEINTR)
  stack[0].ival = WSAEINTR;
  return 0;
#else
  env->die(env, stack, "WSAEINTR is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEINVAL(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEINVAL)
  stack[0].ival = WSAEINVAL;
  return 0;
#else
  env->die(env, stack, "WSAEINVAL is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEINVALIDPROCTABLE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEINVALIDPROCTABLE)
  stack[0].ival = WSAEINVALIDPROCTABLE;
  return 0;
#else
  env->die(env, stack, "WSAEINVALIDPROCTABLE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEINVALIDPROVIDER(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEINVALIDPROVIDER)
  stack[0].ival = WSAEINVALIDPROVIDER;
  return 0;
#else
  env->die(env, stack, "WSAEINVALIDPROVIDER is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEISCONN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEISCONN)
  stack[0].ival = WSAEISCONN;
  return 0;
#else
  env->die(env, stack, "WSAEISCONN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAELOOP(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAELOOP)
  stack[0].ival = WSAELOOP;
  return 0;
#else
  env->die(env, stack, "WSAELOOP is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEMFILE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEMFILE)
  stack[0].ival = WSAEMFILE;
  return 0;
#else
  env->die(env, stack, "WSAEMFILE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEMSGSIZE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEMSGSIZE)
  stack[0].ival = WSAEMSGSIZE;
  return 0;
#else
  env->die(env, stack, "WSAEMSGSIZE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAENAMETOOLONG(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAENAMETOOLONG)
  stack[0].ival = WSAENAMETOOLONG;
  return 0;
#else
  env->die(env, stack, "WSAENAMETOOLONG is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAENETDOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAENETDOWN)
  stack[0].ival = WSAENETDOWN;
  return 0;
#else
  env->die(env, stack, "WSAENETDOWN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAENETRESET(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAENETRESET)
  stack[0].ival = WSAENETRESET;
  return 0;
#else
  env->die(env, stack, "WSAENETRESET is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAENETUNREACH(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAENETUNREACH)
  stack[0].ival = WSAENETUNREACH;
  return 0;
#else
  env->die(env, stack, "WSAENETUNREACH is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAENOBUFS(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAENOBUFS)
  stack[0].ival = WSAENOBUFS;
  return 0;
#else
  env->die(env, stack, "WSAENOBUFS is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAENOMORE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAENOMORE)
  stack[0].ival = WSAENOMORE;
  return 0;
#else
  env->die(env, stack, "WSAENOMORE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAENOPROTOOPT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAENOPROTOOPT)
  stack[0].ival = WSAENOPROTOOPT;
  return 0;
#else
  env->die(env, stack, "WSAENOPROTOOPT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAENOTCONN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAENOTCONN)
  stack[0].ival = WSAENOTCONN;
  return 0;
#else
  env->die(env, stack, "WSAENOTCONN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAENOTEMPTY(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAENOTEMPTY)
  stack[0].ival = WSAENOTEMPTY;
  return 0;
#else
  env->die(env, stack, "WSAENOTEMPTY is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAENOTSOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAENOTSOCK)
  stack[0].ival = WSAENOTSOCK;
  return 0;
#else
  env->die(env, stack, "WSAENOTSOCK is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEOPNOTSUPP(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEOPNOTSUPP)
  stack[0].ival = WSAEOPNOTSUPP;
  return 0;
#else
  env->die(env, stack, "WSAEOPNOTSUPP is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEPFNOSUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEPFNOSUPPORT)
  stack[0].ival = WSAEPFNOSUPPORT;
  return 0;
#else
  env->die(env, stack, "WSAEPFNOSUPPORT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEPROCLIM(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEPROCLIM)
  stack[0].ival = WSAEPROCLIM;
  return 0;
#else
  env->die(env, stack, "WSAEPROCLIM is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEPROTONOSUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEPROTONOSUPPORT)
  stack[0].ival = WSAEPROTONOSUPPORT;
  return 0;
#else
  env->die(env, stack, "WSAEPROTONOSUPPORT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEPROTOTYPE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEPROTOTYPE)
  stack[0].ival = WSAEPROTOTYPE;
  return 0;
#else
  env->die(env, stack, "WSAEPROTOTYPE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEPROVIDERFAILEDINIT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEPROVIDERFAILEDINIT)
  stack[0].ival = WSAEPROVIDERFAILEDINIT;
  return 0;
#else
  env->die(env, stack, "WSAEPROVIDERFAILEDINIT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEREFUSED(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEREFUSED)
  stack[0].ival = WSAEREFUSED;
  return 0;
#else
  env->die(env, stack, "WSAEREFUSED is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEREMOTE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEREMOTE)
  stack[0].ival = WSAEREMOTE;
  return 0;
#else
  env->die(env, stack, "WSAEREMOTE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAESHUTDOWN(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAESHUTDOWN)
  stack[0].ival = WSAESHUTDOWN;
  return 0;
#else
  env->die(env, stack, "WSAESHUTDOWN is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAESOCKTNOSUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAESOCKTNOSUPPORT)
  stack[0].ival = WSAESOCKTNOSUPPORT;
  return 0;
#else
  env->die(env, stack, "WSAESOCKTNOSUPPORT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAESTALE(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAESTALE)
  stack[0].ival = WSAESTALE;
  return 0;
#else
  env->die(env, stack, "WSAESTALE is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAETIMEDOUT(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAETIMEDOUT)
  stack[0].ival = WSAETIMEDOUT;
  return 0;
#else
  env->die(env, stack, "WSAETIMEDOUT is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAETOOMANYREFS(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAETOOMANYREFS)
  stack[0].ival = WSAETOOMANYREFS;
  return 0;
#else
  env->die(env, stack, "WSAETOOMANYREFS is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEUSERS(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEUSERS)
  stack[0].ival = WSAEUSERS;
  return 0;
#else
  env->die(env, stack, "WSAEUSERS is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}

int32_t SPVM__Errno__WSAEWOULDBLOCK(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(WSAEWOULDBLOCK)
  stack[0].ival = WSAEWOULDBLOCK;
  return 0;
#else
  env->die(env, stack, "WSAEWOULDBLOCK is not defined in this system", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_BASIC_TYPE_ID_ERROR_NOT_SUPPORTED_CLASS;
#endif

}