use Test;
BEGIN { plan(tests => 6) }

use Net::Frame::Layer qw(:consts :subs);

my $host = 'gomor.org';
my $ip6 = '2001:41d0:2:1a47::2';
my $ip6v4mapping = '::ffff:94.23.25.71';
my $ip4 = '94.23.25.71';

#
# IPv4 functions
#
ok(
   sub {
      my $ip = getHostIpv4Addr($host);
      if ($ip eq $ip4) {
         print "[+] $ip\n";
         return 1;  # OK
      }
      print "[-] $ip\n";
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
      print "[-] ".unpack('H*', $a)."\n";
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
      print "[-] $a\n";
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
      if ($ip eq $ip6 || $ip eq $ip6v4mapping) {
         print "[+] $ip\n";
         return 1;  # OK
      }
      print "[-] $ip\n";
      return 0;  # NOK
   },
   1,
   $@,
);

ok(
   sub {
      my $a = inet6Aton($ip6);
      if ($a && unpack('H*', $a) eq '200141d000021a470000000000000002') {
         print "[+] ".unpack('H*', $a)."\n";
         return 1;  # OK
      }
      print "[-] ".unpack('H*', $a)."\n";
      return 0;  # NOK
   },
   1,
   $@,
);

ok(
   sub {
      my $a = inet6Ntoa(pack('H*', '200141d000021a470000000000000002'));
      if ($a && $a eq $ip6) {
         print "[+] $a\n";
         return 1;  # OK
      }
      print "[-] $a\n";
      return 0;  # NOK
   },
   1,
   $@,
);
