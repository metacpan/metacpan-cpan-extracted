// Copyright (c) 2026 Yuki Kimoto
// MIT License

#include "spvm_native.h"
#include "uv.h"
#include "spvm_uv.h"

static const char* FILE_NAME = "UV/Loop.c";

int32_t SPVM__UV__Loop__default_loop(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_loop = env->get_class_var_object_by_name(env, stack, "UV::Loop", "$DEFAULT_LOOP", &error_id, __func__, FILE_NAME, __LINE__);
  
  if (!obj_uv_loop) {
    uv_loop_t* uv_loop = uv_default_loop();
    
    obj_uv_loop = env->new_pointer_object_by_name(env, stack, "UV::Loop", uv_loop, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) return error_id;
    
    env->set_no_free(env, stack, obj_uv_loop, 1);
    
    stack[0].oval = obj_uv_loop;
    env->call_instance_method_by_name(env, stack, "init", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) return error_id;
    
    env->set_class_var_object_by_name(env, stack, "UV::Loop", "$DEFAULT_LOOP", obj_uv_loop, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) return error_id;
  }
  
  stack[0].oval = obj_uv_loop;
  
  return 0;
}

int32_t SPVM__UV__Loop__new(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  uv_loop_t* uv_loop = env->new_memory_block(env, stack, sizeof(uv_loop_t));
  
  int32_t status = uv_loop_init(uv_loop);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_loop_init failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  SPVM_OBJ* obj_uv_loop = env->new_pointer_object_by_name(env, stack, "UV::Loop", uv_loop, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  stack[0].oval = obj_uv_loop;
  env->call_instance_method_by_name(env, stack, "init", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  stack[0].oval = obj_uv_loop;
  
  return 0;
}

static void SPVM__UV__Loop__async_cb(uv_async_t* uv_handle) {
  
  int32_t error_id = 0;
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = (SPVM__UV__Handle__HANDLE_DATA*)uv_handle->data;
  
  SPVM_ENV* env = uv_handle_data->env;
  SPVM_VALUE* stack = uv_handle_data->stack;
  SPVM_OBJ* obj_uv_handle = uv_handle_data->obj_uv_handle;
  SPVM_OBJ* obj_cb = env->get_field_object_by_name(env, stack, obj_uv_handle, "async_cb", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'async_cb' field failed.");
    abort();
  }
  
  stack[0].oval = obj_cb;
  stack[1].oval = obj_uv_handle;
  env->call_instance_method_by_name(env, stack, "", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[An exception is converted to a warning in SPVM__UV__Loop__async_cb]\n%s", env->get_exception_chars(env, stack));
    return;
  }
  
}

int32_t SPVM__UV__Loop__run(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  SPVM_OBJ* obj_uv_loop = stack[0].oval;
  int32_t uv_run_mode = stack[1].ival;
  
  uv_loop_t* uv_loop = env->get_pointer(env, stack, obj_uv_loop);
  assert(uv_loop);
  
  int32_t status = uv_run(uv_loop, uv_run_mode);
  
  stack[0].ival = status;
  
  return 0;
}

int32_t SPVM__UV__Loop__idle_init(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_loop = stack[0].oval;
  SPVM_OBJ* obj_uv_idle = stack[1].oval;
  
  if (!obj_uv_idle) {
    return env->die(env, stack, "$uv_idle must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_loop_t* uv_loop = env->get_pointer(env, stack, obj_uv_loop);
  uv_idle_t* uv_idle = env->get_pointer(env, stack, obj_uv_idle);
  
  int32_t status = uv_idle_init(uv_loop, uv_idle);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_idle_init failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  stack[0].oval = obj_uv_loop;
  stack[1].oval = obj_uv_idle;
  env->call_instance_method_by_name(env, stack, "set_uv_handle", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  return 0;
}

int32_t SPVM__UV__Loop__async_init(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_loop = stack[0].oval;
  SPVM_OBJ* obj_uv_async = stack[1].oval;
  SPVM_OBJ* obj_cb = stack[2].oval;
  
  if (!obj_uv_async) {
    return env->die(env, stack, "$uv_async must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  if (!obj_cb) {
    return env->die(env, stack, "$cb must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_loop_t* uv_loop = env->get_pointer(env, stack, obj_uv_loop);
  uv_async_t* uv_async = env->get_pointer(env, stack, obj_uv_async);
  
  env->set_field_object_by_name(env, stack, obj_uv_async, "async_cb", obj_cb, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  int32_t status = uv_async_init(uv_loop, uv_async, SPVM__UV__Loop__async_cb);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_async_init failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  stack[0].oval = obj_uv_loop;
  stack[1].oval = obj_uv_async;
  env->call_instance_method_by_name(env, stack, "set_uv_handle", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  return 0;
}

int32_t SPVM__UV__Loop__timer_init(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_loop = stack[0].oval;
  SPVM_OBJ* obj_uv_timer = stack[1].oval;
  
  if (!obj_uv_timer) {
    return env->die(env, stack, "$uv_timer must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_loop_t* uv_loop = env->get_pointer(env, stack, obj_uv_loop);
  uv_timer_t* uv_timer = env->get_pointer(env, stack, obj_uv_timer);
  
  int32_t status = uv_timer_init(uv_loop, uv_timer);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_timer_init failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  stack[0].oval = obj_uv_loop;
  stack[1].oval = obj_uv_timer;
  env->call_instance_method_by_name(env, stack, "set_uv_handle", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  return 0;
}

int32_t SPVM__UV__Loop__poll_init(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_loop = stack[0].oval;
  SPVM_OBJ* obj_uv_poll = stack[1].oval;
  int32_t fd = stack[2].ival;
  
  if (!obj_uv_poll) {
    return env->die(env, stack, "$uv_poll must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_loop_t* uv_loop = env->get_pointer(env, stack, obj_uv_loop);
  uv_poll_t* uv_poll = env->get_pointer(env, stack, obj_uv_poll);
  
  int32_t status = uv_poll_init(uv_loop, uv_poll, fd);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_poll_init failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  stack[0].oval = obj_uv_loop;
  stack[1].oval = obj_uv_poll;
  env->call_instance_method_by_name(env, stack, "set_uv_handle", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  return 0;
}

int32_t SPVM__UV__Loop__pipe_init(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_loop = stack[0].oval;
  SPVM_OBJ* obj_uv_pipe = stack[1].oval;
  int32_t ipc = stack[2].ival;
  
  if (!obj_uv_pipe) {
    return env->die(env, stack, "$uv_pipe must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  uv_loop_t* uv_loop = env->get_pointer(env, stack, obj_uv_loop);
  uv_pipe_t* uv_pipe = env->get_pointer(env, stack, obj_uv_pipe);
  
  int32_t status = uv_pipe_init(uv_loop, uv_pipe, ipc);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_pipe_init failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  stack[0].oval = obj_uv_loop;
  stack[1].oval = obj_uv_pipe;
  env->call_instance_method_by_name(env, stack, "set_uv_handle", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) return error_id;
  
  return 0;
}

static void SPVM__UV__Loop__exit_cb(uv_process_t* uv_process, int64_t exit_status, int term_signal) {
  
  int32_t error_id = 0;
  
  SPVM__UV__Handle__HANDLE_DATA* uv_handle_data = (SPVM__UV__Handle__HANDLE_DATA*)uv_process->data;
  if (!uv_handle_data) {
    return;
  }
  
  SPVM_ENV* env = uv_handle_data->env;
  SPVM_VALUE* stack = uv_handle_data->stack;
  SPVM_OBJ* obj_uv_process = uv_handle_data->obj_uv_handle;
  
  SPVM_OBJ* obj_cb = env->get_field_object_by_name(env, stack, obj_uv_process, "exit_cb", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    spvm_diag("[Unexpected Error]Getting 'exit_cb' field failed.");
    abort();
  }
  
  if (obj_cb) {
    stack[0].oval = obj_cb;
    stack[1].oval = obj_uv_process;
    stack[2].lval = exit_status;
    stack[3].ival = term_signal;
    env->call_instance_method_by_name(env, stack, "", 4, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      spvm_diag("[An exception is converted to a warning in SPVM__UV__Loop__exit_cb]\n%s", env->get_exception_chars(env, stack));
      return;
    }
  }
}

int32_t SPVM__UV__Loop__spawn(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_loop = stack[0].oval;
  SPVM_OBJ* obj_uv_process = stack[1].oval;
  SPVM_OBJ* obj_options = stack[2].oval;
  
  char** argv = NULL;
  char** envp = NULL;
  uv_stdio_container_t* stdio_containers = NULL;
  
  if (!obj_uv_process) {
    error_id = env->die(env, stack, "$uv_process must be defined.", __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  if (!obj_options) {
    error_id = env->die(env, stack, "$options must be defined.", __func__, FILE_NAME, __LINE__);
    goto END_OF_FUNC;
  }
  
  uv_loop_t* uv_loop = env->get_pointer(env, stack, obj_uv_loop);
  assert(uv_loop);
  
  uv_process_t* uv_process = env->get_pointer(env, stack, obj_uv_process);
  assert(uv_process);
  
  uv_process_options_t options;
  memset(&options, 0, sizeof(options));
  
  SPVM_OBJ* obj_file = env->get_field_object_by_name(env, stack, obj_options, "file", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    goto END_OF_FUNC;
  }
  const char* file_chars = obj_file ? env->get_chars(env, stack, obj_file) : NULL;
  options.file = file_chars;
  
  SPVM_OBJ* obj_args = env->get_field_object_by_name(env, stack, obj_options, "args", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    goto END_OF_FUNC;
  }
  if (obj_args) {
    int32_t argc = env->length(env, stack, obj_args);
    argv = (char**)env->new_memory_block(env, stack, (argc + 1) * sizeof(char*));
    memset(argv, 0, (argc + 1) * sizeof(char*));
    for (int32_t i = 0; i < argc; i++) {
      SPVM_OBJ* obj_arg = env->get_elem_object(env, stack, obj_args, i);
      argv[i] = obj_arg ? (char*)env->get_chars(env, stack, obj_arg) : NULL;
    }
    argv[argc] = NULL;
    options.args = argv;
  }
  
  SPVM_OBJ* obj_env = env->get_field_object_by_name(env, stack, obj_options, "env", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    goto END_OF_FUNC;
  }
  if (obj_env) {
    int32_t envc = env->length(env, stack, obj_env);
    envp = (char**)env->new_memory_block(env, stack, (envc + 1) * sizeof(char*));
    memset(envp, 0, (envc + 1) * sizeof(char*));
    for (int32_t i = 0; i < envc; i++) {
      SPVM_OBJ* obj_env_elem = env->get_elem_object(env, stack, obj_env, i);
      envp[i] = obj_env_elem ? (char*)env->get_chars(env, stack, obj_env_elem) : NULL;
    }
    envp[envc] = NULL;
    options.env = envp;
  }
  
  SPVM_OBJ* obj_cwd = env->get_field_object_by_name(env, stack, obj_options, "cwd", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    goto END_OF_FUNC;
  }
  const char* cwd_chars = obj_cwd ? env->get_chars(env, stack, obj_cwd) : NULL;
  options.cwd = cwd_chars;
  
  int32_t flags = env->get_field_int_by_name(env, stack, obj_options, "flags", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    goto END_OF_FUNC;
  }
  options.flags = flags;
  
  SPVM_OBJ* obj_stdios = env->get_field_object_by_name(env, stack, obj_options, "stdios", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    goto END_OF_FUNC;
  }
  if (obj_stdios) {
    int32_t stdio_count = env->length(env, stack, obj_stdios);
    options.stdio_count = stdio_count;
    stdio_containers = (uv_stdio_container_t*)env->new_memory_block(env, stack, stdio_count * sizeof(uv_stdio_container_t));
    memset(stdio_containers, 0, stdio_count * sizeof(uv_stdio_container_t));
    for (int32_t i = 0; i < stdio_count; i++) {
      SPVM_OBJ* obj_stdio = env->get_elem_object(env, stack, obj_stdios, i);
      if (obj_stdio) {
        uv_stdio_container_t* container_ptr = env->get_pointer(env, stack, obj_stdio);
        if (container_ptr) {
          stdio_containers[i] = *container_ptr;
        }
      }
    }
    options.stdio = stdio_containers;
  }
  
  int32_t uid = env->get_field_int_by_name(env, stack, obj_options, "uid", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    goto END_OF_FUNC;
  }
  options.uid = uid;
  
  int32_t gid = env->get_field_int_by_name(env, stack, obj_options, "gid", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    goto END_OF_FUNC;
  }
  options.gid = gid;
  
  SPVM_OBJ* obj_exit_cb = env->get_field_object_by_name(env, stack, obj_options, "exit_cb", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    goto END_OF_FUNC;
  }
  if (obj_exit_cb) {
    env->set_field_object_by_name(env, stack, obj_uv_process, "exit_cb", obj_exit_cb, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) {
      goto END_OF_FUNC;
    }
    options.exit_cb = SPVM__UV__Loop__exit_cb;
  }
  
  int32_t status = uv_spawn(uv_loop, uv_process, &options);
  
  if (!(status == 0)) {
    error_id = env->die(env, stack, "uv_spawn failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
    goto END_OF_FUNC;
  }
  
  stack[0].oval = obj_uv_loop;
  stack[1].oval = obj_uv_process;
  env->call_instance_method_by_name(env, stack, "set_uv_handle", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) {
    goto END_OF_FUNC;
  }
  
  stack[0].ival = status;
  
  error_id = 0;

END_OF_FUNC:
  
  if (argv) {
    env->free_memory_block(env, stack, argv);
  }
  if (envp) {
    env->free_memory_block(env, stack, envp);
  }
  if (stdio_containers) {
    env->free_memory_block(env, stack, stdio_containers);
  }
  
  return error_id;
}


int32_t SPVM__UV__Loop__DESTROY(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  SPVM_OBJ* obj_uv_loop = stack[0].oval;
  
  uv_loop_t* uv_loop = env->get_pointer(env, stack, obj_uv_loop);
  
  int32_t status = uv_loop_close(uv_loop);
  
  if (!(status == 0)) {
    return env->die(env, stack, "uv_loop_close failed. status=%d.", __func__, FILE_NAME, __LINE__, status);
  }
  
  int32_t no_free = env->no_free(env, stack, obj_uv_loop);
  if (!no_free) {
    env->free_memory_block(env, stack, uv_loop);
    env->set_no_free(env, stack, obj_uv_loop, 1);
  }
  
  return 0;
}
