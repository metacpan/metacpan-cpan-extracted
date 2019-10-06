#!perl

# This script includes a Perl implementation of some of the tests from
# ast_tester/testtime.f.

use strict;

use Test::More tests => 4;
use Test::Number::Delta;

require_ok('Starlink::AST');

do {
    my $tf = new Starlink::AST::TimeFrame('');
    isa_ok($tf, 'Starlink::AST::TimeFrame');

    my $current = $tf->CurrentTime();
    like($current, qr/^[-0-9.]+$/, 'Current time looks like a number');
};

do {
    my $tm = new Starlink::AST::TimeMap('');
    isa_ok($tm, 'Starlink::AST::TimeMap');

    $tm->TimeAdd('UTCTOUT', [37.0]);
};
