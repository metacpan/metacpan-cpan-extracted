#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use Object::NulStr;

my $str = Object::NulStr->new;

is("$str", "\0", "object stringifies to NUL character");

eval { die $str };
my $eval_err = $@;
is(ref($eval_err), "Object::NulStr", "object from die()");
is("$eval_err", "\0", "object from die (stringified)");

done_testing();
