use Mojo::Base -strict;
use Mojo::Redis2;
use Test::Mojo;
use Test::More;
use t::Util;

plan skip_all => 'Cannot test on Win32' if $^O eq 'Win32';
plan skip_all => $@ unless eval { Mojo::Redis2::Server->start };

t::Util->compile_lite_app;
my $t = Test::Mojo->new;

$t->app->redis->set('some:message' => 'Too cool!');
$t->get_ok('/')->status_is(200)->json_is('/error', '')->json_is('/message', 'Too cool!');

done_testing;
