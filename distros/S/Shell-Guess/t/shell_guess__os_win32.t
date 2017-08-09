use strict;
use warnings;
use Test::More;

plan skip_all => 'windows only test' unless $^O eq 'MSWin32';
plan tests => 4;

my $fake_is_win95 = 0;

eval q{
  package Win32;
  
  $INC{'Win32.pm'} = __FILE__;
  
  no warnings;
  sub IsWin95 { $fake_is_win95 ? 1 : 0 }
  sub IsWinNT { $fake_is_win95 ? 0 : 1 }
};
die $@ if $@;

eval q{ use Shell::Guess };
die $@ if $@;

do {
  local $ENV{ComSpec} = 'C:\\Windows\\system32\\cmd.exe';
  is eval { Shell::Guess->running_shell->is_cmd }, 1, "running cmd.exe";
  diag $@ if $@;
};

do {
  local $ENV{ComSpec} = 'C:\\Windows\\system32\\command.exe';
  is eval { Shell::Guess->running_shell->is_command }, 1, "running command.com";
  diag $@ if $@;
};

$fake_is_win95 = 1;
is eval { Shell::Guess->login_shell->is_command }, 1, 'login command.com';
diag $@ if $@;

$fake_is_win95 = 0;
is eval { Shell::Guess->login_shell->is_cmd }, 1, 'login cmd.exe';
diag $@ if $@;