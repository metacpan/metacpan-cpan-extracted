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

my $filenames = ['lib/SQL/Statement/Function/ByName/DATE.pm','lib/SQL/Statement/Function/ByName/DAY.pm','lib/SQL/Statement/Function/ByName/DAYOFMONTH.pm','lib/SQL/Statement/Function/ByName/DAYOFYEAR.pm','lib/SQL/Statement/Function/ByName/HOUR.pm','lib/SQL/Statement/Function/ByName/ISO_YEARWEEK.pm','lib/SQL/Statement/Function/ByName/MINUTE.pm','lib/SQL/Statement/Function/ByName/MONTH.pm','lib/SQL/Statement/Function/ByName/SECOND.pm','lib/SQL/Statement/Function/ByName/TIME.pm','lib/SQL/Statement/Function/ByName/WEEKDAY.pm','lib/SQL/Statement/Function/ByName/WEEKOFYEAR.pm','lib/SQL/Statement/Function/ByName/YEAR.pm','lib/SQL/Statement/Functions/Date.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
