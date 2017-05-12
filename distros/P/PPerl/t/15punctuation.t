#!perl -w
use strict;
use Test;

my @expect = `$^X t/punctuation.plx`;
plan tests => 4 * @expect;


for my $perl ('./pperl -Iblib/lib -Iblib/arch --prefork 1', './pperl', './pperl', './pperl') {
    print "# $perl\n";
    my @got = `$perl t/punctuation.plx`;
    for (my $i = 0; $i < @expect; $i++) {
        ok($got[$i], $expect[$i]);
    }
}
`./pperl -k t/punctuation.plx`;
