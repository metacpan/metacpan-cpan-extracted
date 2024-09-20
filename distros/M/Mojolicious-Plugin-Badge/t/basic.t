use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

plugin 'Badge';

get '/badge1' => sub {

    my $c = shift;

    my $badge = $c->app->badge(
        label      => 'Hello',
        message    => 'Mojo!',
        title      => 'Hello: Mojo!',
        color      => 'informational',
        embed_logo => 1
    );

    $c->render(text => $badge, format => 'svg');

};

my $t = Test::Mojo->new;

subtest 'Badge API' => sub {

    $t->get_ok('/badge')->status_is(404)->header_is('Content-Type', 'image/svg+xml');

    $t = $t->get_ok('/badge/Hello-Mojo!-informational')->status_is(200)->header_is('Content-Type', 'image/svg+xml');
    is $t->tx->res->dom->at('title')->text, 'Hello: Mojo!';

};

subtest 'Badge Helper' => sub {

    $t = $t->get_ok('/badge1');
    is $t->tx->res->dom->at('title')->text, 'Hello: Mojo!';

};

done_testing();
