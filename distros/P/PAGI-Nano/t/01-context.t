use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::Response;
use PAGI::Test::Client;
use PAGI::Nano::Context::HTTP;

# PAGI::Nano::Context::HTTP is a real PAGI::Context::HTTP (so the inherited
# request/response/json/state sugar all work) plus $c->params, which selects the
# body-vs-data strong-parameters source by content-type.

subtest 'is a real PAGI::Context::HTTP with inherited sugar' => sub {
    my $c = PAGI::Nano::Context::HTTP->new({ type => 'http', method => 'GET', path => '/' }, sub {}, sub {});
    isa_ok $c, ['PAGI::Context::HTTP'], 'inherits the HTTP context';
    can_ok $c, [qw/req response respond json text html redirect state path_param/],
        'inherited HTTP sugar is present';
    ok $c->can('params'), 'adds params';
};

subtest 'params picks body for form posts' => sub {
    my $client = PAGI::Test::Client->new(app => async sub { my ($scope, $receive, $send) = @_;
        my $c = PAGI::Nano::Context::HTTP->new($scope, $receive, $send);
        my $clean = await $c->params->permitted('a', 'b');
        await PAGI::Response->json($clean)->respond($send);
    });
    my $res = $client->post('/', form => { a => '1', b => '2', c => '3' });
    is $res->json, { a => '1', b => '2' }, 'form body whitelisted via params';
};

subtest 'params picks data for json posts' => sub {
    my $client = PAGI::Test::Client->new(app => async sub { my ($scope, $receive, $send) = @_;
        my $c = PAGI::Nano::Context::HTTP->new($scope, $receive, $send);
        my $clean = await $c->params->permitted('title', +{ tags => [] });
        await PAGI::Response->json($clean)->respond($send);
    });
    my $res = $client->post('/', json => { title => 'Hi', tags => ['x', 'y'], drop => 1 });
    is $res->json, { title => 'Hi', tags => ['x', 'y'] }, 'json body whitelisted, array kept';
};

done_testing;
