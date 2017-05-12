#!perl -w
use strict;
use Test;
BEGIN { plan tests => 8 }

my $expect = `$^X t/data.plx`;
ok($expect);

for my $perl ( $^X, './pperl -Iblib/lib -Iblib/arch --prefork 2',
               ( './pperl' ) x 5 ) {
    ok(`$perl t/data.plx`, $expect);
}

`./pperl -k t/data.plx`;
