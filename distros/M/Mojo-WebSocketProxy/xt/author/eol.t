use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Mojo/WebSocketProxy.pm',
    'lib/Mojo/WebSocketProxy/Backend.pm',
    'lib/Mojo/WebSocketProxy/Backend/JSONRPC.pm',
    'lib/Mojo/WebSocketProxy/Backend/JSONRPC.pod',
    'lib/Mojo/WebSocketProxy/Config.pm',
    'lib/Mojo/WebSocketProxy/Config.pod',
    'lib/Mojo/WebSocketProxy/Dispatcher.pm',
    'lib/Mojo/WebSocketProxy/Dispatcher.pod',
    'lib/Mojo/WebSocketProxy/Parser.pm',
    'lib/Mojolicious/Plugin/WebSocketProxy.pm',
    'lib/Mojolicious/Plugin/WebSocketProxy.pod',
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
    't/23-binary-frame.t',
    't/24-multiple-backends.t',
    't/27-before_shutdown_hook.t',
    't/28-rpc_failure_cb.t',
    't/SampleRPC.pm',
    't/TestWSP.pm',
    't/rc/perlcriticrc',
    't/rc/perltidyrc',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
