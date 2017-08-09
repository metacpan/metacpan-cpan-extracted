use strict;
use warnings;
use Test::More;
use Shell::Guess;

plan skip_all => 'VMS only test' unless $^O eq 'VMS';
plan tests => 2;

is eval { Shell::Guess->running_shell->is_dcl }, 1, "running dcl";
diag $@ if $@;
is eval { Shell::Guess->login_shell->is_dcl }, 1, "login dcl";
diag $@ if $@;