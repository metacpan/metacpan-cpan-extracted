use Test::More tests => 26;

use lib 't/lib';

use_ok('MojoX::Session');

my $session =
  MojoX::Session->new(store => 'dummy', transport => 'dummy', expires => 30);

# no cookies
ok(not defined $session->load());
ok(not defined $session->sid);
is_deeply($session->data, {});
is($session->expires, 0);

# not existing sid
ok(not defined $session->load(123));
ok(not defined $session->sid);
is_deeply($session->data, {});
is($session->expires, 0);

# transport with not existing sid
$session->transport->get('123');
ok(not defined $session->load(123));
ok(not defined $session->sid);
is_deeply($session->data, {});
is($session->expires, 0);

# no data
my $sid = $session->create();
$session->flush();
is($session->load($sid), $sid);

$sid = $session->create();
$session->data(foo => 'bar');
$session->flush();

# correct sid
is($session->load($sid), $sid);
ok($session->sid);
is_deeply($session->data, { foo => 'bar'});
ok($session->expires > 0);

# correct transport sid
$session->transport->get($sid);
is($session->load(), $sid);
ok($session->sid);
is_deeply($session->data, { foo => 'bar'});
ok($session->expires > 0);

# after session was found
# not existing sid
ok(not defined $session->load(123));
ok(not defined $session->sid);
is_deeply($session->data, {});
is($session->expires, 0);
