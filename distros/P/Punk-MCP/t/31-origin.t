#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Test;
use Punk::Plugin::MCP ();

my $n = 0;
sub app {
    my ($opts) = @_;
    my $pkg = 'T31::A' . ++$n;
    eval qq{
        package ${pkg}::Controller::T; sub a { 'a' }
        package $pkg;
        use Punk;
        use Punk::Plugin::MCP;
        plugin 'MCP' => { session => 0, $opts };
        mcp tool => a => 'T#a';
        1;
    } or die $@;
    return Punk::Test->new($pkg);
}
sub ping {
    my ($t, $origin, %env) = @_;
    $t->post_ok('/mcp', body => '{"jsonrpc":"2.0","id":1,"method":"ping"}',
                type => 'application/json',
                headers => { (defined $origin ? (Origin => $origin) : ()) },
                env => \%env);
    return $t->status;
}

# ---- with no origins: the server's own -----------------------------------------------

my $t = app('');
is(ping($t, undef), 200, 'no Origin: a non-browser client, allowed');
is(ping($t, 'http://localhost', HTTP_HOST => 'localhost'), 200, 'the same origin');
is(ping($t, 'http://LOCALHOST:80', HTTP_HOST => 'localhost'), 200,
    'the same origin, cased and with the default port');
is(ping($t, 'https://localhost', HTTP_HOST => 'localhost'), 403, 'another scheme');
is(ping($t, 'http://evil.test', HTTP_HOST => 'localhost'), 403, 'another site');
is(ping($t, 'http://localhost:8080', HTTP_HOST => 'localhost'), 403, 'another port');
is(ping($t, 'null', HTTP_HOST => 'localhost'), 403, 'null');
is($t->header('Access-Control-Expose-Headers'),
    'Mcp-Session-Id, MCP-Protocol-Version, WWW-Authenticate',
    'an answer to a browser exposes the MCP headers');

# ---- with origins ----------------------------------------------------------------------

$t = app(q{origins => ['https://app.acme.test', 'http://localhost:3000']});
is(ping($t, 'https://app.acme.test'), 200, 'a listed origin');
is(ping($t, 'https://app.acme.test:443/'), 200, 'listed, with the default port and a slash');
is(ping($t, 'http://localhost:3000'), 200, 'the other listed origin');
is(ping($t, 'http://localhost', HTTP_HOST => 'localhost'), 403,
    'the server\'s own origin is not implied once origins are listed');
is(ping($t, 'https://evil.acme.test'), 403, 'an unlisted one');
is(ping($t, 'null'), 403, 'null');
is(ping($t, undef), 200, 'and still no Origin at all');

done_testing;
