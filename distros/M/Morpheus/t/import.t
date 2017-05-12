#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use lib 'lib';

use Morpheus -defaults => {
    "import-test" => {
        foo => { x => 5 },
        bar => {
            x => { a => 3, b => 4 },
        },
    }
};

is(
    scalar(eval(q#package X1; use Morpheus "import-test/foo" => [qw($x)]; $x#)),
    5,
    "import scalar"
);

is_deeply(
    scalar(eval(q#package X2; use Morpheus "import-test/bar" => [qw($x)]; $x#)),
    { a => 3, b => 4 },
    "import subtree"
);

is(
    scalar(eval(q#package X3; use Morpheus "import-test/foo" => [ x => qw($y) ]; $y#)),
    5,
    "import with rename"
);

is(
    scalar(eval(q#package X4; use Morpheus "import-test" => [ foo => [ qw($x) ] ]; $x#)),
    5,
    "deeply nested import parameters"
);

is(
    scalar(eval(q#package X4; use Morpheus "import-test/bar/x" => [ qw($a $b) ]; "$a $b"#)),
    "3 4",
    "import two vars from the same ns"
);

is(
    scalar(eval(q#package X4; my $y; use Morpheus "import-test/bar/x/a" => \$y; $y#)),
    3,
    "binding to 'my'"
);
