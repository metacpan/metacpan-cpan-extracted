use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Mojolicious::Plugin::HTMX';

my @HX_RESWAPS = (qw[
    innerHTML
    outerHTML
    beforebegin
    afterbegin
    beforeend
    afterend
    delete
    none
]);

my $t = Test::Mojo->new;

subtest 'Response: HX-Location' => sub {

    get '/hx_location_1' => sub {
        my $c = shift;
        $c->htmx->res->location('/test');
        $c->rendered(200);
    };

    get '/hx_location_2' => sub {
        my $c = shift;
        $c->htmx->res->location(path => '/test', target => '#test');
        $c->rendered(200);
    };

    $t->get_ok('/hx_location_1')->status_is(200)->header_exists('HX-Location');
    $t->get_ok('/hx_location_2')->status_is(200)->header_like('HX-Location', qr/path/);
    $t->get_ok('/hx_location_2')->status_is(200)->header_like('HX-Location', qr/target/);

};

subtest 'Response: HX-Push-Url' => sub {

    get '/hx_push_url_1' => sub {
        my $c = shift;
        $c->htmx->res->push_url($c->url_for('/'));
        $c->rendered(200);
    };

    $t->get_ok('/hx_push_url_1')->status_is(200)->header_exists('HX-Push-Url');
    $t->get_ok('/hx_push_url_1')->status_is(200)->header_is('HX-Push-Url', '/');

};

subtest 'Response: HX-Redirect' => sub {

    get '/hx_redirect_1' => sub {
        my $c = shift;
        $c->htmx->res->redirect($c->url_for('/'));
        $c->rendered(200);
    };

    $t->get_ok('/hx_redirect_1')->status_is(200)->header_exists('HX-Redirect');
    $t->get_ok('/hx_redirect_1')->status_is(200)->header_is('HX-Redirect', '/');

};

subtest 'Response: HX-Refresh' => sub {

    get '/hx_refresh_1' => sub {
        my $c = shift;
        $c->htmx->res->refresh;
        $c->rendered(200);
    };

    $t->get_ok('/hx_refresh_1')->status_is(200)->header_exists('HX-Refresh');

};

subtest 'Response: HX-Replace-Url' => sub {

    get '/hx_replace_url_1' => sub {
        my $c = shift;
        $c->htmx->res->replace_url('/test');
        $c->rendered(200);
    };

    $t->get_ok('/hx_replace_url_1')->status_is(200)->header_exists('HX-Replace-Url');
    $t->get_ok('/hx_replace_url_1')->status_is(200)->header_is('HX-Replace-Url', '/test');

};

subtest 'Response: HX-Reswap' => sub {

    get "/hx_reswap_1" => sub {
        my $c    = shift;
        my $type = $c->param('type');
        $c->htmx->res->reswap($type);
        $c->rendered(200);
    };

    for my $type (@HX_RESWAPS) {
        $t->get_ok("/hx_reswap_1?type=$type")->status_is(200)->header_exists('HX-Reswap');
        $t->get_ok("/hx_reswap_1?type=$type")->status_is(200)->header_is('HX-Reswap', $type);
    }

};

subtest 'Response: HX-Retarget' => sub {

    get '/hx_retarget_1' => sub {
        my $c = shift;
        $c->htmx->res->retarget('#test');
        $c->rendered(200);
    };

    $t->get_ok('/hx_retarget_1')->status_is(200)->header_exists('HX-Retarget');
    $t->get_ok('/hx_retarget_1')->status_is(200)->header_is('HX-Retarget', '#test');

};

subtest 'Response: HX-Trigger' => sub {

    get '/hx_trigger_1' => sub {
        my $c = shift;
        $c->htmx->res->trigger('event');
        $c->rendered(200);
    };

    get '/hx_trigger_2' => sub {
        my $c = shift;
        $c->htmx->res->trigger(event => 'value');
        $c->rendered(200);
    };

    $t->get_ok('/hx_trigger_1')->status_is(200)->header_exists('HX-Trigger');
    $t->get_ok('/hx_trigger_2')->status_is(200)->header_exists('HX-Trigger');
    $t->get_ok('/hx_trigger_2')->status_is(200)->header_like('HX-Trigger', qr/value/);

};

subtest 'Response: HX-Trigger-After-Settle' => sub {

    get '/hx_trigger_after_settle_1' => sub {
        my $c = shift;
        $c->htmx->res->trigger_after_settle('event');
        $c->rendered(200);
    };

    get '/hx_trigger_after_settle_2' => sub {
        my $c = shift;
        $c->htmx->res->trigger_after_settle(event => 'value');
        $c->rendered(200);
    };

    $t->get_ok('/hx_trigger_after_settle_1')->status_is(200)->header_exists('HX-Trigger-After-Settle');
    $t->get_ok('/hx_trigger_after_settle_2')->status_is(200)->header_exists('HX-Trigger-After-Settle');
    $t->get_ok('/hx_trigger_after_settle_2')->status_is(200)->header_like('HX-Trigger-After-Settle', qr/value/);

};

subtest 'Response: HX-Trigger-After-Swap' => sub {

    get '/hx_trigger_after_swap_1' => sub {
        my $c = shift;
        $c->htmx->res->trigger_after_swap('event');
        $c->rendered(200);
    };

    get '/hx_trigger_after_swap_2' => sub {
        my $c = shift;
        $c->htmx->res->trigger_after_swap(event => 'value');
        $c->rendered(200);
    };

    $t->get_ok('/hx_trigger_after_swap_1')->status_is(200)->header_exists('HX-Trigger-After-Swap');
    $t->get_ok('/hx_trigger_after_swap_2')->status_is(200)->header_exists('HX-Trigger-After-Swap');
    $t->get_ok('/hx_trigger_after_swap_2')->status_is(200)->header_like('HX-Trigger-After-Swap', qr/value/);

};

done_testing();
