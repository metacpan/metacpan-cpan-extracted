/* 
 * Copyright (c) 2001 Ping Liang
 * All rights reserved.
 *
 * This program is free software; you can use, redistribute and/or
 * modify it under the same terms as Perl itself.
 *
 * $Id: Native.xs,v 1.4 2002/01/01 20:41:53 liang Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <jni.h>

typedef jobject cstring;

MODULE = PBJ::JNI::Native  PACKAGE = PBJ::JNI::Native

PROTOTYPES: ENABLE

jint
JNI_GetDefaultJavaVMInitArgs(vm_args)
    void *vm_args

jint
JNI_CreateJavaVM(OUT vm, OUT env, options)
    JavaVM *vm = NO_INIT
    JNIEnv *env = NO_INIT
    SV *options
  INIT:
    I32 num_opts = 0;
    int i, n;

    if ((!SvROK(options))
        || (SvTYPE(SvRV(options)) != SVt_PVAV)
        || ((num_opts = av_len((AV *)SvRV(options))) < 0)) {
       croak("options must be a reference");
    }
  CODE:
    {
      JavaVMInitArgs vm_args;
      JavaVMOption *vm_opts = malloc((num_opts + 1) * sizeof(JavaVMOption));
    
      for (n = 0; n <= num_opts; n++) {
        STRLEN l;
        char * fn = SvPV(*av_fetch((AV *)SvRV(options), n, 0), l);
        vm_opts[n].optionString = fn;
      }

      vm_opts[++num_opts].optionString = "-Xrs";

      vm_args.version = 0x00010002; /*JNI_VERSION_1_2;*/
      vm_args.options = vm_opts;
      vm_args.nOptions = num_opts + 1;
      vm_args.ignoreUnrecognized = JNI_FALSE;
      RETVAL = JNI_CreateJavaVM(&vm, (void **) &env, &vm_args);
      free(vm_opts);
    }
  OUTPUT:
    RETVAL
    vm
    env

jint
DestroyJavaVM(vm)
    JavaVM *vm
  CODE:
    { 
      int i = (*vm)->DestroyJavaVM(vm);
      RETVAL = i;
    }
  OUTPUT:
    RETVAL

jint
AttachCurrentThread(vm, OUT env, args)
    JavaVM *vm
    JNIEnv *env = NO_INIT
    void *args
  CODE:
    RETVAL = (*vm)->AttachCurrentThread(vm, (void **) &env, args);
  OUTPUT:
    RETVAL
    env

jint
DetachCurrentThread(vm)
    JavaVM *vm
  CODE:
    RETVAL = (*vm)->DetachCurrentThread(vm);
  OUTPUT:
    RETVAL

jint
GetEnv(vm, OUT env, version)
    JavaVM *vm
    JNIEnv *env
    jint version
  CODE:
    RETVAL = (*vm)->GetEnv(vm, (void **) &env, version = 0x00010002);
  OUTPUT:
    RETVAL
    env

jint 
GetVersion(env)
    JNIEnv *env
  CODE:
    RETVAL = (*env)->GetVersion(env);
  OUTPUT:
    RETVAL

jclass 
DefineClass(env, name, loader, buf, len)
    JNIEnv *env 
    const char *name
    jobject loader
    const jbyte *buf
    jsize len
  CODE:
    RETVAL = (*env)->DefineClass(env, name, loader, buf, len);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jclass 
FindClass(env, name)
    JNIEnv *env
    const char *name
  CODE:
    /*printf("class name: %s\n", name);*/
    RETVAL = (*env)->FindClass(env, name);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jmethodID 
FromReflectedMethod(env, method)
    JNIEnv *env
    jobject method
  CODE:
    RETVAL = (*env)->FromReflectedMethod(env, method);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jfieldID 
FromReflectedField(env, field)
    JNIEnv *env
    jobject field
  CODE:
    RETVAL = (*env)->FromReflectedField(env, field);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jobject 
ToReflectedMethod(env, cls, methodID, isStatic)
    JNIEnv *env
    jclass cls
    jmethodID methodID
    jboolean isStatic
  CODE:
    RETVAL = (*env)->ToReflectedMethod(env, cls, methodID, isStatic);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jclass 
GetSuperclass(env, sub)
    JNIEnv *env
    jclass sub
  CODE:
    RETVAL = (*env)->GetSuperclass(env, sub);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jboolean 
IsAssignableFrom(env, sub, sup)
    JNIEnv *env
    jclass sub
    jclass sup
  CODE:
    RETVAL = (*env)->IsAssignableFrom(env, sub, sup);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jobject 
ToReflectedField(env, cls, fieldID, isStatic)
    JNIEnv *env
    jclass cls 
    jfieldID fieldID
    jboolean isStatic
  CODE:
    RETVAL = (*env)->ToReflectedField(env, cls, fieldID, isStatic);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
Throw(env, obj)
    JNIEnv *env
    jthrowable obj
  CODE:
    RETVAL = (*env)->Throw(env, obj);
  OUTPUT:
    RETVAL

jint 
ThrowNew(env, clazz, msg)
    JNIEnv *env
    jclass clazz
    const char *msg
  CODE:
    RETVAL = (*env)->ThrowNew(env, clazz, msg);
  OUTPUT:
    RETVAL

jthrowable 
ExceptionOccurred(env)
    JNIEnv *env
  CODE:
    RETVAL = (*env)->ExceptionOccurred(env);
  OUTPUT:
    RETVAL

void 
ExceptionDescribe(env)
    JNIEnv *env
  CODE:
    (*env)->ExceptionDescribe(env);

void 
ExceptionClear(env)
    JNIEnv *env
  CODE:
    (*env)->ExceptionClear(env);

void 
FatalError(env, msg)
    JNIEnv *env
    const char *msg
  CODE:
    (*env)->FatalError(env, msg);

jint 
PushLocalFrame(env, capacity)
    JNIEnv *env
    jint capacity
  CODE:
    RETVAL = (*env)->PushLocalFrame(env, capacity);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jobject 
PopLocalFrame(env, sv)
    JNIEnv *env
    SV *sv
  CODE:
    {
      jobject result;
      if (sv_derived_from(sv, "jobject")) {
        IV tmp = SvIV((SV*)SvRV(sv));
        result = INT2PTR(jobject, tmp);
      }
      else {
        result = NULL;
      }
      RETVAL = (*env)->PopLocalFrame(env, result);
    }
  OUTPUT:
    RETVAL

jobject 
NewGlobalRef(env, lobj)
    JNIEnv *env
    jobject lobj
  CODE:
    RETVAL = (*env)->NewGlobalRef(env, lobj);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

void 
DeleteGlobalRef(env, sv)
    JNIEnv *env
    SV *sv
  CODE:
    {
      jobject gref;
      if (sv_derived_from(sv, "jobject")) {
        IV tmp = SvIV((SV*)SvRV(sv));
        gref = INT2PTR(jobject, tmp);
      }
      else {
        gref = NULL;
      }
      (*env)->DeleteGlobalRef(env, gref);
      Util_exception_check(env);
    }

void 
DeleteLocalRef(env, sv)
    JNIEnv *env
    SV *sv
  CODE:
    {
      jobject lref;
      if (sv_derived_from(sv, "jobject")) {
        IV tmp = SvIV((SV*)SvRV(sv));
        lref = INT2PTR(jobject, tmp);
      }
      else {
        lref = NULL;
      }
      (*env)->DeleteLocalRef(env, lref);
      Util_exception_check(env);
    }

jboolean 
IsSameObject(env, sv1, sv2)
    JNIEnv *env
    SV *sv1 
    SV *sv2
  CODE:
    {
      jobject obj1, obj2;
      if (sv_derived_from(sv1, "jobject")) {
        IV tmp = SvIV((SV*)SvRV(sv1));
        obj1 = INT2PTR(jobject, tmp);
      }
      else {
        obj1 = NULL;
      }
      if (sv_derived_from(sv2, "jobject")) {
        IV tmp = SvIV((SV*)SvRV(sv2));
        obj2 = INT2PTR(jobject, tmp);
      }
      else {
        obj2 = NULL;
      }
      RETVAL = (*env)->IsSameObject(env, obj1, obj2);
      Util_exception_check(env);
    }
  OUTPUT:
    RETVAL

jobject 
NewLocalRef(env, ref)
    JNIEnv *env
    jobject ref
  CODE:
    RETVAL = (*env)->NewLocalRef(env, ref);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
EnsureLocalCapacity(env, capacity)
    JNIEnv *env
    jint capacity
  CODE:
    RETVAL = (*env)->EnsureLocalCapacity(env, capacity);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jobject 
AllocObject(env, clazz)
  JNIEnv *env
  jclass clazz
  CODE:
    RETVAL = (*env)->AllocObject(env, clazz);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jobject 
NewObject(env, clazz, methodID, ...)
    JNIEnv *env
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jobject ret;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      ret = (*env)->NewObjectA(env, clazz, methodID, args);
      if (args != NULL)
        free(args);
      RETVAL = ret;
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jclass 
GetObjectClass(env, obj)
    JNIEnv *env
    jobject obj
  CODE:
    RETVAL = (*env)->GetObjectClass(env, obj);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jboolean 
IsInstanceOf(env, obj, clazz)
    JNIEnv *env
    jobject obj
    jclass clazz
  CODE:
    RETVAL = (*env)->IsInstanceOf(env, obj, clazz);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jmethodID 
GetMethodID(env, clazz, name, sig)
    JNIEnv *env 
    jclass clazz 
    const char *name
    const char *sig
  CODE:
    RETVAL = (*env)->GetMethodID(env, clazz, name, sig);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jobject 
CallObjectMethod(env, obj, methodID, ...)
    JNIEnv *env
    jobject obj
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jobject ret;
      jvalue *args;
      int count = items - 3;
    
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallObjectMethodA(env, obj, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jboolean 
CallBooleanMethod(env, obj, methodID, ...)
    JNIEnv *env
    jobject obj
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jobject ret;
      jvalue *args;
      int count = items - 3;

      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallBooleanMethodA(env, obj, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jbyte 
CallByteMethod(env, obj, methodID, ...)
    JNIEnv *env
    jobject obj
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jobject ret;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallByteMethodA(env, obj, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jchar 
CallCharMethod(env, obj, methodID, ...)
    JNIEnv *env
    jobject obj
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jobject ret;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallCharMethodA(env, obj, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jshort 
CallShortMethod(env, obj, methodID, ...)
    JNIEnv *env
    jobject obj
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jobject ret;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallShortMethodA(env, obj, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
CallIntMethod(env, obj, methodID, ...)
    JNIEnv *env
    jobject obj
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jobject ret;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallIntMethodA(env, obj, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jlong 
CallLongMethod(env, obj, methodID, ...)
    JNIEnv *env
    jobject obj
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jobject ret;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallLongMethodA(env, obj, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jfloat 
CallFloatMethod(env, obj, methodID, ...)
    JNIEnv *env
    jobject obj
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jobject ret;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallFloatMethodA(env, obj, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jdouble 
CallDoubleMethod(env, obj, methodID, ...)
    JNIEnv *env
    jobject obj
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jobject ret;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallDoubleMethodA(env, obj, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

void 
CallVoidMethod(env, obj, methodID, ...)
    JNIEnv *env
    jobject obj
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      (*env)->CallVoidMethodA(env, obj, methodID, args);
      if (args != NULL)
        free(args);
      Util_exception_check(env);
    }

jobject 
CallNonvirtualObjectMethod(env, obj, clazz, methodID, ...)
    JNIEnv *env
    jobject obj
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallNonvirtualObjectMethodA(env, obj, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jboolean 
CallNonvirtualBooleanMethod(env, obj, clazz, methodID, ...)
    JNIEnv *env
    jobject obj
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallNonvirtualBooleanMethodA(env, obj, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jbyte 
CallNonvirtualByteMethod(env, obj, clazz, methodID, ...)
    JNIEnv *env
    jobject obj
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallNonvirtualByteMethodA(env, obj, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jchar 
CallNonvirtualCharMethod(env, obj, clazz, methodID, ...)
    JNIEnv *env
    jobject obj
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallNonvirtualCharMethodA(env, obj, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jshort 
CallNonvirtualShortMethod(env, obj, clazz, methodID, ...)
    JNIEnv *env
    jobject obj
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallNonvirtualShortMethodA(env, obj, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
CallNonvirtualIntMethod(env, obj, clazz, methodID, ...)
    JNIEnv *env
    jobject obj
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallNonvirtualIntMethodA(env, obj, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jlong 
CallNonvirtualLongMethod(env, obj, clazz, methodID, ...)
    JNIEnv *env
    jobject obj
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallNonvirtualLongMethodA(env, obj, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jfloat 
CallNonvirtualFloatMethod(env, obj, clazz, methodID, ...)
    JNIEnv *env
    jobject obj
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallNonvirtualFloatMethodA(env, obj, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jdouble 
CallNonvirtualDoubleMethod(env, obj, clazz, methodID, ...)
    JNIEnv *env
    jobject obj
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallNonvirtualDoubleMethodA(env, obj, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

void 
CallNonvirtualVoidMethod(env, obj, clazz, methodID, ...)
    JNIEnv *env
    jobject obj
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      (*env)->CallNonvirtualVoidMethodA(env, obj, clazz, methodID, args);
      if (args != NULL)
        free(args);
      Util_exception_check(env);
    }

jfieldID 
GetFieldID(env, clazz, name, sig)
    JNIEnv *env
    jclass clazz
    const char *name
    const char *sig
  CODE:
    RETVAL = (*env)->GetFieldID(env, clazz, name, sig);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jobject 
GetObjectField(env, obj, fieldID)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetObjectField(env, obj, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jboolean 
GetBooleanField(env, obj, fieldID)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetBooleanField(env, obj, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jbyte 
GetByteField(env, obj, fieldID)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetByteField(env, obj, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jchar 
GetCharField(env, obj, fieldID)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetCharField(env, obj, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jshort 
GetShortField(env, obj, fieldID)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetShortField(env, obj, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
GetIntField(env, obj, fieldID)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetIntField(env, obj, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jlong 
GetLongField(env, obj, fieldID)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetLongField(env, obj, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jfloat 
GetFloatField(env, obj, fieldID)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetFloatField(env, obj, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jdouble 
GetDoubleField(env, obj, fieldID)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetDoubleField(env, obj, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

void 
SetObjectField(env, obj, fieldID, val)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
    jobject val
  CODE:
    (*env)->SetObjectField(env, obj, fieldID, val);
    Util_exception_check(env);

void 
SetBooleanField(env, obj, fieldID, val)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
    jboolean val
  CODE:
    (*env)->SetBooleanField(env, obj, fieldID, val);
    Util_exception_check(env);

void 
SetByteField(env, obj, fieldID, val)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
    jbyte val
  CODE:
    (*env)->SetByteField(env, obj, fieldID, val);
    Util_exception_check(env);

void 
SetCharField(env, obj, fieldID, val)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
    jchar val
  CODE:
    (*env)->SetCharField(env, obj, fieldID, val);
    Util_exception_check(env);

void 
SetShortField(env, obj, fieldID, val)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
    jshort val
  CODE:
    (*env)->SetShortField(env, obj, fieldID, val);
    Util_exception_check(env);

void 
SetIntField(env, obj, fieldID, val)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
    jint val
  CODE:
    (*env)->SetIntField(env, obj, fieldID, val);
    Util_exception_check(env);

void 
SetLongField(env, obj, fieldID, val)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
    jlong val
  CODE:
    (*env)->SetLongField(env, obj, fieldID, val);
    Util_exception_check(env);

void 
SetFloatField(env, obj, fieldID,val)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
    jfloat val
  CODE:
    (*env)->SetFloatField(env, obj, fieldID,val);
    Util_exception_check(env);

void 
SetDoubleField(env, obj, fieldID, val)
    JNIEnv *env
    jobject obj
    jfieldID fieldID
    jdouble val
  CODE:
    (*env)->SetDoubleField(env, obj, fieldID, val);
    Util_exception_check(env);

jmethodID 
GetStaticMethodID(env, clazz, name, sig)
    JNIEnv *env
    jclass clazz
    const char *name
    const char *sig
  CODE:
    RETVAL = (*env)->GetStaticMethodID(env, clazz, name, sig);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jobject 
CallStaticObjectMethod(env, clazz, methodID, ...)
    JNIEnv *env
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallStaticObjectMethodA(env, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jboolean 
CallStaticBooleanMethod(env, clazz, methodID, ...)
    JNIEnv *env
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallStaticBooleanMethodA(env, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jbyte 
CallStaticByteMethod(env, clazz, methodID, ...)
    JNIEnv *env
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallStaticByteMethodA(env, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jchar 
CallStaticCharMethod(env, clazz, methodID, ...)
    JNIEnv *env
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallStaticCharMethodA(env, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jshort 
CallStaticShortMethod(env, clazz, methodID, ...)
    JNIEnv *env
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallStaticShortMethodA(env, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
CallStaticIntMethod(env, clazz, methodID, ...)
    JNIEnv *env
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallStaticIntMethodA(env, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jlong 
CallStaticLongMethod(env, clazz, methodID, ...)
    JNIEnv *env
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallStaticLongMethodA(env, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jfloat 
CallStaticFloatMethod(env, clazz, methodID, ...)
    JNIEnv *env
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallStaticFloatMethodA(env, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jdouble 
CallStaticDoubleMethod(env, clazz, methodID, ...)
    JNIEnv *env
    jclass clazz
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      RETVAL = (*env)->CallStaticDoubleMethodA(env, clazz, methodID, args);
      if (args != NULL)
        free(args);
    }
    Util_exception_check(env);
  OUTPUT:
    RETVAL

void 
CallStaticVoidMethod(env, cls, methodID, ...)
    JNIEnv *env
    jclass cls
    jmethodID methodID
  CODE:
    {
      int i = 0;
      jvalue *args;
      int count = items - 3;
      
      if (count != 0) {
        args = malloc(count * sizeof(jvalue));
        for (i = 0; i < count; i++) {
          int a = i + 3;
          Util_rv_to_jvalue(&args[i], ST(a));
        }
      }
      else
        args = NULL;
      (*env)->CallStaticVoidMethodA(env, cls, methodID, args);
      if (args != NULL)
        free(args);
      Util_exception_check(env);
    }

jfieldID 
GetStaticFieldID(env, clazz, name, sig)
    JNIEnv *env
    jclass clazz
    const char *name
    const char *sig
  CODE:
    RETVAL = (*env)->GetStaticFieldID(env, clazz, name, sig);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jobject
GetStaticObjectField(env, clazz, fieldID)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetStaticObjectField(env, clazz, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jboolean 
GetStaticBooleanField(env, clazz, fieldID)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetStaticBooleanField(env, clazz, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jbyte 
GetStaticByteField(env, clazz, fieldID)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetStaticByteField(env, clazz, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jchar 
GetStaticCharField(env, clazz, fieldID)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetStaticCharField(env, clazz, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jshort 
GetStaticShortField(env, clazz, fieldID)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetStaticShortField(env, clazz, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
GetStaticIntField(env, clazz, fieldID)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetStaticIntField(env, clazz, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jlong 
GetStaticLongField(env, clazz, fieldID)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetStaticLongField(env, clazz, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jfloat 
GetStaticFloatField(env, clazz, fieldID)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetStaticFloatField(env, clazz, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jdouble 
GetStaticDoubleField(env, clazz, fieldID)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
  CODE:
    RETVAL = (*env)->GetStaticDoubleField(env, clazz, fieldID);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

void 
SetStaticObjectField(env, clazz, fieldID, sv)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
    SV *sv
  CODE:
    {
      jobject value;
      if (sv_derived_from(sv, "jobject")) {
        IV tmp = SvIV((SV*)SvRV(sv));
        value = INT2PTR(jobject, tmp);
      }
      else {
        value = NULL;
      }
      (*env)->SetStaticObjectField(env, clazz, fieldID, value);
      Util_exception_check(env);
    }

void 
SetStaticBooleanField(env, clazz, fieldID, value)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
    jboolean value
  CODE:
    (*env)->SetStaticBooleanField(env, clazz, fieldID, value);
    Util_exception_check(env);

void 
SetStaticByteField(env, clazz, fieldID, value)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
    jbyte value
  CODE:
    (*env)->SetStaticByteField(env, clazz, fieldID, value);
    Util_exception_check(env);

void 
SetStaticCharField(env, clazz, fieldID, value)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
    jchar value
  CODE:
    (*env)->SetStaticCharField(env, clazz, fieldID, value);
    Util_exception_check(env);

void 
SetStaticShortField(env, clazz, fieldID, value)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
    jshort value
  CODE:
    (*env)->SetStaticShortField(env, clazz, fieldID, value);
    Util_exception_check(env);

void 
SetStaticIntField(env, clazz, fieldID, value)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
    jint value
  CODE:
    (*env)->SetStaticIntField(env, clazz, fieldID, value);
    Util_exception_check(env);

void 
SetStaticLongField(env, clazz, fieldID, value)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
    jlong value
  CODE:
    (*env)->SetStaticLongField(env, clazz, fieldID, value);
    Util_exception_check(env);

void 
SetStaticFloatField(env, clazz, fieldID,value)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
    jfloat value
  CODE:
    (*env)->SetStaticFloatField(env, clazz, fieldID,value);
    Util_exception_check(env);

void 
SetStaticDoubleField(env, clazz, fieldID, value)
    JNIEnv *env
    jclass clazz
    jfieldID fieldID
    jdouble value
  CODE:
    (*env)->SetStaticDoubleField(env, clazz, fieldID, value);
    Util_exception_check(env);

jobject 
NewString(env, unicode, len)
    JNIEnv *env
    const jchar *unicode
    jsize len
  CODE:
    RETVAL = (*env)->NewString(env, unicode, len);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jsize 
GetStringLength(env, str)
    JNIEnv *env
    jobject str
  CODE:
    RETVAL = (*env)->GetStringLength(env, str);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

const jchar *
GetStringChars(env, str, OUT isCopy)
    JNIEnv *env
    jobject str
    jboolean isCopy
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetStringChars(env, str, (jboolean *) &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

void 
ReleaseStringChars(env, str, chars)
    JNIEnv *env
    jobject str
    const jchar *chars
  CODE:
    (*env)->ReleaseStringChars(env, str, chars);

jobject 
NewStringUTF(env, utf)
    JNIEnv *env
    const char *utf
  CODE:
    RETVAL = (*env)->NewStringUTF(env, utf);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jsize 
GetStringUTFLength(env, str)
    JNIEnv *env
    jobject str
  CODE:
    RETVAL = (*env)->GetStringUTFLength(env, str);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

const char* 
GetStringUTFChars(env, str, OUT isCopy, OUT cstr)
    JNIEnv *env
    jobject str
    int isCopy
    cstring cstr
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetStringUTFChars(env, str, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
      cstr = (cstring) RETVAL;
    }
  OUTPUT:
    RETVAL
    isCopy

void 
ReleaseStringUTFChars(env, str, chars)
    JNIEnv *env
    jobject str
    cstring chars
  CODE:
    (*env)->ReleaseStringUTFChars(env, str, (const char*) chars);

jsize 
GetArrayLength(env, array)
    JNIEnv *env
    jarray array
  CODE:
    RETVAL = (*env)->GetArrayLength(env, array);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jobjectArray 
NewObjectArray(env, len, clazz, sv)
    JNIEnv *env
    jsize len
    jclass clazz
    SV *sv
  CODE:
    {
      jobject init;
      if (sv_derived_from(sv, "jobject")) {
        IV tmp = SvIV((SV*)SvRV(sv));
        init = INT2PTR(jobject, tmp);
      }
      else {
        init = NULL;
      }
      RETVAL = (*env)->NewObjectArray(env, len, clazz, init);
      Util_exception_check(env);
    }
  OUTPUT:
    RETVAL

jobject 
GetObjectArrayElement(env, array, index)
    JNIEnv *env
    jobjectArray array
    jsize index
  CODE:
    RETVAL = (*env)->GetObjectArrayElement(env, array, index);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

void 
SetObjectArrayElement(env, array, index, sv)
    JNIEnv *env
    jobjectArray array
    jsize index
    SV *sv
  CODE:
    {
      jobject val;
      if (sv_derived_from(sv, "jobject")) {
        IV tmp = SvIV((SV*)SvRV(sv));
        val = INT2PTR(jobject, tmp);
      }
      else {
        val = NULL;
      }
      (*env)->SetObjectArrayElement(env, array, index, val);
      Util_exception_check(env);
    }

jbooleanArray 
NewBooleanArray(env, len)
    JNIEnv *env
    jsize len
  CODE:
    RETVAL = (*env)->NewBooleanArray(env, len);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jbyteArray 
NewByteArray(env, len)
    JNIEnv *env
    jsize len
  CODE:
    RETVAL = (*env)->NewByteArray(env, len);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jcharArray 
NewCharArray(env, len)
    JNIEnv *env
    jsize len
  CODE:
    RETVAL = (*env)->NewCharArray(env, len);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jshortArray 
NewShortArray(env, len)
    JNIEnv *env
    jsize len
  CODE:
    RETVAL = (*env)->NewShortArray(env, len);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jintArray 
NewIntArray(env, len)
    JNIEnv *env
    jsize len
  CODE:
    RETVAL = (*env)->NewIntArray(env, len);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jlongArray 
NewLongArray(env, len)
    JNIEnv *env
    jsize len
  CODE:
    RETVAL = (*env)->NewLongArray(env, len);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jfloatArray 
NewFloatArray(env, len)
    JNIEnv *env
    jsize len
  CODE:
    RETVAL = (*env)->NewFloatArray(env, len);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jdoubleArray 
NewDoubleArray(env, len)
    JNIEnv *env
    jsize len
  CODE:
    RETVAL = (*env)->NewDoubleArray(env, len);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jboolean * 
GetBooleanArrayElements(env, array, OUT isCopy)
    JNIEnv *env
    jbooleanArray array
    int isCopy = NO_INIT
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetBooleanArrayElements(env, array, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

jbyte * 
GetByteArrayElements(env, array, OUT isCopy)
    JNIEnv *env
    jbyteArray array
    int isCopy = NO_INIT
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetByteArrayElements(env, array, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

jchar * 
GetCharArrayElements(env, array, OUT isCopy)
    JNIEnv *env
    jcharArray array
    int isCopy = NO_INIT
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetCharArrayElements(env, array, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

jshort *
GetShortArrayElements(env, array, OUT isCopy)
    JNIEnv *env
    jshortArray array
    int isCopy = NO_INIT
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetShortArrayElements(env, array, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

jint * 
GetIntArrayElements(env, array, OUT isCopy)
    JNIEnv *env
    jintArray array
    int isCopy = NO_INIT
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetIntArrayElements(env, array, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

jlong * 
GetLongArrayElements(env, array, OUT isCopy)
    JNIEnv *env
    jlongArray array
    int isCopy = NO_INIT
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetLongArrayElements(env, array, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

jfloat *
GetFloatArrayElements(env, array, OUT isCopy)
    JNIEnv *env
    jfloatArray array
    int isCopy = NO_INIT
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetFloatArrayElements(env, array, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

jdouble * 
GetDoubleArrayElements(env, array, OUT isCopy)
    JNIEnv *env
    jdoubleArray array
    int isCopy = NO_INIT
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetDoubleArrayElements(env, array, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

void 
ReleaseBooleanArrayElements(env, array, elems, mode)
    JNIEnv *env
    jbooleanArray array
    jboolean *elems
    jint mode
  CODE:
    (*env)->ReleaseBooleanArrayElements(env, array, elems, mode);

void 
ReleaseByteArrayElements(env, array, elems, mode)
    JNIEnv *env
    jbyteArray array
    jbyte *elems
    jint mode
  CODE:
    (*env)->ReleaseByteArrayElements(env, array, elems, mode);

void 
ReleaseCharArrayElements(env, array, elems, mode)
    JNIEnv *env
    jcharArray array
    jchar *elems
    jint mode
  CODE:
    (*env)->ReleaseCharArrayElements(env, array, elems, mode);

void 
ReleaseShortArrayElements(env, array, elems, mode)
    JNIEnv *env
    jshortArray array
    jshort *elems
    jint mode
  CODE:
    (*env)->ReleaseShortArrayElements(env, array, elems, mode);

void 
ReleaseIntArrayElements(env, array, elems, mode)
    JNIEnv *env
    jintArray array
    jint *elems
    jint mode
  CODE:
    (*env)->ReleaseIntArrayElements(env, array, elems, mode);

void 
ReleaseLongArrayElements(env, array, elems, mode)
    JNIEnv *env
    jlongArray array
    jlong *elems
    jint mode
  CODE:
    (*env)->ReleaseLongArrayElements(env, array, elems, mode);

void 
ReleaseFloatArrayElements(env, array, elems, mode)
    JNIEnv *env
    jfloatArray array
    jfloat *elems
    jint mode
  CODE:
    (*env)->ReleaseFloatArrayElements(env, array, elems, mode);

void 
ReleaseDoubleArrayElements(env, array, elems, mode)
    JNIEnv *env
    jdoubleArray array
    jdouble *elems
    jint mode
  CODE:
    (*env)->ReleaseDoubleArrayElements(env, array, elems, mode);

SV *
GetBooleanArrayRegion(env, array, start, len)
    JNIEnv *env
    jbooleanArray array
    jsize start
    jsize len
  CODE:
    {
      jboolean *buf;
      int i;
      AV *av = (AV *)sv_2mortal((SV *)newAV());

      buf = malloc((len + 1) * sizeof(jboolean));
      memset(buf, 0, len + 1);
      (*env)->GetBooleanArrayRegion(env, array, start, len, buf);
      for (i = 0; i < len; i++) {
        SV *new_sv = newSVnv(buf[i]);
        av_push(av, new_sv);
      } 
      free(buf);
      Util_exception_check(env);
      RETVAL = newRV((SV *)av);
    }
  OUTPUT:
     RETVAL

SV *
GetByteArrayRegion(env, array, start, len)
    JNIEnv *env
    jbyteArray array
    jsize start
    jsize len
  CODE:
    {
      jbyte *buf;
      int i;
      AV *av = (AV *)sv_2mortal((SV *)newAV());

      buf = malloc((len + 1) * sizeof(jbyte));
      memset(buf, 0, len + 1);
      (*env)->GetByteArrayRegion(env, array, start, len, buf);
      for (i = 0; i < len; i++) {
        SV *new_sv = newSVnv(buf[i]);
        av_push(av, new_sv);
      }
      free(buf);
      Util_exception_check(env);
      RETVAL = newRV((SV *)av);
    }
  OUTPUT:
     RETVAL

SV * 
GetCharArrayRegion(env, array, start, len)
    JNIEnv *env
    jcharArray array
    jsize start
    jsize len
  CODE:
    {
      jchar *buf;
      int i;
      AV *av = (AV *)sv_2mortal((SV *)newAV());

      buf = malloc((len + 1) * sizeof(jchar));
      memset(buf, 0, len + 1);
      (*env)->GetCharArrayRegion(env, array, start, len, buf);
      for (i = 0; i < len; i++) {
        SV *new_sv = newSVnv(buf[i]);
        av_push(av, new_sv);
      } 
      free(buf);
      Util_exception_check(env);
      RETVAL = newRV((SV *)av);
    }
  OUTPUT:
     RETVAL

SV *
GetShortArrayRegion(env, array, start, len)
    JNIEnv *env
    jshortArray array
    jsize start
    jsize len
  CODE:
    {
      jshort *buf;
      int i;
      AV *av = (AV *)sv_2mortal((SV *)newAV());

      buf = malloc((len + 1) * sizeof(jshort));
      memset(buf, 0, len + 1);
      (*env)->GetShortArrayRegion(env, array, start, len, buf);
      for (i = 0; i < len; i++) {
        SV *new_sv = newSVnv(buf[i]);
        av_push(av, new_sv);
      }
      free(buf);
      Util_exception_check(env);
      RETVAL = newRV((SV *)av);
    }
  OUTPUT:
     RETVAL

SV *
GetIntArrayRegion(env, array, start, len)
    JNIEnv *env
    jintArray array
    jsize start
    jsize len
  CODE:
    {
      jint *buf;
      int i;
      AV *av = (AV *)sv_2mortal((SV *)newAV());

      buf = malloc((len + 1) * sizeof(jint));
      memset(buf, 0, len + 1);
      (*env)->GetIntArrayRegion(env, array, start, len, buf);
      for (i = 0; i < len; i++) {
        SV *new_sv = newSVnv(buf[i]);
        av_push(av, new_sv);
      }
      free(buf);
      Util_exception_check(env);
      RETVAL = newRV((SV *)av);
    }
  OUTPUT:
     RETVAL

SV *
GetLongArrayRegion(env, array, start, len)
    JNIEnv *env
    jlongArray array
    jsize start
    jsize len
  CODE:
    {
      jlong *buf;
      int i;
      AV *av = (AV *)sv_2mortal((SV *)newAV());

      buf = malloc((len + 1) * sizeof(jlong));
      memset(buf, 0, len + 1);
      (*env)->GetLongArrayRegion(env, array, start, len, buf);
      for (i = 0; i < len; i++) {
        SV *new_sv = newSVnv(buf[i]);
        av_push(av, new_sv);
      }
      free(buf);
      Util_exception_check(env);
      RETVAL = newRV((SV *)av);
    }
  OUTPUT:
     RETVAL

SV *
GetFloatArrayRegion(env, array, start, len)
    JNIEnv *env
    jfloatArray array
    jsize start
    jsize len
  CODE:
    {
      jfloat *buf;
      int i;
      AV *av = (AV *)sv_2mortal((SV *)newAV());

      buf = malloc((len + 1) * sizeof(jfloat));
      memset(buf, 0, len + 1);
      (*env)->GetFloatArrayRegion(env, array, start, len, buf);
      for (i = 0; i < len; i++) {
        SV *new_sv = newSVnv(buf[i]);
        av_push(av, new_sv);
      }
      free(buf);
      Util_exception_check(env);
      RETVAL = newRV((SV *)av);
    }
  OUTPUT:
     RETVAL

SV *
GetDoubleArrayRegion(env, array, start, len)
    JNIEnv *env
    jdoubleArray array
    jsize start
    jsize len
  CODE:
    {
      jdouble *buf;
      int i;
      AV *av = (AV *)sv_2mortal((SV *)newAV());

      buf = malloc((len + 1) * sizeof(jdouble));
      memset(buf, 0, len + 1);
      (*env)->GetDoubleArrayRegion(env, array, start, len, buf);
      for (i = 0; i < len; i++) {
        SV *new_sv = newSVnv(buf[i]);
        av_push(av, new_sv);
      }
      free(buf);
      Util_exception_check(env);
      RETVAL = newRV((SV *)av);
    }
  OUTPUT:
     RETVAL

void 
SetBooleanArrayRegion(env, array, start, len, buf)
    JNIEnv *env
    jbooleanArray array
    jsize start
    jsize len
    SV *buf
  CODE:
    {
      I32 elems = 0;
      int i, n;
      jboolean* jbuf;

      if ((!SvROK(buf))
          || (SvTYPE(SvRV(buf)) != SVt_PVAV)
          || ((elems = av_len((AV *)SvRV(buf))) < 0)) {
         croak("Argument 'buf' must be a reference");
      }
      jbuf = malloc((elems + 1) * sizeof(jboolean));
      for (n = 0; n <= elems; n++) {
        STRLEN l;
	char * c = SvPV(*av_fetch((AV *)SvRV(buf), n, 0), l);
	jbuf[n] = (jboolean) *c;
        /*printf("element: %d: %d\n", n, jbuf[n]);*/
      }

      (*env)->SetBooleanArrayRegion(env, array, start, len, jbuf);
      free(jbuf);
      Util_exception_check(env);
    }

void 
SetByteArrayRegion(env, array, start, len, buf)
    JNIEnv *env
    jbyteArray array
    jsize start
    jsize len
    SV *buf
  CODE:
    {
      I32 elems = 0;
      int i, n;
      jbyte * jbuf;

      if ((!SvROK(buf))
          || (SvTYPE(SvRV(buf)) != SVt_PVAV)
          || ((elems = av_len((AV *)SvRV(buf))) < 0)) {
         croak("Argument 'buf' must be a reference");
      }
      jbuf = malloc((elems + 1) * sizeof(jbyte));
      for (n = 0; n <= elems; n++) {
        STRLEN l;
	char * c = SvPV(*av_fetch((AV *)SvRV(buf), n, 0), l);
	jbuf[n] = (jbyte) *c;
        /*printf("element: %d: %d\n", n, jbuf[n]);*/
      }

      (*env)->SetByteArrayRegion(env, array, start, len, jbuf);
      free(jbuf);
      Util_exception_check(env);
    }

void 
SetCharArrayRegion(env, array, start, len, buf)
    JNIEnv *env
    jcharArray array
    jsize start
    jsize len
    SV *buf 
  CODE:
    {
      I32 elems = 0;
      int i, n;
      jchar* jbuf;

      if ((!SvROK(buf))
          || (SvTYPE(SvRV(buf)) != SVt_PVAV)
          || ((elems = av_len((AV *)SvRV(buf))) < 0)) {
         croak("Argument 'buf' must be a reference");
      }
      jbuf = malloc((elems + 1) * sizeof(jchar));
      for (n = 0; n <= elems; n++) {
        STRLEN l;
	char * c = SvPV(*av_fetch((AV *)SvRV(buf), n, 0), l);
	jbuf[n] = (jchar) *c;
        /*printf("element: %d: %d\n", n, jbuf[n]);*/
      }

      (*env)->SetCharArrayRegion(env, array, start, len, jbuf);
      free(jbuf);
      Util_exception_check(env);
    }

void 
SetShortArrayRegion(env, array, start, len, buf)
    JNIEnv *env
    jshortArray array
    jsize start
    jsize len
    SV *buf
  CODE:
    {
      I32 elems = 0;
      int i, n;
      jshort* jbuf;

      if ((!SvROK(buf))
          || (SvTYPE(SvRV(buf)) != SVt_PVAV)
          || ((elems = av_len((AV *)SvRV(buf))) < 0)) {
         croak("Argument 'buf' must be a reference");
      }
      jbuf = malloc((elems + 1) * sizeof(jshort));
      for (n = 0; n <= elems; n++) {
        STRLEN l;
	jshort c = SvIV(*av_fetch((AV *)SvRV(buf), n, 0));
	jbuf[n] = c;
        /*printf("element: %d: %d\n", n, jbuf[n]);*/
      }

      (*env)->SetShortArrayRegion(env, array, start, len, jbuf);
      free(jbuf);
      Util_exception_check(env);
    }

void 
SetIntArrayRegion(env, array, start, len, buf)
    JNIEnv *env
    jintArray array
    jsize start
    jsize len
    SV *buf
  CODE:
    {
      I32 elems = 0;
      int i, n;
      jint* jbuf;

      if ((!SvROK(buf))
          || (SvTYPE(SvRV(buf)) != SVt_PVAV)
          || ((elems = av_len((AV *)SvRV(buf))) < 0)) {
         croak("Argument 'buf' must be a reference");
      }
      jbuf = malloc((elems + 1) * sizeof(jint));
      for (n = 0; n <= elems; n++) {
        STRLEN l;
	jint c = SvIV(*av_fetch((AV *)SvRV(buf), n, 0));
	jbuf[n] = c;
        /*printf("element: %d: %d\n", n, jbuf[n]);*/
      }

      (*env)->SetIntArrayRegion(env, array, start, len, jbuf);
      free(jbuf);
      Util_exception_check(env);
    }

void 
SetLongArrayRegion(env, array, start, len, buf)
    JNIEnv *env
    jlongArray array
    jsize start
    jsize len
    SV *buf
  CODE:
    {
      I32 elems = 0;
      int i, n;
      jlong* jbuf;

      if ((!SvROK(buf))
          || (SvTYPE(SvRV(buf)) != SVt_PVAV)
          || ((elems = av_len((AV *)SvRV(buf))) < 0)) {
         croak("Argument 'buf' must be a reference");
      }
      jbuf = malloc((elems + 1) * sizeof(jlong));
      for (n = 0; n <= elems; n++) {
        STRLEN l;
	jlong c = SvIV(*av_fetch((AV *)SvRV(buf), n, 0));
	jbuf[n] = c;
        /*printf("element: %d: %d\n", n, jbuf[n]);*/
      }

      (*env)->SetLongArrayRegion(env, array, start, len, jbuf);
      free(jbuf);
      Util_exception_check(env);
    }

void 
SetFloatArrayRegion(env, array, start, len, buf)
    JNIEnv *env
    jfloatArray array
    jsize start
    jsize len
    SV *buf
  CODE:
    {
      I32 elems = 0;
      int i, n;
      jfloat* jbuf;

      if ((!SvROK(buf))
          || (SvTYPE(SvRV(buf)) != SVt_PVAV)
          || ((elems = av_len((AV *)SvRV(buf))) < 0)) {
         croak("Argument 'buf' must be a reference");
      }
      jbuf = malloc((elems + 1) * sizeof(jfloat));
      for (n = 0; n <= elems; n++) {
        STRLEN l;
	jbuf[n] = SvNV(*av_fetch((AV *)SvRV(buf), n, 0));
        /*printf("element: %d: %d\n", n, jbuf[n]);*/
      }

      (*env)->SetFloatArrayRegion(env, array, start, len, jbuf);
      free(jbuf);
      Util_exception_check(env);
    }

void 
SetDoubleArrayRegion(env, array, start, len, buf)
    JNIEnv *env
    jdoubleArray array
    jsize start
    jsize len
    SV *buf
  CODE:
    {
      I32 elems = 0;
      int i, n;
      jdouble* jbuf;

      if ((!SvROK(buf))
          || (SvTYPE(SvRV(buf)) != SVt_PVAV)
          || ((elems = av_len((AV *)SvRV(buf))) < 0)) {
         croak("Argument 'buf' must be a reference");
      }
      jbuf = malloc((elems + 1) * sizeof(jdouble));
      for (n = 0; n <= elems; n++) {
        STRLEN l;
	jdouble c = SvNV(*av_fetch((AV *)SvRV(buf), n, 0));
	jbuf[n] = c;
        /*printf("element: %d: %d\n", n, jbuf[n]);*/
      }

      (*env)->SetDoubleArrayRegion(env, array, start, len, jbuf);
      free(jbuf);
      Util_exception_check(env);
    }

jint 
RegisterNatives(env, clazz, methods, nMethods)
    JNIEnv *env
    jclass clazz
    const JNINativeMethod *methods
    jint nMethods
  CODE:
    RETVAL = (*env)->RegisterNatives(env, clazz, methods, nMethods);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
UnregisterNatives(env, clazz)
    JNIEnv *env
    jclass clazz
  CODE:
    RETVAL = (*env)->UnregisterNatives(env, clazz);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
MonitorEnter(env, obj)
    JNIEnv *env
    jobject obj
  CODE:
    RETVAL = (*env)->MonitorEnter(env, obj);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
MonitorExit(env, obj)
    JNIEnv *env
    jobject obj
  CODE:
    RETVAL = (*env)->MonitorExit(env, obj);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

jint 
GetJavaVM(env, OUT vm)
    JNIEnv *env
    JavaVM *vm
  CODE:
    RETVAL = (*env)->GetJavaVM(env, &vm);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

void 
GetStringRegion(env, str, start, len, buf)
    JNIEnv *env
    jobject str
    jsize start
    jsize len
    jchar *buf
  CODE:
    (*env)->GetStringRegion(env, str, start, len, buf);
    Util_exception_check(env);

void 
GetStringUTFRegion(env, str, start, len, buf)
    JNIEnv *env
    jobject str
    jsize start
    jsize len
    char *buf
  CODE:
    (*env)->GetStringUTFRegion(env, str, start, len, buf);
    Util_exception_check(env);

void * 
GetPrimitiveArrayCritical(env, array, OUT isCopy)
    JNIEnv *env
    jarray array
    int isCopy = NO_INIT
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetPrimitiveArrayCritical(env, array, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

void 
ReleasePrimitiveArrayCritical(env, array, carray, mode)
    JNIEnv *env
    jarray array
    void *carray
    jint mode
  CODE:
    (*env)->ReleasePrimitiveArrayCritical(env, array, carray, mode);

const jchar * 
GetStringCritical(env, string, OUT isCopy)
    JNIEnv *env
    jobject string
    int isCopy = NO_INIT
  CODE:
    {
      jboolean is_copy;
      RETVAL = (*env)->GetStringCritical(env, string, &is_copy);
      isCopy = is_copy ? 1 : 0;
      Util_exception_check(env);
    }
  OUTPUT:
    isCopy
    RETVAL

void 
ReleaseStringCritical(env, string, cstring)
    JNIEnv *env
    jobject string
    const jchar *cstring
  CODE:
    (*env)->ReleaseStringCritical(env, string, cstring);

jweak 
NewWeakGlobalRef (env, sv)
    JNIEnv *env
    SV *sv
  CODE:
    {
      jobject obj;
      if (sv_derived_from(sv, "jobject")) {
        IV tmp = SvIV((SV*)SvRV(sv));
        obj = INT2PTR(jobject, tmp);
      }
      else {
        obj = NULL;
      }
      RETVAL = (*env)->NewWeakGlobalRef(env, obj);
      Util_exception_check(env);
    }
  OUTPUT:
    RETVAL

void 
DeleteWeakGlobalRef (env, sv)
    JNIEnv *env
    SV *sv
  CODE:
    {
      jweak ref;
      if (sv_derived_from(sv, "jobject")) {
        IV tmp = SvIV((SV*)SvRV(sv));
        ref = INT2PTR(jobject, tmp);
      }
      else {
        ref = NULL;
      }
      (*env)->DeleteWeakGlobalRef(env, ref);
      Util_exception_check(env);
    }

jboolean 
ExceptionCheck (env)
    JNIEnv *env
  CODE:
    RETVAL = (*env)->ExceptionCheck(env);
    Util_exception_check(env);
  OUTPUT:
    RETVAL

