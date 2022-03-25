use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use lib 't';
use lib 'lib';
use lib 't/lib';

plugin 'Route' => {inverse => 1};

my $t = Test::Mojo->new;
$t->get_ok('/baz')->status_is(200)->content_is('Baz'); 
$t->get_ok('/base/bar')->status_is(200)->content_is('Bar'); 
$t->get_ok('/base/page/foo')->status_is(200)->content_is('Foo');

done_testing;
