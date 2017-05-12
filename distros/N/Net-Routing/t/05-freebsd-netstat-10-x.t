use Test;
BEGIN { plan(tests => 3) }

# FreeBSD 10.1-RELEASE

use Data::Dumper;
use Net::Routing::FreeBSD;

my $lines4 = [
   "Routing tables",
   "",
   "Internet:",
   "Destination        Gateway            Flags      Netif Expire",
   "default            8.8.25.254       UGS         re0",
   "8.8.25.0/24        link#1             U           re0",
   "8.8.25.71          link#1             UHS         lo0",
   "127.0.0.1          link#2             UH          lo0",
];
my $route4 =  {
   '0.0.0.0/0|8.8.25.254|re0|1|0' => 1,
   '8.8.25.0/24|0.0.0.0|re0|0|1' => 1,
   '8.8.25.71/32|0.0.0.0|lo0|0|1' => 1,
   '127.0.0.1/32|0.0.0.0|lo0|0|1' => 1,
};
my $route4_count = keys %$route4;

my $lines6 = [
   "Routing tables",
   "",
   "Internet6:",
   "Destination                       Gateway                       Flags      Netif Expire",
   "::/96                             ::1                           UGRS        lo0",
   "::1                               link#2                        UH          lo0",
   "::ffff:0.0.0.0/96                 ::1                           UGRS        lo0",
   "2003:12ab:1:1a00::/56             link#1                        U           re0",
   "2003:12ab:1:1a47::/64             link#1                        U           re0",
   "2003:12ab:1:1a47::1               link#1                        UHS         lo0",
   "2003:12ab:1:1aff:ff:ff:ff:ff      11:11:bb:27:d6:18             UHS         re0",
   "fe80::/10                         ::1                           UGRS        lo0",
   "fe80::%re0/64                     link#1                        U           re0",
   "fe80::1111:bbff:fe27:d618%re0     link#1                        UHS         lo0",
   "fe80::%lo0/64                     link#2                        U           lo0",
   "fe80::1%lo0                       link#2                        UHS         lo0",
   "ff01::%re0/32                     fe80::1111:bbff:fe27:d618%re0 U           re0",
   "ff01::%lo0/32                     ::1                           U           lo0",
   "ff02::/16                         ::1                           UGRS        lo0",
   "ff02::%re0/32                     fe80::1111:bbff:fe27:d618%re0 U           re0",
   "ff02::%lo0/32                     ::1                           U           lo0",
];
my $route6 = {
   '::/96|::|lo0|0|1' => 1,
   '::1/128|::|lo0|0|1' => 1,
   '2003:12ab:1:1a00::/56|::|re0|0|1' => 1,
   '2003:12ab:1:1a47::/64|::|re0|0|1' => 1,
   '2003:12ab:1:1a47::1/128|::|lo0|0|1' => 1,
   '::/0|2003:12ab:1:1aff:ff:ff:ff:ff|re0|0|0' => 1,
   'fe80::/10|::|lo0|0|1' => 1,
   'fe80::/64|::|re0|0|1' => 1,
   'fe80::1111:bbff:fe27:d618/128|::|lo0|0|1' => 1,
   'fe80::/64|::|lo0|0|1' => 1,
   'fe80::1/128|::|lo0|0|1' => 1,
   'ff01::/32|::|lo0|0|1' => 1,
   'ff02::/16|::|lo0|0|1' => 1,
   'ff02::/32|::|lo0|0|1' => 1,
};
my $route6_count = keys %$route6;

sub _to_psv {
   my ($r) = @_;
   return $r->{route}.'|'.$r->{gateway}.'|'.$r->{interface}.'|'.
      (exists($r->{default})?'1':'0').'|'.(exists($r->{local})?'1':'0');
}

sub default_route4 {
   my $routes = Net::Routing::FreeBSD->_get_inet4($lines4);

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
   my $routes = Net::Routing::FreeBSD->_get_inet6($lines6);

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
   sub { eval('my $new = Net::Routing::FreeBSD->new()'); return $@ ? 0 : 1 },
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
