#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Time::HiRes ();
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPApp;

my $pkg = 'T23::A';
my $t = mcp_app(qq{
    package ${pkg}::Controller::T;
    sub string    { 'plain words' }
    sub number    { 42 }
    sub nothing   { return }
    sub hash      { { a => 1, b => [2, 3] } }
    sub array     { [1, 'two'] }
    sub shaped    { { content => [{ type => 'text', text => 'mine' }], isError => 1 } }
    sub shaped_ok { { content => [{ type => 'text', text => 'fine' }] } }
    sub json      { \$_[0]->json({ found => 1 }) }
    sub json_422  { \$_[0]->json({ error => 'bad' }, 422) }
    sub text_404  { \$_[0]->text('no such book', 404) }
    sub future    { Punk::Future->done_future({ later => 1 }) }
    sub fut_fail  { Punk::Future->fail_future("it did not happen\\n") }
    sub pending   { \$_[0]->promise }
    sub fut_text  { Punk::Future->done_future(\$_[0]->text('via a future')) }
    sub code      { { cb => sub { 1 } } }
    sub scalarref { \\'x' }
    sub good_out  { { n => 3 } }
    sub bad_out   { { n => 'three' } }
    sub text_out  { 'not an object' }
    package $pkg;
    plugin 'MCP' => { session => 0 };
    mcp tool => \$_ => 'T#' . \$_
        for qw(string number nothing hash array shaped shaped_ok json json_422
               text_404 future fut_fail fut_text code scalarref);
    mcp tool => pending => { timeout => 0.2 } => 'T#pending';
    mcp tool => \$_ => { output => { type => 'object', required => ['n'],
                                    properties => { n => { type => 'integer' } } } }
                      => 'T#' . \$_ for qw(good_out bad_out text_out);
}, pkg => $pkg);

sub res { my ($name, $v) = @_; my (undef, $r) = call_tool($t, $name, undef, $v); $r }
my $r;

# ---- plain values ------------------------------------------------------------------

$r = res('string')->{result};
is_deeply($r, { content => [{ type => 'text', text => 'plain words' }] },
    'a string is one text block');
is(res('number')->{result}{content}[0]{text}, '42', 'a number is its text');
is_deeply(res('nothing')->{result}, { content => [] }, 'nothing is no content');

$r = res('hash')->{result};
is_deeply($r->{structuredContent}, { a => 1, b => [2, 3] }, 'a hash is structuredContent');
is_deeply(JSON::PP->new->decode($r->{content}[0]{text}), { a => 1, b => [2, 3] },
    'and its JSON as text');
$r = res('hash', '2025-03-26')->{result};
ok(!exists $r->{structuredContent}, '2025-03-26 has no structuredContent');
ok($r->{content}[0]{text}, 'only the text');

$r = res('array')->{result};
ok(!exists $r->{structuredContent}, 'an array is never structuredContent');
is($r->{content}[0]{text}, '[1,"two"]', 'it goes out as JSON text');

# ---- results already in MCP's shape ---------------------------------------------------

$r = res('shaped')->{result};
is($r->{content}[0]{text}, 'mine', 'an MCP-shaped hash passes through');
ok(JSON::PP::is_bool($r->{isError}) && $r->{isError}, 'with isError a real boolean');
ok(!exists res('shaped_ok')->{result}{isError}, 'and no isError when it gave none');

# ---- PSGI triplets ---------------------------------------------------------------------

$r = res('json')->{result};
is_deeply($r->{structuredContent}, { found => 1 }, '$c->json is decoded into structuredContent');
is($r->{_meta}{status}, 200, 'with the status in _meta');
ok(!$r->{isError}, 'and no error');

$r = res('json_422')->{result};
ok($r->{isError}, 'a 4xx triplet is a tool error');
is($r->{content}[0]{text}, '{"error":"bad"}', 'with its body as the text');
is($r->{_meta}{status}, 422, 'and its status');

$r = res('text_404')->{result};
ok($r->{isError}, '$c->text with 404 is a tool error');
is($r->{content}[0]{text}, 'no such book', 'with its words');

# ---- Futures -----------------------------------------------------------------------------

is_deeply(res('future')->{result}{structuredContent}, { later => 1 }, 'a Future is awaited');
$r = res('fut_fail')->{result};
ok($r->{isError}, 'a failed Future is a tool error');
is($r->{content}[0]{text}, 'it did not happen', 'with its failure');
is(res('fut_text')->{result}{content}[0]{text}, 'via a future',
    'a Future of a triplet is converted like the triplet');

my $t0 = Time::HiRes::time();
$r = res('pending')->{result};
my $took = Time::HiRes::time() - $t0;
ok($r->{isError}, 'a Future that never settles is a tool error');
is($r->{content}[0]{text}, 'timed out after 0.2 seconds', 'saying it timed out');
cmp_ok($took, '<', 3, 'after the timeout, not forever');

# ---- output schemas -----------------------------------------------------------------------

$r = res('good_out')->{result};
is_deeply($r->{structuredContent}, { n => 3 }, 'a result matching its output schema passes');
$r = res('bad_out')->{result};
ok($r->{isError}, 'a mismatch is a tool error, never a silent pass');
like($r->{content}[0]{text}, qr/does not match its output schema/, 'saying so');
like($r->{content}[0]{text}, qr{: /n }, 'with the errors in words');
ok(!exists $r->{structuredContent},
    'and no structuredContent, which would not match the schema either');
$r = res('text_out')->{result};
ok($r->{isError}, 'a tool with an output schema that returns text is a tool error');
ok(!res('bad_out', '2025-03-26')->{result}{isError},
    '2025-03-26 has no structured content, so nothing to check');

# ---- results that cannot be results -------------------------------------------------------

for my $name (qw(code scalarref)) {
    $r = res($name);
    is($r->{error}{code}, -32603, "$name: -32603");
    is($r->{error}{message}, "the tool's result is not JSON", "$name: says why");
}
is(res('string')->{result}{content}[0]{text}, 'plain words',
    'and the server is whole after them');

done_testing;
