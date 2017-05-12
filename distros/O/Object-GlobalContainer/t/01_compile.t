#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Test::More tests => 2;

my @modules = qw(
  Object::GlobalContainer
  Class::Inspector
);

foreach my $module (@modules) {
    eval " use $module ";
    ok(!$@, "$module compiles");
}

1;
