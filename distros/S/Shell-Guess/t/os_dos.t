use strict;
use warnings;
use Test::More;
use Shell::Guess;

plan skip_all => 'DOS only test' unless $^O eq 'dos';
plan tests => 2;

is eval { Shell::Guess->running_shell->is_command }, 1, "running command";
diag $@ if $@;
is eval { Shell::Guess->login_shell->is_command }, 1, "login command";
diag $@ if $@;
