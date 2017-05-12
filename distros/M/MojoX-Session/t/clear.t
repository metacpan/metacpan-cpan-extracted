use Test::More tests => 7;

use_ok('MojoX::Session');

use lib 't/lib';

my $session = MojoX::Session->new(store => 'dummy');

$session->create;
$session->data('foo' => 'bar');
$session->flush;
$session->clear;
is($session->_is_flushed, 0);

ok($session->sid);
ok($session->expires_delta);
is_deeply($session->data, {});

$session->data('foo' => 'bar', 'baz' => 'faz');
$session->clear('foo');
is_deeply($session->data, {baz => 'faz'});

$session->clear;
$session->data('foo' => undef);
is_deeply($session->data, {foo => undef});
