#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

our $VERSION = '1.000';

# Test that our declared minimum Perl version matches our syntax
BEGIN {
    ## no critic(RequireLocalizedPunctuationVars)
	$|  = 1;
	$^W = 1;
}

use Perl::MinimumVersion 1.20;
use Test::MinimumVersion 0.008;
use Test::More;

all_minimum_version_from_metayml_ok();

exit;
