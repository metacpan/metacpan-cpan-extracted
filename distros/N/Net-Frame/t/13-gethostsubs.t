use Test;
BEGIN { plan(tests => 6) }

use Net::Frame::Layer qw(:consts :subs);

my $host = 'google.com';
my $ip6 = qr{^[a-f0-9:]+$};
my $ip6v4mapping = qr{^::ffff:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$};
my $ip4 = qr{^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$};

#
# IPv4 functions
#
ok(
   sub {
      my $ip = getHostIpv4Addr($host);
      if ($ip =~ $ip4) {
         print "[+] $ip\n";
         return 1;  # OK
      }
      printf(STDERR "[-] 1: $ip\n");
      return 0;  # NOK
   },
   1,
   $@,
);

ok(
   sub {
      my $a = inetAton("127.0.0.1");
      if ($a && unpack('H*', $a) eq '7f000001') {
         print "[+] ".unpack('H*', $a)."\n";
         return 1;  # OK
      }
      printf(STDERR "[-] 2: ".unpack('H*', $a)."\n");
      return 0;  # NOK
   },
   1,
   $@,
);

ok(
   sub {
      my $a = inetNtoa(pack('H*', '7f000001'));
      if ($a && $a eq '127.0.0.1') {
         print "[+] $a\n";
         return 1;  # OK
      }
      printf(STDERR "[-] 3: $a\n");
      return 0;  # NOK
   },
   1,
   $@,
);

#
# IPv6 functions
#
ok(
   sub {
      my $ip = getHostIpv6Addr($host);
      if ($ip =~ $ip6 || $ip =~ $ip6v4mapping) {
         print "[+] $ip\n";
         return 1;  # OK
      }
      printf(STDERR "[-] 4: $ip\n");
      return 0;  # NOK
   },
   1,
   $@,
);

ok(
   sub {
      my $a = inet6Aton('::1');
      if ($a && unpack('H*', $a) eq '00000000000000000000000000000001') {
         print "[+] ".unpack('H*', $a)."\n";
         return 1;  # OK
      }
      printf(STDERR "[-] 5: ".unpack('H*', $a)."\n");
      return 0;  # NOK
   },
   1,
   $@,
);

ok(
   sub {
      my $a = inet6Ntoa(pack('H*', '00000000000000000000000000000001'));
      if ($a && $a =~ $ip6) {
         print "[+] $a\n";
         return 1;  # OK
      }
      printf(STDERR "[-] 6: $a\n");
      return 0;  # NOK
   },
   1,
   $@,
);
