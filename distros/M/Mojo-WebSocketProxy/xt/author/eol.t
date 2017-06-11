use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Mojo/WebSocketProxy.pm',
    'lib/Mojo/WebSocketProxy/CallingEngine.pm',
    'lib/Mojo/WebSocketProxy/Config.pm',
    'lib/Mojo/WebSocketProxy/Dispatcher.pm',
    'lib/Mojo/WebSocketProxy/Parser.pm',
    'lib/Mojolicious/Plugin/WebSocketProxy.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/05_basic.t',
    't/10-before_forward.t',
    't/11-timeout.t',
    't/12-before_send_api_response.t',
    't/13-action-not-found.t',
    't/14-bad-request.t',
    't/15-simple-success.t',
    't/16-auth-error-sample.t',
    't/17-instead_of_forward.t',
    't/18-per-action_before-forward.t',
    't/19-rpc_response_cb.t',
    't/20-after_got_rpc_response.t',
    't/21-mojo-stash.t',
    't/22-override-response.t',
    't/SampleRPC.pm',
    't/TestWSP.pm',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
