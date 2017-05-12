use strict;
use warnings;
use 5.008001;
use Test::More tests => 3;
use Shell::Guess;
use Shell::Config::Generate;

is eval { Shell::Config::Generate->new->echo_off->generate(Shell::Guess->bourne_shell) }, "", "echo off = ''";
diag $@ if $@;

is eval { Shell::Config::Generate->new->echo_off->generate(Shell::Guess->cmd_shell) }, "\@echo off\n", 'echo off = @echo off';
diag $@ if $@;

is eval { Shell::Config::Generate->new->echo_off->echo_on->generate(Shell::Guess->cmd_shell) }, "", 'echo off = ""';
diag $@ if $@;

