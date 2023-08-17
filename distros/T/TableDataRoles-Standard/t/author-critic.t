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

my $filenames = ['lib/TableData/AOA.pm','lib/TableData/AOH.pm','lib/TableData/DBI.pm','lib/TableData/Munge/Concat.pm','lib/TableData/Munge/Filter.pm','lib/TableData/Munge/MungeColumns.pm','lib/TableData/Munge/Reverse.pm','lib/TableData/Sample/DeNiro.pm','lib/TableData/Test/Source/AOA.pm','lib/TableData/Test/Source/AOH.pm','lib/TableData/Test/Source/CSVInDATA.pm','lib/TableData/Test/Source/CSVInFile.pm','lib/TableData/Test/Source/CSVInFile/Select.pm','lib/TableData/Test/Source/CSVInFiles.pm','lib/TableData/Test/Source/DBI.pm','lib/TableData/Test/Source/Iterator.pm','lib/TableDataRole/Munge/Concat.pm','lib/TableDataRole/Munge/Filter.pm','lib/TableDataRole/Munge/MungeColumns.pm','lib/TableDataRole/Munge/Reverse.pm','lib/TableDataRole/Source/AOA.pm','lib/TableDataRole/Source/AOH.pm','lib/TableDataRole/Source/CSVInDATA.pm','lib/TableDataRole/Source/CSVInFile.pm','lib/TableDataRole/Source/CSVInFiles.pm','lib/TableDataRole/Source/DBI.pm','lib/TableDataRole/Source/Iterator.pm','lib/TableDataRole/Util/CSV.pm','lib/TableDataRoles/Standard.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
