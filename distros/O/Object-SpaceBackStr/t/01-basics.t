#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use Object::SpaceBackStr;

my $str = Object::SpaceBackStr->new;

is("$str", " \b", "object stringifies to SPC+BACKSPACE");

eval { die $str };
my $eval_err = $@;
is(ref($eval_err), "Object::SpaceBackStr", "object from die");
is("$eval_err", " \b", "object from die (stringified)");

done_testing();
