use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

BEGIN {
plan skip_all => "Signatures feature not available" unless $^V gt v5.20.0;
}

use experimental 'signatures';

plugin 'auto_params';

get '/hello/:name' => sub ($c,$name) {
    shift->render(text => "hello, $name" );
};

my $t = Test::Mojo->new;

$t->get_ok('/hello/world')->status_is(200)->content_is('hello, world');

done_testing();

