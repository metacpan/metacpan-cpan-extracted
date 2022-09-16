#include "spvm_native.h"

#include <unistd.h>
#include <sys/types.h>
#include <sys/time.h>
#include <errno.h>
#include <signal.h>
#include <stdlib.h>

#ifdef _WIN32

#else
#include <sys/resource.h>
#include <sys/wait.h>
#include <sys/times.h>
#endif

const char* FILE_NAME = "Sys/Process.c";

int32_t SPVM__Sys__Process__alarm(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "alarm is not supported on this system", FILE_NAME, __LINE__);
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

int32_t SPVM__Sys__Process__fork(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "fork is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t seconds = stack[0].ival;
  
  int32_t status = fork();
  
  if (status == -1) {
    env->die(env, stack, "[System Error]fork failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status ;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__getpriority(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "getpriority is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;

  int32_t which = stack[0].ival;
  int32_t who = stack[1].ival;
  
  errno = 0;
  int32_t nice = getpriority(which, who);
  if (errno != 0) {
    env->die(env, stack, "[System Error]getpriority failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = nice;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__setpriority(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "setpriority is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t which = stack[0].ival;
  int32_t who = stack[1].ival;
  int32_t prio = stack[2].ival;
  
  int32_t status = setpriority(which, who, prio);
  if (status == -1) {
    env->die(env, stack, "[System Error]setpriority failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__sleep(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t seconds = stack[0].ival;
  
  int32_t rest_time = sleep(seconds);
  
  stack[0].ival = rest_time;
  
  return 0;
}

int32_t SPVM__Sys__Process__kill(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "kill is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t pid = stack[0].ival;
  int32_t sig = stack[1].ival;
  
  int32_t status = kill(pid, sig);
  if (status == -1) {
    env->die(env, stack, "[System Error]kill failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__wait(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "wait is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t* wstatus_ref = stack[0].iref;
  
  int wstatus_int;
  int32_t process_id = wait(&wstatus_int);
  *wstatus_ref = wstatus_int;
  
  if (process_id == -1) {
    env->die(env, stack, "[System Error]wait failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = process_id;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__waitpid(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "waitpid is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t pid = stack[0].ival;
  int32_t* wstatus_ref = stack[1].iref;
  int32_t options = stack[2].ival;
  
  int wstatus_int;
  int32_t process_id = waitpid(pid, &wstatus_int, options);
  *wstatus_ref = wstatus_int;
  
  if (process_id == -1) {
    env->die(env, stack, "[System Error]waitpid failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = process_id;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__system(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  void* obj_command = stack[0].oval;
  
  const char* command = NULL;
  if (obj_command) {
    command = env->get_chars(env, stack, obj_command);
  }
  
  int32_t status = system(command);
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Process__exit(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t stauts = stack[0].ival;
  
  exit(stauts);
  
  return 0;
}

int32_t SPVM__Sys__Process__pipe(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "pipe is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  void* obj_pipefds = stack[0].oval;
  
  if (!obj_pipefds) {
    return env->die(env, stack, "The pipe file descriptors must be defined", FILE_NAME, __LINE__);
  }
  
  int32_t pipefds_length = env->length(env, stack, obj_pipefds);
  if (!(pipefds_length == 2)) {
    return env->die(env, stack, "The length of the pipe file descriptors must 2", FILE_NAME, __LINE__);
  }
  
  int32_t* pipefds = env->get_elems_int(env, stack, obj_pipefds);

  int pipefds_int[2] = {pipefds[0], pipefds[1]};
  int32_t status = pipe(pipefds_int);

  if (status == -1) {
    env->die(env, stack, "[System Error]pipe failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__getpgrp(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "getpgrp is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t process_group_id = getpgrp();
  
  if (process_group_id == -1) {
    env->die(env, stack, "[System Error]getpgrp failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = process_group_id;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__setpgrp(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "setpgrp is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t status = setpgrp();
  
  if (status == -1) {
    env->die(env, stack, "[System Error]setpgrp failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__getpid(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  int32_t process_id = getpid();
  
  stack[0].ival = process_id;
  
  return 0;
}

int32_t SPVM__Sys__Process__getppid(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "setpgrp is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  (void)env;
  (void)stack;
  
  int32_t parent_process_id = getppid();
  
  stack[0].ival = parent_process_id;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__execv(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)env;
  (void)stack;
  
  void* obj_path = stack[0].oval;
  
  if (!obj_path) {
    return env->die(env, stack, "The path must be defined", FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);
  
  void* obj_args = stack[1].oval;
  char** argv;
  if (obj_args) {
    int32_t args_length = env->length(env, stack, obj_args);
    char** argv = env->new_memory_stack(env, stack, sizeof(char*) * args_length + 1);
    for (int32_t i = 0; i < args_length; i++) {
      void* obj_arg = env->get_elem_object(env, stack, obj_args, i);
      char* arg = (char*)env->get_chars(env, stack, obj_arg);
      argv[i] = arg;
    }
  }
  else {
    argv = env->new_memory_stack(env, stack, sizeof(char*) * 1);
  }
  
  int32_t status = execv(path, argv);
  
  env->free_memory_stack(env, stack, argv);
  
  if (status == -1) {
    env->die(env, stack, "[System Error]execv failed:%s", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__Sys__Process__times(SPVM_ENV* env, SPVM_VALUE* stack) {
#ifdef _WIN32
  env->die(env, stack, "setpgrp is not supported on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  void* obj_st_tms = stack[0].oval;
  
  if (!obj_st_tms) {
    return env->die(env, stack, "The buffer must be defined", FILE_NAME, __LINE__);
  }
  
  struct tms* st_tms = env->get_pointer(env, stack, obj_st_tms);
  
  errno = 0;
  int64_t clock_tick = times(st_tms);
  
  if (errno != 0) {
    env->die(env, stack, "[System Error]times failed:%s.", env->strerror(env, stack, errno, 0), FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].lval = clock_tick;
  
  return 0;
#endif
}

int32_t SPVM__Sys__Process__WIFEXITED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WCONTINUED
  stack[0].ival = WIFEXITED(stack[0].ival);
  return 0;
#else
  env->die(env, stack, "WIFEXITED is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__WEXITSTATUS(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WEXITSTATUS
  stack[0].ival = WEXITSTATUS(stack[0].ival);
  return 0;
#else
  env->die(env, stack, "WEXITSTATUS is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__WIFSIGNALED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WIFSIGNALED
  stack[0].ival = WIFSIGNALED(stack[0].ival);
  return 0;
#else
  env->die(env, stack, "WIFSIGNALED is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__WTERMSIG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WTERMSIG
  stack[0].ival = WTERMSIG(stack[0].ival);
  return 0;
#else
  env->die(env, stack, "WTERMSIG is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__WCOREDUMP(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WCOREDUMP
  stack[0].ival = WCOREDUMP(stack[0].ival);
  return 0;
#else
  env->die(env, stack, "WCOREDUMP is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__WIFSTOPPED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WIFSTOPPED
  stack[0].ival = WIFSTOPPED(stack[0].ival);
  return 0;
#else
  env->die(env, stack, "WIFSTOPPED is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__WSTOPSIG(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WSTOPSIG
  stack[0].ival = WSTOPSIG(stack[0].ival);
  return 0;
#else
  env->die(env, stack, "WSTOPSIG is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}

int32_t SPVM__Sys__Process__WIFCONTINUED(SPVM_ENV* env, SPVM_VALUE* stack) {

#ifdef WIFCONTINUED
  stack[0].ival = WIFCONTINUED(stack[0].ival);
  return 0;
#else
  env->die(env, stack, "WIFCONTINUED is not defined on this system", FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#endif

}
