#!/usr/bin/env perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use warnings;
use strict;

use File::Spec;
use Test::Most;
use English qw(-no_match_vars);


eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
  plan( skip_all
        => 'Test::Perl::Critic not found'  );
}

my $rcfile = File::Spec->catfile( 'xt', 'author', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile
                          , -exclude =>  [
                              'ProhibitStringyEval' 
                            , 'TestingAndDebugging::RequireUseStrict'
                            , 'TestingAndDebugging::RequireUseWarnings' ] );

all_critic_ok( 'lib' );
done_testing;
