#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Perinci::Gen::ForModule qw(gen_meta_for_module);

package Foo::Bar;

our %SPEC;
sub _s1 { "s1" }
sub s2  { "s2" }
sub s3  { $_[0] * $_[1] }

package main;

gen_meta_for_module(module=>"Foo::Bar");
is_deeply([sort keys %Foo::Bar::SPEC],
          [":package", "s2", "s3"], "metadata generated");

done_testing;
