use Test::More;
use strict; use warnings;

use POEx::IRC::Backend::Connect;

{ package
    POE::Wheel; use strict; use warnings;
  sub new { bless [], shift }
  sub ID  { 1234 }
}

my $conn = POEx::IRC::Backend::Connect->new(
  args      => +{ tag => 'foo' },
  wheel     => POE::Wheel->new,
  protocol  => 4,
  peeraddr  => 'foo',
  peerport  => '123',
  sockaddr  => 'bar',
  sockport  => '456',
);

ok $conn->does('POEx::IRC::Backend::Role::HasWheel'),
  'consumes POEx::IRC::Backend::Role::HasWheel';
ok $conn->has_wheel, 'has_wheel ok';
cmp_ok $conn->wheel_id, '==', 1234, 'wheel_id ok';

# (ro) args
ok $conn->has_args, 'has_args ok';
is_deeply $conn->args, +{ tag => 'foo' }, 'args ok';

# (rw) alarm_id
ok !$conn->has_alarm_id, 'has_alarm_id ok';
cmp_ok $conn->alarm_id, '==', 0, 'default alarm_id ok';
$conn->alarm_id(1);
cmp_ok $conn->alarm_id, '==', 1, 'rw alarm_id ok';

# (rw) is_client [Bool]
ok !$conn->is_client, 'default is_client ok';
$conn->is_client(1);
ok $conn->is_client, 'rw is_client ok';
eval {; $conn->is_client([]) };
ok $@, 'bad type is_client dies ok';

# (rw) is_peer [Bool]
ok !$conn->is_peer, 'default is_peer ok';
$conn->is_peer(1);
ok $conn->is_peer, 'rw is_peer ok';
eval {; $conn->is_peer([]) };
ok $@, 'bad type is_peer dies ok';

# (rw) is_disconnecting
ok !$conn->is_disconnecting, 'default is_disconnecting ok';
$conn->is_disconnecting(1);
ok $conn->is_disconnecting, 'rw is_disconnecting ok';
$conn->is_disconnecting('foo');
cmp_ok $conn->is_disconnecting, 'eq', 'foo', 'str is_disconnecting ok';

# (rw) is_pending_compress
ok !$conn->is_pending_compress, 'default is_pending_compress ok';
$conn->is_pending_compress(1);
ok $conn->is_pending_compress, 'rw is_pending_compress ok';
eval {; $conn->is_pending_compress([]) };
ok $@, 'bad type is_pending_compress dies ok';

# idle
cmp_ok $conn->idle, '==', 180, 'default idle ok';

# compressed / set_compressed
ok !$conn->compressed, 'default compressed ok';
$conn->set_compressed(1);
ok $conn->compressed, 'set_compressed ok';

# (rw) ping_pending
ok !$conn->ping_pending, 'default ping_pending false ok';
$conn->ping_pending(1);
ok $conn->ping_pending, 'rw ping_pending ok';

# (rw) seen
cmp_ok $conn->seen, '==', 0, 'default seen ok';
$conn->seen(123);
cmp_ok $conn->seen, '==', 123, 'rw seen ok';

# peeraddr / set_peeraddr
cmp_ok $conn->peeraddr, 'eq', 'foo', 'peeraddr ok';
$conn->set_peeraddr('bar');
cmp_ok $conn->peeraddr, 'eq', 'bar', 'set_peeraddr ok';

# peerport / set_peerport
cmp_ok $conn->peerport, '==', 123, 'peerport ok';
$conn->set_peerport(321);
cmp_ok $conn->peerport, '==', 321, 'set_peerport ok';

# sockaddr / set_sockaddr
cmp_ok $conn->sockaddr, 'eq', 'bar', 'sockaddr ok';
$conn->set_sockaddr('foo');
cmp_ok $conn->sockaddr, 'eq', 'foo', 'set_sockaddr ok';

# sockport / set_sockport
cmp_ok $conn->sockport, '==', 456, 'sockport ok';
$conn->set_sockport(654);
cmp_ok $conn->sockport, '==', 654, 'set_sockport ok';

# peeraddr required
eval {;
  POEx::IRC::Backend::Connect->new(
    args      => +{ tag => 'foo' },
    wheel     => POE::Wheel->new,
    protocol  => 4,
    peerport  => '123',
    sockaddr  => 'bar',
    sockport  => '456',
  );
};
like $@, qr/peeraddr/, 'missing peeraddr dies';

# peerport required
eval {;
  POEx::IRC::Backend::Connect->new(
    args      => +{ tag => 'foo' },
    wheel     => POE::Wheel->new,
    protocol  => 4,
    peeraddr  => '123',
    sockaddr  => 'bar',
    sockport  => '456',
  );
};
like $@, qr/peerport/, 'missing peerport dies';

# protocol required
eval {;
  POEx::IRC::Backend::Connect->new(
    args      => +{ tag => 'foo' },
    wheel     => POE::Wheel->new,
    peeraddr  => '123',
    peerport  => '1234',
    sockaddr  => 'bar',
    sockport  => '456',
  );
};
like $@, qr/protocol/, 'missing protocol dies';

# sockaddr required
eval {;
  POEx::IRC::Backend::Connect->new(
    args      => +{ tag => 'foo' },
    wheel     => POE::Wheel->new,
    protocol  => 4,
    peeraddr  => '123',
    peerport  => '1234',
    sockport  => '456',
  );
};
like $@, qr/sockaddr/, 'missing sockaddr dies';

# sockport required
eval {;
  POEx::IRC::Backend::Connect->new(
    args      => +{ tag => 'foo' },
    wheel     => POE::Wheel->new,
    protocol  => 4,
    peeraddr  => '123',
    peerport  => '1234',
    sockaddr  => 'bar',
  );
};
like $@, qr/sockport/, 'missing sockport dies';


# FIXME Role::Socket bits ->
# args
# FIXME
# ssl
# FIXME
# protocol
cmp_ok $conn->protocol, '==', 4, 'protocol ok';
# FIXME type check tests

# FIXME Role::CheckAvail tests

done_testing
