use Test;
BEGIN { plan(tests => 3) }

use Net::Routing::Darwin;

my $lines4 = [
   "Routing tables",
   "",
   "Internet:",
   "Destination        Gateway            Flags        Refs      Use   Netif Expire",
   "default            10.0.2.2           UGSc            2        0     en0",
   "10.0.2/24          link#4             UCS             2        0     en0",
   "10.0.2.2           52:54:0:12:35:2    UHLWIir         3        0     en0   1070",
   "10.0.2.3           52:54:0:12:35:3    UHLWIi          1       14     en0   1165",
   "10.0.2.15          127.0.0.1          UHS             0        0     lo0",
   "127                127.0.0.1          UCS             0        0     lo0",
   "127.0.0.1          127.0.0.1          UH              1       28     lo0",
   "169.254            link#4             UCS             0        0     en0",
   "192.168.56         link#5             UC              1        0     en1",
   "192.168.56.1       a:0:27:0:0:0       UHLWIi          2      140     en1   1176",
];
my $route4 =  {
   '0.0.0.0/0|10.0.2.2|en0|1|0' => 1,
   '10.0.2.0/24|0.0.0.0|en0|0|1' => 1,
   '10.0.2.15/32|127.0.0.1|lo0|0|0' => 1,
   '127.0.0.0/8|127.0.0.1|lo0|0|0' => 1,
   '127.0.0.1/32|127.0.0.1|lo0|0|0' => 1,
   '169.254.0.0/16|0.0.0.0|en0|0|1' => 1,
   '192.168.56.0/24|0.0.0.0|en1|0|1' => 1,
};
my $route4_count = keys %$route4;

my $lines6 = [
   "Routing tables",
   "",
   "Internet6:",
   "Destination                             Gateway                         Flags         Netif Expire",
   "::1                                     ::1                             UHL             lo0",
   "fe80::%lo0/64                           fe80::1%lo0                     UcI             lo0",
   "fe80::1%lo0                             link#1                          UHLI            lo0",
   "fe80::%en0/64                           link#4                          UCI             en0",
   "fe80::a00:27ff:fe5d:e50d%en0            8:0:27:5d:e5:d                  UHLI            lo0",
   "ff01::%lo0/32                           ::1                             UmCI            lo0",
   "ff01::%en0/32                           link#4                          UmCI            en0",
   "ff02::%lo0/32                           ::1                             UmCI            lo0",
   "ff02::%en0/32                           link#4                          UmCI            en0",
];
my $route6 = {
   '::1/128|::|lo0|0|1' => 1,
   'fe80::1/128|::|lo0|0|1' => 1,
   'fe80::/64|::|en0|0|1' => 1,
   '::/0|fe80::a00:27ff:fe5d:e50d|lo0|0|0' => 1,
   'ff01::/32|::|lo0|0|1' => 1,
   'ff01::/32|::|en0|0|1' => 1,
   'ff02::/32|::|lo0|0|1' => 1,
   'ff02::/32|::|en0|0|1' => 1,
};
my $route6_count = keys %$route6;

sub _to_psv {
   my ($r) = @_;
   return $r->{route}.'|'.$r->{gateway}.'|'.$r->{interface}.'|'.
      (exists($r->{default})?'1':'0').'|'.(exists($r->{local})?'1':'0');
}

sub default_route4 {
   my $routes = Net::Routing::Darwin->_get_inet4($lines4);

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
   my $routes = Net::Routing::Darwin->_get_inet6($lines6);

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
   sub { eval('my $new = Net::Routing::Darwin->new()'); return $@ ? 0 : 1 },
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
