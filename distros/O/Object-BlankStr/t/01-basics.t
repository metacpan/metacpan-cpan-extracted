#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use Object::BlankStr;

my $str = Object::BlankStr->new;

is("$str", "", "object stringifies to empty string");

eval { die $str };
my $eval_err = $@;
is("$eval_err", "", "die Object::BlankStr->new doesn't print anything");
is(ref($eval_err), "Object::BlankStr", "object returned by die()");

done_testing();
