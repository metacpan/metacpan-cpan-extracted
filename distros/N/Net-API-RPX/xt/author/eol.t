use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/API/RPX.pm',
    'lib/Net/API/RPX/Exception.pm',
    'lib/Net/API/RPX/Exception/Network.pm',
    'lib/Net/API/RPX/Exception/Service.pm',
    'lib/Net/API/RPX/Exception/Usage.pm',
    't/00-compile/lib_Net_API_RPX_Exception_Network_pm.t',
    't/00-compile/lib_Net_API_RPX_Exception_Service_pm.t',
    't/00-compile/lib_Net_API_RPX_Exception_Usage_pm.t',
    't/00-compile/lib_Net_API_RPX_Exception_pm.t',
    't/00-compile/lib_Net_API_RPX_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-exceptions.t',
    't/mock/LWP/UserAgent.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
