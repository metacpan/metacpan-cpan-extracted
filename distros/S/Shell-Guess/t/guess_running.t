use strict;
use warnings;
use Test::More tests => 3;
use Shell::Guess;

my $shell = eval { Shell::Guess->running_shell };
diag $@ if $@;

isa_ok $shell, 'Shell::Guess';
ok $shell->is_win32 || $shell->is_unix || $shell->is_vms, 'shell is one of win32 unix or vms environment';
ok $shell->name, "name is : " . $shell->name;