#!perl
use Mojo::Base -strict;
use Mojo::Log;
use Test::More;

delete $ENV{MOJO_LOG_COLORS};

my $log = Mojo::Log->with_roles('+Color')->new(handle => \*STDOUT);
ok $log->does('Mojo::Log::Role::Color'), 'role applied';

my $has_terminal = -t STDOUT     ? 1 : 0;
my $detected     = $log->colored ? 1 : 0;
is $detected, $has_terminal, "colored $detected/$has_terminal";

if (open my $FH, '>', '/dev/tty') {
  my $tty = Mojo::Log->with_roles('+Color')->new(handle => $FH);
  ok $tty->colored, 'dev-tty has colors';
}

if (open my $FH, '>', '/dev/null') {
  my $null = Mojo::Log->with_roles('+Color')->new(handle => $FH);
  ok !$null->colored, 'dev-null has no colors';
}

done_testing;
