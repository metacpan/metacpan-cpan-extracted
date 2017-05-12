#!perl -T

use strict;
use warnings;

use Test::More;

my @methods = qw<
 new here
 cxt
 uid is_valid assert_valid

 package file line
 sub_name sub_has_args
 gimme
 eval_text is_require
 hints_bits warnings_bits

 want
 up sub eval

 reap localize localize_elem localize_delete
 unwind yield
 uplevel
>;

push @methods, 'hints_hash' if "$]" >= 5.010;

plan tests => scalar(@methods);

require Scope::Context;

for (@methods) {
 ok(Scope::Context->can($_), 'Scope::Context objects can ' . $_);
}

