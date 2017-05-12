use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/reply',
    'lib/Reply.pm',
    'lib/Reply/App.pm',
    'lib/Reply/Config.pm',
    'lib/Reply/Plugin.pm',
    'lib/Reply/Plugin/AutoRefresh.pm',
    'lib/Reply/Plugin/Autocomplete/Commands.pm',
    'lib/Reply/Plugin/Autocomplete/Functions.pm',
    'lib/Reply/Plugin/Autocomplete/Globals.pm',
    'lib/Reply/Plugin/Autocomplete/Keywords.pm',
    'lib/Reply/Plugin/Autocomplete/Lexicals.pm',
    'lib/Reply/Plugin/Autocomplete/Methods.pm',
    'lib/Reply/Plugin/Autocomplete/Packages.pm',
    'lib/Reply/Plugin/CollapseStack.pm',
    'lib/Reply/Plugin/Colors.pm',
    'lib/Reply/Plugin/DataDump.pm',
    'lib/Reply/Plugin/DataDumper.pm',
    'lib/Reply/Plugin/DataPrinter.pm',
    'lib/Reply/Plugin/Defaults.pm',
    'lib/Reply/Plugin/Editor.pm',
    'lib/Reply/Plugin/FancyPrompt.pm',
    'lib/Reply/Plugin/Hints.pm',
    'lib/Reply/Plugin/Interrupt.pm',
    'lib/Reply/Plugin/LexicalPersistence.pm',
    'lib/Reply/Plugin/LoadClass.pm',
    'lib/Reply/Plugin/Nopaste.pm',
    'lib/Reply/Plugin/Packages.pm',
    'lib/Reply/Plugin/Pager.pm',
    'lib/Reply/Plugin/ReadLine.pm',
    'lib/Reply/Plugin/ResultCache.pm',
    'lib/Reply/Plugin/Timer.pm',
    'lib/Reply/Util.pm',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;
