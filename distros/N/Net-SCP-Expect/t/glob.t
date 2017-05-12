######################################################
# Make sure file globbing does not cause a core dump
######################################################
use strict;
use Test::More qw/no_plan/;

BEGIN{ use_ok('Net::SCP::Expect') }

my @files = glob("*.t");
