use strict;
use warnings;
use Test::More tests => 16;
use Shell::Guess;

my $shell = eval { Shell::Guess->fish_shell };
diag $@ if $@;

isa_ok $shell, 'Shell::Guess';

is eval { $shell->is_cmd     }, 0, "cmd = 0";
diag $@ if $@;
is eval { $shell->is_command }, 0, "command = 0";
diag $@ if $@;
is eval { $shell->is_dcl     }, 0, "dcl = 0";
diag $@ if $@;
is eval { $shell->is_bash    }, 0, "bash = 0";
diag $@ if $@;
is eval { $shell->is_fish    }, 1, "fish = 1";
diag $@ if $@;
is eval { $shell->is_korn    }, 0, "korn = 0";
diag $@ if $@;
is eval { $shell->is_c       }, 0, "c = 0";
diag $@ if $@;
is eval { $shell->is_win32   }, 0, "win32 = 0";
diag $@ if $@;
is eval { $shell->is_unix    }, 1, "unix = 1";
diag $@ if $@;
is eval { $shell->is_vms     }, 0, "vms = 0";
diag $@ if $@;
is eval { $shell->is_bourne  }, 0, "bourne = 0";
diag $@ if $@;
is eval { $shell->is_tc      }, 0, "tc = 0";
diag $@ if $@;
is eval { $shell->is_power   }, 0, "power = 0";
diag $@ if $@;
is eval { $shell->is_z       }, 0, "z = 0";
diag $@ if $@;

is $shell->default_location,  undef, 'default_location = undef';
