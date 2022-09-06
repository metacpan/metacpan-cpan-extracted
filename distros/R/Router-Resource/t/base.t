use strict; use warnings;

use Router::Resource;
use Test::More tests => 72;

can_ok 'Router::Resource', qw(
    new
    router
    resource
    missing
    dispatch
    match
    GET
    HEAD
    POST
    PUT
    DELETE
    OPTIONS
    TRACE
    CONNECT
    PATCH
);

my $reqmeth = 'GET';

ok my $router = router {
    resource '/' => sub {
        GET {
            is_deeply shift, { REQUEST_METHOD => $reqmeth, PATH_INFO => '/' },
                'Method first arg should be request env';
            is_deeply shift, {},
                'Method second arg should be the route hash';
            return 'get /'
        };
        PUT { 'put /' };
    };

    resource '/wiki/:page' => sub {
        GET {
            is_deeply shift, { REQUEST_METHOD => 'GET', PATH_INFO => '/wiki/Theory' },
                'Method first arg should be request env';
            is_deeply shift, { page => 'Theory' },
                'Method second arg should be the route hash';
            return 'get /wiki/:page'
        };

        POST {
            is_deeply shift, { REQUEST_METHOD => 'POST', PATH_INFO => '/wiki/Theory' },
                'Method first arg should be request env';
            is_deeply shift, { page => 'Theory' },
                'Method second arg should be the route hash';
            return 'post /wiki/:page'
        };
    };

    resource '/foo' => sub {
        GET     { 'get /foo'     };
        HEAD    { 'head /foo'    };
        POST    { 'post /foo'    };
        PUT     { 'put /foo'     };
        DELETE  { 'delete /foo'  };
        OPTIONS { 'options /foo' };
        GET     { 'get /foo'     };
        TRACE   { 'trace /foo'   };
        CONNECT { 'connect /foo' };
        PATCH   { 'patch /foo'   };
    };
};

isa_ok $router, 'Router::Resource', 'it';

ok my $res = $router->dispatch({
    REQUEST_METHOD => "GET",
    PATH_INFO => "/",
}), 'Should dispatch GET /';

is $res, 'get /', 'And it should be the correct code ref';

ok my $match = $router->match({
    REQUEST_METHOD => "GET",
    PATH_INFO => "/",
}), 'Should Match GET /';

isa_ok $match, 'HASH', 'Should get a hash ref from match()';
is $match->{code}, 200, 'Code should be 200';
isa_ok $match->{meth}, 'CODE', 'The method';
is_deeply $match->{data}, {}, 'Data should be a hash ref';
is $match->{meth}->({REQUEST_METHOD => 'GET', PATH_INFO => '/'}, {}),
    'get /', 'The method code ref should be right';

$reqmeth = 'HEAD';
ok $res = $router->dispatch({
    REQUEST_METHOD => "HEAD",
    PATH_INFO => "/",
}), 'Should dispatch HEAD /';

is $res, 'get /', 'And it should be the correct result';

# Try a non-match.
ok $res = $router->dispatch({
    PATH_INFO => '/nonesuch',
    REQUEST_METHOD => 'GET',
}), 'Dispatch unknown path';
is_deeply $res, [404, [], ['not found']], 'Should get default 404 response';

ok $match = $router->match({
    PATH_INFO => '/nonesuch',
    REQUEST_METHOD => 'GET',
}), 'Match unknown path';
is_deeply $match, { code => 404, message => 'not found', headers => [] },
    'Should get 404 response match data';

# Try a missing method.
ok $res = $router->dispatch({
    PATH_INFO => '/',
    REQUEST_METHOD => 'POST',
}), 'Dispatch to resource without method';
is_deeply $res, [405, [Allow => 'GET, HEAD, PUT'], ['not allowed']],
    'Should get default 405 response';

ok $match = $router->match({
    PATH_INFO => '/',
    REQUEST_METHOD => 'POST',
}), 'Match resource without method';
is_deeply $match, { code => 405, message => 'not allowed', headers => [
    Allow => 'GET, HEAD, PUT'
] }, 'Should get 404 response match data';

# Now try with Router::Simple stuff.
ok $res = $router->dispatch({
    REQUEST_METHOD => "GET",
    PATH_INFO => "/wiki/Theory",
}), 'Should dispatch GET /wiki/Theory';
is $res, 'get /wiki/:page', 'And it should be the correct response';

# Try a POST method.
ok $res = $router->dispatch({
    REQUEST_METHOD => "POST",
    PATH_INFO => "/wiki/Theory",
}), 'Should dispatch POST /wiki/Theory';

is $res, 'post /wiki/:page', 'And it should be the correct response';

# Try a nonexistent method method.
ok $res = $router->dispatch({
    REQUEST_METHOD => "PUT",
    PATH_INFO => "/wiki/Theory",
}), 'Should dispatch PUT /wiki/Theory';
is_deeply $res, [405, [Allow => 'GET, HEAD, POST'], ['not allowed']],
    'Should get default 405 response';

# Make sure that all the methods work.
for my $meth (qw(get head post put delete options trace connect patch)) {
    ok my $res = $router->dispatch({
        REQUEST_METHOD => uc $meth,
        PATH_INFO => '/foo'
    }), "Send request for $meth /foo";
    is $res, "$meth /foo", 'And it should return the expected response';
}

# Try the missing() method.
$reqmeth = 'GET';
my $reqpath = '/ick';
$match = { code => 404, message => 'not found', headers => [] };
ok $router = router {
    resource '/' => sub {
        GET { 'hi there' };
    };
    missing {
        is_deeply shift, {REQUEST_METHOD => $reqmeth, PATH_INFO => $reqpath },
            'The first arg to missing should be the environment';
        is_deeply shift, $match,
            'The second arg to missing should be the match hash';
        'missing'
    };
}, 'Create a new router with a missing method';

ok $res = $router->dispatch({ REQUEST_METHOD => 'GET', PATH_INFO => '/' }),
    'Dispatch GET /';
is $res, 'hi there', 'It should have been found';

# Try an invalid path.
ok $res = $router->dispatch({ REQUEST_METHOD => $reqmeth, PATH_INFO => $reqpath }),
    'Dispatch GET /ick';
is $res, 'missing', 'It should have executed the missing method';

# Try a valid path but missing method.
$reqmeth = 'PUT';
$reqpath = '/';
$match = { code => 405, message => 'not allowed', headers => [Allow => 'GET, HEAD'] };
ok $res = $router->dispatch({ REQUEST_METHOD => $reqmeth, PATH_INFO => $reqpath }),
    'Dispatch GET / with missing method';
is $res, 'missing', 'It, too, shoudl have executed the missing method';

# Try the auto_options setting.
$reqmeth = 'GET';
$match = { code => 200, message => '', headers => ['Allow', 'OPTIONS, GET'] };
$router = router {
    resource '/' => sub {
        GET { 'hi there' };
    };
   
} auto_options => 1;
ok $router, 'router created with auto_options';

ok $res = $router->dispatch({ REQUEST_METHOD => 'OPTIONS', PATH_INFO => '/' }),
    'Dispatch OPTIONS /';
is $res->[1][0], 'Allow', 'Allow exists';
like $res->[1][1], qr/OPTIONS/, 'and is set correctly';
like $res->[1][1], qr/GET/, 'and is set correctly';
like $res->[1][1], qr/HEAD/, 'and is set correctly';
