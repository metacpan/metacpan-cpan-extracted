use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/POE/Component/IRC/Plugin/AlarmClock.pm',
    'lib/POE/Component/IRC/Plugin/CoinFlip.pm',
    'lib/POE/Component/IRC/Plugin/Fortune.pm',
    'lib/POE/Component/IRC/Plugin/Magic8Ball.pm',
    'lib/POE/Component/IRC/Plugin/SigFail.pm',
    'lib/POE/Component/IRC/Plugin/Thanks.pm',
    'lib/POE/Component/IRC/Plugin/YouAreDoingItWrong.pm',
    'lib/POE/Component/IRC/PluginBundle/Toys.pm',
    't/00-compile.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
