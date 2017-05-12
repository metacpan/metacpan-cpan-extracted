use Test::More;

use IO::Socket::INET;
use POE;
plan tests => 2;


# this quiets the warning "POE::Kernel's run() method was never called."
POE::Kernel->run();

eval { require POE::Component::SNMP };

$|++;

my $CONF = do "config.cache";

my $localport;
do {
    $localport = int(rand(65535 - 1025) + 1025)
} while (check_port_free($localport));


eval { POE::Component::SNMP->create(
                                    -alias     => 'snmp',
                                    -hostname  => $CONF->{hostname} || 'localhost',
                                    -community => $CONF->{community}|| 'public',
                                    -debug     => $CONF->{debug},
                                    -timeout   => 5,
                                    -localport => $localport,
                                   )
};

SKIP: {
    skip "ASSERT_DATA bug", 1 if ($POE::VERSION <= 0.95 and POE::Kernel::ASSERT_DATA);
    ok $poe_kernel->alias_resolve('snmp');
}

eval { POE::Component::SNMP->create(
                                    -alias     => 'snmp2',
                                    -hostname  => $CONF->{hostname} || 'localhost',
                                    -community => $CONF->{community}|| 'public',
                                    -debug     => $CONF->{debug},
                                    -timeout   => 5,
                                    -localport => $localport,
                                   )
};

SKIP: {
    skip "ASSERT_DATA bug", 1 if ($POE::VERSION <= 0.95 and POE::Kernel::ASSERT_DATA);
    ok ! ($poe_kernel->alias_resolve('snmp2'));
}

# returns 1 if there is an error, 0 if no error
sub check_port_free {
    my $port = shift;

    my $s = IO::Socket::INET->new(
                                  Proto => 'udp',
                                  LocalPort => $port,
                                  PeerAddr => $CONF->{hostname} || 'localhost',
                                  PeerPort => 161,
                                 );

    return $@ ? 1 : 0 ;
}
