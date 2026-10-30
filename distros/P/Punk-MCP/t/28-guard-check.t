#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Punk::Plugin::MCP ();

# P4: a declaration whose action sits behind a guarded route must say how it
# is guarded, because MCP calls the action directly and would skip the guard.

my $n = 0;
sub compiled {
    my ($body) = @_;
    my $pkg = 'T28::App' . ++$n;
    my $src = "package ${pkg}::Controller::Books;\n"
            . "sub list { 'l' } sub remove { 'r' } sub deep { 'd' } sub open { 'o' }\n"
            . "package $pkg;\nuse Punk;\nuse Punk::Plugin::MCP;\n"
            . "our \$G = sub { return };\n"
            . "plugin 'MCP' => { session => 0 };\n$body\n1;\n";
    eval $src or return $@;
    eval { $pkg->to_app; 1 } or return $@;
    return '';
}

is(compiled(q{
    get '/books' => 'Books#list';
    mcp tool => list => 'Books#list';
}), '', 'an action on an unguarded route needs nothing');

like(compiled(q{
    __PACKAGE__->punk_app->route('DELETE', '/books/:id', 'Books#remove', [$G]);
    mcp tool => remove => 'Books#remove';
}), qr/mcp tool 'remove' runs the action that DELETE \/books\/:id guards, and a call through MCP would skip that guard\. Give it `guard => \.\.\.`, or `guard => 'none'`/,
    'an action behind a guarded route croaks, naming the declaration and the route');

my $under = q{
    my $s = under '/admin' => $G;
    $s->del('/books/:id' => 'Books#remove');
};
like(compiled($under . q{ mcp tool => remove => 'Books#remove'; }),
    qr/runs the action that DELETE \/admin\/books\/:id guards/,
    "an under scope's guard counts");

like(compiled(q{
    my $s = under '/admin' => $G;
    my $d = $s->under('/deep');
    $d->get('/x' => 'Books#deep');
    mcp resource => 'books://deep' => 'Books#deep';
}), qr/mcp resource 'books:\/\/deep' runs the action that GET \/admin\/deep\/x guards/,
    "a nested scope's guard counts, and for a resource");

like(compiled($under . q{
    get '/books/remove' => 'Books#remove';
    mcp prompt => remove => 'Books#remove';
}), qr/mcp prompt 'remove' runs the action/,
    'one guarded route among unguarded ones is enough');

is(compiled($under . q{ mcp tool => remove => { guard => $G } => 'Books#remove'; }),
    '', 'a declaration with its own guard passes');
is(compiled($under . q{ mcp tool => remove => { guard => 'none' } => 'Books#remove'; }),
    '', "guard => 'none' is the explicit opt-out");

like(compiled(q{
    my $code = sub { 'shared' };
    my $s = under '/admin' => $G;
    $s->get('/c' => $code);
    mcp tool => shared => $code;
}), qr/mcp tool 'shared' runs the action that GET \/admin\/c guards/,
    'a code ref target is matched by identity too');

is(compiled(q{
    my $s = under '/admin' => $G;
    $s->get('/c' => sub { 'one' });
    mcp tool => other => sub { 'two' };
}), '', 'a different code ref on a guarded route is not confused with it');

is(compiled(q{
    under '/admin' => $G;
    mcp tool => open => 'Books#open';
}), '', 'an action that no route reaches needs nothing');

done_testing;
