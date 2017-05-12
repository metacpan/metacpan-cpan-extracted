use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/Travis/API.pm',
    'lib/Net/Travis/API/Auth/GitHub.pm',
    'lib/Net/Travis/API/Role/Client.pm',
    'lib/Net/Travis/API/UA.pm',
    'lib/Net/Travis/API/UA/Response.pm',
    't/00-compile/lib_Net_Travis_API_Auth_GitHub_pm.t',
    't/00-compile/lib_Net_Travis_API_Role_Client_pm.t',
    't/00-compile/lib_Net_Travis_API_UA_Response_pm.t',
    't/00-compile/lib_Net_Travis_API_UA_pm.t',
    't/00-compile/lib_Net_Travis_API_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
