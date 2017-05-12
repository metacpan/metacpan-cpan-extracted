#!perl -w
use strict;
use Test;
BEGIN { plan tests => 8 };

my $out;

$out = `$^X t/spammy.plx 2>&1`;
ok($? >> 8, 0);
ok($out, "");

$out = `$^X t/spammy.plx foo 2>&1`;
ok($? >> 8, 70);
ok($out, "foo at t/spammy.plx line 7.\n");

$out = `./pperl -Iblib/lib -Iblib/arch t/spammy.plx 2>&1`;
ok($? >> 8, 0);
ok($out, "");

$out = `./pperl t/spammy.plx foo 2>&1`;
ok($? >> 8, 70);
ok($out, "foo at t/spammy.plx line 7.\n");

`./pperl -k t/spammy.plx`
