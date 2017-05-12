#!perl
use strict;
use Test;
plan tests => 3;

#check fork-on-execcy stuff

my $expect = `cat t/cat.plx`;
ok($expect);
ok(`$^X t/invoke_cat.plx`, $expect);
ok(`./pperl -Iblib/lib -Iblib/arch t/invoke_cat.plx`, $expect);
`./pperl -k t/invoke_cat.plx`;
