use Test::Mojo;
use Test::More;
use Mojolicious::Lite -signatures;
use Mojolicious::Plugin::WebComponent;

$ENV{MOJO_MODE} = 'test';

plugin WebComponent => {};

app->static->paths->[0] =~ s/\/public/\/files/;

get '/' => sub($c) {
    $c->render(text => 'Hello World!');
};

get '/index' => sub($c) {
    $c->render(template => 'default/index');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200);

$t->get_ok('/index')->status_is(200)->content_like(qr{<my-component></my-component>});

is_deeply $t->app->component('my-component', { requestId => 'test-id' }),
    "<script src='/component/test-id/my-component.js'></script>";

$t->get_ok('/component/test-id/my-component.js')->status_is(200)
    ->content_like(qr{<div>This is a custom web component</div>});

done_testing;
