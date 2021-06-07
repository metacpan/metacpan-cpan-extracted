#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/TableData/AOH.pm','lib/TableData/DBI.pm','lib/TableData/Sample/DeNiro.pm','lib/TableData/Test/Source/AOH.pm','lib/TableData/Test/Source/CSVInDATA.pm','lib/TableData/Test/Source/DBI.pm','lib/TableData/Test/Source/Iterator.pm','lib/TableDataRole/Source/AOH.pm','lib/TableDataRole/Source/CSVInDATA.pm','lib/TableDataRole/Source/DBI.pm','lib/TableDataRole/Source/Iterator.pm','lib/TableDataRole/Util/CSV.pm','lib/TableDataRoles/Standard.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
