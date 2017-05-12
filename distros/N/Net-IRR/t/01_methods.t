
use Test::More tests => 21;

BEGIN{ use_ok('Net::IRR') }

my $host = 'whois.radb.net';
can_ok("Net::IRR", "connect");
my $i = Net::IRR->connect( host => $host );
ok($i, "connected to $host");

can_ok($i, "get_irrd_version");
ok ($i->get_irrd_version, 'IRRd version number found');

can_ok($i, "get_routes_by_origin");
my @routes = $i->get_routes_by_origin("AS5650");
my $found = scalar @routes;
ok ($found, "found $found routes for AS5650");

can_ok($i, "get_ipv6_routes_by_origin");

can_ok($i, "get_as_set");
if (my @ases = $i->get_as_set("AS-ELI", 1)) {
    my $found = scalar @ases;
    ok ($found, "found $found ASNs in the AS-ELI AS set. (1)");
}
else {
    fail('no ASNs found in the AS-ELI AS set (1)');
}

can_ok($i, "get_route_set");
if (my @ases = $i->get_route_set("AS-ELI", 1)) {
    my $found = scalar @ases;
    ok ($found, "found $found ASNs in the AS-ELI AS set (2).");
}
else {
    fail('no ASNs found in the AS-ELI AS set (2)');
}

can_ok($i, "match");
my $person = $i->match("aut-num","as5650");
ok($person, "found an aut-num object for AS5650");

can_ok($i, "route_search");
my $origin = $i->route_search("208.186.0.0/15", 'o');
ok( $origin, "$origin originates 208.186.0.0/15" );

my $origin1 = $i->route_search("10.0.0.0/8", 'o');
ok( not(defined($i->error())), "10.0.0.0/8 was not found" );

can_ok($i, "get_sync_info");
my $info = $i->get_sync_info();
ok($info, 'found synchronization information');

can_ok($i, "disconnect");
ok($i->disconnect(), 'disconnect was successful');

