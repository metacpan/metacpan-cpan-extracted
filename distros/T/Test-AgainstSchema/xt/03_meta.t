#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

our $VERSION = '1.000';

# Test that our META.yml file matches the specification
BEGIN {
    ## no critic(RequireLocalizedPunctuationVars)
	$|  = 1;
	$^W = 1;
}

use Test::CPAN::Meta 0.12;
use Test::More;

if (! -f 'META.yml')
{
    plan skip_all => 'No META.yml file found';
    exit 0;
}

meta_yaml_ok();

exit 0;
