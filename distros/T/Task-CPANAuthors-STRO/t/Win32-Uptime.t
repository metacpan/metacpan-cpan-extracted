#!/usr/bin/env perl -w

# $Id: Win32-Uptime.t 11 2009-11-20 13:39:02Z stro $

use strict;
use warnings;

my @modules = qw/
    Win32::Uptime
/;

if ($^O ne 'MSWin32') {
    eval ' use Test; plan tests => ' . scalar @modules;
    skip('Win32 environment is needed for Win32::Uptime');
} else {
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
}