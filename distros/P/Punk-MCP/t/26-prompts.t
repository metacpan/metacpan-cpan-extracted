#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPApp;

my $pkg = 'T26::A';
my $t = mcp_app(qq{
    package ${pkg}::Controller::P;
    sub summarize { my (\$c) = \@_; 'Summarise book ' . \$c->param('id') . ' in ' . (\$c->param('style') // 'prose') }
    sub chat      { [ { role => 'user', content => 'hi' },
                      { role => 'assistant', content => { type => 'text', text => 'hello' } } ] }
    sub shaped    { { description => 'Mine.', messages => [{ role => 'user', content => 'x' }] } }
    sub one       { { role => 'assistant', content => 'only me' } }
    sub system    { [{ role => 'system', content => 'nope' }] }
    sub empty     { [{ role => 'user' }] }
    sub nothing   { return }
    sub dies      { die "no prompt today\\n" }
    sub via_text  { \$_[0]->text('from a response') }
    sub via_404   { \$_[0]->text('gone', 404) }
    sub later     { Punk::Future->done_future('later words') }
    sub meta      { my (\$c) = \@_; \$c->mcp->method . ' ' . \$c->mcp->name }
    package $pkg;
    our \$NO = sub { [403, [], ['no']] };
    plugin 'MCP' => { session => 0 };
    mcp prompt => summarize => {
        title => 'Summarise', description => 'Summarise one book.',
        arguments => [ { name => 'id', description => 'The book.', required => 1 },
                       { name => 'style' } ],
        icons => [{ src => 'https://x.test/p.png' }],
    } => 'P#summarize';
    mcp prompt => \$_ => 'P#' . \$_
        for qw(chat shaped one system empty nothing dies via_text via_404 later meta);
    mcp prompt => secret => { guard => \$NO } => 'P#chat';
}, pkg => $pkg);

sub get { my (undef, $r) = rpc_msg($t, 'prompts/get', { name => $_[0], arguments => $_[1] // {} }, $_[2]); $r }

# ---- the list --------------------------------------------------------------------

my ($items) = list_all($t, 'prompts/list', 'prompts');
is_deeply([map { $_->{name} } @$items], [sort map { $_->{name} } @$items], 'sorted by name');
ok(!grep({ $_->{name} eq 'secret' } @$items), 'a refusing guard hides one');
my ($s) = grep { $_->{name} eq 'summarize' } @$items;
is_deeply($s, {
    name => 'summarize', title => 'Summarise', description => 'Summarise one book.',
    arguments => [ { name => 'id', description => 'The book.', required => JSON::PP::true },
                   { name => 'style', required => JSON::PP::false } ],
    icons => [{ src => 'https://x.test/p.png' }],
}, 'every field, required as a boolean');
($items) = list_all($t, 'prompts/list', 'prompts', '2025-03-26');
($s) = grep { $_->{name} eq 'summarize' } @$items;
ok(!exists $s->{$_}, "2025-03-26 has no $_") for qw(title icons);

# ---- getting ------------------------------------------------------------------------

my $r = get('summarize', { id => '7', style => 'verse' })->{result};
is($r->{description}, 'Summarise one book.', "the prompt's description");
is_deeply($r->{messages}, [{ role => 'user',
    content => { type => 'text', text => 'Summarise book 7 in verse' } }],
    'a string is one user message, and the arguments are params');

is_deeply(get('chat')->{result}{messages}, [
    { role => 'user',      content => { type => 'text', text => 'hi' } },
    { role => 'assistant', content => { type => 'text', text => 'hello' } },
], 'a list of messages, text content wrapped and blocks kept');
$r = get('shaped')->{result};
is($r->{description}, 'Mine.', 'a hash with messages brings its own description');
is($r->{messages}[0]{content}{text}, 'x', 'and its messages');
is_deeply(get('one')->{result}{messages},
    [{ role => 'assistant', content => { type => 'text', text => 'only me' } }],
    'one message hash');
is(get('via_text')->{result}{messages}[0]{content}{text}, 'from a response',
    "a triplet's body is the message");
is(get('later')->{result}{messages}[0]{content}{text}, 'later words', 'a Future is awaited');
is(get('meta')->{result}{messages}[0]{content}{text}, 'prompts/get meta',
    '$c->mcp names the method and the prompt');

# ---- refusals ----------------------------------------------------------------------

for my $case (
    [ 'summarize', {},                    -32602, 'a required argument is missing', 'id' ],
    [ 'summarize', { id => [1] },         -32602, 'prompt arguments must be strings', 'id' ],
    [ 'summarize', { id => undef },       -32602, 'prompt arguments must be strings', 'id' ],
    [ 'nope',      {},                    -32602, 'unknown prompt' ],
    [ 'secret',    {},                    -32602, 'unknown prompt' ],
    [ 'system',    {},                    -32603, 'a prompt message has a role that is not user or assistant' ],
    [ 'empty',     {},                    -32603, 'a prompt message has no content' ],
    [ 'nothing',   {},                    -32603, 'the prompt returned nothing' ],
    [ 'dies',      {},                    -32603, 'the prompt failed' ],
    [ 'via_404',   {},                    -32603, 'the prompt failed' ],
) {
    my ($name, $args, $code, $msg, $arg) = @$case;
    $r = get($name, $args);
    is($r->{error}{code}, $code, "$name: $code");
    is($r->{error}{message}, $msg, "$name: $msg");
    is($r->{error}{data}{argument}, $arg, "$name: names the argument") if $arg;
}
is(get('dies')->{error}{data}{reason}, 'no prompt today', 'a die gives its reason');
is(get('via_404')->{error}{data}{status}, 404, 'a 4xx gives its status');

(undef, $r) = rpc_msg($t, 'prompts/get', {});
is($r->{error}{message}, 'a prompt name is required', 'no name is -32602');
(undef, $r) = rpc_msg($t, 'prompts/get', { name => 'chat', arguments => [] });
is($r->{error}{message}, 'arguments must be an object', 'arguments must be an object');

# ---- declarations that are refused -------------------------------------------------------

my $n = 0;
sub refused {
    my ($decl) = @_;
    my $p = 'T26::Bad' . ++$n;
    my $src = "package ${p}::Controller::P; sub a { 1 }\n"
            . "package $p; use Punk; use Punk::Plugin::MCP;\n"
            . "plugin 'MCP' => { session => 0 };\n$decl;\n1;\n";
    eval $src or return $@;
    eval { $p->to_app; 1 } or return $@;
    return '';
}
for my $case (
    [ q{mcp prompt => x => { arguments => {} } => 'P#a'}, qr/arguments must be a list/ ],
    [ q{mcp prompt => x => { arguments => [{ description => 'd' }] } => 'P#a'},
      qr/has an argument with no name/ ],
    [ q{mcp prompt => x => { arguments => [{ name => 'a' }, { name => 'a' }] } => 'P#a'},
      qr/names the argument 'a' twice/ ],
    [ q{mcp prompt => x => { arguments => [{ name => 'a', optional => 1 }] } => 'P#a'},
      qr/unknown mcp prompt 'x' argument key 'optional'/ ],
    [ q{mcp prompt => x => { messages => [] } => 'P#a'}, qr/unknown mcp prompt 'x' key 'messages'/ ],
) {
    my ($decl, $want) = @$case;
    like(refused($decl), $want, "refused: $decl");
}

done_testing;
