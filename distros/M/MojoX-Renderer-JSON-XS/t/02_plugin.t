use strict;
use utf8;
use warnings;
use Mojolicious::Lite;
use JSON::XS qw(decode_json);
use Test::Mojo;
use Test::More;
use Test::Pretty;

my $app = app;
$app->plugin('JSON::XS');

get '/json' => sub {
    my $c = shift;
    $c->render(json => { msg => 'あいうえお' });
};

subtest 'Test JSON output' => sub {
    my $t = Test::Mojo->new($app);

    $t->get_ok('/json')->status_is(200);

    my $res = $t->tx->res->body;

    is_deeply decode_json($res),
              { msg => 'あいうえお' },
              'Response body is ok';
};

done_testing;
