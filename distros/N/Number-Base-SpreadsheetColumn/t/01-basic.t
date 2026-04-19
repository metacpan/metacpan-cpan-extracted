#!perl -T

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Number::Base::SpreadsheetColumn qw(to_scbase from_scbase);

subtest "from_scbase" => sub {
    is(from_scbase("A"), 0);
    is(from_scbase("z"), 25);
    is(from_scbase("AA"), 26);
    is(from_scbase("AZ"), 51);
    is(from_scbase("BA"), 52);
    is(from_scbase("ZZ"), 701);
    is(from_scbase("AAA"), 702);
};

subtest "to_scbase" => sub {
    is(to_scbase(0), "A");
    is(to_scbase(25), "Z");
    is(to_scbase(26), "AA");
    is(to_scbase(51), "AZ");
    is(to_scbase(52), "BA");
    is(to_scbase(701), "ZZ");
    is(to_scbase(702), "AAA");
};

DONE_TESTING:
done_testing();
