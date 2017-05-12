use Test::More tests => 8;

use MojoX::Session;
use MojoX::Session::Store::File;

my $session = MojoX::Session->new(store => MojoX::Session::Store::File->new);

my $sid = $session->create;
$session->flush;
ok defined $sid, 'create';

ok $session->load($sid), 'load';

is $session->sid, $sid, 'sid';

$session->data(foo => 'foo');
$session->data(bar => {bar => 'bar'});
$session->data(baz => ['baz']);
$session->flush;
ok $session->load($sid), 'load after data';
is $session->data('foo'), 'foo', 'scalar data';
is_deeply $session->data('bar'), {bar => 'bar'}, 'hashref data';
is_deeply $session->data('baz'), ['baz'], 'arrayref data';

$session->clear;
$session->expire;
$session->flush;
is $session->load($sid), undef, 'delete';
