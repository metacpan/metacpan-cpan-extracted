#!/usr/bin/perl -w

use strict;

use Test::Unit::Debug qw(debug_pkgs);
use Test::Unit::HarnessUnit;

#debug_pkgs(qw{Test::Unit::Result});

use lib 't/lib', 'lib';

my $testrunner = Test::Unit::HarnessUnit->new();
$testrunner->start("Test::C2FIT::test::AllTests");
