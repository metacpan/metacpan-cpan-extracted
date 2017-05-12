/* 
 * Copyright (c) 2001 Ping Liang
 * All rights reserved.
 *
 * This program is free software; you can use, redistribute and/or
 * modify it under the same terms as Perl itself.
 *
 * $Id: Utils.c,v 1.3 2001/11/13 14:34:48 liang Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <jni.h>

jvalue
Util_cast_jvalue(SV *sv) {
  I32 num = 0;
  STRLEN L;
  char * ptr, * type;
  jvalue v;
  
  if ((!SvROK(sv))
      || (SvTYPE(SvRV(sv)) != SVt_PVAV)
      || ((num = av_len((AV *)SvRV(sv))) < 0)) {
    croak("Cannot convert a non-reference into jvalue.");
  }

  if (num != 2) {
    croak("Do not recongnize this array reference for jvalue");
  }

  ptr = SvPV(*av_fetch((AV *)SvRV(sv), 0, 0), L);

  if (strcmp(ptr, "jvalue") != 0) {
    croak("Argument was not casted");
  }

  type = SvPV(*av_fetch((AV *)SvRV(sv), 1, 0), L);
  switch(*type) {
  case 'Z':
    v.z = SvTRUE(*av_fetch((AV *)SvRV(sv), 2, 0));
    break;
  case 'B':
    ptr = SvPV(*av_fetch((AV *)SvRV(sv), 2, 0), L);
    v.b = *ptr;
    break;
  case 'C':
    ptr = SvPV(*av_fetch((AV *)SvRV(sv), 2, 0), L);
    v.c = *ptr;
    break;
  case 'S':
    v.s = SvIV(*av_fetch((AV *)SvRV(sv), 2, 0));
    break;
  case 'I':
    v.i = SvIV(*av_fetch((AV *)SvRV(sv), 2, 0));
    break;
  case 'J':
    v.j = SvIV(*av_fetch((AV *)SvRV(sv), 2, 0));
    break;
  case 'F':
    v.f = SvNV(*av_fetch((AV *)SvRV(sv), 2, 0));
    break;
  case 'D':
    v.d = SvNV(*av_fetch((AV *)SvRV(sv), 2, 0));
    break;
  case 'L':
    v.l = (jobject) SvIV(SvRV(*av_fetch((AV *)SvRV(sv), 2, 0)));
    break;
  default:
    croak("Do not recongnize the type to cast '%c'", *type);
    break;
  }
  return v;
}

void
Util_rv_to_jvalue(jvalue *u, SV *sv) {
  *u = Util_cast_jvalue(sv);
}

void 
Util_exception_check(JNIEnv *env) {
  jthrowable except;

  except = (*env)->ExceptionOccurred(env);
  if (except != 0) {
    (*env)->ExceptionDescribe(env);
    (*env)->DeleteLocalRef(env, except);
    croak("Java exception occurred");
  }
  else {
    (*env)->DeleteLocalRef(env, except);
  }
}

