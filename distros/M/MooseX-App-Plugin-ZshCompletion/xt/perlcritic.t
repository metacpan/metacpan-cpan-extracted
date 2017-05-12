#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

#eval " use Test::Perl::Critic (-severity => 4, -exclude => ['ProhibitSubroutinePrototypes','ProhibitMultiplePackages'] ); ";

eval " use Test::Perl::Critic (-severity => 4, -exclude => [] ); ";
if ( $@ ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 'xt', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
Test::Perl::Critic::all_critic_ok();
