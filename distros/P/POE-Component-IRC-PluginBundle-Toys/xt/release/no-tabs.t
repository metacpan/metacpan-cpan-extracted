use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/POE/Component/IRC/Plugin/AlarmClock.pm',
    'lib/POE/Component/IRC/Plugin/CoinFlip.pm',
    'lib/POE/Component/IRC/Plugin/Fortune.pm',
    'lib/POE/Component/IRC/Plugin/Magic8Ball.pm',
    'lib/POE/Component/IRC/Plugin/SigFail.pm',
    'lib/POE/Component/IRC/Plugin/Thanks.pm',
    'lib/POE/Component/IRC/Plugin/YouAreDoingItWrong.pm',
    'lib/POE/Component/IRC/PluginBundle/Toys.pm'
);

notabs_ok($_) foreach @files;
done_testing;
