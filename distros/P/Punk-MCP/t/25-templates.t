#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPApp;

my $pkg = 'T25::A';
my $t = mcp_app(qq{
    package ${pkg}::Controller::R;
    sub book    { my (\$c) = \@_; return { id => \$c->param('id') } }
    sub chapter { my (\$c) = \@_; return { id => \$c->param('id'), ch => \$c->param('ch') } }
    sub file    { my (\$c) = \@_; return 'path=' . \$c->param('path') }
    sub exact   { 'the catalog' }
    sub meta    { my (\$c) = \@_; return { name => \$c->mcp->name, method => \$c->mcp->method } }
    package $pkg;
    plugin 'MCP' => { session => 0 };
    mcp resource => 'books://{id}' => { name => 'book', mime => 'application/json' } => 'R#book';
    mcp resource => 'books://catalog' => 'R#exact';
    mcp resource => 'shelf://{id}/chapters/{ch}' => 'R#chapter';
    mcp resource => 'file:///srv/{path}' => { mime => 'text/plain' } => 'R#file';
    mcp resource => 'meta://{x}' => 'R#meta';
}, pkg => $pkg);

sub read_uri { my (undef, $r) = rpc_msg($t, 'resources/read', { uri => $_[0] }); $r }
sub value    { my $r = read_uri(@_); $r->{result} ? $r->{result}{contents}[0]{text} : $r->{error}{code} }

my ($items) = list_all($t, 'resources/templates/list', 'resourceTemplates');
is_deeply([map { $_->{uriTemplate} } @$items],
    ['books://{id}', 'shelf://{id}/chapters/{ch}', 'file:///srv/{path}', 'meta://{x}'],
    'templates are listed in declaration order, as uriTemplate');
is_deeply($items->[0], { uriTemplate => 'books://{id}', name => 'book',
                         mimeType => 'application/json' }, 'with their fields');
($items) = list_all($t, 'resources/list', 'resources');
is_deeply([map { $_->{uri} } @$items], ['books://catalog'],
    'and only the exact URI is in resources/list');

# ---- matching -----------------------------------------------------------------------

is(value('books://catalog'), 'the catalog', 'an exact URI wins over a template that matches it');
is(value('books://42'), '{"id":"42"}', 'a template variable reaches $c->param');
is(value('shelf://9/chapters/3'), '{"ch":"3","id":"9"}', 'two variables');
is(value('books://a%20b%2Fc'), '{"id":"a b/c"}', 'values are percent-decoded');
is(value('books://caf%C3%A9'), qq({"id":"caf\x{e9}"}), 'UTF-8 escapes decode to characters');
is(value('file:///srv/..%2F..%2Fetc%2Fpasswd'), 'path=../../etc/passwd',
    'a value arrives decoded and unchecked, as the POD warns');
is(value('meta://q'), '{"method":"resources/read","name":"meta://q"}',
    '$c->mcp names the method and the URI');

for my $uri ('books://', 'books://a/b', 'books://a?b', 'shelf://9/chapters/',
             'shelf://9/chapter/3', 'books://bad%zzescape', 'books://trail%4') {
    is(value($uri), -32002, "'$uri' does not match: -32002");
}

# ---- templates that are refused ---------------------------------------------------------

my $n = 0;
sub refused {
    my ($decl) = @_;
    my $p = 'T25::Bad' . ++$n;
    my $src = "package ${p}::Controller::R; sub a { 1 }\n"
            . "package $p; use Punk; use Punk::Plugin::MCP;\n"
            . "plugin 'MCP' => { session => 0 };\n$decl;\n1;\n";
    eval $src or return $@;
    eval { $p->to_app; 1 } or return $@;
    return '';
}

for my $case (
    [ q{mcp resource => 'x://{+path}' => 'R#a'}, qr/uses an operator, and only level 1/ ],
    [ q{mcp resource => 'x://a{?q}' => 'R#a'},   qr/uses an operator/ ],
    [ q{mcp resource => 'x://{id*}' => 'R#a'},   qr/uses a modifier/ ],
    [ q{mcp resource => 'x://{id:3}' => 'R#a'},  qr/uses a modifier/ ],
    [ q{mcp resource => 'x://{a}{b}' => 'R#a'},  qr/has two variables with no text between them/ ],
    [ q[mcp resource => 'x://{id' => 'R#a'],     qr/has a '\{' with no '\}'/ ],
    [ q[mcp resource => 'x://id}' => 'R#a'],     qr/has a '\}' with no '\{'/ ],
    [ q{mcp resource => 'x://{}' => 'R#a'},      qr/has an empty \{\}/ ],
    [ q{mcp resource => 'x://{a}/{a}' => 'R#a'}, qr/uses one variable name twice/ ],
    [ q{mcp resource => 'x://{a-b}' => 'R#a'},   qr/variable name that is not letters/ ],
) {
    my ($decl, $want) = @$case;
    like(refused($decl), $want, "refused: $decl");
}

# Overlap: two templates one URI could match.
for my $case (
    [ q{x://{id}},       q{x://{name}},       1, 'the same shape, other names' ],
    [ q{x://{a}/b},      q{x://a/{b}},        1, 'x://a/b matches both' ],
    [ q{x://{a}.json},   q{x://{b}},          1, 'x://n.json matches both' ],
    [ q{x://pre{a}},     q{x://{b}post},      1, 'x://prepost matches both' ],
    [ q{x://{a}/one},    q{x://{a}/two},      0, 'different literals after' ],
    [ q{x://{a}},        q{x://{a}/{b}},      0, 'a variable takes no slash' ],
    [ q{x://a/{b}},      q{y://a/{b}},        0, 'different schemes' ],
    [ q{x://{a}.json},   q{x://{b}.xml},      0, 'different extensions' ],
) {
    my ($one, $two, $overlap, $name) = @$case;
    my $err = refused("mcp resource => '$one' => 'R#a'; mcp resource => '$two' => 'R#a'");
    if ($overlap) {
        like($err, qr/mcp resource '\Q$one\E' and '\Q$two\E' can match the same URI/,
            "overlap croaks: $name");
    }
    else { is($err, '', "no overlap: $name") }
}
is(refused(q{mcp resource => 'x://{id}' => 'R#a'; mcp resource => 'x://fixed' => 'R#a'}), '',
    'an exact URI a template also matches is not an overlap');

done_testing;
