use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Pod/Weaver/Plugin/StopWords.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/eg/in.pod',
    't/eg/out.pod',
    't/eg/weaver.ini',
    't/eg2/weaver.ini',
    't/ini-config.t',
    't/ini-leftovers/in.pod',
    't/ini-leftovers/out.pod',
    't/ini-leftovers/weaver.ini',
    't/ini-lots/in.pod',
    't/ini-lots/out.pod',
    't/ini-lots/weaver.ini',
    't/ini-nogather/in.pod',
    't/ini-nogather/out.pod',
    't/ini-nogather/weaver.ini',
    't/ini-nowrap/in.pod',
    't/ini-nowrap/out.pod',
    't/ini-nowrap/weaver.ini',
    't/lib/TestPW.pm',
    't/lib/TestPWEncoding.pm'
);

notabs_ok($_) foreach @files;
done_testing;
