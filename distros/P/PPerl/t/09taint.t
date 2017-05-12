#!perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

my $err = `t/taint_pperl.plx arg 2>&1`;
ok($err, "Insecure dependency in open while running with -T switch at t/taint_pperl.plx line 4.\n");

`./pperl -k t/taint_pperl.plx`;
