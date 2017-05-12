# Copyright (c) 2001 Ping Liang
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Callback.pm,v 1.1 2002/01/01 20:40:29 liang Exp $

package PBJ::JNI::Callback;

our $VERSION = '0.1';

use Carp;
use PBJ::JNI::JNIEnv;

sub callback() {
  my $_env = shift;
  my $jmethod = shift;
  my ($ret, $env);
  my ($method, $cptr, $is_copy);

  $env = new PBJ::JNI::JNIEnv($_env);

  $env->PushLocalFrame(16) == 0 or die;
  $method = $env->GetStringUTFChars($jmethod, $is_copy, $cptr);
  $env->ReleaseStringUTFChars($jmethod, $cptr);
  $env->PopLocalFrame(0);

  unshift(@_, $env);
  # now the arguments are $env and the jobject passed from java program.
  eval { package MAIN; $ret = &$method; };
  if ($@) {
    # should throw java exception here.
    croak("$method: $@");
  }
  return $ret;
};

