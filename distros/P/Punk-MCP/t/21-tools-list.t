#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPApp;

my $DECL = q{
    package %s::Controller::T;
    sub a { 'a' }
    package %s;
    plugin 'MCP' => { session => 0 };
    mcp tool => zeta => { description => 'Last.' } => 'T#a';
    mcp tool => alpha => {
        title       => 'Alpha',
        description => 'First.',
        input       => { type => 'object', properties => { q => { type => 'string' } } },
        output      => { type => 'object', properties => { n => { type => 'integer' } } },
        annotations => { title => 'The alpha', readOnlyHint => 1, destructiveHint => 0 },
        icons       => [{ src => 'https://x.test/a.png', mimeType => 'image/png' }],
    } => 'T#a';
    mcp tool => 'mid.dle-1' => 'T#a';
};
my $pkg = 'T21::A';
my $t = mcp_app(sprintf($DECL, $pkg, $pkg), pkg => $pkg);

my (undef, $r, $raw) = list_tools($t, undef, '2025-11-25');
my @tools = @{ $r->{result}{tools} };
is_deeply([map { $_->{name} } @tools], ['alpha', 'mid.dle-1', 'zeta'],
    'sorted by name, whatever the declaration order');
ok(!exists $r->{result}{nextCursor}, 'one page, no cursor');

my ($a) = grep { $_->{name} eq 'alpha' } @tools;
is($a->{title}, 'Alpha', 'title');
is($a->{description}, 'First.', 'description');
is_deeply($a->{inputSchema}{properties}, { q => { type => 'string' } }, 'inputSchema as given');
is_deeply($a->{outputSchema}{properties}, { n => { type => 'integer' } }, 'outputSchema');
is_deeply($a->{icons}, [{ src => 'https://x.test/a.png', mimeType => 'image/png' }], 'icons');
is($a->{annotations}{title}, 'The alpha', 'annotation title');
ok(JSON::PP::is_bool($a->{annotations}{readOnlyHint}) && $a->{annotations}{readOnlyHint},
    'a true hint is a JSON true');
ok(JSON::PP::is_bool($a->{annotations}{destructiveHint}) && !$a->{annotations}{destructiveHint},
    'a false hint is a JSON false');

my ($z) = grep { $_->{name} eq 'zeta' } @tools;
is_deeply($z->{inputSchema}, { type => 'object' }, 'inputSchema defaults to an object');
ok(!exists $z->{$_}, "no $_ when not declared") for qw(title outputSchema annotations icons);

# ---- by version ---------------------------------------------------------------

(undef, $r) = list_tools($t, undef, '2025-06-18');
($a) = grep { $_->{name} eq 'alpha' } @{ $r->{result}{tools} };
ok(exists $a->{title} && exists $a->{outputSchema}, '2025-06-18 has title and outputSchema');
ok(!exists $a->{icons}, 'but no icons');

(undef, $r) = list_tools($t, undef, '2025-03-26');
($a) = grep { $_->{name} eq 'alpha' } @{ $r->{result}{tools} };
ok(!exists $a->{$_}, "2025-03-26 has no $_") for qw(title outputSchema icons);
ok(exists $a->{annotations}, 'but has annotations');

# ---- frozen ---------------------------------------------------------------------

my (undef, undef, $again) = list_tools($t, undef, '2025-11-25');
is($again, $raw, 'the bytes do not change between calls');

# ---- what a declaration may not be -------------------------------------------------

my $n = 0;
sub refused {
    my ($decl) = @_;
    my $p = 'T21::Bad' . ++$n;
    my $src = "package ${p}::Controller::T; sub a { 1 }\n"
            . "package $p; use Punk; use Punk::Plugin::MCP;\n"
            . "plugin 'MCP' => { session => 0 };\n$decl;\n1;\n";
    eval $src or return $@;
    eval { $p->to_app; 1 } or return $@;
    return '';
}

is(refused(q{mcp tool => ('x' x 128) => 'T#a'}), '', 'a 128-character name');
for my $case (
    [ q{mcp tool => ('x' x 129) => 'T#a'},
      qr/has a name that is not 1 to 128 of/, 'a 129-character name' ],
    [ q{mcp tool => 'two words' => 'T#a'},
      qr/mcp tool 'two words' has a name that is not/, 'a space in a name' ],
    [ q{mcp tool => x => { inputs => {} } => 'T#a'},
      qr/unknown mcp tool 'x' key 'inputs'/, 'an unknown key' ],
    [ q{mcp tool => x => { input => [] } => 'T#a'},
      qr/mcp tool 'x' input must be a JSON Schema hash/, 'input not a hash' ],
    [ q{mcp tool => x => { input => { type => 'array' } } => 'T#a'},
      qr/mcp tool 'x' input must have type 'object'/, 'input not an object schema' ],
    [ q{mcp tool => x => { output => { type => 'string' } } => 'T#a'},
      qr/mcp tool 'x' output must have type 'object'/, 'output not an object schema' ],
    [ q{mcp tool => x => { input => { type => 'object', '$ref' => 'https://nowhere.test/s' } } => 'T#a'},
      qr/mcp tool 'x' input does not compile: .*cannot resolve \$ref/,
      'a remote $ref is refused, not fetched' ],
    [ q{mcp tool => x => { annotations => { sideEffects => 1 } } => 'T#a'},
      qr/unknown tool annotation 'sideEffects'/, 'an unknown annotation' ],
    [ q{mcp tool => x => { annotations => { title => [] } } => 'T#a'},
      qr/annotation title must be a string/, 'an annotation title that is not text' ],
    [ q{mcp tool => x => { title => {} } => 'T#a'},
      qr/mcp tool 'x' title must be a string/, 'a title that is not text' ],
    [ q{mcp tool => x => { timeout => -1 } => 'T#a'},
      qr/timeout must be a number of seconds above 0/, 'a bad timeout' ],
    [ q{mcp tool => x => { icons => [{ src => 'ftp://x' }] } => 'T#a'},
      qr/an icon src must be an https or data: URI/, 'a bad icon' ],
    [ q{mcp tool => x => { guard => [] } => 'T#a'},
      qr/option 'guard' must be a guard/, 'a guard that is not one' ],
) {
    my ($decl, $want, $name) = @$case;
    like(refused($decl), $want, "$name croaks at to_app");
}

done_testing;
