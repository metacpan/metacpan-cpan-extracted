use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/POE/Component/Supervisor.pm',
    'lib/POE/Component/Supervisor/Handle.pm',
    'lib/POE/Component/Supervisor/Handle/Interface.pm',
    'lib/POE/Component/Supervisor/Handle/Proc.pm',
    'lib/POE/Component/Supervisor/Handle/Session.pm',
    'lib/POE/Component/Supervisor/Interface.pm',
    'lib/POE/Component/Supervisor/LogDispatch.pm',
    'lib/POE/Component/Supervisor/Supervised.pm',
    'lib/POE/Component/Supervisor/Supervised/Interface.pm',
    'lib/POE/Component/Supervisor/Supervised/Proc.pm',
    'lib/POE/Component/Supervisor/Supervised/Session.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_load.t',
    't/02_basic.t',
    't/03_stubborn.t',
    't/04_global_restart_policy.t',
    't/05_sessions.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
