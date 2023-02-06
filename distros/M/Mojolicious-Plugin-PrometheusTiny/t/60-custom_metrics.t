use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite -signatures;
use Test::Mojo;

plugin 'PrometheusTiny' => (
    setup  => sub($app, $p) {
        $p->declare('mojo_custom_gauge',
            type => 'gauge',
            help => "Custom prometheus gauge"
        );
        $p->declare('mojo_custom_counter',
            type => 'counter',
            help => "Custom prometheus counter"
        );
        $p->set(mojo_custom_gauge => 100);
        $p->set(mojo_custom_counter => 1);
    },
    update => sub($c, $p) {
        app->log->trace("c=$c p=$p");
        $p->add(mojo_custom_gauge => 100);
        $p->inc('mojo_custom_counter');
    },
);

get '/' => sub($c) {
    $c->prometheus->set(mojo_custom_gauge => 0);
    $c->prometheus->set('mojo_custom_counter' => 0);
    $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;

$t->get_ok('/metrics')
    ->status_is(200)
    ->content_type_like(qr(^text/plain))
    ->content_like(qr/# TYPE mojo_custom_gauge gauge/)
    ->content_like(qr/# HELP mojo_custom_gauge Custom prometheus gauge/)
    ->content_like(qr/mojo_custom_gauge 200/)
    ->content_like(qr/# TYPE mojo_custom_counter counter/)
    ->content_like(qr/# HELP mojo_custom_counter Custom prometheus counter/)
    ->content_like(qr/mojo_custom_counter 2/);

$t->get_ok('/')
    ->status_is(200)
    ->content_type_like(qr(^text/html));

$t->get_ok('/metrics')
    ->status_is(200)
    ->content_type_like(qr(^text/plain))
    ->content_like(qr/mojo_custom_gauge 100/)
    ->content_like(qr/mojo_custom_counter 1/);

done_testing();