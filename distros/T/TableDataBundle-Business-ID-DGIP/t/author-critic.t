#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/TableData/Business/ID/DGIP/Class.pm','lib/TableData/Business/ID/DGIP/Class/1.pm','lib/TableData/Business/ID/DGIP/Class/10.pm','lib/TableData/Business/ID/DGIP/Class/11.pm','lib/TableData/Business/ID/DGIP/Class/12.pm','lib/TableData/Business/ID/DGIP/Class/13.pm','lib/TableData/Business/ID/DGIP/Class/14.pm','lib/TableData/Business/ID/DGIP/Class/15.pm','lib/TableData/Business/ID/DGIP/Class/16.pm','lib/TableData/Business/ID/DGIP/Class/17.pm','lib/TableData/Business/ID/DGIP/Class/18.pm','lib/TableData/Business/ID/DGIP/Class/19.pm','lib/TableData/Business/ID/DGIP/Class/2.pm','lib/TableData/Business/ID/DGIP/Class/20.pm','lib/TableData/Business/ID/DGIP/Class/21.pm','lib/TableData/Business/ID/DGIP/Class/22.pm','lib/TableData/Business/ID/DGIP/Class/23.pm','lib/TableData/Business/ID/DGIP/Class/24.pm','lib/TableData/Business/ID/DGIP/Class/25.pm','lib/TableData/Business/ID/DGIP/Class/26.pm','lib/TableData/Business/ID/DGIP/Class/27.pm','lib/TableData/Business/ID/DGIP/Class/28.pm','lib/TableData/Business/ID/DGIP/Class/29.pm','lib/TableData/Business/ID/DGIP/Class/3.pm','lib/TableData/Business/ID/DGIP/Class/30.pm','lib/TableData/Business/ID/DGIP/Class/31.pm','lib/TableData/Business/ID/DGIP/Class/32.pm','lib/TableData/Business/ID/DGIP/Class/33.pm','lib/TableData/Business/ID/DGIP/Class/34.pm','lib/TableData/Business/ID/DGIP/Class/35.pm','lib/TableData/Business/ID/DGIP/Class/36.pm','lib/TableData/Business/ID/DGIP/Class/37.pm','lib/TableData/Business/ID/DGIP/Class/38.pm','lib/TableData/Business/ID/DGIP/Class/39.pm','lib/TableData/Business/ID/DGIP/Class/4.pm','lib/TableData/Business/ID/DGIP/Class/40.pm','lib/TableData/Business/ID/DGIP/Class/41.pm','lib/TableData/Business/ID/DGIP/Class/42.pm','lib/TableData/Business/ID/DGIP/Class/43.pm','lib/TableData/Business/ID/DGIP/Class/44.pm','lib/TableData/Business/ID/DGIP/Class/45.pm','lib/TableData/Business/ID/DGIP/Class/5.pm','lib/TableData/Business/ID/DGIP/Class/6.pm','lib/TableData/Business/ID/DGIP/Class/7.pm','lib/TableData/Business/ID/DGIP/Class/8.pm','lib/TableData/Business/ID/DGIP/Class/9.pm','lib/TableDataBundle/Business/ID/DGIP.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
