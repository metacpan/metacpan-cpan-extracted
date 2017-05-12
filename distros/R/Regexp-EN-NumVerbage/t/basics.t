#!perl

use 5.010;
use strict;
use warnings;
use Test::More;

use Regexp::EN::NumVerbage qw($RE);

my %test_pat = (
    "six" => 1,
    "negative" => 0,
    "point" => 0,
    "seventy-seven" => 1, # dash after tens
    "minus zero point seven" => 1,
    "7.5 millions" => 1, # plural
    "two million sixty seven thousand" => 1, # multiple terms
    "two hundred billions" => 1, # multiple multipliers
);

for (sort keys %test_pat) {
    my $match = $_ =~ /\b$RE\b/;
    if ($test_pat{$_}) {
        ok($match, "'$_' matches");
    } else {
        ok(!$match, "'$_' doesn't match");
    }
}

done_testing();
