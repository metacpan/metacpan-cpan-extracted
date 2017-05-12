#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More;

## no critic(ProhibitStringyEval)

our $VERSION = '1.000';

my $return = eval 'use Test::Pod 1.00; 1;';
if (! $return)
{
    plan skip_all => 'Test::Pod 1.00 required for testing POD';
    exit 0;
}

all_pod_files_ok();

exit 0;
