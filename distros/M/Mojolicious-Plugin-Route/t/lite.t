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

$t->get_ok('/bar/qux/b')->status_is(200)->content_is('Bar::Qux::B');

ok(1, 'Test');
done_testing;
