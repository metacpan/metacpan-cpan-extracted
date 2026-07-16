use strict;
use warnings;
use Test2::V0;
use PAGI::Test::Client;
use PAGI::Nano;

# app { } returns an assembled PAGI app (a value, not global state). Routing maps
# to PAGI::App::Router; handler return values are coerced per the coercion table.

my $app = app {
    get '/string' => sub { my ($c) = @_; 'hello' };
    get '/hash'   => sub { my ($c) = @_; { ok => 1 } };
    get '/array'  => sub { my ($c) = @_; [1, 2, 3] };
    get '/resp'   => sub { my ($c) = @_; $c->json({ made => 'by hand' }, status => 201) };
    get '/explicit-404' => sub { my ($c) = @_; $c->json({ error => 'nope' }, status => 404) };
    get '/oops'   => sub { my ($c) = @_; return };   # forgot to return -> loud error
    get '/blessed-junk' => sub { my ($c) = @_; bless {}, 'Some::Domain::Object' };
    get '/other-ref'    => sub { my ($c) = @_; \my $scalar };   # uncoercible ref
    get '/thrown-resp'  => sub {
        my ($c) = @_;
        die $c->json({ thrown => 1 }, status => 418);   # die a respond-able
    };
};

my $client = PAGI::Test::Client->new(app => $app);

subtest 'app { } returns a coderef PAGI app' => sub {
    is ref($app), 'CODE', 'the assembled app is a coderef';
};

subtest 'string -> text/plain' => sub {
    my $res = $client->get('/string');
    is $res->status, 200, '200';
    like $res->content_type, qr{text/plain}, 'text/plain';
    is $res->content, 'hello', 'body is the string';
};

subtest 'hashref -> application/json' => sub {
    my $res = $client->get('/hash');
    like $res->content_type, qr{application/json}, 'json content-type';
    is $res->json, { ok => 1 }, 'json body';
};

subtest 'arrayref -> application/json' => sub {
    my $res = $client->get('/array');
    is $res->json, [1, 2, 3], 'json array body';
};

subtest 'PAGI::Response -> sent as-is' => sub {
    my $res = $client->get('/resp');
    is $res->status, 201, 'status from the response';
    is $res->json, { made => 'by hand' }, 'body from the response';
};

subtest 'a returned response carries its own status' => sub {
    my $res = $client->get('/explicit-404');
    is $res->status, 404, 'explicit 404';
    is $res->json, { error => 'nope' }, 'explicit body';
};

subtest 'return; is a loud error, not a silent empty 200' => sub {
    my $res = $client->get('/oops');
    is $res->status, 500, 'forgot-to-return surfaces as a 500';
    isnt $res->status, 200, 'never a silent 200';
};

subtest 'a blessed non-respondable return is a loud error' => sub {
    my $res = $client->get('/blessed-junk');
    is $res->status, 500, 'an object without ->respond cannot be coerced -> 500';
};

subtest 'an uncoercible plain reference is a loud error' => sub {
    my $res = $client->get('/other-ref');
    is $res->status, 500, 'a scalar/code ref is neither response, hash, nor array -> 500';
};

subtest 'a thrown respond-able is sent as-is' => sub {
    my $res = $client->get('/thrown-resp');
    is $res->status, 418, 'die $c->json(..., status => 418) sends the response';
    is $res->json, { thrown => 1 }, 'the thrown response body is sent';
};

subtest 'a route without a handler is a loud build-time error' => sub {
    my $err = dies { app { get '/x' } };
    like $err, qr/missing a handler/,
        'declaring a route with no handler dies at app { } build, not at request time';
};

subtest '404 for unknown route (router default)' => sub {
    my $res = $client->get('/nowhere');
    is $res->status, 404, 'unmatched route is 404';
};

done_testing;
