use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/graph-stepford.pl',
    'lib/Stepford/Grapher.pm',
    'lib/Stepford/Grapher/CommandLine.pm',
    'lib/Stepford/Grapher/Renderer/Graphviz.pm',
    'lib/Stepford/Grapher/Renderer/Json.pm',
    'lib/Stepford/Grapher/Role/Renderer.pm',
    'lib/Stepford/Grapher/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01basic.t',
    't/02gv.t',
    't/lib/MockStep.pm',
    't/lib/Step/Atmosphere.pm',
    't/lib/Step/Bob.pm',
    't/lib/Step/Brazil.pm',
    't/lib/Step/CotedAzur.pm',
    't/lib/Step/Hug.pm',
    't/lib/Step/Love.pm',
    't/lib/Step/Partner.pm',
    't/lib/Step/Sol.pm',
    't/lib/Step/Supermarket.pm',
    't/lib/Step/Villain.pm'
);

notabs_ok($_) foreach @files;
done_testing;
