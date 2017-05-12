#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use Shell::Base;

plan tests => 6;

use_ok("Shell::Base");

my $sh = Shell::Base->new;

is(scalar keys %{ $sh->args() }, 0, "No args == nothing in \$self->args");
is($sh->prompt, $Shell::Base::PROMPT, "Default prompt");
ok(! defined $sh->{ PAGER }, "PAGER undefined by default");
ok(! defined $sh->{ HISTFILE }, "HISTFILE undefined by default");
ok($sh->pager, "PAGER is defined when asked for");
