use Test;
BEGIN { plan(tests => 2) }

use Net::Write::Layer qw(:constants :subs);

my $ip4 = '127.0.0.1';
my $ip6 = '::1';

ok(
   sub {
      my $saddr;
      eval { $saddr = Net::Write::Layer::nw_inet_pton(NW_AF_INET6, $ip6); };
      if ($@) {
         return 0; # Error
      }
      if (defined($saddr)) {
         my $hex = unpack('H*', $saddr);
         if ($hex eq '00000000000000000000000000000001') {
            return 1;  # OK
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
      eval { $saddr = Net::Write::Layer::nw_inet_pton(NW_AF_INET, $ip4); };
      if ($@) {
         return 0; # Error
      }
      if (defined($saddr)) {
         my $hex = unpack('H*', $saddr);
         if ($hex eq '7f000001') {
            return 1;  # OK
         }
      }
      return 0;  # Error
   },
   1,
   $@,
);
