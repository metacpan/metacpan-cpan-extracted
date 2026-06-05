#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Encode qw(encode_utf8);

require_ok('Router::Ragel');

subtest 'match() before compile() croaks' => sub {
    my $router = Router::Ragel->new;
    $router->add('/x', 'data');
    eval { $router->match('/x') };
    like($@, qr/compile\(\) not called/, 'helpful error instead of segfault');
};

subtest 'compile() with no routes croaks' => sub {
    my $router = Router::Ragel->new;
    eval { $router->compile };
    like($@, qr/no routes added/, 'compile fails fast on empty router');
};

subtest 'all-static routes (max_captures == 0)' => sub {
    my $router = Router::Ragel->new;
    $router->add('/a', 'A');
    $router->add('/a/b', 'AB');
    $router->add('/a/b/c', 'ABC');
    ok($router->compile, 'compiles cleanly with no placeholders');

    is(($router->match('/a'))[0], 'A', '/a');
    is(($router->match('/a/b'))[0], 'AB', '/a/b');
    is(($router->match('/a/b/c'))[0], 'ABC', '/a/b/c');
    is(scalar $router->match('/a/b'), 'AB', 'static route returns single value');
    is_deeply([$router->match('/none')], [], 'no match returns empty list');
};

subtest 'backslash in pattern is correctly escaped' => sub {
    my $router = Router::Ragel->new;
    $router->add('/path/with\\backslash', 'bs_data');
    $router->add('/path/:id/end', 'cap_data');
    ok($router->compile, 'compile accepts backslash in literal segment');

    my @r = $router->match('/path/with\\backslash');
    is($r[0], 'bs_data', 'literal backslash matches');

    my @c = $router->match('/path/42/end');
    is_deeply(\@c, ['cap_data', '42'], 'capture still works alongside backslash route');
};

subtest 'add() after compile() invalidates and forces recompile' => sub {
    my $router = Router::Ragel->new;
    $router->add('/a', 'A');
    $router->compile;
    is(($router->match('/a'))[0], 'A', 'matches before second add');

    $router->add('/b', 'B');
    eval { $router->match('/a') };
    like($@, qr/compile\(\) not called/, 'add() invalidated compiled state');

    $router->compile;
    is(($router->match('/a'))[0], 'A', 'old route still matches after recompile');
    is(($router->match('/b'))[0], 'B', 'new route matches after recompile');
};

subtest 'slashes match exactly (no collapsing)' => sub {
    my $router = Router::Ragel->new;
    $router->add('/users/:id', 'user');
    $router->compile;

    is(($router->match('/users/42'))[0], 'user', 'single slash matches');
    is_deeply([$router->match('//users/42')], [], 'leading double slash does not match');
    is_deeply([$router->match('/users//42')], [], 'middle double slash does not match');
    is_deeply([$router->match('/users/42/')], [], 'trailing slash does not match');
};

subtest 'malformed patterns croak at compile time' => sub {
    my $r1 = Router::Ragel->new;
    $r1->add('/foo/:', 'data');
    eval { $r1->compile };
    like($@, qr/empty placeholder name/, 'bare colon rejected');

    my $r2 = Router::Ragel->new;
    $r2->add("/foo/\0/bar", 'data');
    eval { $r2->compile };
    like($@, qr/NUL byte/, 'NUL byte in pattern rejected');
};

subtest 'list-context [0] returns route data' => sub {
    my $router = Router::Ragel->new;
    $router->add('/users/:id', 'user_detail');
    $router->compile;

    my $first = ($router->match('/users/42'))[0];
    is($first, 'user_detail', 'first list element is the route data');
};

subtest 'function-form call' => sub {
    my $router = Router::Ragel->new;
    $router->add('/users/:id', 'user');
    $router->compile;

    my @r = Router::Ragel::match($router, '/users/7');
    is_deeply(\@r, ['user', '7'], 'Router::Ragel::match() works as a function');
};

subtest 'shared route data across patterns' => sub {
    my $shared = { tag => 'shared' };
    my $router = Router::Ragel->new;
    $router->add('/a/:x', $shared);
    $router->add('/b/:x', $shared);
    $router->compile;

    my @r1 = $router->match('/a/1');
    my @r2 = $router->match('/b/2');
    is($r1[0], $shared, 'same hashref returned from /a');
    is($r2[0], $shared, 'same hashref returned from /b');
};

subtest 'chained add()/compile() returns $self' => sub {
    my $router = Router::Ragel->new->add('/a','A')->add('/b','B')->compile;
    isa_ok($router, 'Router::Ragel', 'chain returned the router');
    is(($router->match('/a'))[0], 'A', '/a matched after chain');
    is(($router->match('/b'))[0], 'B', '/b matched after chain');
};

subtest 'malformed patterns at compile time' => sub {
    my $r1 = Router::Ragel->new->add('', 'data');
    eval { $r1->compile };
    like($@, qr/empty pattern/, 'empty pattern rejected');

    my $r2 = Router::Ragel->new->add('users/:id', 'data');
    eval { $r2->compile };
    like($@, qr{must start with '/'}, 'pattern without leading / rejected');

    my $r3 = Router::Ragel->new;
    $r3->add(undef, 'data');
    eval { $r3->compile };
    like($@, qr/empty pattern/, 'undef pattern rejected');

    my $r4 = Router::Ragel->new->add('/foo//bar', 'data');
    eval { $r4->compile };
    like($@, qr/consecutive slashes/, 'consecutive slashes rejected');

    my $r5 = Router::Ragel->new->add('//foo', 'data');
    eval { $r5->compile };
    like($@, qr/consecutive slashes/, 'leading double slash rejected');
};

subtest 'one-arg add() stores undef data' => sub {
    my $router = Router::Ragel->new;
    $router->add('/x');
    $router->compile;
    my @r = $router->match('/x');
    is(scalar @r, 1, 'one-arg add stores route returning a single element');
    is($r[0], undef, 'route data is undef');
};

subtest 'root route /' => sub {
    my $router = Router::Ragel->new->add('/', 'root')->compile;
    is(($router->match('/'))[0], 'root', '/ matches /');
    is_deeply([$router->match('')], [], '/ does not match empty string');
    is_deeply([$router->match('/x')], [], '/ does not match /x');
    is_deeply([$router->match('//')], [], '/ does not match //');
};

subtest 'typed placeholders' => sub {
    my $r = Router::Ragel->new
        ->add('/u/:id<int>', 'int')
        ->add('/h/:hash<hex>', 'hex')
        ->add('/s/:s<string>', 'string')
        ->compile;

    is_deeply([$r->match('/u/42')], ['int', '42'], ':id<int> matches digits');
    is_deeply([$r->match('/u/4a')], [], ':id<int> rejects non-digits');
    is_deeply([$r->match('/u/')], [], ':id<int> rejects empty');

    is_deeply([$r->match('/h/deadBEEF')], ['hex', 'deadBEEF'], ':hash<hex> matches both cases');
    is_deeply([$r->match('/h/zz')], [], ':hash<hex> rejects non-hex');

    is_deeply([$r->match('/s/anything-here')], ['string', 'anything-here'], ':s<string> matches non-slash');
};

subtest 'inline placeholders within segments' => sub {
    my $r = Router::Ragel->new
        ->add('/path/to_:type<string>/id_:id<int>/whatever', 'inline')
        ->compile;

    my @r = $r->match('/path/to_user/id_42/whatever');
    is_deeply(\@r, ['inline', 'user', '42'], 'inline placeholders capture correctly');

    is_deeply([$r->match('/path/to_user/id_xx/whatever')], [], ':id<int> rejects non-digits in inline form');
    is_deeply([$r->match('/path/to_/id_42/whatever')], [], ':type<string> rejects empty');
};

subtest 'multiple placeholders in one segment' => sub {
    my $r = Router::Ragel->new
        ->add('/v/:major<int>.:minor<int>.:patch<int>', 'ver')
        ->compile;

    is_deeply([$r->match('/v/1.2.3')], ['ver', '1', '2', '3'], 'dot-separated triple');
    is_deeply([$r->match('/v/1.2')], [], 'missing component');
    is_deeply([$r->match('/v/1.2.foo')], [], 'non-int component rejected');
};

subtest 'raw regex constraint' => sub {
    my $r = Router::Ragel->new
        ->add('/code/:c<[0-9]{4}>', 'code')
        ->add('/slug/:s<[a-z0-9\-]+>', 'slug')
        ->compile;

    is_deeply([$r->match('/code/1234')], ['code', '1234'], 'exact-4-digits matches');
    is_deeply([$r->match('/code/123')], [], 'too short');
    is_deeply([$r->match('/code/12345')], [], 'too long');
    is_deeply([$r->match('/code/12ab')], [], 'non-digit');

    is_deeply([$r->match('/slug/foo-bar-42')], ['slug', 'foo-bar-42'], 'escaped \\- accepts dashes');
    is_deeply([$r->match('/slug/Foo')], [], 'rejects uppercase');
};

subtest 'unterminated <type> croaks' => sub {
    my $r = Router::Ragel->new->add('/x/:id<int', 'data');
    eval { $r->compile };
    like($@, qr/unterminated '<'/, 'unclosed type bracket rejected');
};

subtest 'empty <> croaks' => sub {
    for my $bad ('/x/:id<>', '/x/:id< >', "/x/:id<\t>") {
        my $r = Router::Ragel->new->add($bad, 'data');
        eval { $r->compile };
        like($@, qr/empty type expression/, "empty type rejected: $bad");
    }
};

subtest 'whitespace in <type> is trimmed' => sub {
    my $r = Router::Ragel->new->add('/x/:id< int >', 'data')->compile;
    is_deeply([$r->match('/x/42')], ['data', '42'], '< int > works as <int>');
    is_deeply([$r->match('/x/4a')], [], '< int > still rejects non-digits');
};

subtest 'nested < inside <type> croaks' => sub {
    my $r = Router::Ragel->new->add('/x/:id<<int>>', 'data');
    eval { $r->compile };
    like($@, qr/'<' is not allowed/, 'nested < rejected at compile time');
};

subtest 'trailing slash is a distinct route' => sub {
    my $router = Router::Ragel->new
        ->add('/x', 'no_slash')
        ->add('/x/', 'with_slash')
        ->compile;
    is(($router->match('/x'))[0], 'no_slash', '/x matches /x exactly');
    is(($router->match('/x/'))[0], 'with_slash', '/x/ matches /x/ exactly');

    my $only_trailing = Router::Ragel->new->add('/y/', 'y_slash')->compile;
    is_deeply([$only_trailing->match('/y')], [], '/y does not match /y/');
    is(($only_trailing->match('/y/'))[0], 'y_slash', '/y/ matches /y/');
};

subtest 'literal suffix after <type> within a segment' => sub {
    # The POD's motivating case for the greedy-name-then-type design:
    # ':name<type>suffix' is the placeholder followed by a literal.
    my $r = Router::Ragel->new
        ->add('/:name<string>_extra', 'suf')
        ->add('/:x<int>px', 'int_suf')
        ->compile;

    is_deeply([$r->match('/hello_extra')], ['suf', 'hello'],
        ':name<string>_extra captures the name and matches the literal suffix');
    is_deeply([$r->match('/hello_wrong')], [], 'wrong suffix does not match');
    is_deeply([$r->match('/_extra')], [],
        'string placeholder needs at least one char before the suffix');
    is_deeply([$r->match('/42px')], ['int_suf', '42'],
        ':x<int>px captures digits and matches the literal suffix');
    is_deeply([$r->match('/42')], [], 'missing literal suffix fails to match');
};

subtest 'utf8-flagged (wide) path matched as UTF-8 bytes' => sub {
    my $r = Router::Ragel->new
        ->add(encode_utf8("/caf\x{e9}"), 'cafe')
        ->add(encode_utf8('/x/:p'), 'cap')
        ->compile;

    my $wide = "/caf\x{e9}";
    utf8::upgrade($wide); # force the utf8 flag on
    is_deeply([$r->match($wide)], ['cafe'],
        'wide path matches the byte pattern via its UTF-8 representation');

    my $wcap = "/x/caf\x{e9}";
    utf8::upgrade($wcap);
    my @c = $r->match($wcap);
    is($c[0], 'cap', 'wide path with a capture matches');
    is($c[1], encode_utf8("caf\x{e9}"), 'capture returns the raw UTF-8 bytes');
    ok(!utf8::is_utf8($c[1]), 'captured value is a byte string (utf8 flag off)');
};

subtest 'match() without a router object croaks instead of crashing' => sub {
    eval { Router::Ragel::match('not a router', '/x') };
    like($@, qr/requires a router object/, 'non-reference self croaks');

    eval { Router::Ragel->match('/x') };
    like($@, qr/requires a router object/, 'class-method call (forgot ->new) croaks');

    my $r = Router::Ragel->new->add('/x', 'd')->compile;
    eval { Router::Ragel::match('/x', $r) };
    like($@, qr/requires a router object/, 'swapped arguments (path first) croaks');
};

subtest 'Ragel metacharacters in literal segments match literally' => sub {
    # Only ' and \ are escaped for Ragel string literals (covered in t/01 and
    # the backslash subtest above). Every other metacharacter -- including
    # '#', Ragel's comment introducer -- must pass through and match itself
    # rather than act as grammar.
    my $lit = 'a#b%c{d}e<f>g|h*i+j(k)l[m]n.o&p=q@r~s^t$u';
    my $r = Router::Ragel->new->add("/lit/$lit/end", 'special')->compile;
    is(($r->match("/lit/$lit/end"))[0], 'special',
        'segment full of metacharacters matches itself');
    is_deeply([$r->match('/lit/aXb/end')], [],
        'a different literal in that segment does not match');
};

subtest 'zero-width capture from a *-quantified custom type' => sub {
    # The capture arrays are left uninitialized; the read-back is safe because
    # every capture action of the matched route has fired. A type matching zero
    # bytes still fires both start and end, yielding '' rather than a stale read.
    my $r = Router::Ragel->new->add('/z/:p<[a-z]*>', 'zw')->compile;
    my @e = $r->match('/z/');
    is($e[0], 'zw', 'route with an empty capture still matches');
    is($e[1], '', '...and returns an empty string, not a stale value');
    is_deeply([$r->match('/z/abc')], ['zw', 'abc'], 'non-empty capture works too');
};

done_testing;
