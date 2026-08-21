#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use Punk;

# Parity harness for the XS tier: the C router must agree with the Perl
# reference on every case, and the C response builders must produce
# byte-identical triplets. Plus the leak gate: steady-state request
# loops may not grow RSS. There is no pure-Perl tier to skip for - the XS
# is loaded by Punk itself, so if it is not there nothing loads at all.

# ---- the XS router: the whole match path in C --------------------------------
{
    # one rec per add, indexed in add order; ANY expands to per-method static
    # triples but stays one rec
    my @routes = (
        [ GET  => '/books' ],               # 0 static
        [ POST => '/books' ],               # 1 static
        [ GET  => '/books/:id' ],           # 2 dynamic
        [ PUT  => '/books/:id' ],           # 3 dynamic
        [ GET  => '/books/:id/tags/:tag' ], # 4 dynamic
        [ GET  => '/files/*rest' ],         # 5 dynamic
        [ ANY  => '/health' ],              # 6 static (every method)
        [ GET  => '/:page' ],               # 7 dynamic
    );
    my $rt = Punk::Router->new;
    $rt->add(method => $_->[0], path => $_->[1], target => "t$_->[1]")
        for @routes;
    my $xs = $rt->compile(sub { $_[1] });   # compile returns the handle
    isa_ok($xs, 'Punk::Router', 'the C handle');

    # records() maps a match index back to its { code, guards, method, path }
    my $recs = $xs->records;
    is(scalar @$recs, scalar @routes, 'one record per route');
    is($recs->[2]{method}, 'GET',        'record carries its method');
    is($recs->[2]{path},   '/books/:id', 'and its path');
    is(ref $recs->[2]{guards}, 'ARRAY',  'and a guards arrayref');

    # static exact matches
    is($xs->match_static('GET',  '/books'),  0, 'static GET hit');
    is($xs->match_static('POST', '/books'),  1, 'static POST hit');
    is($xs->match_static('DELETE', '/books'), undef, 'static miss on method');
    is($xs->match_static('GET', '/nope'),    undef, 'static miss on path');
    is($xs->match_static('HEAD', '/books'),  0, 'HEAD falls back to GET');
    is($xs->match_static('PATCH', '/health'), 6, 'ANY static matches any method');

    # dynamic hits: (record index, \%captures)
    is_deeply([ $xs->match('GET', '/books/7') ], [ 2, { id => '7' } ],
        ':param capture');
    is_deeply([ $xs->match('PUT', '/books/7') ], [ 3, { id => '7' } ],
        'method selects the record');
    is_deeply([ $xs->match('GET', '/books/7/tags/new') ],
        [ 4, { id => '7', tag => 'new' } ], 'two captures');
    is_deeply([ $xs->match('GET', '/files/a/b/c.txt') ],
        [ 5, { rest => 'a/b/c.txt' } ], '*splat captures the remainder');
    is_deeply([ $xs->match('GET', '/about') ], [ 7, { page => 'about' } ],
        'single dynamic segment');
    is_deeply([ $xs->match('HEAD', '/books/9') ], [ 2, { id => '9' } ],
        'HEAD falls back to GET on dynamic routes');

    # 405: (undef, sorted \@allow) - static and dynamic methods merge
    is_deeply([ $xs->match('DELETE', '/books/7') ], [ undef, [ 'GET', 'PUT' ] ],
        '405 Allow from the dynamic records');
    is_deeply([ $xs->match('DELETE', '/books') ], [ undef, [ 'GET', 'POST' ] ],
        '405 Allow merges static and dynamic (GET via /:page too)');

    # 404: the empty list
    is_deeply([ $xs->match('GET', '/nope/at/all') ], [], 'no match is a 404');
    is_deeply([ $xs->match('GET', '/files/') ], [],
        '*splat needs a non-empty remainder');
    is($xs->match_static('GET', '/books/7'), undef,
        'a dynamic path is not a static hit');
}

# ---- response builder parity -------------------------------------------------
{
    package XsApp;
    use Punk;
    get '/t' => sub { $_[0]->text('hello') };
    get '/j' => sub { $_[0]->status(201)->header('X-A' => 1);
                      $_[0]->json({ a => [ 1, 'two' ] }) };
    get '/d' => sub { { plain => 'data' } };
    package main;

    my $app = XsApp->to_app;
    is_deeply(hit($app, path => '/t'),
        [ 200, [ 'Content-Type' => 'text/plain; charset=utf-8',
                 'Content-Length' => 5 ], ['hello'] ],
        'XS text triplet is byte-identical to the Perl shape');
    my $j = hit($app, path => '/j');
    is($j->[0], 201, 'XS json keeps the pending status');
    my %h = @{ $j->[1] };
    is($h{'X-A'}, 1, 'and the pending headers');
    is($h{'Content-Length'}, length $j->[2][0], 'CL matches the body');
    is($j->[2][0], '{"a":[1,"two"]}', 'frj-encoded body');
    is(hit($app, path => '/d')->[2][0], '{"plain":"data"}',
        'data coercion goes through the frj fast path');
}

# ---- request parser parity ---------------------------------------------------
{
    my $body = 'name=rex&tags=a&tags=b%20c&empty=&flag';
    open my $in, '<', \$body or die $!;
    my $req = Punk::Request->new({
        REQUEST_METHOD => 'POST',
        PATH_INFO      => '',
        QUERY_STRING   => 'q=x%2Fy;q=2&plus=a+b',
        CONTENT_TYPE   => 'application/x-www-form-urlencoded',
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        HTTP_USER_AGENT => 'punk',
        HTTP_COOKIE    => 'sid=a%20b; sid=second; theme=dark;  pad=x',
    });
    is($req->method, 'POST', 'method');
    is($req->path, '/', 'empty PATH_INFO is /');
    is($req->header('User-Agent'), 'punk', 'header via HTTP_');
    is($req->header('content-type'),
        'application/x-www-form-urlencoded', 'content-type special case');
    is($req->header('X-Nope'), undef, 'missing header undef');

    # headers: the same environment seen all at once, keyed lowercase and
    # dash-separated - the shape the OpenAPI validation path builds from the
    # same C helper (pq_headers).
    is_deeply($req->headers, {
        'user-agent'     => 'punk',
        'cookie'         => 'sid=a%20b; sid=second; theme=dark;  pad=x',
        'content-type'   => 'application/x-www-form-urlencoded',
        'content-length' => length $body,
    }, 'headers: HTTP_* lowercased and dashed, content-* folded in');
    is($req->headers->{'user-agent'}, $req->header('User-Agent'),
        'headers agrees with header()');
    isnt($req->headers, $req->headers, 'a fresh hashref each call');

    is_deeply($req->query, { q => [ 'x/y', 2 ], plus => 'a b' },
        'query: multi-value promotion, %XX and + decoding, ; separator');
    is_deeply($req->form,
        { name => 'rex', tags => [ 'a', 'b c' ], empty => '', flag => '' },
        'form: body parse with empty and bare keys');
    is($req->param('q')->[0], 'x/y', 'param reads query first');
    is($req->param('name'), 'rex', 'param falls back to form');
    is($req->param('nope'), undef, 'unknown param undef');
    is_deeply($req->params,
        { q => [ 'x/y', 2 ], plus => 'a b', name => 'rex',
          tags => [ 'a', 'b c' ], empty => '', flag => '' },
        'params merges with query winning');
    is_deeply($req->cookies,
        { sid => 'a b', theme => 'dark', pad => 'x' },
        'cookies: first value wins, value decoded, spaces eaten');
    is($req->cookie('sid'), 'a b', 'cookie accessor');
    is($req->query, $req->query, 'query cache returns the same hashref');

    # params(@keys): a slice in list context, a hashref of what is there
    # in scalar context - both by the precedence param() resolves with.
    my @vals = $req->params(qw(plus name nope));
    is_deeply(\@vals, [ 'a b', 'rex', undef ],
        'params(@keys) in list context is a slice, undef for a missing name');
    is_deeply(scalar $req->params(qw(plus name nope)),
        { plus => 'a b', name => 'rex' },
        'params(@keys) in scalar context leaves the missing name out');
    is_deeply({ %{ $req->params(qw(name nope)) } }, { name => 'rex' },
        'a deref block is scalar context, so %{ } is the filter hash');
    my @one = $req->params('name');
    is(scalar @one, 1, 'one value back per name asked for');
    is_deeply(scalar $req->params('q'), { q => [ 'x/y', 2 ] },
        'a repeated parameter keeps its arrayref through params(@keys)');
    is_deeply($req->params, {
        q => [ 'x/y', 2 ], plus => 'a b', name => 'rex',
        tags => [ 'a', 'b c' ], empty => '', flag => '' },
        'params with no names is still the whole merged hash');
}

# ---- leak gate ---------------------------------------------------------------
{
    package LeakApp;
    use Punk;
    get '/books/:id' => sub { { id => $_[0]->param('id') } };
    get '/t' => sub { $_[0]->text('x') };
    package main;

    my $app = LeakApp->to_app;
    my %dyn = (REQUEST_METHOD => 'GET', PATH_INFO => '/books/42',
               QUERY_STRING => '');
    my %txt = (REQUEST_METHOD => 'GET', PATH_INFO => '/t',
               QUERY_STRING => '');
    $app->({ %dyn }), $app->({ %txt }) for 1 .. 5000;
    my ($before) = `ps -o rss= -p $$` =~ /(\d+)/;
    for (1 .. 100_000) { $app->({ %dyn }); $app->({ %txt }) }
    my ($after) = `ps -o rss= -p $$` =~ /(\d+)/;
    my $growth = $after - $before;
    cmp_ok($growth, '<=', 512,
        "steady state grows <= 512KB over 200k requests (got ${growth}KB)");
}

done_testing();
