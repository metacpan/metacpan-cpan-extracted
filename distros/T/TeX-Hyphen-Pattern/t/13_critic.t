#!/usr/bin/env perl -w    # -*- cperl -*-
use strict;
use warnings;
use 5.014000;
use utf8;

use File::Spec;
use Test::More;

our $VERSION = v1.1.1;

if ( not $ENV{'AUTHOR_TESTING'} ) {
    my $msg =
q{Author test. Set the environment variable AUTHOR_TESTING to enable this test.};
    plan 'skip_all' => $msg;
}

eval {
    require Test::Perl::Critic;
    1;
} or do {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan 'skip_all' => $msg;
};

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( '-profile' => $rcfile );
Test::Perl::Critic::all_critic_ok(qw(blib t));
