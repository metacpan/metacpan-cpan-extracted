
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <assert.h>

#include "spvm_native.h"

#include "spvm_api.h"
#include "spvm_op.h"
#include "spvm_compiler.h"
#include "spvm_hash.h"
#include "spvm_list.h"
#include "spvm_package.h"
#include "spvm_sub.h"
#include "spvm_basic_type.h"

// module source get functions declaration
const char* SPMODSRC__SPVM__Byte__get_module_source();
const char* SPMODSRC__SPVM__Short__get_module_source();
const char* SPMODSRC__SPVM__Int__get_module_source();
const char* SPMODSRC__SPVM__Long__get_module_source();
const char* SPMODSRC__SPVM__Float__get_module_source();
const char* SPMODSRC__SPVM__Double__get_module_source();
const char* SPMODSRC__MyExe__get_module_source();
const char* SPMODSRC__MyExe__Precompile__get_module_source();
const char* SPMODSRC__TestCase__NativeAPI2__get_module_source();
// precompile functions declaration
int32_t SPPRECOMPILE__MyExe__Precompile__sum(SPVM_ENV* env, SPVM_VALUE* stack);
// native functions declaration
int32_t SPNATIVE__TestCase__NativeAPI2__mul(SPVM_ENV* env, SPVM_VALUE* stack);
int32_t SPNATIVE__TestCase__NativeAPI2__src_foo(SPVM_ENV* env, SPVM_VALUE* stack);
int32_t SPNATIVE__TestCase__NativeAPI2__src_bar(SPVM_ENV* env, SPVM_VALUE* stack);

int32_t main(int32_t argc, const char *argv[]) {
  // Package name
  const char* package_name = "MyExe";
  
  // Create compiler
  SPVM_COMPILER* compiler = SPVM_COMPILER_new();
  compiler->no_directry_module_search = 1;

  // Create use op for entry point package
  SPVM_OP* op_name_start = SPVM_OP_new_op_name(compiler, package_name, package_name, 0);
  SPVM_OP* op_type_start = SPVM_OP_build_basic_type(compiler, op_name_start);
  SPVM_OP* op_use_start = SPVM_OP_new_op(compiler, SPVM_OP_C_ID_USE, package_name, 0);
  SPVM_OP_build_use(compiler, op_use_start, op_type_start, NULL, 0);
  SPVM_LIST_push(compiler->op_use_stack, op_use_start);
  
  // Set module sources
  {
    const char* module_source = SPMODSRC__SPVM__Byte__get_module_source();
    SPVM_HASH_insert(compiler->module_source_symtable, "SPVM::Byte", strlen("SPVM::Byte"), (void*)module_source);
  }
  {
    const char* module_source = SPMODSRC__SPVM__Short__get_module_source();
    SPVM_HASH_insert(compiler->module_source_symtable, "SPVM::Short", strlen("SPVM::Short"), (void*)module_source);
  }
  {
    const char* module_source = SPMODSRC__SPVM__Int__get_module_source();
    SPVM_HASH_insert(compiler->module_source_symtable, "SPVM::Int", strlen("SPVM::Int"), (void*)module_source);
  }
  {
    const char* module_source = SPMODSRC__SPVM__Long__get_module_source();
    SPVM_HASH_insert(compiler->module_source_symtable, "SPVM::Long", strlen("SPVM::Long"), (void*)module_source);
  }
  {
    const char* module_source = SPMODSRC__SPVM__Float__get_module_source();
    SPVM_HASH_insert(compiler->module_source_symtable, "SPVM::Float", strlen("SPVM::Float"), (void*)module_source);
  }
  {
    const char* module_source = SPMODSRC__SPVM__Double__get_module_source();
    SPVM_HASH_insert(compiler->module_source_symtable, "SPVM::Double", strlen("SPVM::Double"), (void*)module_source);
  }
  {
    const char* module_source = SPMODSRC__MyExe__get_module_source();
    SPVM_HASH_insert(compiler->module_source_symtable, "MyExe", strlen("MyExe"), (void*)module_source);
  }
  {
    const char* module_source = SPMODSRC__MyExe__Precompile__get_module_source();
    SPVM_HASH_insert(compiler->module_source_symtable, "MyExe::Precompile", strlen("MyExe::Precompile"), (void*)module_source);
  }
  {
    const char* module_source = SPMODSRC__TestCase__NativeAPI2__get_module_source();
    SPVM_HASH_insert(compiler->module_source_symtable, "TestCase::NativeAPI2", strlen("TestCase::NativeAPI2"), (void*)module_source);
  }


  SPVM_COMPILER_compile(compiler);

  if (compiler->error_count > 0) {
    exit(1);
  }
  { 
    const char* package_name = "MyExe::Precompile";
    const char* sub_name = "sum";
    SPVM_BASIC_TYPE* basic_type = SPVM_HASH_fetch(compiler->basic_type_symtable, package_name, strlen(package_name));
    assert(basic_type);
    SPVM_PACKAGE* package = basic_type->package;
    assert(package);
    SPVM_SUB* sub = SPVM_HASH_fetch(package->sub_symtable, sub_name, strlen(sub_name));
    assert(sub);
    sub->precompile_address = SPPRECOMPILE__MyExe__Precompile__sum;
  }
  { 
    const char* package_name = "TestCase::NativeAPI2";
    const char* sub_name = "mul";
    SPVM_BASIC_TYPE* basic_type = SPVM_HASH_fetch(compiler->basic_type_symtable, package_name, strlen(package_name));
    assert(basic_type);
    SPVM_PACKAGE* package = basic_type->package;
    assert(package);
    SPVM_SUB* sub = SPVM_HASH_fetch(package->sub_symtable, sub_name, strlen(sub_name));
    assert(sub);
    sub->native_address = SPNATIVE__TestCase__NativeAPI2__mul;
  }
  { 
    const char* package_name = "TestCase::NativeAPI2";
    const char* sub_name = "src_foo";
    SPVM_BASIC_TYPE* basic_type = SPVM_HASH_fetch(compiler->basic_type_symtable, package_name, strlen(package_name));
    assert(basic_type);
    SPVM_PACKAGE* package = basic_type->package;
    assert(package);
    SPVM_SUB* sub = SPVM_HASH_fetch(package->sub_symtable, sub_name, strlen(sub_name));
    assert(sub);
    sub->native_address = SPNATIVE__TestCase__NativeAPI2__src_foo;
  }
  { 
    const char* package_name = "TestCase::NativeAPI2";
    const char* sub_name = "src_bar";
    SPVM_BASIC_TYPE* basic_type = SPVM_HASH_fetch(compiler->basic_type_symtable, package_name, strlen(package_name));
    assert(basic_type);
    SPVM_PACKAGE* package = basic_type->package;
    assert(package);
    SPVM_SUB* sub = SPVM_HASH_fetch(package->sub_symtable, sub_name, strlen(sub_name));
    assert(sub);
    sub->native_address = SPNATIVE__TestCase__NativeAPI2__src_bar;
  }
    
  // Create env
  SPVM_ENV* env = SPVM_API_create_env(compiler);
  
  // Call begin blocks
  SPVM_API_call_begin_blocks(env);

  // Package
  int32_t sub_id = SPVM_API_get_sub_id(env, package_name, "main", "int(string[])");
  
  if (sub_id < 0) {
    return -1;
  }
  
  // Enter scope
  int32_t scope_id = env->enter_scope(env);
  
  // new byte[][args_length] object
  int32_t arg_type_basic_id = env->get_basic_type_id(env, "byte");
  void* cmd_args_obj = env->new_muldim_array(env, arg_type_basic_id, 1, argc);
  
  // Set command line arguments
  for (int32_t arg_index = 0; arg_index < argc; arg_index++) {
    void* cmd_arg_obj = env->new_string(env, argv[arg_index], strlen(argv[arg_index]));
    env->set_elem_object(env, cmd_args_obj, arg_index, cmd_arg_obj);
  }
  
  SPVM_VALUE stack[255];
  stack[0].oval = cmd_args_obj;
  
  // Run
  int32_t exception_flag = env->call_sub(env, sub_id, stack);
  
  int32_t status;
  if (exception_flag) {
    SPVM_API_print(env, env->exception_object);
    printf("\n");
    status = 255;
  }
  else {
    status = stack[0].ival;
  }
  
  // Leave scope
  env->leave_scope(env, scope_id);
  
  SPVM_API_free_env(env);

  // Free compiler
  SPVM_COMPILER_free(compiler);
  
  return status;
}
