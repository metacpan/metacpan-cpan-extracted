use Mojo::Base -strict;
use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Collection;
use Prometheus::Collector::Custom;

plugin 'Prometheus' => { shm_key => time() };

my $collector = Prometheus::Collector::Custom->new;
app->prometheus->register($collector);
get '/' => sub { shift->render(text => 'Hello Mojo!') };

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200) for 0..2;
is $collector->called, 0, 'collector called zero times';

$t->get_ok('/metrics')->status_is(200)->content_like(qr/custom 1/);
is $collector->called, 1, 'collector called once';


done_testing();
