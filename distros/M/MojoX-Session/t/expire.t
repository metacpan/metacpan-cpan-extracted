use Test::More tests => 4;

use lib 't/lib';

use_ok('MojoX::Session');

use MojoX::Session::Store::Dummy;
use MojoX::Session::Transport::Dummy;

my $session = MojoX::Session->new(store => 'dummy', transport => 'dummy');

my $sid = $session->create;
$session->flush;

is($session->is_expired, 0);
$session->expire;
is($session->is_expired, 1);
$session->flush;

ok(not defined $session->load);
