use Test::More tests => 18;

use lib 't/lib';

use_ok('MojoX::Session');

my $session =
  MojoX::Session->new(store => 'dummy', transport => 'dummy', expires => 30);

# no changes
is($session->_is_flushed, 1);
is($session->_is_stored, 0);

# change expire time
$session->expires(1);
is($session->_is_flushed, 0);
is($session->_is_stored, 0);

# no changes
$session->_is_flushed(1);
# change data
$session->data('a' => 'b');
is($session->_is_flushed, 0);
is($session->_is_stored, 0);

my $sid = $session->create;
# no changes
is($session->_is_flushed, 0);
is($session->_is_stored, 0);
$session->flush;
is($session->_is_flushed, 1);
is($session->_is_stored, 1);

ok($session->load($sid));
is($session->sid, $sid);
# no changes
is($session->_is_flushed, 1);
is($session->_is_stored, 1);

$session->extend_expires;
is($session->_is_flushed, 0);

# expired session
$sid = $session->create;
$session->expires(0);
is($session->is_expired, 1);
# automatically delete session if it is expired
$session->flush;

ok(not defined $session->load($sid));
