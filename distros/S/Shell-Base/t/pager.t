#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 4;
$ENV{"PAGER"} = "more";

use_ok("Shell::Base");

my $shell = Shell::Base->new;
is($shell->pager, $ENV{"PAGER"}, "pager inherits from the environment");
is($shell->pager("foo"), "foo", "pager is settable");

delete $shell->{ PAGER };
delete $ENV{"PAGER"};

is($shell->pager, "more", "default pager (more)");
