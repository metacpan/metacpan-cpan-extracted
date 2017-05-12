#!/usr/bin/perl -w

use strict;
use Test::More;
#use ex::lib '../lib';

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
$@ and plan skip_all => "Test::Pod $min_tp required for testing POD";
plan tests => 1;

pod_file_ok($INC{ 'Sub/Lvalue.pm' });
