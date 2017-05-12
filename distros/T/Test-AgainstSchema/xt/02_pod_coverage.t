#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More;

## no critic(ProhibitStringyEval)

our $VERSION = '1.000';

my @MODULES = qw(Test::AgainstSchema Test::AgainstSchema::XML);

my $return = eval 'use Test::Pod::Coverage 1.00; 1;';
if (! $return)
{
    plan skip_all =>
        'Test::Pod::Coverage 1.00 required for testing POD coverage';
    exit 0;
}

plan tests => scalar @MODULES;

for (@MODULES)
{
    pod_coverage_ok($_);
}

exit 0;
