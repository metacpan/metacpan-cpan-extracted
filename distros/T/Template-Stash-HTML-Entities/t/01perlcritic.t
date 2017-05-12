#!/usr/bin/env perl
#
# $Id: 01perlcritic.t,v 1.2 2007/05/04 07:33:33 hironori.yoshida Exp $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.3.1');

use blib;
use English qw(-no_match_vars);
use Test::More;

if ( $ENV{TEST_CRITIC} || $ENV{TEST_ALL} || !$ENV{HARNESS_ACTIVE} ) {
    eval {
        my $format = "%l: %m (severity %s)\n";
        if ( $ENV{TEST_VERBOSE} ) {
            $format .= "%p\n%d\n";
        }
        require Test::Perl::Critic;
        Test::Perl::Critic->import( -format => $format, -severity => 1 );
    };
    if ($EVAL_ERROR) {
        plan skip_all =>
          'Test::Perl::Critic required for testing PBP compliance';
    }
}
else {
    plan skip_all => 'set TEST_CRITIC for testing PBP compliance';
}

all_critic_ok();
