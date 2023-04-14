// Copyright (c) 2023 Yuki Kimoto
// MIT License

// Windows 8.1+
#define _WIN32_WINNT 0x0603

#include "spvm_native.h"

#include <assert.h>

#if defined(_WIN32)
  #include <winsock2.h>
#else
  #include <poll.h>
#endif

const char* FILE_NAME = "Sys/Poll/PollfdArray";

int32_t SPVM__Sys__Poll__PollfdArray__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  int32_t length = stack[0].ival;
  
  if (!(length >= 0)) {
    return env->die(env, stack, "The length must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  
  struct pollfd* fds = env->new_memory_stack(env, stack, sizeof(struct pollfd) * length);
  
  int32_t fields_length = 1;
  void* obj_self = env->new_pointer_object_by_name(env, stack, "Sys::Poll::PollfdArray", fds, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  env->set_field_int_by_name(env, stack, obj_self, "length", length, &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  stack[0].oval = obj_self;
  
  return 0;
}

int32_t SPVM__Sys__Poll__PollfdArray__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  struct pollfd* fds = env->get_pointer(env, stack, obj_self);
  
  assert(fds);
  
  env->free_memory_stack(env, stack, fds);
  env->set_pointer(env, stack, obj_self, NULL);
  
  return 0;
}

int32_t SPVM__Sys__Poll__PollfdArray__fd(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t index = stack[1].ival;
  
  int32_t length = env->get_field_int_by_name(env, stack, obj_self, "length", &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  if (!(index >= 0)) {
    return env->die(env, stack, "The index must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(index < length)) {
    return env->die(env, stack, "The index must be less than the length of the file descripters", __func__, FILE_NAME, __LINE__);
  }

  struct pollfd* fds = env->get_pointer(env, stack, obj_self);
  
  int32_t fd = fds[index].fd;
  
  stack[0].ival = fd;
  
  return 0;
}

int32_t SPVM__Sys__Poll__PollfdArray__set_fd(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;

  int32_t index = stack[1].ival;
  
  int32_t length = env->get_field_int_by_name(env, stack, obj_self, "length", &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  if (!(index >= 0)) {
    return env->die(env, stack, "The index must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(index < length)) {
    return env->die(env, stack, "The index must be less than the length of the file descripters", __func__, FILE_NAME, __LINE__);
  }

  int32_t fd = stack[2].ival;
  
  struct pollfd* fds = env->get_pointer(env, stack, obj_self);
  
  fds[index].fd = fd;
  
  return 0;
}

int32_t SPVM__Sys__Poll__PollfdArray__events(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t index = stack[1].ival;
  if (!(index >= 0)) {
    return env->die(env, stack, "The index must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t length = env->get_field_int_by_name(env, stack, obj_self, "length", &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  if (!(index < length)) {
    return env->die(env, stack, "The index must be less than the length of the file descripters", __func__, FILE_NAME, __LINE__);
  }

  struct pollfd* fds = env->get_pointer(env, stack, obj_self);
  
  int16_t events = fds[index].events;
  
  stack[0].ival = events;
  
  return 0;
}

int32_t SPVM__Sys__Poll__PollfdArray__set_events(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;

  int32_t index = stack[1].ival;
  if (!(index >= 0)) {
    return env->die(env, stack, "The index must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t length = env->get_field_int_by_name(env, stack, obj_self, "length", &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  if (!(index < length)) {
    return env->die(env, stack, "The index must be less than the length of the file descripters", __func__, FILE_NAME, __LINE__);
  }

  int16_t events = stack[2].ival;
  
  struct pollfd* fds = env->get_pointer(env, stack, obj_self);
  
  fds[index].events = events;
  
  return 0;
}

int32_t SPVM__Sys__Poll__PollfdArray__revents(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;
  
  int32_t index = stack[1].ival;
  if (!(index >= 0)) {
    return env->die(env, stack, "The index must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  int32_t length = env->get_field_int_by_name(env, stack, obj_self, "length", &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  if (!(index < length)) {
    return env->die(env, stack, "The index must be less than the length of the file descripters", __func__, FILE_NAME, __LINE__);
  }

  struct pollfd* fds = env->get_pointer(env, stack, obj_self);
  
  int16_t revents = fds[index].revents;
  
  stack[0].ival = revents;
  
  return 0;
}

int32_t SPVM__Sys__Poll__PollfdArray__set_revents(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t e = 0;
  
  void* obj_self = stack[0].oval;

  int32_t index = stack[1].ival;
  if (!(index >= 0)) {
    return env->die(env, stack, "The index must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t length = env->get_field_int_by_name(env, stack, obj_self, "length", &e, __func__, FILE_NAME, __LINE__);
  if (e) { return e; }
  
  if (!(index < length)) {
    return env->die(env, stack, "The index must be less than the length of the file descripters", __func__, FILE_NAME, __LINE__);
  }

  int16_t revents = stack[2].ival;
  
  struct pollfd* fds = env->get_pointer(env, stack, obj_self);
  
  fds[index].revents = revents;
  
  return 0;
}
