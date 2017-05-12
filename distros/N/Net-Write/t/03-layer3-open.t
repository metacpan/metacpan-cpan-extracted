use Test;
BEGIN { plan(tests => 2) }

use Net::Write::Layer qw(:constants);
use Net::Write::Layer3;

my $ip4 = '127.0.0.1';
my $ip6 = '::1';

ok(
   sub {
      my $fd = Net::Write::Layer3->new(
         dst => $ip4,
         protocol => NW_IPPROTO_RAW,
         family => NW_AF_INET,
      );
      eval { $fd->open; };
      if ($@) {
         if ($@ =~ /EUID 0/) {
            return 1;  # SKIP as non-root
         }
         return 0; # Error
      }
      if (! defined($fd)) {
         return 0;  # Error
      }
      if ($fd <= 0) {
         return 0;  # Error
      }
      return 1;  # OK
   },
   1,
   $@,
);

ok(
   sub {
      my $fd = Net::Write::Layer3->new(
         dst => $ip6,
         protocol => NW_IPPROTO_RAW,
         family => NW_AF_INET6,
      );
      eval { $fd->open; };
      if ($@) {
         if ($@ =~ /EUID 0/) {
            return 1;  # SKIP as non-root
         }
         elsif ($@ =~ /IPHDRINCL only supported on Linux/) {
            return 1;  # SKIP as not supported
         }
         return 0; # Error
      }
      if (! defined($fd)) {
         return 0;  # Error
      }
      if ($fd <= 0) {
         return 0;  # Error
      }
      return 1;  # OK
   },
   1,
   $@,
);
