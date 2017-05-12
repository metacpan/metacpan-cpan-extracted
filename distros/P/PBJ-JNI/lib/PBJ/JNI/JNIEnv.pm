# Copyright (c) 2001 Ping Liang
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: JNIEnv.pm,v 1.1.1.1 2001/11/12 15:10:47 liang Exp $

package PBJ::JNI::JNIEnv;

$VERSION = '0.1';

require Exporter;
require DynaLoader;

use Carp;
use PBJ::JNI::Native;

# takes one argument, the env object.
sub new {
  my $classname = shift;
  my $self = {};
  my $handle = shift;
  #print "we have handle: " . $handle . "\n";
  bless($self, $classname);
  $self->{HANDLE} = $handle;
  return $self;
};

sub cast {
  my ($self, $type, $value) = @_;
  my @jvalue;

  @jvalue = ("jvalue", $type, $value);
  return \@jvalue;
};

# upon called for a method,
# look for a corresponding JNI env interface functoin to call.
sub AUTOLOAD {
  my $self = shift;
  my $method;
  my $ret;

  $method = $AUTOLOAD;
  $method =~ s/.*://; # strip fully-qualified portion

  $method = "PBJ::JNI::Native::" . $method;
  unshift(@_, $self->{HANDLE});
  eval { $ret = &$method; };
  if ($@) {
    croak("$method: $@");
  }
  return $ret;
}

sub DESTROY() {
}

1;
