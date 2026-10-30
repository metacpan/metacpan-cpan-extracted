#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use FindBin;
use JSON::PP ();
use lib "$FindBin::Bin/lib";
use Punk::Test;
use Punk::Plugin::MCP ();

# The MUSTs, named.
#
# Each requirement the 2025-11-25 specification puts on a server, in the
# specification's words where they fit in a test name, asserted once against
# the real endpoint. The section is in the name, so a row that fails says
# which part of the spec it broke. Rows that changed for 2025-06-18 are
# asserted for both versions. Most are covered elsewhere as behaviour; here
# they are covered as requirements.

my $J = JSON::PP->new->canonical;
my $DIR = File::Temp::tempdir(CLEANUP => 1);
my $V = '2025-11-25';
my $n = 0;

sub app {
    my ($opts, %o) = @_;
    my $pkg = 'T90::A' . ++$n;
    eval qq{
        package ${pkg}::Controller::T;
        sub echo   { 'you said ' . \$_[0]->param('q') }
        sub typed  { { n => 1 } }
        sub badout { { n => 'one' } }
        sub slow   { my (\$c) = \@_; \$c->mcp_progress(1, 3); \$c->mcp_progress(2, 3); 'done' }
        sub book   { 'book ' . \$_[0]->param('id') }
        sub greet  { 'Hello ' . \$_[0]->param('who') }
        package $pkg;
        use Punk;
        use Punk::Plugin::MCP;
        cache mcp => { backend => 'file', dir => '$DIR/$n' };
        plugin 'MCP' => { $opts };
        mcp tool => echo => { input => { type => 'object', required => ['q'],
                                         properties => { q => { type => 'string' } } } } => 'T#echo';
        mcp tool => typed  => { output => { type => 'object', required => ['n'],
                                            properties => { n => { type => 'integer' } } } } => 'T#typed';
        mcp tool => badout => { output => { type => 'object', required => ['n'],
                                            properties => { n => { type => 'integer' } } } } => 'T#badout';
        mcp tool => strict => { input  => { type => 'object', required => ['q'] },
                                output => { type => 'object', required => ['n'] } } => 'T#typed';
        mcp tool => slow => { stream => 1 } => 'T#slow';
        mcp resource => 'books://{id}' => 'T#book';
        mcp prompt => greet => { arguments => [{ name => 'who', required => 1 }] } => 'T#greet';
        1;
    } or die $@;
    return Punk::Test->new($pkg);
}

# One POST. %o: sid, version (undef sends none), accept, origin, raw (a body as
# is). Returns (status, decoded body or undef).
sub post {
    my ($t, $msg, %o) = @_;
    my %h = (Accept => $o{accept} // 'application/json, text/event-stream');
    $h{'MCP-Protocol-Version'} = exists $o{version} ? $o{version} : $V;
    delete $h{'MCP-Protocol-Version'} unless defined $h{'MCP-Protocol-Version'};
    $h{'Mcp-Session-Id'} = $o{sid} if defined $o{sid};
    $h{Origin} = $o{origin} if defined $o{origin};
    $t->post_ok('/mcp', body => defined $o{raw} ? $o{raw} : $J->encode($msg),
                type => 'application/json', headers => \%h);
    my $b = $t->body;
    my $r = (length $b && ($t->header('Content-Type') // '') =~ m{^application/json})
          ? JSON::PP->new->utf8->decode($b) : undef;
    return ($t->status, $r);
}

sub req  { +{ jsonrpc => '2.0', id => $_[0], method => $_[1], ($_[2] ? (params => $_[2]) : ()) } }
sub init { req(1, 'initialize', { protocolVersion => $_[0] // $V, capabilities => {},
                                  clientInfo => { name => 't90', version => '1' } }) }

my $s = app("session => 'mcp', logging => 1");
my $t = app("session => 0");

# ---- basic: JSON-RPC ---------------------------------------------------------------

my ($st, $r) = post($t, req(undef, 'ping'));
is($r->{error}{code}, -32600, 'basic: a request id MUST NOT be null');

($st, $r) = post($t, req(41, 'ping'));
is($r->{id}, 41, 'basic: a response MUST carry the id of the request');
($st, $r) = post($t, req('s-41', 'ping'));
is($r->{id}, 's-41', 'basic: the same id, a string as a string');
ok(exists $r->{result} && !exists $r->{error}, 'basic: a result MUST NOT also set error');
($st, $r) = post($t, req(42, 'no/such'));
ok(exists $r->{error} && !exists $r->{result}, 'basic: an error MUST NOT also set result');
like($r->{error}{code}, qr/^-?\d+\z/, 'basic: an error code MUST be an integer');

($st) = post($t, { jsonrpc => '2.0', method => 'notifications/initialized' });
is($st, 202, 'basic: a notification MUST NOT be answered (202, no body)');
is($t->body, '', 'basic: and the body is empty');

# ---- lifecycle -------------------------------------------------------------------------

($st, $r) = post($s, req(2, 'tools/list'));
is($st, 400, 'lifecycle: initialization MUST be the first interaction (no session, 400)');

($st, $r) = post($s, init($V), version => undef);
is($r->{result}{protocolVersion}, $V, 'lifecycle: a supported version MUST be answered with the same version');
ok($r->{result}{serverInfo}{name} && $r->{result}{capabilities},
   'lifecycle: the server MUST answer with its capabilities and information');
my $sid = $s->header('Mcp-Session-Id');
($st, $r) = post($s, init('1999-01-01'), version => undef);
is($r->{result}{protocolVersion}, $V,
   'lifecycle: an unsupported version MUST be answered with one the server supports, its latest');
($st) = post($s, undef, raw => $J->encode([init($V)]), version => undef);
is($st, 400, 'lifecycle: initialize MUST NOT be part of a batch');

# ---- transports: Streamable HTTP ----------------------------------------------------

like($sid // '', qr/^[\x21-\x7E]+\z/, 'transports: a session id MUST be visible ASCII only');
($st, $r) = post($s, req(3, 'tools/list'), sid => $sid);
is($st, 200, 'transports: one endpoint takes the session\'s requests');
like($s->header('Content-Type'), qr{^(?:application/json|text/event-stream)},
     'transports: a request MUST be answered as application/json or text/event-stream');

($st) = post($s, { jsonrpc => '2.0', method => 'notifications/initialized' }, sid => $sid);
is($st, 202, 'transports: an accepted notification MUST be 202 with no body');
($st) = post($s, { jsonrpc => '2.0', id => 77, result => {} }, sid => $sid);
is($st, 202, 'transports: an accepted response MUST be 202 with no body');

$s->post_ok('/mcp', body => $J->encode(req(4, 'tools/call', { name => 'slow',
                                             _meta => { progressToken => 'pt' } })),
            type => 'application/json',
            headers => { Accept => 'application/json, text/event-stream', 'Mcp-Session-Id' => $sid,
                         'MCP-Protocol-Version' => $V });
my @events = map { JSON::PP->new->utf8->decode($_) } $s->body =~ /^data: (.*)$/mg;
is($events[-1]{id}, 4, 'transports: an SSE answer MUST end with the response');
is(scalar(grep { exists $_->{id} } @events), 1, 'transports: and carry it once');
my @prog = grep { ($_->{method} // '') eq 'notifications/progress' } @events;
ok(@prog && !grep({ $_->{params}{progressToken} ne 'pt' } @prog),
   'progress: a notification MUST only reference a token from an active request');
ok(@prog == 2 && $prog[1]{params}{progress} > $prog[0]{params}{progress},
   'progress: the progress value MUST increase with each notification');

$t->get_ok('/mcp', headers => { Accept => 'text/event-stream' });
is($t->status, 405, 'transports: GET MUST be an event stream or 405 (405 without sessions)');
$s->get_ok('/mcp', headers => { Accept => 'text/event-stream' });
is($s->status, 400, 'transports: a request other than initialize without the session id is 400');

($st) = post($s, req(5, 'ping'), sid => $sid, origin => 'https://evil.test');
is($st, 403, 'transports: the Origin MUST be validated, and an invalid one is 403');
($st) = post($s, req(6, 'ping'), sid => $sid, version => '2099-01-01');
is($st, 400, 'transports: an unsupported MCP-Protocol-Version MUST be 400');
($st) = post($s, req(6, 'ping'), sid => $sid, version => 'nonsense');
is($st, 400, 'transports: an invalid MCP-Protocol-Version MUST be 400');

my ($dsid) = do { post($s, init($V), version => undef); $s->header('Mcp-Session-Id') };
$s->request_ok('DELETE', '/mcp', headers => { 'Mcp-Session-Id' => $dsid });
($st) = post($s, req(7, 'ping'), sid => $dsid);
is($st, 404, 'transports: a request for a terminated session MUST be 404');

# ---- server features: capabilities --------------------------------------------------

my $caps;
(undef, $r) = post($s, init($V), version => undef);
$caps = $r->{result}{capabilities};
ok($caps->{tools}, 'tools: a server with tools MUST declare the tools capability');
ok($caps->{resources}, 'resources: a server with resources MUST declare the resources capability');
ok($caps->{prompts}, 'prompts: a server with prompts MUST declare the prompts capability');
ok($caps->{logging}, 'logging: a server that sends log messages MUST declare logging');
ok(!grep({ ref $caps->{$_} eq 'HASH' && $caps->{$_}{listChanged} } qw(tools resources prompts)),
   'tools, resources, prompts: listChanged is not claimed, since no change is sent');
(undef, $r) = post($t, init($V), version => undef);
ok(!$r->{result}{capabilities}{logging}, 'logging: a server that cannot send logs does not declare it');

# ---- tools ---------------------------------------------------------------------------

(undef, $r) = post($t, req(10, 'tools/list'));
my %tools = map { $_->{name} => $_ } @{ $r->{result}{tools} };
ok(!grep({ ref $_->{inputSchema} ne 'HASH' } values %tools),
   'tools: every inputSchema MUST be a JSON Schema object, never null');
ok(!grep({ length($_) > 128 || /[^A-Za-z0-9_.-]/ } keys %tools),
   'tools: names are 1 to 128 of A-Z a-z 0-9 _ - .');

(undef, $r) = post($t, req(11, 'tools/call', { name => 'typed' }));
is_deeply($r->{result}{structuredContent}, { n => 1 },
   'tools: with an outputSchema the server MUST return structuredContent');
ok(($r->{result}{content}[0]{text} // '') =~ /"n"/,
   'tools: and the serialised JSON as text, for older clients');
(undef, $r) = post($t, req(12, 'tools/call', { name => 'badout' }));
ok($r->{result}{isError} && !exists $r->{result}{structuredContent},
   'tools: structured results MUST conform to the outputSchema, so a mismatch is an error');

(undef, $r) = post($t, req(16, 'tools/call', { name => 'strict', arguments => {} }));
ok($r->{result}{isError} && !exists $r->{result}{structuredContent},
   'tools: a bad input to a tool with an outputSchema puts no errors in structuredContent');
(undef, $r) = post($t, req(13, 'tools/call', { name => 'missing' }));
is($r->{error}{code}, -32602, 'tools: an unknown tool is a protocol error, -32602');

(undef, $r) = post($t, req(14, 'tools/call', { name => 'echo', arguments => { q => 7 } }));
ok($r->{result}{isError}, 'tools (2025-11-25): servers MUST validate inputs, and a bad one is isError');
(undef, $r) = post($t, req(14, 'tools/call', { name => 'echo', arguments => { q => 7 } }),
                   version => '2025-06-18');
is($r->{error}{code}, -32602, 'tools (2025-06-18): the same input is a -32602 protocol error');
(undef, $r) = post($t, req(14, 'tools/call', { name => 'echo', arguments => { q => 7 } }),
                   version => undef);
is($r->{error}{code}, -32602,
   'transports: no MCP-Protocol-Version and no session SHOULD be read as 2025-03-26');

(undef, $r) = post($t, req(15, 'tools/list'), version => '2025-06-18');
ok(!grep({ exists $_->{icons} } @{ $r->{result}{tools} }), 'tools (2025-06-18): no icons');

# ---- resources and prompts ------------------------------------------------------------

(undef, $r) = post($t, req(20, 'resources/read', { uri => 'nothing://here' }));
is($r->{error}{code}, -32002, 'resources: a resource that is not there is -32002');
(undef, $r) = post($t, req(21, 'resources/read', { uri => 'books://7' }));
is($r->{result}{contents}[0]{uri}, 'books://7', 'resources: contents name the URI read');
ok((defined $r->{result}{contents}[0]{text} xor defined $r->{result}{contents}[0]{blob}),
   'resources: each content is text or blob');

(undef, $r) = post($t, req(22, 'prompts/get', { name => 'nope' }));
is($r->{error}{code}, -32602, 'prompts: an invalid prompt name is -32602');
(undef, $r) = post($t, req(23, 'prompts/get', { name => 'greet' }));
is($r->{error}{code}, -32602, 'prompts: a missing required argument is -32602');

# ---- utilities -------------------------------------------------------------------------

(undef, $r) = post($t, req(30, 'tools/list', { cursor => 'not-a-cursor' }));
is($r->{error}{code}, -32602, 'pagination: an invalid cursor is -32602');

(undef, $r) = post($t, req(31, 'ping'));
is_deeply($r->{result}, {}, 'ping: the receiver MUST answer with an empty result');

($st) = post($t, { jsonrpc => '2.0', method => 'notifications/cancelled',
                   params => { requestId => 'never-sent' } });
is($st, 202, 'cancellation: a cancel for an unknown request is ignored');

(undef, $r) = post($s, req(32, 'logging/setLevel', { level => 'loud' }), sid => $sid);
is($r->{error}{code}, -32602, 'logging: an invalid level is -32602');
(undef, $r) = post($s, req(33, 'logging/setLevel', { level => 'error' }), sid => $sid);
is_deeply($r->{result}, {}, 'logging: setLevel answers with an empty result');

# ---- authorization ----------------------------------------------------------------------

SKIP: {
    skip 'Punk-OAuth2 0.08 and Crypt::JWS required', 7
        unless eval { require Punk::OAuth2::Checker; Punk::OAuth2->VERSION('0.08');
                      require Crypt::JWS; require PMCPAuth; 1 };
    PMCPAuth->import;
    my $a = PMCPAuth::auth_app(q{oauth => { issuer => 'https://id.test', key => $PMCPAuth::SECRET,
                                            algs => ['HS256'], scopes => ['mcp'] }});
    $a->get_ok('/.well-known/oauth-protected-resource/mcp');
    my $prm = $a->status == 200 ? JSON::PP->new->decode($a->body) : {};
    is($prm->{resource}, 'http://localhost/mcp',
       'authorization: servers MUST serve RFC 9728 protected resource metadata');
    PMCPAuth::mcp_call($a);
    is($a->status, 401, 'authorization: a request without a token is 401');
    like($a->header('WWW-Authenticate') // '', qr/resource_metadata="/,
         'authorization: a 401 MUST point at the metadata from WWW-Authenticate');
    PMCPAuth::mcp_call($a, Authorization => 'Bearer ' . PMCPAuth::token(aud => 'https://other.test/mcp'));
    is($a->status, 401, 'authorization: a token for another audience MUST be refused');
    PMCPAuth::mcp_call($a, Authorization => 'Bearer ' . PMCPAuth::token(exp => time - 60));
    is($a->status, 401, 'authorization: an expired token MUST be refused with 401');
    PMCPAuth::mcp_call($a, Authorization => 'Bearer ' . PMCPAuth::token(scope => 'other'));
    is($a->status, 403, 'authorization: a token short of a scope is 403');
    PMCPAuth::mcp_call($a, Authorization => 'Bearer ' . PMCPAuth::token());
    is($a->status, 200, 'authorization: a good token is let in');
}

done_testing;
