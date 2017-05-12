#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $class = "MojoX::Plugin::AnyCache";
use_ok $class;
new_ok $class;

my $class2 = "MojoX::Plugin::ManyCache";
use_ok $class2;
new_ok $class2;

done_testing(4);
