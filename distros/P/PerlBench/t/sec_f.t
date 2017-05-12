#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 20;

use PerlBench::Utils qw(sec_f);

ok(sec_f(60*60), "1.0 h");
ok(sec_f(60), "1.0 min");
ok(sec_f(1), "1.0 s");
ok(sec_f(15), "15 s");
ok(sec_f(0.1), "100 ms");
ok(sec_f(0.01), "10 ms");
ok(sec_f(0.001), "1.0 ms");
ok(sec_f(0.0001), "100 \xB5s");
ok(sec_f(0.00001), "10 \xB5s");
ok(sec_f(0.000001), "1.0 \xB5s");
ok(sec_f(0.0000001), "100 ns");
ok(sec_f(0.00000001), "10 ns");
ok(sec_f(0.000000001), "1.0 ns");

ok(sec_f(1, 1), "1.0 s \xB11.0");
ok(sec_f(1, 0.1), "1.00 s \xB10.10");
ok(sec_f(1, 0.0026), "1.000 s \xB10.003");
ok(sec_f(1.5e-7, 5.6e-9), "150 ns \xB16");

ok(sec_f(60*60, undef, "s"), "3600 s");
ok(sec_f(0.01, undef, "s"), "0.010 s");
ok(sec_f(0.0001, undef, "ms"), "0.10 ms");
