use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Plack/Middleware/OIDC.pm',
    'lib/Plack/Middleware/OIDC/Logger.pm',
    'lib/Plack/Middleware/OIDC/Redirect.pm',
    't/00-compile.t',
    't/auth-code-flow.t',
    't/configuration-and-routing.t',
    't/flash.t',
    't/lib/TestOIDC/Logger.pm',
    't/logger.t',
    't/multi-provider-and-errors.t',
    't/redirect-exception.t',
    't/redirect-halts.t',
    't/request-data.t',
    't/session-and-stash.t'
);

notabs_ok($_) foreach @files;
done_testing;
