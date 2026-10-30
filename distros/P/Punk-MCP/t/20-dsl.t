#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Punk::Plugin::MCP ();

# An application, compiled from source so `use Punk::Plugin::MCP` installs the
# keyword at its compile time, as it would in a real one.
my $n = 0;
sub app {
    my ($body, %o) = @_;
    my $pkg = $o{pkg} || ('T20::App' . ++$n);
    my $src = "package ${pkg}::Controller::Books;\n"
            . "sub search { 's' } sub one { 'o' } sub sum { 'p' }\n"
            . "package $pkg;\nuse Punk;\n"
            . ($o{no_use} ? '' : "use Punk::Plugin::MCP;\n")
            . "$body;\n1;\n";
    eval $src or return (undef, $@);
    return ($pkg, '');
}
sub compiled {
    my ($body, %o) = @_;
    my ($pkg, $err) = app($body, %o);
    return (undef, $err) unless $pkg;
    eval { $pkg->to_app; 1 } or return (undef, $@);
    return ($pkg, '');
}
sub state_of { Punk::Plugin::MCP->state_for($_[0]) }

# ---- the two forms ------------------------------------------------------------------

my ($pkg, $err) = compiled(q{
    plugin 'MCP' => { session => 0 };
    mcp tool => search => { description => 'Search.' } => 'Books#search';
    mcp(tool => lookup => { description => 'Look up.' } => 'Books#one');
    mcp resource => 'books://{id}' => 'Books#one';
    mcp prompt => summarize => sub { 'p' };
});
ok($pkg, 'an application with the DSL compiles') or diag($err);
my $s = state_of($pkg);
is_deeply($s->{tools}, [qw(search lookup)], 'the bareword and parenthesised forms');
is_deeply($s->{resources}, ['books://{id}'], 'a resource');
is_deeply($s->{prompts}, ['summarize'], 'a prompt, with the spec left out');
is($s->{registered}, 1, 'registered');
is($s->{frozen}, 1, 'frozen at to_app');
is(scalar(grep { ref $_->{target} eq 'CODE' } @{ $s->{declarations} }), 4,
    "every target resolved to code, 'Controller#method' or not");
is($s->{declarations}[0]{target}, \&{"${pkg}::Controller::Books::search"},
    'to the action the string names');
is_deeply($s->{declarations}[0]{spec}, { description => 'Search.' },
    'the spec is kept as given');
is_deeply($s->{declarations}[3]{spec}, {}, 'and is empty when left out');
is_deeply($s->{server}, { tools => 1, resources => 1, prompts => 1,
                          logging => 0, can_notify => 0 },
    'the frozen server knows what was declared');

# Declarations may come before the plugin line.
($pkg, $err) = compiled(q{
    mcp tool => early => 'Books#search';
    plugin 'MCP' => { session => 0 };
});
is_deeply(state_of($pkg)->{tools}, ['early'], 'a declaration above the plugin line');

# The plugin without `use`: register installs the keyword, and the parenthesised
# form finds it at runtime.
($pkg, $err) = compiled(q{
    plugin 'MCP' => { session => 0 };
    mcp(tool => late => 'Books#search');
}, no_use => 1);
is_deeply($pkg ? state_of($pkg)->{tools} : $err, ['late'],
    'plugin without use, then the parenthesised form');

# ---- what the keyword refuses ----------------------------------------------------------

for my $case (
    [ q{mcp widget => x => 'Books#search'},
      qr/mcp takes tool, resource or prompt, not 'widget'/, 'an unknown kind' ],
    [ q{mcp tool => '' => 'Books#search'},
      qr/mcp tool needs a name/, 'a tool with no name' ],
    [ q{mcp resource => undef, 'Books#one'},
      qr/mcp resource needs a URI/, 'a resource with no URI' ],
    [ q{mcp tool => x => [] => 'Books#search'},
      qr/mcp tool 'x' takes its description as a hash/, 'a spec that is not a hash' ],
    [ q{mcp tool => x => {} => {}},
      qr/mcp tool 'x' needs a code ref or a 'Controller#method' target/, 'a target that is not one' ],
    [ q{mcp tool => 'x'},
      qr/mcp takes KIND => KEY => \{spec\} => TARGET/, 'too few arguments' ],
    [ q{mcp tool => x => 'Books#search'; mcp tool => x => 'Books#one'},
      qr/mcp tool 'x' is declared twice/, 'a name declared twice' ],
) {
    my ($body, $want, $name) = @$case;
    (undef, $err) = app("plugin 'MCP' => { session => 0 }; $body");
    like($err, $want, "$name croaks");
}
(undef, $err) = app(q{
    plugin 'MCP' => { session => 0 };
    mcp tool => x => 'Books#search';
    mcp resource => x => 'Books#one';
});
is($err, '', 'the same key under two kinds is fine');

# ---- the tripwire ----------------------------------------------------------------

(undef, $err) = compiled(q{ mcp tool => x => 'Books#search' });
like($err, qr/mcp was used but plugin 'MCP' was never registered/,
    'mcp used and the plugin never registered croaks at to_app');

(undef, $err) = compiled(q{ plugin 'MCP' => { session => 0 } });
like($err, qr/plugin 'MCP' is registered but nothing is declared/,
    'the plugin registered with nothing declared croaks at to_app');

(undef, $err) = compiled(q{ plugin 'MCP' => { session => 0, openapi => 'api' } });
like($err, qr/openapi 'api' names no api mount/,
    'openapi passes the nothing-declared tripwire, and naming no mount croaks (t/50 has real ones)');

($pkg, $err) = compiled(q{ get '/' => sub { 'home' } });
ok($pkg, 'use Punk::Plugin::MCP with no mcp and no plugin is silent');

(undef, $err) = app(q{
    plugin 'MCP' => { session => 0 };
    plugin 'MCP' => { session => 0 };
});
like($err, qr/plugin 'MCP' is registered twice/, 'registering twice croaks');

(undef, $err) = compiled(q{
    plugin 'MCP' => { session => 0 };
    mcp tool => x => 'Books#missing';
});
like($err, qr/missing/, 'a target that does not resolve croaks at to_app');

($pkg, $err) = compiled(q{
    plugin 'MCP' => { session => 0 };
    mcp tool => x => 'Books#search';
});
eval { $pkg->punk_app->plugin('Nothing') if 0;
       my $kw = $pkg->can('mcp'); $kw->(tool => y => 'Books#one') };
like($@, qr/mcp tool 'y' is declared after to_app/, 'a declaration after to_app croaks');

# ---- the one route ----------------------------------------------------------

($pkg, $err) = compiled(q{
    plugin 'MCP' => { session => 0 };
    mcp tool => x => 'Books#search';
    get '/home' => sub { 'home' };
});
my @routes = sort map { "$_->{method} $_->{path}" } @{ $pkg->punk_app->{router}->records };
is_deeply(\@routes, ['GET /home', 'POST /mcp'], 'the plugin adds one route, POST on its path');

# ---- separate applications ------------------------------------------------------------

my ($one) = compiled(q{
    plugin 'MCP' => { session => 0, title => 'One' };
    mcp tool => alpha => 'Books#search';
});
my ($two) = compiled(q{
    plugin 'MCP' => { session => 0, title => 'Two' };
    mcp tool => beta => 'Books#search';
    mcp prompt => gamma => 'Books#sum';
});
is_deeply(state_of($one)->{tools}, ['alpha'], 'two apps: the first keeps its own');
is_deeply(state_of($two)->{tools}, ['beta'], 'two apps: the second keeps its own');
is(state_of($one)->{opts}{title}, 'One', 'and its own options');
is(state_of($two)->{server}{prompts}, 1, 'and its own frozen server');
is(state_of($one)->{server}{prompts}, 0, 'which the other does not share');

# ---- state_for -------------------------------------------------------------------------

($pkg) = compiled(q{ get '/' => sub { 'x' } }, no_use => 1);
ok(!defined state_of($pkg), 'state_for a Punk app with no MCP is undef');
($pkg) = compiled(q{ get '/' => sub { 'x' } });
is(state_of($pkg)->{registered}, 0,
    'one that uses the plugin and never registers it says so');
ok(!defined state_of('No::Such::Class'), 'state_for something else is undef');
my $view = state_of($one);
$view->{opts}{title} = 'Changed';
is(state_of($one)->{opts}{title}, 'One', 'state_for hands back a copy');

# ---- the frozen server answers ------------------------------------------------------------

my ($status, $bytes) = Punk::Plugin::MCP::_dispatch_app($two,
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}');
like($bytes, qr/"capabilities":\{"prompts":\{\},"tools":\{\}\}/,
    'initialize answers from the frozen declarations');
like($bytes, qr/"serverInfo":\{"name":"T20::App\d+","title":"Two","version":"0"\}/,
    'with the options it was given');

done_testing;
