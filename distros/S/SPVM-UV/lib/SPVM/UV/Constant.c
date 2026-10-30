// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"

static const char* FILE_NAME = "UV/Constant.c";

int32_t SPVM__UV__Constant__UV_VERSION_MAJOR(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_VERSION_MAJOR;
  return 0;
}

int32_t SPVM__UV__Constant__UV_VERSION_MINOR(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_VERSION_MINOR;
  return 0;
}

int32_t SPVM__UV__Constant__UV_VERSION_PATCH(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_VERSION_PATCH;
  return 0;
}

int32_t SPVM__UV__Constant__UV_VERSION_IS_RELEASE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_VERSION_IS_RELEASE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_VERSION_HEX(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_VERSION_HEX;
  return 0;
}

int32_t SPVM__UV__Constant__UV_VERSION_SUFFIX(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].oval = env->new_string_nolen(env, stack, UV_VERSION_SUFFIX);
  return 0;
}

int32_t SPVM__UV__Constant__UV_E2BIG(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_E2BIG;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EACCES(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EACCES;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EADDRINUSE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EADDRINUSE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EADDRNOTAVAIL(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EADDRNOTAVAIL;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAFNOSUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAFNOSUPPORT;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAGAIN(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAGAIN;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_ADDRFAMILY(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_ADDRFAMILY;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_AGAIN(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_AGAIN;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_BADFLAGS(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_BADFLAGS;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_BADHINTS(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_BADHINTS;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_CANCELED(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_CANCELED;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_FAIL(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_FAIL;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_FAMILY(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_FAMILY;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_MEMORY(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_MEMORY;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_NODATA(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_NODATA;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_NONAME(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_NONAME;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_OVERFLOW(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_OVERFLOW;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_PROTOCOL(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_PROTOCOL;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_SERVICE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_SERVICE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EAI_SOCKTYPE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EAI_SOCKTYPE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EALREADY(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EALREADY;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EBADF(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EBADF;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EBUSY(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EBUSY;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ECANCELED(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ECANCELED;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ECHARSET(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ECHARSET;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ECONNABORTED(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ECONNABORTED;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ECONNREFUSED(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ECONNREFUSED;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ECONNRESET(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ECONNRESET;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EDESTADDRREQ(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EDESTADDRREQ;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EEXIST(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EEXIST;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EFAULT(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EFAULT;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EFBIG(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EFBIG;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EHOSTUNREACH(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EHOSTUNREACH;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EINTR(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EINTR;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EINVAL(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EINVAL;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EIO(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EIO;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EISCONN(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EISCONN;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EISDIR(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EISDIR;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ELOOP(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ELOOP;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EMFILE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EMFILE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EMSGSIZE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EMSGSIZE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENAMETOOLONG(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENAMETOOLONG;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENETDOWN(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENETDOWN;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENETUNREACH(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENETUNREACH;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENFILE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENFILE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOBUFS(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOBUFS;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENODEV(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENODEV;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOENT(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOENT;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOMEM(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOMEM;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENONET(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENONET;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOPROTOOPT(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOPROTOOPT;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOSPC(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOSPC;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOSYS(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOSYS;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOTCONN(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOTCONN;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOTDIR(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOTDIR;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOTEMPTY(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOTEMPTY;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOTSOCK(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOTSOCK;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENOTSUP(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENOTSUP;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EPERM(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EPERM;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EPIPE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EPIPE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EPROTO(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EPROTO;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EPROTONOSUPPORT(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EPROTONOSUPPORT;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EPROTOTYPE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EPROTOTYPE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ERANGE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ERANGE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EROFS(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EROFS;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ESHUTDOWN(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ESHUTDOWN;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ESPIPE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ESPIPE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ESRCH(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ESRCH;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ETIMEDOUT(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ETIMEDOUT;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ETXTBSY(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ETXTBSY;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EXDEV(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EXDEV;
  return 0;
}

int32_t SPVM__UV__Constant__UV_UNKNOWN(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_UNKNOWN;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EOF(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EOF;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ENXIO(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ENXIO;
  return 0;
}

int32_t SPVM__UV__Constant__UV_EMLINK(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_EMLINK;
  return 0;
}

int32_t SPVM__UV__Constant__UV_ASYNC(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_ASYNC;
  return 0;
}

int32_t SPVM__UV__Constant__UV_CHECK(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_CHECK;
  return 0;
}

int32_t SPVM__UV__Constant__UV_FS_EVENT(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_FS_EVENT;
  return 0;
}

int32_t SPVM__UV__Constant__UV_FS_POLL(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_FS_POLL;
  return 0;
}

int32_t SPVM__UV__Constant__UV_IDLE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_IDLE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_NAMED_PIPE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_NAMED_PIPE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_POLL(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_POLL;
  return 0;
}

int32_t SPVM__UV__Constant__UV_PREPARE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_PREPARE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_PROCESS(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_PROCESS;
  return 0;
}

int32_t SPVM__UV__Constant__UV_STREAM(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_STREAM;
  return 0;
}

int32_t SPVM__UV__Constant__UV_TCP(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_TCP;
  return 0;
}

int32_t SPVM__UV__Constant__UV_TIMER(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_TIMER;
  return 0;
}

int32_t SPVM__UV__Constant__UV_TTY(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_TTY;
  return 0;
}

int32_t SPVM__UV__Constant__UV_UDP(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_UDP;
  return 0;
}

int32_t SPVM__UV__Constant__UV_SIGNAL(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_SIGNAL;
  return 0;
}

int32_t SPVM__UV__Constant__UV_FILE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_FILE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_RUN_DEFAULT(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_RUN_DEFAULT;
  return 0;
}

int32_t SPVM__UV__Constant__UV_RUN_ONCE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_RUN_ONCE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_RUN_NOWAIT(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_RUN_NOWAIT;
  return 0;
}

int32_t SPVM__UV__Constant__UV_LOOP_BLOCK_SIGNAL(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_LOOP_BLOCK_SIGNAL;
  return 0;
}

int32_t SPVM__UV__Constant__UV_READABLE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_READABLE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_WRITABLE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_WRITABLE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_DISCONNECT(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_DISCONNECT;
  return 0;
}

int32_t SPVM__UV__Constant__UV_PRIORITIZED(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_PRIORITIZED;
  return 0;
}

int32_t SPVM__UV__Constant__UV_TTY_MODE_NORMAL(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_TTY_MODE_NORMAL;
  return 0;
}

int32_t SPVM__UV__Constant__UV_TTY_MODE_RAW(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_TTY_MODE_RAW;
  return 0;
}

int32_t SPVM__UV__Constant__UV_TTY_MODE_IO(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_TTY_MODE_IO;
  return 0;
}

int32_t SPVM__UV__Constant__UV_JOIN_GROUP(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_JOIN_GROUP;
  return 0;
}

int32_t SPVM__UV__Constant__UV_LEAVE_GROUP(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_LEAVE_GROUP;
  return 0;
}

int32_t SPVM__UV__Constant__UV_IGNORE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_IGNORE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_CREATE_PIPE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_CREATE_PIPE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_INHERIT_FD(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_INHERIT_FD;
  return 0;
}

int32_t SPVM__UV__Constant__UV_INHERIT_STREAM(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_INHERIT_STREAM;
  return 0;
}

int32_t SPVM__UV__Constant__UV_READABLE_PIPE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_READABLE_PIPE;
  return 0;
}

int32_t SPVM__UV__Constant__UV_WRITABLE_PIPE(SPVM_ENV* env, SPVM_VALUE* stack) {
  stack[0].ival = (int32_t)UV_WRITABLE_PIPE;
  return 0;
}
