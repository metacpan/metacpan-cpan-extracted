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

my $filenames = ['lib/Tables/DBI.pm','lib/Tables/Sample/DeNiro.pm','lib/Tables/Test/Angka.pm','lib/Tables/Test/Dynamic.pm','lib/TablesRole/Source/CSVDATA.pm','lib/TablesRole/Source/DBI.pm','lib/TablesRole/Source/Iterator.pm','lib/TablesRole/Util/Basic.pm','lib/TablesRole/Util/CSV.pm','lib/TablesRole/Util/Random.pm','lib/TablesRoles/Standard.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
