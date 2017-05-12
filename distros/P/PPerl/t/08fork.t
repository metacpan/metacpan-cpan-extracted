#!perl -w
use strict;
use Test;
BEGIN { plan tests => 10 };

my $out = `$^X t/fork.plx`;

for (1..10) {
    ok(`./pperl t/fork.plx`, $out);
}

`./pperl -k t/fork.plx`;
