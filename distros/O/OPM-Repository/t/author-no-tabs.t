
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/OPM/Repository.pm',
    'lib/OPM/Repository/Source.pm',
    't/data/otrs.xml',
    't/list/otrs.xml',
    't/minimum_maximum/otrs.xml',
    't/repository.t',
    't/repository_dup.t',
    't/repository_list.t',
    't/repository_list_details.t',
    't/source.t',
    't/source_does_not_exist.t',
    't/source_invalid_xml.t',
    't/source_list.t',
    't/source_list_details.t',
    't/source_min_max.t'
);

notabs_ok($_) foreach @files;
done_testing;
