#! /usr/bin/perl

# Copyright (c) 2001 Ping Liang
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: print_string.t,v 1.4 2002/01/01 20:41:53 liang Exp $

use Test;
BEGIN { plan tests => 1 };
use PBJ::JNI::JavaVM;
use strict;

my ($env, $jvm, @vm_opts, $str, @chars);

# Create the Java VM
@vm_opts = ("-Xrs");#, "-Xcheck:jni");
$jvm = new PBJ::JNI::JavaVM();
$env = $jvm->get_env(@vm_opts);

# now get down to business.
@chars = ("t", "h", "i", "s", " ", "i", "s", " ", "a",
	  " ", "t", "e", "s", "t", "!");
$str = &get_jstring(@chars);
&println($str);
$env->DeleteGlobalRef($str);

ok(1); # If we made it this far, we're ok.

sub get_jstring() {
  my (@chars) = @_;
  my ($cls, $mid, $arr, $len, $str, $str_g);

  # define the string
  $len = scalar(@chars);

  $env->PushLocalFrame(26) == 0 or die;
  $cls = $env->FindClass("java/lang/String") or die "Can't find class.\n";
  $mid = $env->GetMethodID($cls, "<init>", "([C)V") or die "Can't find method.\n";
  $arr = $env->NewCharArray($len) or die "NewCharArray die\n";
  $env->SetCharArrayRegion($arr, 0, $len, \@chars);
  $str = $env->NewObject($cls, $mid, $env->cast("L", $arr)) or die "NewObject die\n";
  $str_g = $env->NewGlobalRef($str) or die;
  $env->PopLocalFrame(0);
  return $str_g;
}

sub println() {
  my ($str) = @_;
  my ($cls, $fid, $mid, $out);

  $env->PushLocalFrame(16) == 0 or die;
  $cls = $env->FindClass("java/lang/System") or die;
  $fid = $env->GetStaticFieldID($cls, "out", "Ljava/io/PrintStream;") or die;
  $out = $env->GetStaticObjectField($cls, $fid) or die;
  $cls = $env->GetObjectClass($out) or die;
  $mid = $env->GetMethodID($cls, "println", "(Ljava/lang/String;)V") or die;
  $env->CallVoidMethod($out, $mid, $env->cast("L", $str));
  $env->PopLocalFrame(0);
}

