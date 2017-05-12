use Test;
BEGIN { plan(tests => 2) }

use Net::Write::Layer qw(:constants :subs);

my $ip4 = '127.0.0.1';
my $ip6 = '::1';
my $os = $^O;

ok(
   sub {
      my $saddr;
      eval { $saddr = Net::Write::Layer::nw_getsaddr($ip6, NW_AF_INET6); };
      if ($@) {
         return 0; # Error
      }
      if (defined($saddr)) {
         my $hex = unpack('H*', $saddr);
         print "1: $hex\n";
         # Only Linux currently support sending at Layer3
         if ($os eq 'linux') {
            return $hex eq '0a000000000000000000000000000000000000000000000100000000' ? 1 : 0;
         }
         else {
            return 1;  # SKIP for others
         }
      }
      return 0;  # Error
   },
   1,
   $@,
);

ok(
   sub {
      my $saddr;
      eval { $saddr = Net::Write::Layer::nw_getsaddr($ip4, NW_AF_INET); };
      if ($@) {
         return 0; # Error
      }
      if (defined($saddr)) {
         my $hex = unpack('H*', $saddr);
         print "2: $hex\n";
         # Only Linux currently support sending at Layer3
         if ($os eq 'linux') {
            return $hex eq '020000007f0000010000000000000000' ? 1 : 0;
         }
         else {
            return 1;  # SKIP for others
         }
      }
      return 0;  # Error
   },
   1,
   $@,
);
