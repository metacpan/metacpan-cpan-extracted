use Test;
BEGIN { plan(tests => 3) }

use Data::Dumper;
use Net::Routing::Linux;

my $lines4 = [
   "Kernel IP routing table",
   "Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface",
   "0.0.0.0         192.168.0.1     0.0.0.0         UG        0 0          0 wlan0",
   "192.168.0.0     0.0.0.0         255.255.255.0   U         0 0          0 wlan0",
];
my $route4 =  {
   '0.0.0.0/0|192.168.0.1|wlan0|1|0' => 1,
   '192.168.0.0/24|0.0.0.0|wlan0|0|1' => 1,
};
my $route4_count = keys %$route4;

my $lines6 = [
   "Kernel IPv6 routing table",
   "Destination                    Next Hop                   Flag Met Ref Use If",
   "fe80::/64                      ::                         U    256 0     0 wlan0",
   "::/0                           ::                         !n   -1  1 22107 lo",
   "::1/128                        ::                         Un   0   3    73 lo",
   "fe80::2ab2:bdff:fef3:e82d/128  ::                         Un   0   1     0 lo",
   "ff00::/8                       ::                         U    256 0     0 wlan0",
   "::/0                           ::                         !n   -1  1 22107 lo",
];
my $route6 = {
   'fe80::/64|::|wlan0|0|1' => 1,
   '::1/128|::|lo|0|1' => 1,
   'fe80::2ab2:bdff:fef3:e82d/128|::|lo|0|1' => 1,
   'ff00::/8|::|wlan0|0|1' => 1,
   '::/0|::|lo|0|1' => 1,
};
my $route6_count = keys %$route6;

sub _to_psv {
   my ($r) = @_;
   return $r->{route}.'|'.$r->{gateway}.'|'.$r->{interface}.'|'.
      (exists($r->{default})?'1':'0').'|'.(exists($r->{local})?'1':'0');
}

sub default_route4 {
   my $routes = Net::Routing::Linux->_get_inet4($lines4);

   my $count = @$routes;
   if ($count != $route4_count) {
      die("Invalid number of IPv4 routes: $count instead of $route4_count\n");
   }

   for my $route (@$routes) {
      my $psv = _to_psv($route);
      if (! exists($route4->{$psv})) {
         die("Invalid IPv4 route: $psv\n");
      }
   }

   return 1;
}

sub default_route6 {
   my $routes = Net::Routing::Linux->_get_inet6($lines6);

   my $count = @$routes;
   if ($count != $route6_count) {
      die("Invalid number of IPv6 routes: $count instead of $route6_count\n");
   }

   for my $route (@$routes) {
      my $psv = _to_psv($route);
      if (! exists($route6->{$psv})) {
         die("Invalid IPv6 route: $psv\n");
      }
   }

   return 1;
}

ok(
   sub { eval('my $new = Net::Routing::Linux->new()'); return $@ ? 0 : 1 },
   1,
   $@,
);

ok(
   sub { eval { default_route4() }; return $@ ? 0 : 1 },
   1,
   $@,
);

ok(
   sub { eval { default_route6() }; return $@ ? 0 : 1 },
   1,
   $@,
);
