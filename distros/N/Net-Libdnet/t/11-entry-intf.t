use Test;
BEGIN { plan(tests => 1) }

use Net::Libdnet::Entry::Intf;

my $e = Net::Libdnet::Entry::Intf->new;
defined($e) ? ok(1) : ok(0);
