use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/FTP/Path/Iter.pm',
    'lib/Net/FTP/Path/Iter/Dir.pm',
    'lib/Net/FTP/Path/Iter/Entry.pm',
    'lib/Net/FTP/Path/Iter/File.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/ftp.t'
);

notabs_ok($_) foreach @files;
done_testing;
