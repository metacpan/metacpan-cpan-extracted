use Test::More tests => 3;
use Net::DNSBL::Client;

my $c = Net::DNSBL::Client->new();

is ($c->_reverse_address('1.2.3.4'), '4.3.2.1', '_reverse_address works on simple IPv4 address');

is ($c->_reverse_address('::ffff:1.2.3.4'), '4.3.2.1', '_reverse_address works on IPv6-mapped IPv4 address');

is ($c->_reverse_address('2001:4567::1fbc:9'), '9.0.0.0.c.b.f.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.7.6.5.4.1.0.0.2', '_reverse_address works on IPv6 address');

