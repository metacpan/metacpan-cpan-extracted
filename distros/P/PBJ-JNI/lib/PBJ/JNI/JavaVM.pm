# Copyright (c) 2001 Ping Liang
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: JavaVM.pm,v 1.2 2002/01/01 20:41:53 liang Exp $

package PBJ::JNI::JavaVM;

use strict;

our $VERSION = '0.1';

use PBJ::JNI::JNIEnv;

my $_jvm;
my $_env;

sub new {
  my $classname = shift;
  my $self = {};
  my $handle = shift;
  bless($self, $classname);
  return $self;
};

sub get_env() {
  my ($self, @vm_opts) = @_;
  my ($ret);

  unless (defined $_env) {
    $ret = PBJ::JNI::Native::JNI_CreateJavaVM($_jvm, $_env, \@vm_opts);
    $ret == 0 or die "Can't create Java VM";
  }
  else {
    return $_env;
  }
  return  new PBJ::JNI::JNIEnv($_env);
}

sub DESTROY() {
  my $ret;
  #if (PBJ::JNI::Native::ExceptionOccurred($_env)) {
  #PBJ::JNI::Native::ExceptionDescribe($_env);
  #}
  #PBJ::JNI::Native::ExceptionClear($_env);
  if ($_jvm) {
    $ret = PBJ::JNI::Native::DetachCurrentThread($_jvm);
    $ret == 0 or die "DetachCurrentThread failed.\n";
    # always return -1 anyway...
    PBJ::JNI::Native::DestroyJavaVM($_jvm);
  }
  return 1;
}

1;

