#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

our $VERSION = '1.000';

# Test that the module passes perlcritic
BEGIN {
    ## no critic(RequireLocalizedPunctuationVars)
	$|  = 1;
	$^W = 1;
}

use Perl::Critic 1.098;
use Test::Perl::Critic 1.01;
use Test::More;

all_critic_ok();

exit;
