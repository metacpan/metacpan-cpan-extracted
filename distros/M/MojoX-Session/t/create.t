use Test::More tests => 6;

use lib 't/lib';

use_ok('MojoX::Session');

my $session =
  MojoX::Session->new(store => 'dummy', transport => 'dummy', expires => 30);

my $sid = $session->create;
ok($sid);
ok($session->expires >= time + 30);
is_deeply($session->data, {});
is($session->transport->set, $sid);
$session->flush;
ok($session->store->sessions->{$sid});
