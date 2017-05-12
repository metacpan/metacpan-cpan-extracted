#!/usr/bin/perl

use Test::More tests => 4;
BEGIN { use_ok('Sys::Protect') };

my $rv = eval { syscall(1, 123); };
my $err = $@;
is($rv, undef, "syscall failed");
like($err, qr/Opcode denied/);

$rv = eval { exit(2); };
ok(!defined($rv));
