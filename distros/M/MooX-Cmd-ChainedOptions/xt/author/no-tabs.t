use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooX/Cmd/ChainedOptions.pm',
    'lib/MooX/Cmd/ChainedOptions/Base.pm',
    'lib/MooX/Cmd/ChainedOptions/Role.pm',
    't/00-compile.t',
    't/00-report-prereqs.t',
    't/chained.t',
    't/croak.t',
    't/lib/MyTest/Base.pm',
    't/lib/MyTest/Default.pm',
    't/lib/MyTest/Default/Cmd/first.pm',
    't/lib/MyTest/Default/Cmd/first/Cmd/second.pm',
    't/lib/MyTest/X/first.pm',
    't/lib/MyTest/XX/second.pm'
);

notabs_ok($_) foreach @files;
done_testing;
