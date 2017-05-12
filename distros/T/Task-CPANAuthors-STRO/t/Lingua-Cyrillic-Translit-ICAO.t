#!/usr/bin/env perl -w

# $Id: Lingua-Cyrillic-Translit-ICAO.t 11 2009-11-20 13:39:02Z stro $

use strict;
use warnings;

my @modules = qw/
    Lingua::Cyrillic::Translit::ICAO
/;

## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
eval 'use Test::More';
if ($@) {
## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
    eval 'use Test; plan tests => ' . scalar @modules;
    skip('Test::More is required for testing "require"');
} else {
    Test::More::plan('tests' => scalar @modules);
    require Test::More;
    require_ok($_) foreach (@modules);
}
