use Net::Proxy::Connector::dummy;
use Test::More tests => 4;

# these are dummy calls to the dummy connector
# (mostly to raise coverage)
my $conn = Net::Proxy::Connector::dummy->new();
is( $conn->read_from( '' ), '', 'read_from()' );
eval { $conn->write_to(); };
is( $@, '', 'write_to()' );

eval { $conn->listen(); };
is( $@, '', 'listen()' );
eval { $conn->accept_from(); };
is( $@, '', 'accept_from()' );
