#ifndef SPVM_CSOURCE_BUILDER_PRECOMPILE_H
#define SPVM_CSOURCE_BUILDER_PRECOMPILE_H
#include <spvm_native.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <inttypes.h>
#define SPVM_API_GET_OBJECT_NO_WEAKEN_ADDRESS(object) ((void*)((intptr_t)object & ~(intptr_t)1))
#define SPVM_API_GET_REF_COUNT(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset)))
#define SPVM_API_INC_REF_COUNT_ONLY(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset))++)
#define SPVM_API_INC_REF_COUNT(object)\
do {\
  if (object != NULL) {\
    SPVM_API_INC_REF_COUNT_ONLY(object);\
  }\
} while (0)\

#define SPVM_API_DEC_REF_COUNT_ONLY(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset))--)
#define SPVM_API_DEC_REF_COUNT(object)\
do {\
  if (object != NULL) {\
    if (SPVM_API_GET_REF_COUNT(object) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(object); }\
    else { env->dec_ref_count(env, object); }\
  }\
} while (0)\

#define SPVM_API_ISWEAK(dist_address) (((intptr_t)*(void**)dist_address) & 1)

#define SPVM_API_OBJECT_ASSIGN(dist_address, src_object) \
do {\
  void* tmp_object = SPVM_API_GET_OBJECT_NO_WEAKEN_ADDRESS(src_object);\
  if (tmp_object != NULL) {\
    SPVM_API_INC_REF_COUNT_ONLY(tmp_object);\
  }\
  if (*(void**)(dist_address) != NULL) {\
    if (__builtin_expect(SPVM_API_ISWEAK(dist_address), 0)) { env->unweaken(env, dist_address); }\
    if (SPVM_API_GET_REF_COUNT(*(void**)(dist_address)) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*(void**)(dist_address)); }\
    else { env->dec_ref_count(env, *(void**)(dist_address)); }\
  }\
  *(void**)(dist_address) = tmp_object;\
} while (0)\

#endif
// Package variable id declarations
// Field id declarations
// Sub id declarations
static int32_t MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon_sub0 = -1;
static int32_t MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon_sub1 = -1;
static int32_t MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon__15__13__ = -1;
static int32_t MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon__22__13__ = -1;
// Basic type id declarations
static int32_t MyExe__Precompile_ACCESS_BASIC_TYPE_ID_MyExe__Precompile__anon__15__13 = -1;
static int32_t MyExe__Precompile_ACCESS_BASIC_TYPE_ID_MyExe__Precompile__anon__22__13 = -1;
// Function Declarations
int32_t SPPRECOMPILE__MyExe__Precompile__sum(SPVM_ENV* env, SPVM_VALUE* stack);
int32_t SPPRECOMPILE__MyExe__Precompile__anon_sub_sum(SPVM_ENV* env, SPVM_VALUE* stack);
int32_t SPPRECOMPILE__MyExe__Precompile__anon_sub0(SPVM_ENV* env, SPVM_VALUE* stack);
int32_t SPPRECOMPILE__MyExe__Precompile__anon_sub1(SPVM_ENV* env, SPVM_VALUE* stack);

// Function Implementations
int32_t SPPRECOMPILE__MyExe__Precompile__sum(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  int32_t int_vars[7];
  int32_t exception_flag = 0;
  int32_t mortal_stack[1];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  int_vars[1] = *(int32_t*)&stack[0];
  int_vars[2] = *(int32_t*)&stack[1];

L0: // INIT_INT
  int_vars[0] = 0;
L1: // ADD_INT
  int_vars[3] = int_vars[1] + int_vars[2];
L2: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[3];
  goto L5;
L3: // INIT_INT
  int_vars[5] = 0;
L4: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[5];
  goto L5;
L5: // END_SUB
  if (!exception_flag) {
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__MyExe__Precompile__anon_sub_sum(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  int32_t int_vars[8];
  int32_t exception_flag = 0;
  int32_t mortal_stack[1];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];

L0: // INIT_INT
  int_vars[0] = 0;
L1: // CALL_SUB_INT
  // MyExe::Precompile->anon_sub0
  {
    if (MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon_sub0 < 0) {
      MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon_sub0 = env->get_sub_id(env, "MyExe::Precompile", "anon_sub0", "int()");
      if (MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon_sub0 < 0) {
        void* exception = env->new_string_nolen_raw(env, "Subroutine not found MyExe::Precompile anon_sub0");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon_sub0;
    exception_flag = SPPRECOMPILE__MyExe__Precompile__anon_sub0(env, stack);
    if (!exception_flag) {
      int_vars[1] = *(int32_t*)&stack[0];
    }
  }
L2: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "MyExe::Precompile";
    const char* sub_name = "anon_sub_sum";
    const char* file = "t/exe/lib/MyExe/Precompile.spvm";
    int32_t line = 7;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L9;
  }
L3: // CALL_SUB_INT
  // MyExe::Precompile->anon_sub1
  {
    if (MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon_sub1 < 0) {
      MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon_sub1 = env->get_sub_id(env, "MyExe::Precompile", "anon_sub1", "int()");
      if (MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon_sub1 < 0) {
        void* exception = env->new_string_nolen_raw(env, "Subroutine not found MyExe::Precompile anon_sub1");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon_sub1;
    exception_flag = SPPRECOMPILE__MyExe__Precompile__anon_sub1(env, stack);
    if (!exception_flag) {
      int_vars[3] = *(int32_t*)&stack[0];
    }
  }
L4: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "MyExe::Precompile";
    const char* sub_name = "anon_sub_sum";
    const char* file = "t/exe/lib/MyExe/Precompile.spvm";
    int32_t line = 8;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L9;
  }
L5: // ADD_INT
  int_vars[4] = int_vars[1] + int_vars[3];
L6: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[4];
  goto L9;
L7: // INIT_INT
  int_vars[6] = 0;
L8: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[6];
  goto L9;
L9: // END_SUB
  if (!exception_flag) {
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__MyExe__Precompile__anon_sub0(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[1] = {0};
  int32_t int_vars[6];
  int32_t exception_flag = 0;
  int32_t mortal_stack[2];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // NEW_OBJECT
  {
    if (MyExe__Precompile_ACCESS_BASIC_TYPE_ID_MyExe__Precompile__anon__15__13 < 0) {
      MyExe__Precompile_ACCESS_BASIC_TYPE_ID_MyExe__Precompile__anon__15__13 = env->get_basic_type_id(env, "MyExe::Precompile::anon::15::13");
      if (MyExe__Precompile_ACCESS_BASIC_TYPE_ID_MyExe__Precompile__anon__15__13 < 0) {
        void* exception = env->new_string_nolen_raw(env, "Basic type not found MyExe::Precompile::anon::15::13");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t basic_type_id = MyExe__Precompile_ACCESS_BASIC_TYPE_ID_MyExe__Precompile__anon__15__13;
    void* object = env->new_object_raw(env, basic_type_id);
    if (object == NULL) {
      void* exception = env->new_string_nolen_raw(env, "Can't allocate memory for object");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[0], object);
    }
  }
L3: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[0];
L4: // CALL_SUB_INT
  // MyExe::Precompile::anon::15::13->
  {
    if (MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon__15__13__ < 0) {
      MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon__15__13__ = env->get_sub_id(env, "MyExe::Precompile::anon::15::13", "", "int(self)");
      if (MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon__15__13__ < 0) {
        void* exception = env->new_string_nolen_raw(env, "Subroutine not found MyExe::Precompile::anon::15::13 ");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon__15__13__;
    exception_flag = env->call_sub(env, call_sub_id, stack);
    if (!exception_flag) {
      int_vars[2] = *(int32_t*)&stack[0];
    }
  }
L5: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "MyExe::Precompile";
    const char* sub_name = "anon_sub0";
    const char* file = "t/exe/lib/MyExe/Precompile.spvm";
    int32_t line = 17;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L9;
  }
L6: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[2];
  goto L9;
L7: // INIT_INT
  int_vars[4] = 0;
L8: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[4];
  goto L9;
L9: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L10: // END_SUB
  if (!exception_flag) {
  }
  return exception_flag;
}

int32_t SPPRECOMPILE__MyExe__Precompile__anon_sub1(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[1] = {0};
  int32_t int_vars[6];
  int32_t exception_flag = 0;
  int32_t mortal_stack[2];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // NEW_OBJECT
  {
    if (MyExe__Precompile_ACCESS_BASIC_TYPE_ID_MyExe__Precompile__anon__22__13 < 0) {
      MyExe__Precompile_ACCESS_BASIC_TYPE_ID_MyExe__Precompile__anon__22__13 = env->get_basic_type_id(env, "MyExe::Precompile::anon::22::13");
      if (MyExe__Precompile_ACCESS_BASIC_TYPE_ID_MyExe__Precompile__anon__22__13 < 0) {
        void* exception = env->new_string_nolen_raw(env, "Basic type not found MyExe::Precompile::anon::22::13");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t basic_type_id = MyExe__Precompile_ACCESS_BASIC_TYPE_ID_MyExe__Precompile__anon__22__13;
    void* object = env->new_object_raw(env, basic_type_id);
    if (object == NULL) {
      void* exception = env->new_string_nolen_raw(env, "Can't allocate memory for object");
      env->set_exception(env, exception);
      exception_flag = 1;
    }
    else {
      SPVM_API_OBJECT_ASSIGN(&object_vars[0], object);
    }
  }
L3: // PUSH_ARG_OBJECT
  *(void**)&stack[0] = object_vars[0];
L4: // CALL_SUB_INT
  // MyExe::Precompile::anon::22::13->
  {
    if (MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon__22__13__ < 0) {
      MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon__22__13__ = env->get_sub_id(env, "MyExe::Precompile::anon::22::13", "", "int(self)");
      if (MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon__22__13__ < 0) {
        void* exception = env->new_string_nolen_raw(env, "Subroutine not found MyExe::Precompile::anon::22::13 ");
        env->set_exception(env, exception);
        return SPVM_EXCEPTION;
      }
    }
    int32_t call_sub_id = MyExe__Precompile_ACCESS_SUB_ID_MyExe__Precompile__anon__22__13__;
    exception_flag = env->call_sub(env, call_sub_id, stack);
    if (!exception_flag) {
      int_vars[2] = *(int32_t*)&stack[0];
    }
  }
L5: // IF_EXCEPTION_RETURN
  if (exception_flag) {
    const char* sub_package_name = "MyExe::Precompile";
    const char* sub_name = "anon_sub1";
    const char* file = "t/exe/lib/MyExe/Precompile.spvm";
    int32_t line = 24;
    env->set_exception(env, env->new_stack_trace_raw(env, env->get_exception(env), sub_package_name, sub_name, file, line));
    goto L9;
  }
L6: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[2];
  goto L9;
L7: // INIT_INT
  int_vars[4] = 0;
L8: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[4];
  goto L9;
L9: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L10: // END_SUB
  if (!exception_flag) {
  }
  return exception_flag;
}


#ifndef SPVM_CSOURCE_BUILDER_PRECOMPILE_H
#define SPVM_CSOURCE_BUILDER_PRECOMPILE_H
#include <spvm_native.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <inttypes.h>
#define SPVM_API_GET_OBJECT_NO_WEAKEN_ADDRESS(object) ((void*)((intptr_t)object & ~(intptr_t)1))
#define SPVM_API_GET_REF_COUNT(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset)))
#define SPVM_API_INC_REF_COUNT_ONLY(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset))++)
#define SPVM_API_INC_REF_COUNT(object)\
do {\
  if (object != NULL) {\
    SPVM_API_INC_REF_COUNT_ONLY(object);\
  }\
} while (0)\

#define SPVM_API_DEC_REF_COUNT_ONLY(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset))--)
#define SPVM_API_DEC_REF_COUNT(object)\
do {\
  if (object != NULL) {\
    if (SPVM_API_GET_REF_COUNT(object) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(object); }\
    else { env->dec_ref_count(env, object); }\
  }\
} while (0)\

#define SPVM_API_ISWEAK(dist_address) (((intptr_t)*(void**)dist_address) & 1)

#define SPVM_API_OBJECT_ASSIGN(dist_address, src_object) \
do {\
  void* tmp_object = SPVM_API_GET_OBJECT_NO_WEAKEN_ADDRESS(src_object);\
  if (tmp_object != NULL) {\
    SPVM_API_INC_REF_COUNT_ONLY(tmp_object);\
  }\
  if (*(void**)(dist_address) != NULL) {\
    if (__builtin_expect(SPVM_API_ISWEAK(dist_address), 0)) { env->unweaken(env, dist_address); }\
    if (SPVM_API_GET_REF_COUNT(*(void**)(dist_address)) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*(void**)(dist_address)); }\
    else { env->dec_ref_count(env, *(void**)(dist_address)); }\
  }\
  *(void**)(dist_address) = tmp_object;\
} while (0)\

#endif
// Package variable id declarations
// Field id declarations
// Sub id declarations
// Basic type id declarations
// Function Declarations
int32_t SPPRECOMPILE__MyExe__Precompile__anon__15__13__(SPVM_ENV* env, SPVM_VALUE* stack);

// Function Implementations
int32_t SPPRECOMPILE__MyExe__Precompile__anon__15__13__(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[1] = {0};
  int32_t int_vars[5];
  int32_t exception_flag = 0;
  int32_t mortal_stack[2];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  object_vars[0] = *(void**)&stack[0];
  if (object_vars[0] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[0]); }

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // MOVE_CONSTANT_INT
  int_vars[1] = 2;
L3: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[1];
  goto L6;
L4: // INIT_INT
  int_vars[3] = 0;
L5: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[3];
  goto L6;
L6: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L7: // END_SUB
  if (!exception_flag) {
  }
  return exception_flag;
}


#ifndef SPVM_CSOURCE_BUILDER_PRECOMPILE_H
#define SPVM_CSOURCE_BUILDER_PRECOMPILE_H
#include <spvm_native.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <inttypes.h>
#define SPVM_API_GET_OBJECT_NO_WEAKEN_ADDRESS(object) ((void*)((intptr_t)object & ~(intptr_t)1))
#define SPVM_API_GET_REF_COUNT(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset)))
#define SPVM_API_INC_REF_COUNT_ONLY(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset))++)
#define SPVM_API_INC_REF_COUNT(object)\
do {\
  if (object != NULL) {\
    SPVM_API_INC_REF_COUNT_ONLY(object);\
  }\
} while (0)\

#define SPVM_API_DEC_REF_COUNT_ONLY(object) ((*(int32_t*)((intptr_t)object + (intptr_t)env->object_ref_count_offset))--)
#define SPVM_API_DEC_REF_COUNT(object)\
do {\
  if (object != NULL) {\
    if (SPVM_API_GET_REF_COUNT(object) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(object); }\
    else { env->dec_ref_count(env, object); }\
  }\
} while (0)\

#define SPVM_API_ISWEAK(dist_address) (((intptr_t)*(void**)dist_address) & 1)

#define SPVM_API_OBJECT_ASSIGN(dist_address, src_object) \
do {\
  void* tmp_object = SPVM_API_GET_OBJECT_NO_WEAKEN_ADDRESS(src_object);\
  if (tmp_object != NULL) {\
    SPVM_API_INC_REF_COUNT_ONLY(tmp_object);\
  }\
  if (*(void**)(dist_address) != NULL) {\
    if (__builtin_expect(SPVM_API_ISWEAK(dist_address), 0)) { env->unweaken(env, dist_address); }\
    if (SPVM_API_GET_REF_COUNT(*(void**)(dist_address)) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*(void**)(dist_address)); }\
    else { env->dec_ref_count(env, *(void**)(dist_address)); }\
  }\
  *(void**)(dist_address) = tmp_object;\
} while (0)\

#endif
// Package variable id declarations
// Field id declarations
// Sub id declarations
// Basic type id declarations
// Function Declarations
int32_t SPPRECOMPILE__MyExe__Precompile__anon__22__13__(SPVM_ENV* env, SPVM_VALUE* stack);

// Function Implementations
int32_t SPPRECOMPILE__MyExe__Precompile__anon__22__13__(SPVM_ENV* env, SPVM_VALUE* stack) {
  int32_t object_header_byte_size = (intptr_t)env->object_header_byte_size;
  void* object_vars[1] = {0};
  int32_t int_vars[5];
  int32_t exception_flag = 0;
  int32_t mortal_stack[2];
  int32_t mortal_stack_top = 0;
  char convert_string_buffer[21];
  // Copy arguments to variables
  object_vars[0] = *(void**)&stack[0];
  if (object_vars[0] != NULL) { SPVM_API_INC_REF_COUNT_ONLY(object_vars[0]); }

L0: // INIT_INT
  int_vars[0] = 0;
L1: // PUSH_MORTAL
  mortal_stack[mortal_stack_top] = 0;
  mortal_stack_top++;
L2: // MOVE_CONSTANT_INT
  int_vars[1] = 5;
L3: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[1];
  goto L6;
L4: // INIT_INT
  int_vars[3] = 0;
L5: // RETURN_INT
  *(int32_t*)&stack[0] = int_vars[3];
  goto L6;
L6: // LEAVE_SCOPE
  {
    int32_t original_mortal_stack_top = 0;
    {
      int32_t mortal_stack_index;
      for (mortal_stack_index = original_mortal_stack_top; mortal_stack_index < mortal_stack_top; mortal_stack_index++) {
        int32_t var_index = mortal_stack[mortal_stack_index];
        void** object_address = (void**)&object_vars[var_index];
        if (*object_address != NULL) {
          if (SPVM_API_GET_REF_COUNT(*object_address) > 1) { SPVM_API_DEC_REF_COUNT_ONLY(*object_address); }
          else { env->dec_ref_count(env, *object_address); }
          *object_address = NULL;
        }
      }
    }
    mortal_stack_top = original_mortal_stack_top;
  }
L7: // END_SUB
  if (!exception_flag) {
  }
  return exception_flag;
}


