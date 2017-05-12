use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Pod/Weaver/Section/Badges.pm',
    'lib/Pod/Weaver/Section/Badges/PluginSearcher.pm',
    'lib/Pod/Weaver/Section/Badges/Utils.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-utils.t',
    't/02-badges.t',
    't/corpus/01/dist.ini',
    't/corpus/01/lib/Badge/Depot/Plugin/Anothertestplugin.pm',
    't/corpus/01/lib/Badge/Depot/Plugin/Atestpluginwedontwant.pm',
    't/corpus/01/lib/Badge/Depot/Plugin/Thisisatestplugin.pm',
    't/corpus/01/lib/TesterFor/Badges.pm',
    't/corpus/01/weaver.ini'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
