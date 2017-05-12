#! /usr/bin/perl

# Copyright (c) 2001 Ping Liang
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: callback.t,v 1.1 2002/01/01 20:40:29 liang Exp $

use Test;
BEGIN { plan tests => 1 };
use PBJ::JNI::JavaVM;
use PBJ::JNI::Callback;

my ($env, $jvm, @vm_opts);

# Create the Java VM
@vm_opts = ("-Xrs", "-Xcheck:jni", "-Djava.class.path=blib/arch/auto/PBJ/JNI/Native", 
	    "-Djava.library.path=blib/arch/auto/PBJ/JNI/Native");
$jvm = new PBJ::JNI::JavaVM();
$env = $jvm->get_env(@vm_opts);

# now get down to business.
&make_cb();

ok(1); # If we made it this far, we're ok.

sub make_cb() {
  my ($cls, $fid, $mid, $out, $jint);

  $env->PushLocalFrame(16) == 0 or die;

  $cls = $env->FindClass("CallbackTest") or die;
#  $mid = $env->GetStaticMethodID($cls, "callback", "(Ljava/lang/String;Ljava/lang/Object;)V") or die;
#  $env->CallStaticVoidMethod($cls, $mid, $env->cast("L", "test"), $env->cast("L", $num));

  $env->PopLocalFrame(0);
}

package MAIN;

sub receive_callback() {
  my ($env, $jobject) = @_;
  my ($string, $cptr, $is_copy);

  print "I've got the message!\n";

  $env->PushLocalFrame(16) == 0 or die;
  $string = $env->GetStringUTFChars($jobject, $is_copy, $cptr);
  $env->ReleaseStringUTFChars($jobject, $cptr);
  $env->PopLocalFrame(0);

  print "You were saying \"$string\"\n"
}
