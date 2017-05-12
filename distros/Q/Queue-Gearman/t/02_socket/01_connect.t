use strict;
use Test::More 0.98;

use t::Util;
use Queue::Gearman::Socket;

plan skip_all => 'cannot find gearmand.' unless has_gearmand();

my $gearmand = setup_gearmand();
my $server   = sprintf 'localhost:%d', $gearmand->port;

my $socket = Queue::Gearman::Socket->new(
    server             => $server,
    timeout            => 1,
    inactivity_timeout => 1,
);
isa_ok $socket,       'Queue::Gearman::Socket';
isa_ok $socket->sock, 'IO::Socket::INET';

my $sock = $socket->sock;
ok  $sock->opened, 'opened';
undef $socket;
ok !$sock->opened, 'closed';

done_testing;
