use Mojo::Base '-strict';
use Test::More;

#use Test::Mojo;

use Mojo::UserAgent;

use Mojolicious::Lite;

get '/' => sub { shift->render(text => "Hello World") };
get '/wait/:delay' => [delay => qr/\d/] => sub { 
    my ($c) = shift;
    $c->render_later;
    Mojo::IOLoop->timer($c->param('delay') => sub {
        $c->render(text => "Delayed by " . $c->param('delay') . ' seconds');
    })
 };

my $ua = Mojo::UserAgent->new
                        ->with_roles('+Queued');

is($ua->max_active, $ua->max_connections, 'UA has max_active attribute');

# relative urls will be fetched from the Mojolicious::Lite app defined above
$ua->server->app(app);
$ua->server->app->log->level('fatal');

is($ua->get('/')->res->body, "Hello World", "Non-blocking skips queue");

$ua->get('/',
  sub { 
    is(pop->res->body, "Hello World", "non-blocking");
    Mojo::IOLoop->stop;
    });

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

#my $t = Test::Mojo->new->app(app)->ua($ua);
# Should work as normal:
# $t->get_ok('/')->status_is(200)->content_is("Hello World");
for my $d (1 .. 4) {
    $ua->get("/wait/$d" => sub {
        is(pop->res->body, "Delayed by $d seconds");
    });
}
$ua->on('stop_queue' => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# What about promises?
my @p;
for my $n (2,1) {
push @p, $ua->get_p("/wait/$n")->then(sub { is(pop->res->body, "Delayed by $n seconds") })->catch(sub { die "ERROR", $@ });
}
Mojo::Promise->all(@p)->wait;

done_testing();
