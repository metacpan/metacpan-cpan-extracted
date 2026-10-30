#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use MIME::Base64 ();
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPApp;

my $pkg = 'T24::A';
my $t = mcp_app(qq{
    package ${pkg}::Controller::R;
    sub catalog { { books => 2 } }
    sub readme  { "Read me.\\n" }
    sub logo    { "\\x89PNG\\r\\n\\x1a\\n\\x00\\xff" }
    sub utf8    { "caf\\xc3\\xa9" }
    sub chars   { "caf\\x{e9} \\x{263a}" }
    sub latin   { "caf\\xe9" }
    sub none    { return }
    sub gone    { \$_[0]->text('no such thing', 404) }
    sub broken  { \$_[0]->text('upstream down', 503) }
    sub served  { \$_[0]->json({ via => 'json' }) }
    sub shaped  { { contents => [{ uri => 'x://shaped', text => 'my own' }] } }
    sub dies    { die "disk on fire\\n" }
    sub later   { Punk::Future->done_future('from a future') }
    sub odd     { \\'x' }
    sub secret  { 'top secret' }
    package $pkg;
    our \$NO = sub { [403, [], ['no']] };
    plugin 'MCP' => { session => 0, page_size => 3 };
    mcp resource => 'books://catalog' => {
        name => 'catalog', title => 'Catalogue', description => 'Every book.',
        mime => 'application/json', size => 120,
        annotations => { audience => ['user', 'assistant'], priority => 0.5,
                         lastModified => '2026-10-23T09:00:00Z' },
        icons => [{ src => 'https://x.test/c.png' }],
    } => 'R#catalog';
    mcp resource => 'docs://readme' => { mime => 'text/plain' } => 'R#readme';
    mcp resource => 'img://logo'    => { mime => 'image/png' }  => 'R#logo';
    mcp resource => 'txt://utf8'    => 'R#utf8';
    mcp resource => 'txt://chars'   => 'R#chars';
    mcp resource => 'txt://latin'   => 'R#latin';
    mcp resource => 'x://none'      => 'R#none';
    mcp resource => 'x://gone'      => 'R#gone';
    mcp resource => 'x://broken'    => 'R#broken';
    mcp resource => 'x://served'    => 'R#served';
    mcp resource => 'x://shaped'    => 'R#shaped';
    mcp resource => 'x://dies'      => 'R#dies';
    mcp resource => 'x://later'     => 'R#later';
    mcp resource => 'x://odd'       => 'R#odd';
    mcp resource => 'x://secret'    => { guard => \$NO } => 'R#secret';
}, pkg => $pkg);

sub read_uri { my (undef, $r) = rpc_msg($t, 'resources/read', { uri => $_[0] }, $_[1]); $r }

# ---- the list ------------------------------------------------------------------

my ($items, $pages) = list_all($t, 'resources/list', 'resources');
is_deeply([map { $_->{uri} } @$items], [sort map { $_->{uri} } @$items],
    'resources are listed sorted by URI');
is(scalar @$items, 14, 'every resource but the guarded one');
ok(!grep({ $_->{uri} eq 'x://secret' } @$items), 'a refusing guard hides one');
is_deeply($pages, [3, 3, 3, 3, 2], 'paged by page_size');

my ($cat) = grep { $_->{uri} eq 'books://catalog' } @$items;
is_deeply($cat, {
    uri => 'books://catalog', name => 'catalog', title => 'Catalogue',
    description => 'Every book.', mimeType => 'application/json', size => 120,
    annotations => { audience => ['user', 'assistant'], priority => 0.5,
                     lastModified => '2026-10-23T09:00:00Z' },
    icons => [{ src => 'https://x.test/c.png' }],
}, 'every field, on 2025-11-25');
my ($rd) = grep { $_->{uri} eq 'docs://readme' } @$items;
is($rd->{name}, 'docs://readme', 'name defaults to the URI');

($items) = list_all($t, 'resources/list', 'resources', '2025-03-26');
($cat) = grep { $_->{uri} eq 'books://catalog' } @$items;
ok(!exists $cat->{$_}, "2025-03-26 has no $_") for qw(title icons);
ok(exists $cat->{size} && exists $cat->{annotations}, 'but has size and annotations');

my (undef, $tl) = rpc_msg($t, 'resources/templates/list', {});
is_deeply($tl->{result}{resourceTemplates}, [], 'no templates declared, an empty list');

# ---- reading ---------------------------------------------------------------------

my $c = read_uri('books://catalog')->{result}{contents};
is_deeply($c, [{ uri => 'books://catalog', mimeType => 'application/json',
                 text => '{"books":2}' }], 'a hash is JSON text');

is_deeply(read_uri('docs://readme')->{result}{contents},
    [{ uri => 'docs://readme', mimeType => 'text/plain', text => "Read me.\n" }],
    'a string with a text mime is text');

$c = read_uri('img://logo')->{result}{contents}[0];
ok(!exists $c->{text}, 'a binary mime is not text');
is(MIME::Base64::decode_base64($c->{blob}), "\x89PNG\r\n\x1a\n\x00\xff",
    'it is a base64 blob of the exact bytes');

is(read_uri('txt://utf8')->{result}{contents}[0]{text}, "caf\x{e9}",
    'no mime and UTF-8 bytes: text, as the characters they spell');
is(read_uri('txt://chars')->{result}{contents}[0]{text}, "caf\x{e9} \x{263a}",
    'a character string is text');
$c = read_uri('txt://latin')->{result}{contents}[0];
is(MIME::Base64::decode_base64($c->{blob}), "caf\xe9",
    'no mime and bytes that are not UTF-8: a blob');

is_deeply(read_uri('x://served')->{result}{contents},
    [{ uri => 'x://served', mimeType => 'application/json', text => '{"via":"json"}' }],
    "a triplet's body, its JSON type kept");
is(read_uri('x://shaped')->{result}{contents}[0]{text}, 'my own',
    'a hash with contents passes through');
is(read_uri('x://later')->{result}{contents}[0]{text}, 'from a future',
    'a Future is awaited');

# ---- not found, and failures ----------------------------------------------------------

for my $uri ('x://missing', 'x://none', 'x://gone', 'x://secret') {
    my $r = read_uri($uri);
    is($r->{error}{code}, -32002, "$uri: -32002");
    is($r->{error}{message}, 'Resource not found', "$uri: Resource not found");
    is($r->{error}{data}{uri}, $uri, "$uri: with the uri");
}

my $r = read_uri('x://broken');
is($r->{error}{code}, -32603, 'a 5xx is -32603');
is($r->{error}{data}{status}, 503, 'with the status');
$r = read_uri('x://dies');
is($r->{error}{code}, -32603, 'a die is -32603');
is($r->{error}{data}{reason}, 'disk on fire', 'with its text');
$r = read_uri('x://odd');
is($r->{error}{code}, -32603, 'a value that is no resource is -32603');

(undef, $r) = rpc_msg($t, 'resources/read', {});
is($r->{error}{code}, -32602, 'no uri is -32602');
(undef, $r) = rpc_msg($t, 'resources/read', { uri => ['x'] });
is($r->{error}{code}, -32602, 'a uri that is not a string is -32602');

# ---- declarations that are refused ----------------------------------------------------

my $n = 0;
sub refused {
    my ($decl) = @_;
    my $p = 'T24::Bad' . ++$n;
    my $src = "package ${p}::Controller::R; sub a { 1 }\n"
            . "package $p; use Punk; use Punk::Plugin::MCP;\n"
            . "plugin 'MCP' => { session => 0 };\n$decl;\n1;\n";
    eval $src or return $@;
    eval { $p->to_app; 1 } or return $@;
    return '';
}
for my $case (
    [ q{mcp resource => 'no-scheme' => 'R#a'}, qr/is not a URI: it has no scheme/ ],
    [ q{mcp resource => 'x://a' => { mime => [] } => 'R#a'}, qr/mime must be a string/ ],
    [ q{mcp resource => 'x://a' => { size => -1 } => 'R#a'}, qr/size must be a whole number/ ],
    [ q{mcp resource => 'x://a' => { mimeType => 'x' } => 'R#a'}, qr/unknown mcp resource 'x:\/\/a' key 'mimeType'/ ],
    [ q{mcp resource => 'x://a' => { annotations => { audience => ['robot'] } } => 'R#a'},
      qr/audience must be a list of user and assistant/ ],
    [ q{mcp resource => 'x://a' => { annotations => { priority => 2 } } => 'R#a'},
      qr/priority must be a number from 0 to 1/ ],
    [ q{mcp resource => 'x://a' => { annotations => { lastModified => 'yesterday' } } => 'R#a'},
      qr/lastModified must be an ISO 8601 date-time/ ],
    [ q{mcp resource => 'x://{id}' => { size => 3 } => 'R#a'},
      qr/is a template, and a template has no size/ ],
) {
    my ($decl, $want) = @$case;
    like(refused($decl), $want, "refused: $decl");
}

done_testing;
