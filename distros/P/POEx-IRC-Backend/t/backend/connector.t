use Test::More;
use strict; use warnings;

use POEx::IRC::Backend::Connector;

{ package
    POE::Wheel; use strict; use warnings;
  sub new { bless [], shift }
  sub ID  { 1234 }
}

my $listener = POEx::IRC::Backend::Connector->new(
  protocol => 4,
  addr  => '127.0.0.1',
  port  => 1234,
  wheel => POE::Wheel->new,

  args     => +{ foo => 1 },
  bindaddr => '127.0.0.1',
);


# consumed methods

# Role::HasEndpoint
cmp_ok $listener->addr, 'eq', '127.0.0.1', 'addr ok';
cmp_ok $listener->port, '==', 1234, 'port ok';
$listener->set_port(4321);
cmp_ok $listener->port, '==', 4321, 'set_port ok';

eval {;
  POEx::IRC::Backend::Connector->new(
    protocol => 4, port => 1234, wheel => POE::Wheel->new
  )
};
like $@, qr/addr/, 'died on missing addr attribute';

eval {;
  POEx::IRC::Backend::Connector->new(
    protocol => 4, addr => '0.0.0.0', wheel => POE::Wheel->new
  )
};
like $@, qr/port/, 'died on missing port attribute';

# Role::HasWheel
isa_ok $listener->wheel, 'POE::Wheel';
cmp_ok $listener->wheel_id, '==', 1234, 'wheel/wheel_id ok';

# Role::Socket
ok $listener->has_args, 'has_args ok';
is_deeply $listener->args, +{ foo => 1 }, 'args ok';
cmp_ok $listener->protocol, '==', 4, 'protocol ok';
cmp_ok $listener->ssl, '==', 0, 'default ssl ok';


# class methods
ok $listener->has_bindaddr, 'has_bindaddr ok';
cmp_ok $listener->bindaddr, 'eq', '127.0.0.1', 'bindaddr ok';

$listener = POEx::IRC::Backend::Connector->new(
  protocol => 4,
  addr  => '127.0.0.1',
  port  => 1234,
  wheel => POE::Wheel->new,
  ssl   => 1,
);

cmp_ok $listener->bindaddr, 'eq', '', 'default bindaddr ok';
is_deeply $listener->args, +{}, 'default args ok';

ok $listener->ssl, 'ssl init_arg ok';

done_testing
