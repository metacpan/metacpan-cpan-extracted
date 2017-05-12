#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 3;

use_ok("Shell::Base");

is(Shell::Base->default("foo", "bar", "baz"),
   "Shell::Base->foo(bar baz) called, but do_foo is not defined!",
   "default fails correctly");

is(Shell::Base->default("foo", "'bar baz'"),
   "Shell::Base->foo('bar baz') called, but do_foo is not defined!",
   "default fails correctly");
