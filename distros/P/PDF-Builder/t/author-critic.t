#!/usr/bin/perl
use strict;
use warnings;

# Windows: SET AUTHOR_TESTING=1
# this test is a subset of tools/1_pc.pl
BEGIN {
  unless ($ENV{'AUTHOR_TESTING'}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

use Test::Perl::Critic (-profile => "..\.perlcriticrc") x!! -e "..\.perlcriticrc";
all_critic_ok();
