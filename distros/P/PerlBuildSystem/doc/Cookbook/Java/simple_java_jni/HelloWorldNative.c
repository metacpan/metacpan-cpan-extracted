#include <jni.h>
#include <stdio.h>
#include "HelloWorldNative.h"

JNIEXPORT void JNICALL
JNICALL Java_HelloWorldNative_print(JNIEnv* env, jobject obj)
{
	printf ("Hello from native function '%s'\n", __FUNCTION__);
	return;
}
