use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use lib 't';
use lib 'lib';
use lib 't/lib';

plugin 'Route';

my $t = Test::Mojo->new;
$t->get_ok('/foo')->status_is(200)->content_is('Foo');

$t->get_ok('/baz/a')->status_is(200)->content_is('Baz::A');

$t->get_ok('/baz/a/new')->status_is(200)->content_is('Baz::A->new');

$t->get_ok('/bar/qux/b')->status_is(200)->content_is('Bar::Qux::B');

$t->get_ok('/b')->status_is(200)->content_is('B');

$t->get_ok('/login')->status_is(200)->content_is('Login');

$t->get_ok('//Admin:Password@/admin')
  ->status_is(200)
  ->content_is('Admin');
  
$t->get_ok('//Foo:Baz@/admin')
  ->status_is(401)
  ->content_is('Authentication required!');  

done_testing;
