#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Test;
use Punk::Plugin::MCP ();

my $n = 0;
sub app {
    my ($decl, $opts) = @_;
    my $pkg = 'T38::A' . ++$n;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    eval qq{
        package ${pkg}::Controller::T; sub a { 'a' }
        package $pkg;
        use Punk;
        use Punk::Plugin::MCP;
        $decl;
        plugin 'MCP' => { session => 0, ${\ ($opts // '')} };
        mcp tool => a => 'T#a';
        1;
    } or die $@;
    my $t = Punk::Test->new($pkg);
    return ($t, join '', @warn);
}
my $PING = '{"jsonrpc":"2.0","id":1,"method":"ping"}';

# ---- CSRF ----------------------------------------------------------------------------

# Punk's CSRF check spares a request carrying a Bearer-style Authorization and
# a path in `exempt`, and nothing else. A cookie-less POST is still checked.
# Pinned, so the day Punk grows a per-route opt-out this test says so.
my ($t) = app(q{ session secret => 'x' x 32; csrf; });
$t->post_ok('/mcp', body => $PING, type => 'application/json');
is($t->status, 403, 'csrf on: a POST with no Bearer is refused by Punk, before MCP sees it');
like($t->body, qr/invalid csrf token/, 'by the CSRF check');
$t->post_ok('/mcp', body => $PING, type => 'application/json',
            headers => { Authorization => 'Bearer abc' });
is($t->status, 200, 'a Bearer token is not a CSRF target');
$t->post_ok('/mcp', body => $PING, type => 'application/json',
            headers => { Authorization => 'Basic YTpi' });
is($t->status, 403, 'Basic is, since a browser sends it by itself');

($t) = app(q{ session secret => 'x' x 32; csrf exempt => ['/mcp']; });
$t->post_ok('/mcp', body => $PING, type => 'application/json');
is($t->status, 200, "csrf exempt => ['/mcp'] lets every MCP client in, as the POD says");

# ---- CORS ----------------------------------------------------------------------------

my $warn;
($t, $warn) = app(q{ cors origins => ['https://app.acme.test']; },
                  q{origins => ['https://app.acme.test']});
is($warn, '', 'cors with no headers list: Punk echoes the request, no warning');
$t->request_ok('OPTIONS', '/mcp', headers => {
    Origin => 'https://app.acme.test',
    'Access-Control-Request-Method' => 'POST',
    'Access-Control-Request-Headers' => 'content-type, mcp-session-id, mcp-protocol-version, authorization',
});
is($t->status, 204, 'a preflight is answered');
like(lc($t->header('Access-Control-Allow-Headers') // ''), qr/mcp-session-id/,
    'allowing the MCP headers');
$t->post_ok('/mcp', body => $PING, type => 'application/json',
            headers => { Origin => 'https://app.acme.test' });
is($t->header('Access-Control-Allow-Origin'), 'https://app.acme.test', 'the POST is CORS-answered');
is($t->header('Access-Control-Expose-Headers'),
    'Mcp-Session-Id, MCP-Protocol-Version, WWW-Authenticate',
    'and exposes the MCP headers, though the application listed none');

($t, $warn) = app(q{ cors origins => ['https://app.acme.test'], headers => ['Content-Type']; },
                  q{origins => ['https://app.acme.test']});
like($warn, qr/cors `headers` does not allow authorization, mcp-session-id, mcp-protocol-version, last-event-id on \/mcp/,
    'a cors headers list missing the MCP headers warns at to_app, naming them');

($t, $warn) = app(q{ cors origins => ['https://app.acme.test'],
                     headers => ['Content-Type', 'Authorization', 'Mcp-Session-Id',
                                 'MCP-Protocol-Version', 'Last-Event-ID']; },
                  q{origins => ['https://app.acme.test']});
is($warn, '', 'one that lists them does not');

($t, $warn) = app(q{ cors origins => ['https://other.test'], headers => ['Content-Type']; },
                  q{origins => ['https://app.acme.test']});
is($warn, '', 'cors that does not cover the MCP origin is not checked');

done_testing;
