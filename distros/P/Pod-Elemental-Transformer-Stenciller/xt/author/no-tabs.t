use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Pod/Elemental/Transformer/Stenciller.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/corpus/lib/Test/For/StencillerFromUnparsedText.pm',
    't/corpus/source/1-test.stencil'
);

notabs_ok($_) foreach @files;
done_testing;
