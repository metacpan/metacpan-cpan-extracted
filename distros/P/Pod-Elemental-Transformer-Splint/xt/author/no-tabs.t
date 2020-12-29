use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Pod/Elemental/Transformer/Splint.pm',
    'lib/Pod/Elemental/Transformer/Splint/AttributeRenderer.pm',
    'lib/Pod/Elemental/Transformer/Splint/AttributeRenderer/HtmlDefault.pm',
    'lib/Pod/Elemental/Transformer/Splint/MethodRenderer.pm',
    'lib/Pod/Elemental/Transformer/Splint/MethodRenderer/HtmlDefault.pm',
    'lib/Pod/Elemental/Transformer/Splint/Util.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-attribute-documented.t',
    't/03-method-documented.t',
    't/corpus/lib/SplintTestAttributes.pm',
    't/corpus/lib/SplintTestMethods.pm'
);

notabs_ok($_) foreach @files;
done_testing;
