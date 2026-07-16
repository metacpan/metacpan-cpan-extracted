use strict;
use warnings;
use Test2::V0;
use PAGI::Test::Client;
use PAGI::Nano;

# any/del verbs, named-middleware resolution (string -> PAGI::Middleware::*), and
# TO_JSON serialization of blessed objects nested in a coerced JSON body.

# A tiny domain object that knows how to JSON-serialize itself.
package Money {
    sub new { my ($class, $cents) = @_; bless { cents => $cents }, $class }
    sub TO_JSON { my ($self) = @_; sprintf('$%.2f', $self->{cents} / 100) }
}

my $app = app {
    enable 'ContentLength';              # named app-wide middleware, resolved to a class

    any '/any'    => sub { my ($c) = @_; { method => $c->method } };
    del '/thing/:id' => sub { my ($c, $id) = @_; { deleted => $id } };

    get '/price' => sub { my ($c) = @_; { total => Money->new(1299) } };
};

my $client = PAGI::Test::Client->new(app => $app);

subtest 'any matches every method' => sub {
    is $client->get('/any')->json,  { method => 'GET' },  'GET';
    is $client->post('/any')->json, { method => 'POST' }, 'POST';
    is $client->put('/any')->json,  { method => 'PUT' },  'PUT';
};

subtest 'del maps to DELETE' => sub {
    my $res = $client->delete('/thing/42');
    is $res->json, { deleted => '42' }, 'DELETE with path param';
};

subtest 'named middleware resolved and applied (Content-Length present)' => sub {
    my $res = $client->get('/any');
    ok defined $res->header('content-length'), 'ContentLength middleware ran';
};

subtest 'TO_JSON objects serialize themselves in coerced JSON' => sub {
    my $res = $client->get('/price');
    is $res->json, { total => '$12.99' }, 'nested object serialized via TO_JSON';
};

done_testing;
