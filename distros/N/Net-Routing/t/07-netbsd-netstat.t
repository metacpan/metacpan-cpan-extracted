use Test;
BEGIN { plan(tests => 2) }

# NetBSD

use Net::Routing::NetBSD;

my $lines4 = [
   "Routing tables",
   "",
   "Internet:",
   "Destination        Gateway            Flags     Refs     Use    Mtu  Interface",
   "default            208.44.95.1        UGS         0   330309   1500  ex0",
   "127                127.0.0.1          UGRS        0        0  33228  lo0",
   "127.0.0.1          127.0.0.1          UH          1     1624  33228  lo0",
   "172.15.13/24       172.16.14.37       UGS         0        0   1500  ex1",
   "172.16             link#2             UC         13        0   1500  ex1",
];
my $route4 =  {
   '0.0.0.0/0|208.44.95.1|ex0|1|0' => 1,
   '127.0.0.0/8|127.0.0.1|lo0|0|0' => 1,
   '127.0.0.1/32|127.0.0.1|lo0|0|0' => 1,
   '172.15.13.0/24|172.16.14.37|ex1|0|0' => 1,
   '172.16.0.0/16|0.0.0.0|ex1|0|1' => 1,
};
my $route4_count = keys %$route4;

my $lines6 = [
   "Internet6:",
   "Destination                   Gateway                   Flags     Refs     Use Mtu  Interface",
   "::/104                        ::1                       UGRS        0        0 33228  lo0 =>",
   "::/96                         ::1                       UGRS        0        0 1024 en1",
];
my $route6 = {
   '::/104|::|lo0|0|1' => 1,
   '::/96|::|en1|0|1' => 1,
};
my $route6_count = keys %$route6;

sub _to_psv {
   my ($r) = @_;
   return $r->{route}.'|'.$r->{gateway}.'|'.$r->{interface}.'|'.
      (exists($r->{default})?'1':'0').'|'.(exists($r->{local})?'1':'0');
}

sub default_route4 {
   my $routes = Net::Routing::NetBSD->_get_inet4($lines4);

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
   my $routes = Net::Routing::NetBSD->_get_inet6($lines6);

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
   sub { eval { default_route4() }; return $@ ? 0 : 1 },
   1,
   $@,
);

ok(
   sub { eval { default_route6() }; return $@ ? 0 : 1 },
   1,
   $@,
);
