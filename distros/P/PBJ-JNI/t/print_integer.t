#! /usr/bin/perl

# Copyright (c) 2001 Ping Liang
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: print_integer.t,v 1.3 2001/11/13 14:34:50 liang Exp $

use Test;
BEGIN { plan tests => 1 };
use PBJ::JNI::JavaVM;

my ($env, $jvm, @vm_opts);

# Create the Java VM
@vm_opts = ("-Xrs", "-Xcheck:jni");
$jvm = new PBJ::JNI::JavaVM();
$env = $jvm->get_env(@vm_opts);

# now get down to business.
&println(1234);

ok(1); # If we made it this far, we're ok.

sub println() {
  my ($num) = @_;
  my ($cls, $fid, $mid, $out, $jint);

  $env->PushLocalFrame(16) == 0 or die;
  $cls = $env->FindClass("java/lang/System") or die;
  $fid = $env->GetStaticFieldID($cls, "out", "Ljava/io/PrintStream;") or die;
  $out = $env->GetStaticObjectField($cls, $fid) or die;
  $cls = $env->GetObjectClass($out) or die;
  $mid = $env->GetMethodID($cls, "println", "(I)V") or die;
  $env->CallVoidMethod($out, $mid, $env->cast("I", $num));
  $env->PopLocalFrame(0);
}

