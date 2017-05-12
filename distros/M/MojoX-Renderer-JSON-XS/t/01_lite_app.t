use strict;
use utf8;
use warnings;
use Mojolicious::Lite;
use JSON::XS qw(decode_json);
use Test::Mojo;
use Test::More;
use Test::Pretty;
use MojoX::Renderer::JSON::XS;

my $app = app;
$app->renderer->add_handler(
    json => MojoX::Renderer::JSON::XS->build,
);

get '/json' => sub {
    my $c = shift;
    $c->render(json => { msg => 'モダンPerl入門' });
};

subtest 'Test JSON output' => sub {
    my $t = Test::Mojo->new($app);

    $t->get_ok('/json')->status_is(200);

    my $res = $t->tx->res->body;

    is_deeply decode_json($res),
              { msg => 'モダンPerl入門' },
              'Response body is ok';
};

done_testing;
