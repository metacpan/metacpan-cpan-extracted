#!/usr/bin/env perl
use lib './lib';
use Proc::Forkmap;
use IPC::Shareable;

$Proc::Forkmap::MAX_PROCS = 4;

my %opts = (create => 1);
tie @sv, 'IPC::Shareable', 'data', { %opts };

sub foo {
  my $n = shift;
  sleep $n;
  push @sv, "slept $n seconds\n";
}

my @x = (1, 4, 2);

forkmap { foo($_) } @x;
print $_ for @sv;
IPC::Shareable->clean_up_all;
