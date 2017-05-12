#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib','../lib';

use Test::More tests => 3;

my @modules = qw(
Template::Plugin::UTF8toANSI
Template
Unicode::String
);

foreach my $module (@modules) {
    eval " use $module ";
    ok(!$@, "$module compiles");
}

1;
