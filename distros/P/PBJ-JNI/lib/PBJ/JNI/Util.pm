# Copyright (c) 2001 Ping Liang
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Util.pm,v 1.2 2001/11/13 14:34:49 liang Exp $

package PBJ::JNI::Util;

our $VERSION = '0.1';

use strict;
use Carp;
use PBJ::JNI::JNIEnv;

sub get_static_field() {
  my ($clz, $env, $cls_name, $fld_name, $fld_sig) = @_;
  my ($cls, $fid, $mid, $fld, $value);

  $env->PushLocalFrame(16) == 0 or die;
  $cls = $env->FindClass($cls_name) or die;
  $fid = $env->GetStaticFieldID($cls, $fld_name, $fld_sig) or die;
  $value = $env->GetStaticIntField($cls, $fid) or die;
  $env->PopLocalFrame(0);
  return $value;
};

