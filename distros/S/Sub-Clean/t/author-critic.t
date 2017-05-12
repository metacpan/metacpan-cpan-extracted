#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;

use Test::More;
use File::Spec;

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

my $rcfile = '{{ $profile }}';
Test::Perl::Critic->import( -profile => $rcfile );

eval { require Test::Perl::Critic; }
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok();
