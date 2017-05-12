/* 
 * Copyright (c) 2001 Ping Liang
 * All rights reserved.
 *
 * This program is free software; you can use, redistribute and/or
 * modify it under the same terms as Perl itself.
 *
 * $Id: Callback.c,v 1.1 2002/01/01 20:40:29 liang Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <jni.h>
#include "Callback.h"

JNIEXPORT void JNICALL
Java_Callback_callback(JNIEnv *env,
		       jclass cls,
		       jstring method,
		       jobject args) {
  { 
    dSP ; 
    
    ENTER ; 
    SAVETMPS ; 
    
    PUSHMARK(SP) ; 
    XPUSHs(sv_2mortal(sv_setref_pv(newSVnv(0), "JNIEnvPtr", env))); 
    XPUSHs(sv_2mortal(sv_setref_pv(newSVnv(0), "jobject", method))); 
    XPUSHs(sv_2mortal(sv_setref_pv(newSVnv(0), "jobject", args))); 
    PUTBACK ; 
    
    call_pv("PBJ::JNI::Callback::callback", G_DISCARD); 
    
    FREETMPS ; 
    LEAVE ; 
  } 
}
