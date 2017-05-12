use Test;
BEGIN { plan(tests => 3) }

# FreeBSD 9.3-RELEASE

use Net::Routing::FreeBSD;

my $lines4 = [
   "Routing tables",
   "",
   "Internet:",
   "Destination        Gateway            Flags    Refs      Use  Netif Expire",
   "default            8.8.210.254        UGS         0 14188719    em0",
   "8.8.210.0/24       link#1             U           0  9200697    em0",
   "8.8.210.101        link#1             UHS         0    20553    lo0",
   "127.0.0.1          link#5             UH          0   748850    lo0",
   "192.168.0.1        link#5             UH          0   901107    lo0",
];
my $route4 =  {
   '0.0.0.0/0|8.8.210.254|em0|1|0' => 1,
   '8.8.210.0/24|0.0.0.0|em0|0|1' => 1,
   '8.8.210.101/32|0.0.0.0|lo0|0|1' => 1,
   '127.0.0.1/32|0.0.0.0|lo0|0|1' => 1,
   '192.168.0.1/32|0.0.0.0|lo0|0|1' => 1,
};
my $route4_count = keys %$route4;

my $lines6 = [
   "Routing tables",
   "",
   "Internet6:",
   "Destination                       Gateway                       Flags      Netif Expire",
   "::/96                             ::1                           UGRS        lo0 =>",
   "default                           2003:1122:1:ffff:ff:ff:ff:ff  UGS         em0",
   "::1                               link#5                        UH          lo0",
   "::ffff:0.0.0.0/96                 ::1                           UGRS        lo0",
   "2003:1122:1:ff00::/56             link#1                        U           em0",
   "2003:1122:1:ff65::1               link#1                        UHS         lo0",
   "2003:1122:1:ff65::2               link#1                        UHS         lo0",
   "2003:1122:1:ff65::3               link#1                        UHS         lo0",
   "2003:1122:1:ff65::4               link#1                        UHS         lo0",
   "2003:1122:1:ff65::5               link#1                        UHS         lo0",
   "fe80::/10                         ::1                           UGRS        lo0",
   "fe80::%em0/64                     link#1                        U           em0",
   "fe80::11bb:b9ff:aab1:dbcc%em0     link#1                        UHS         lo0",
   "fe80::%lo0/64                     link#5                        U           lo0",
   "fe80::1%lo0                       link#5                        UHS         lo0",
   "ff01::%em0/32                     fe80::11bb:b9ff:aab1:dbcc%em0 U           em0",
   "ff01::%lo0/32                     ::1                           U           lo0",
   "ff02::/16                         ::1                           UGRS        lo0",
   "ff02::%em0/32                     fe80::11bb:b9ff:aab1:dbcc%em0 U           em0",
   "ff02::%lo0/32                     ::1                           U           lo0",
];
my $route6 = {
   '::/96|::|lo0|0|1' => 1,
   '::/0|2003:1122:1:ffff:ff:ff:ff:ff|em0|1|0' => 1,
   '::1/128|::|lo0|0|1' => 1,
   '2003:1122:1:ff00::/56|::|em0|0|1' => 1,
   '2003:1122:1:ff65::1/128|::|lo0|0|1' => 1,
   '2003:1122:1:ff65::2/128|::|lo0|0|1' => 1,
   '2003:1122:1:ff65::3/128|::|lo0|0|1' => 1,
   '2003:1122:1:ff65::4/128|::|lo0|0|1' => 1,
   '2003:1122:1:ff65::5/128|::|lo0|0|1' => 1,
   'fe80::/10|::|lo0|0|1' => 1,
   'fe80::/64|::|em0|0|1' => 1,
   'fe80::11bb:b9ff:aab1:dbcc/128|::|lo0|0|1' => 1,
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
