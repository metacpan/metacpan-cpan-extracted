#!perl

use strict;
use warnings;
use Test::More 0.98;

use Regexp::Common qw/json/;

subtest number => sub {
    my $pat = $RE{json}{number};
    ok(!(q()     =~ $pat));
    ok( (q(1)    =~ $pat));
    ok( (q(1.2)  =~ $pat));
    ok( (q(-3.4) =~ $pat));
    ok(!(q("")   =~ $pat));
    ok(!(q([])   =~ $pat));
    ok(!(q({})   =~ $pat));
    ok(!(q(null) =~ $pat));
};

# XXX string
# XXX array
# XXX object
# XXX value

done_testing;
