use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/ttml',
    'lib/Template/Preprocessor/TTML.pm',
    'lib/Template/Preprocessor/TTML/Base.pm',
    'lib/Template/Preprocessor/TTML/CmdLineProc.pm',
    't/00-compile.t',
    't/01-cmdline-proc.t',
    't/01-cmdline-proc.t~',
    't/02-main.t',
    't/02-main.t~',
    't/data/include/dir1/header.tt2',
    't/data/include/dir2/inc2.tt2',
    't/data/input/explicit-includes.ttml',
    't/data/input/hello.ttml',
    't/data/input/implicit-includes.ttml',
    't/data/input/invalid.ttml',
    't/data/input/simple.ttml',
    't/data/input/two-params.ttml'
);

notabs_ok($_) foreach @files;
done_testing;
