#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Punk::Test;
use Punk::Plugin::MCP ();

my $pkg = 'T30::A';
eval qq{
    package ${pkg}::Controller::T; sub hi { 'hello ' . (\$_[0]->param('who') // 'you') }
    package $pkg;
    use Punk;
    use Punk::Plugin::MCP;
    plugin 'MCP' => { session => 0, max_body => 200 };
    mcp tool => hi => 'T#hi';
    1;
} or die $@;
my $t = Punk::Test->new($pkg);
my $J = JSON::PP->new->canonical;

my %H = (Accept => 'application/json, text/event-stream',
         'MCP-Protocol-Version' => '2025-11-25');
sub post {
    my ($body, %o) = @_;
    my %h = (%H, %{ $o{headers} || {} });
    delete $h{$_} for @{ $o{drop} || [] };
    $t->post_ok('/mcp', body => ref $body ? $J->encode($body) : $body,
                type => $o{type} // 'application/json', headers => \%h,
                env => $o{env} || {});
    return $t;
}
sub msg  { +{ jsonrpc => '2.0', id => 1, method => $_[0], ($_[1] ? (params => $_[1]) : ()) } }
sub body { my $b = $t->body; length $b ? JSON::PP->new->utf8->decode($b) : undef }

# ---- a request, a notification, a response ------------------------------------------

post(msg('tools/call', { name => 'hi', arguments => { who => 'Ada' } }));
is($t->status, 200, 'a request is 200');
is($t->header('Content-Type'), 'application/json', 'application/json');
is($t->header('Cache-Control'), 'no-store', 'never cached');
is(body()->{result}{content}[0]{text}, 'hello Ada', 'answered through the real route');
ok(!defined $t->header('Access-Control-Expose-Headers'),
    'no expose header for a request with no Origin');

post({ jsonrpc => '2.0', method => 'notifications/initialized' });
is($t->status, 202, 'a notification is 202');
is($t->body, '', 'with no body');
ok(!defined $t->header('Content-Type'), 'and no Content-Type');

post({ jsonrpc => '2.0', id => 9, result => {} });
is($t->status, 202, 'a response is 202');

post('{not json');
is($t->status, 400, 'a body that is not JSON is 400');
is(body()->{error}{code}, -32700, 'with -32700');
post('[]');
is($t->status, 400, 'a batch is 400');

# ---- the checks, in order ---------------------------------------------------------------

post(msg('ping'), drop => ['Accept'], headers => {});
is($t->status, 200, 'no Accept at all is taken as anything');
for my $accept ('application/json', 'application/*', '*/*',
                'text/html, application/json;q=0.9', 'APPLICATION/JSON') {
    post(msg('ping'), headers => { Accept => $accept });
    is($t->status, 200, "Accept '$accept' is fine");
}
for my $accept ('text/event-stream', 'text/html', 'application/xml') {
    post(msg('ping'), headers => { Accept => $accept });
    is($t->status, 406, "Accept '$accept' is 406");
    is(body()->{error}{message}, 'Accept must allow application/json', 'saying why');
}

for my $type ('text/plain', 'application/x-www-form-urlencoded', 'application/jsonx') {
    post(msg('ping'), type => $type);
    is($t->status, 415, "Content-Type '$type' is 415");
}
post(msg('ping'), type => 'application/json; charset=utf-8');
is($t->status, 200, 'Content-Type with a charset is fine');

post(msg('ping'), headers => { 'MCP-Protocol-Version' => '1999-01-01' });
is($t->status, 400, 'an unsupported MCP-Protocol-Version is 400');
is(body()->{error}{message}, 'unsupported MCP-Protocol-Version', 'saying why');
is(body()->{id}, undef, 'with a null id');

# a missing header is 2025-03-26: a bad argument is then -32602, not a tool error
eval qq{ package ${pkg}::Controller::T; sub strict { 'ok' } 1 };
post(msg('tools/call', { name => 'hi', arguments => [] }), drop => ['MCP-Protocol-Version']);
is(body()->{error}{code}, -32602, 'no MCP-Protocol-Version: answered all the same');

post(msg('ping', { pad => 'x' x 300 }));
is($t->status, 413, 'a body over max_body is 413');
is(body()->{error}{message}, 'the body is too large', 'saying why');
post(msg('ping', { pad => 'x' x 300 }),
     env => { CONTENT_LENGTH => undef, 'psgix.input.buffered' => 1 });
is($t->status, 413, 'and so is one with no Content-Length, judged on what arrived');
post(msg('ping'), env => { CONTENT_LENGTH => 5000 });
is($t->status, 413, 'a declared length over max_body is 413 before anything is read');

# ---- other methods ---------------------------------------------------------------------

for my $m (qw(GET DELETE PUT)) {
    $t->request_ok($m, '/mcp');
    is($t->status, 405, "$m is 405");
    is($t->header('Allow'), 'POST', 'Allow: POST');
}

done_testing;
