#include "spvm_native.h"

#include <unistd.h>
#include <sys/types.h>
#include <errno.h>
#include <signal.h>
#include <stdlib.h>
#include <assert.h>

static const char* FILE_NAME = "Sys/Signal.c";

int32_t SPVM__Sys__Signal__kill(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "kill is not supported on this system(_WIN32)", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t pid = stack[0].ival;
  int32_t sig = stack[1].ival;
  
  int32_t status = kill(pid, sig);
  if (status == -1) {
    env->die(env, stack, "[System Error]kill failed:%s", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Signal__raise(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t sig = stack[0].ival;
  
  int32_t status = raise(sig);
  if (status != 0) {
    env->die(env, stack, "[System Error]raise failed:%s", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Signal__alarm(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "alarm is not supported on this system(_WIN32)", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t seconds = stack[0].ival;
  
  int32_t rest_time = alarm(seconds);
  
  stack[0].ival = rest_time;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Signal__ualarm(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "ualarm is not supported on this system(_WIN32)", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t usecs = stack[0].ival;

  if (!(usecs >= 0)) {
    return env->die(env, stack, "The $usecs must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }

  if (!(usecs < 1000000)) {
    return env->die(env, stack, "The $usecs must be less than 1000000", __func__, FILE_NAME, __LINE__);
  }

  int32_t interval = stack[1].ival;
  
  if (!(interval >= 0)) {
    return env->die(env, stack, "The $usecs must be greater than 0", __func__, FILE_NAME, __LINE__);
  }

  if (!(interval < 1000000)) {
    return env->die(env, stack, "The $usecs must be less than 1000000", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t rest_usecs = ualarm(usecs, interval);
  
  stack[0].ival = rest_usecs;
  
  return 0;
#endif
}

static int8_t monitored_signal_numbers[256] = {0};

static void set_monitored_signal_numbers(int32_t signum) {
  monitored_signal_numbers[signum] = 1;
}

int32_t SPVM__Sys__Signal__new_signal_handler_sig_monitor(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t e = 0;
  
  void* obj_signal_handler_monitor = env->new_object_by_name(env, stack, "Sys::Signal::Handler", &e, __func__, __FILE__, __LINE__);
  if (e) { return e; }
  
  env->set_pointer(env, stack, obj_signal_handler_monitor, &set_monitored_signal_numbers);
  
  stack[0].oval = obj_signal_handler_monitor;
  
  return 0;
}

int32_t SPVM__Sys__Signal__new_signal_handler_sig_dfl(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t e = 0;
  
  void* obj_signal_handler_monitor = env->new_object_by_name(env, stack, "Sys::Signal::Handler", &e, __func__, __FILE__, __LINE__);
  if (e) { return e; }
  
  env->set_pointer(env, stack, obj_signal_handler_monitor, SIG_DFL);
  
  stack[0].oval = obj_signal_handler_monitor;
  
  return 0;
}

int32_t SPVM__Sys__Signal__new_signal_handler_sig_ign(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t e = 0;
  
  void* obj_signal_handler_monitor = env->new_object_by_name(env, stack, "Sys::Signal::Handler", &e, __func__, __FILE__, __LINE__);
  if (e) { return e; }
  
  env->set_pointer(env, stack, obj_signal_handler_monitor, SIG_IGN);
  
  stack[0].oval = obj_signal_handler_monitor;
  
  return 0;
}

int32_t SPVM__Sys__Signal__new_signal_handler_sig_err(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t e = 0;
  
  void* obj_signal_handler_monitor = env->new_object_by_name(env, stack, "Sys::Signal::Handler", &e, __func__, __FILE__, __LINE__);
  if (e) { return e; }
  
  env->set_pointer(env, stack, obj_signal_handler_monitor, SIG_ERR);
  
  stack[0].oval = obj_signal_handler_monitor;
  
  return 0;
}

int32_t SPVM__Sys__Signal__signal(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t e = 0;
  
  int32_t signum = stack[0].ival;
  if (!(signum >= 0)) {
    return env->die(env, stack, "The $signum must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(signum < 256)) {
    return env->die(env, stack, "The $signum must be less than 256", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_handler = stack[1].oval;

  if (!obj_handler) {
    return env->die(env, stack, "The $handler must be defined", __func__, FILE_NAME, __LINE__);
  }
  
  void* handler = env->get_pointer(env, stack, obj_handler);
  
  void* old_handler = signal(signum, handler);

  if (old_handler == SIG_ERR) {
    env->die(env, stack, "[System Error]signal failed:%s", env->strerror(env, stack, errno, 0), __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  void* obj_old_handler;
  if (old_handler == SIG_DFL) {
    obj_old_handler = env->get_class_var_object_by_name(env, stack, "Sys::Signal", "$SIG_DFL", &e, __func__, __FILE__, __LINE__);
    if (e) { return e; }
  }
  else if (old_handler == SIG_IGN) {
    obj_old_handler = env->get_class_var_object_by_name(env, stack, "Sys::Signal", "$SIG_IGN", &e, __func__, __FILE__, __LINE__);
    if (e) { return e; }
  }
  else if (old_handler == &set_monitored_signal_numbers) {
    obj_old_handler = env->get_class_var_object_by_name(env, stack, "Sys::Signal", "$SIG_MONITOR", &e, __func__, __FILE__, __LINE__);
    if (e) { return e; }
  }
  else {
    obj_old_handler = env->new_object_by_name(env, stack, "Sys::Signal::Handler::Unknown", &e, __func__, __FILE__, __LINE__);
    if (e) { return e; }
  }
  
  stack[0].oval = obj_old_handler;
  
  return 0;
}

int32_t SPVM__Sys__Signal__reset_monitored_signal(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t signum = stack[0].ival;
  if (!(signum >= 0)) {
    return env->die(env, stack, "The $signum must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(signum < 256)) {
    return env->die(env, stack, "The $signum must be less than 256", __func__, FILE_NAME, __LINE__);
  }
  
  monitored_signal_numbers[signum] = 0;
  
  return 0;
}

int32_t SPVM__Sys__Signal__check_monitored_signal(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t signum = stack[0].ival;
  if (!(signum >= 0)) {
    return env->die(env, stack, "The $signum must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  
  if (!(signum < 256)) {
    return env->die(env, stack, "The $signum must be less than 256", __func__, FILE_NAME, __LINE__);
  }
  
  int32_t monitored_signal_number = monitored_signal_numbers[signum];
  
  stack[0].ival = monitored_signal_number;
  
  return 0;
}
