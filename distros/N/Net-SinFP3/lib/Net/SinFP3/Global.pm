#
# $Id: Global.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Global;
use strict;
use warnings;

use base qw(Class::Gomor::Array);
our @AS = qw(
   log
   job
   next
   input
   db
   mode
   search
   output

   target
   targetIp
   targetIpAsInt
   targetReverse
   targetList
   targetListAsInt
   targetCount
   targetSubnet
   targetHostname

   port
   portList
   portCount

   ipv6
   jobs
   macLookup
   dnsReverse
   worker
   device
   retry
   timeout
   pps
   ip
   ip6
   mac
   srcPort
   subnet
   subnet6
   gatewayIp
   gatewayIp6
   gatewayMac
   threshold
   bestScore

   cacheArp
   cacheDnsReverse
   cacheDnsResolve

   data
);
our @AA = qw(
   result
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use File::Glob ':globally';
use IO::Socket::INET;
use IO::Socket::INET6;
use Net::Frame::Device;
use Net::Frame::Dump::Offline;
use Net::Frame::Dump::Online2;
use Net::Frame::Dump::Writer;
use Net::Frame::Layer qw(:subs);
use Net::Frame::Simple;
use Net::Netmask;
use Net::Write::Layer2;
use Net::Write::Layer3;
use Socket;
use Socket6 qw(inet_pton NI_NUMERICHOST NI_NUMERICSERV getnameinfo getaddrinfo);

sub new {
   my $self = shift->SUPER::new(
      job        => 0,
      ipv6       => 0,
      macLookup  => 1,
      dnsReverse => 0,
      jobs       => 10,
      retry      => 3,
      timeout    => 3,
      pps        => 200,
      worker     => 'Fork',
      srcPort    => 31337,
      threshold  => 0,
      bestScore  => 0,
      port       => 'top10',
      targetReverse => 'unknown',
      targetHostname => 'unknown',
      result     => [],
      cacheArp   => {},
      @_,
   );

   if (!defined($self->log)) {
      die("[-] ".__PACKAGE__.": You must provide a log object\n");
   }
   my $log = $self->log;

   my $dev;
   if ($self->target) {
      my $ip = $self->_parseTarget;

      my %args = ();
      $self->ipv6   ? ($args{target6} = $ip) : ($args{target} = $ip);
      $self->device ? ($args{dev}     = $self->device) : ();
      $dev = Net::Frame::Device->new(%args);
      if (!defined($dev)) {
         $log->fatal("Unable to acquire device information from target [".
                     $self->target."]");
      }
   }
   elsif ($self->device) {
      $dev = Net::Frame::Device->new(dev => $self->device);
      if (!defined($dev)) {
         $log->fatal("Unable to acquire device information from device [".
                     $self->device."]");
      }
   }
   else {
      $dev = Net::Frame::Device->new;
      if (!defined($dev)) {
         $log->warning("Unable to get default device information");
      }
   }

   $self->_parsePort;

   $self->device($dev->dev)            if !$self->device    && $dev->dev;
   $self->ip($dev->ip)                 if !$self->ip        && $dev->ip;
   $self->ip6($dev->ip6)               if !$self->ip6       && $dev->ip6;
   $self->mac($dev->mac)               if !$self->mac       && $dev->mac;
   $self->subnet($dev->subnet)         if !$self->subnet    && $dev->subnet;
   $self->gatewayIp($dev->gatewayIp)   if !$self->gatewayIp && $dev->gatewayIp;
   $self->gatewayIp6($dev->gatewayIp6) if !$self->gatewayIp6
                                       &&  $dev->gatewayIp6;
   $self->gatewayMac($dev->gatewayMac) if !$self->gatewayMac
                                       &&  $dev->gatewayMac;

   $log->verbose("dev:    ".$self->device) if $self->device;
   $log->verbose("ip:     ".$self->ip)     if $self->ip;
   $log->verbose("ip6:    ".$self->ip6)    if $self->ip6;
   $log->verbose("mac:    ".$self->mac)    if $self->mac;
   $log->verbose("subnet: ".$self->subnet) if $self->subnet;
   $log->verbose("gatewayIp:  ".$self->gatewayIp)  if $self->gatewayIp;
   $log->verbose("gatewayIp6: ".$self->gatewayIp6) if $self->gatewayIp6;
   $log->verbose("gatewayMac: ".$self->gatewayMac) if $self->gatewayMac;

   return $self;
}

sub _parseTarget {
   my $self = shift;

   my $log = $self->log;

   my $target = $self->target;
   if (! $target) {
      return 1;
   }

   # Possible formats
   #  FQDN => 0
   #  SUBNET => 1
   #  IP/32 => 2 
   #  IP => 2

   $target =~ s/\/32$//;
   $self->target($target);

   my $format = 0;  # FQDN format by default
   if ($target =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/\d+$/) {
      $format = 1; # Subnet format
   }
   elsif ($target =~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
      $format = 2; # Single IP format
   }

   my $ip;
   if ($format == 0) {  # FQDN format
      $ip = $self->getHostAddr(host => $target)
         or $log->fatal("Unable to resolve target hostname: [$target]");

      $self->targetHostname($target);
      $self->targetIp($ip);
      $self->targetCount(1);
      $self->targetList([ $ip ]);

      my $ipAsInt = $self->ipToInt(ip => $ip) or return;
      $self->targetIpAsInt($ipAsInt);
      $self->targetListAsInt([ $ipAsInt ]);
   }
   elsif ($format == 1) {  # Subnet format
       if ($self->ipv6) {
          $log->fatal("IPv6 subnet scanning not supported (yet): [$target]");
       }
       else {
          my $list = $self->expandSubnet(
             subnet => $target,
             asInt => 1,
          ) or $log->fatal("Unable to parse this subnet: [$target]");

          $self->targetSubnet($target);

          my $size = scalar(@$list);
          $self->targetCount($size);
          if ($size > 1) {  # Skip the network address
             $self->targetIpAsInt($list->[1]);
             $ip = $self->intToIp(int => $list->[1]) or return;
          }
          elsif ($size == 1) {  # No network address here
             $self->targetIpAsInt($list->[0]);
             $ip = $self->intToIp(int => $list->[0]) or return;
          }
          else {
             $log->fatal("Unable to analyze this subnet: [$target]");
          }
          $self->targetIp($ip);
          # XXX: do we convert all IPs to ASCII format here? -> targetList
          # No, it will take too much memory. Must be a user option.
          $self->targetListAsInt($list);
       }
   }
   elsif ($format == 2) {  # Single IP format
      $self->targetIp($target);
      my $ipAsInt = $self->ipToInt(ip => $target) or return;
      $self->targetIpAsInt($ipAsInt);
      $self->targetCount(1);
      $self->targetList([ $target ]);
      $self->targetListAsInt([ $ipAsInt ]);
   }
   else {
      $log->fatal("Unknown target format");
   }

   #$log->debug("_parseTarget: target: ".($self->target || '(null)'));
   #$log->debug("_parseTarget: targetIp: ".($self->targetIp || '(null)'));
   #$log->debug("_parseTarget: targetIpAsInt: ".($self->targetIpAsInt || '(null)'));
   #$log->debug("_parseTarget: targetCount: ".($self->targetCount || '(null)'));
   #$log->debug("_parseTarget: targetSubnet: ".($self->targetSubnet || '(null)'));
   #$log->debug("_parseTarget: targetHostname: ".($self->targetHostname || '(null)'));
   #my $listAsInt = $self->targetListAsInt;
   #my $first = $listAsInt->[0] || '(null)';
   #$log->debug("_parseTarget: targetListAsInt first: $first");

   if ($self->dnsReverse) {
      $self->targetReverse(
         $self->getAddrReverse(addr => $self->targetIp) || 'unknown'
      );
   }

   return $self->targetIp;
}

sub _parsePort {
   my $self = shift;

   my $log = $self->log;

   # Valid port format
   #  Single port: 80
   #  Range port: 80-90
   #  Comma list: 80,81,82
   #  Mixed list: 80-90,100
   #  Fixed: top10, top100, top1000, all|full

   my $list = $self->expandPorts(ports => $self->port)
      or $log->fatal("Unable to expand ports: [".$self->port."]");

   $self->portList($list);
   $self->portCount(scalar(@$list));

   #$log->debug("_parsePort: portCount: ".scalar(@$list));
   #$log->debug("_parsePort: portList first: ".$list->[0]);
   ##$log->debug("_parsePort: portList: ".join(',', @$list));

   return 1;
}

sub expandSubnet {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (!defined($h{subnet})) {
      $log->fatal("expandSubnet: You must provide subnet attribute");
   }
   my $subnet = $h{subnet};

   if ($subnet !~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/\d+$/) {
      $log->fatal("expandSubnet: Invalid subnet format: [$subnet]");
   }

   my $oNet = Net::Netmask->new2($subnet);
   if (!defined($oNet)) {
      $log->warning("expandSubnet: Net::Netmask error for subnet ".
                    "[$subnet]: $Net::Netmask::errstr");
      return;
   }

   $log->debug("Expanding subnet IP addresses, this may take a few seconds ...");

   my @list = ();
   my $size = $oNet->size;
   my $ibase = $oNet->{IBASE};
   if ($h{asInt}) {
      for my $i (0..$size-1) {
         push @list, $ibase+$i;
      }
   }
   else {
      for my $i (0..$size-1) {
         push @list, $self->intToIp(int => ($ibase + $i)) or return;
      }
   }

   $log->debug("Expanding subnet IP addresses: Done (count: ".scalar(@list).")");

   return \@list;
}

sub expandPorts {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (!defined($h{ports})) {
      $log->fatal("expandPorts: You must provide ports attribute");
   }
   my $ports = $h{ports};

   #$log->debug("Expanding target ports, this may take a few seconds ...");

   if ($ports =~ /all|full/i) {
      $ports = '0-65535';
   }
   elsif ($ports =~ /top10\s*$/i) {
      $ports = '21,22,23,25,80,135,139,443,445,3389';
   }
   elsif ($ports =~ /top100\s*$/i) {
      $ports = '7,9,13,21,22,23,25,26,37,53,79,80,81,88,106,110,111,113,119,135,139,143,144,179,199,389,427,443,444,445,465,513,514,515,543,544,548,554,587,631,646,873,990,993,995,1025,1026,1027,1028,1029,1110,1433,1720,1723,1755,1900,2000,2001,2049,2121,2717,3000,3128,3306,3389,3986,4899,5000,5009,5051,5060,5101,5190,5357,5432,5631,5666,5800,5900,6000,6001,6646,7070,8000,8008,8009,8080,8081,8443,8888,9100,9999,10000,32768,49152,49153,49154,49155,49156,49157';
   }
   elsif ($ports =~ /top1000\s*$/i) {
      $ports = '1,3,4,6,7,9,13,17,19,20,21,22,23,24,25,26,30,32,33,37,42,43,49,53,70,79,80,81,82,83,84,85,88,89,90,99,100,106,109,110,111,113,119,125,135,139,143,144,146,161,163,179,199,211,212,222,254,255,256,259,264,280,301,306,311,340,366,389,406,407,416,417,425,427,443,444,445,458,464,465,481,497,500,512,513,514,515,524,541,543,544,545,548,554,555,563,587,593,616,617,625,631,636,646,648,666,667,668,683,687,691,700,705,711,714,720,722,726,749,765,777,783,787,800,801,808,843,873,880,888,898,900,901,902,903,911,912,981,987,990,992,993,995,999,1000,1001,1002,1007,1009,1010,1011,1021,1022,1023,1024,1025,1026,1027,1028,1029,1030,1031,1032,1033,1034,1035,1036,1037,1038,1039,1040,1041,1042,1043,1044,1045,1046,1047,1048,1049,1050,1051,1052,1053,1054,1055,1056,1057,1058,1059,1060,1061,1062,1063,1064,1065,1066,1067,1068,1069,1070,1071,1072,1073,1074,1075,1076,1077,1078,1079,1080,1081,1082,1083,1084,1085,1086,1087,1088,1089,1090,1091,1092,1093,1094,1095,1096,1097,1098,1099,1100,1102,1104,1105,1106,1107,1108,1110,1111,1112,1113,1114,1117,1119,1121,1122,1123,1124,1126,1130,1131,1132,1137,1138,1141,1145,1147,1148,1149,1151,1152,1154,1163,1164,1165,1166,1169,1174,1175,1183,1185,1186,1187,1192,1198,1199,1201,1213,1216,1217,1218,1233,1234,1236,1244,1247,1248,1259,1271,1272,1277,1287,1296,1300,1301,1309,1310,1311,1322,1328,1334,1352,1417,1433,1434,1443,1455,1461,1494,1500,1501,1503,1521,1524,1533,1556,1580,1583,1594,1600,1641,1658,1666,1687,1688,1700,1717,1718,1719,1720,1721,1723,1755,1761,1782,1783,1801,1805,1812,1839,1840,1862,1863,1864,1875,1900,1914,1935,1947,1971,1972,1974,1984,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2013,2020,2021,2022,2030,2033,2034,2035,2038,2040,2041,2042,2043,2045,2046,2047,2048,2049,2065,2068,2099,2100,2103,2105,2106,2107,2111,2119,2121,2126,2135,2144,2160,2161,2170,2179,2190,2191,2196,2200,2222,2251,2260,2288,2301,2323,2366,2381,2382,2383,2393,2394,2399,2401,2492,2500,2522,2525,2557,2601,2602,2604,2605,2607,2608,2638,2701,2702,2710,2717,2718,2725,2800,2809,2811,2869,2875,2909,2910,2920,2967,2968,2998,3000,3001,3003,3005,3006,3007,3011,3013,3017,3030,3031,3050,3052,3071,3077,3128,3168,3211,3221,3260,3261,3268,3269,3283,3300,3301,3306,3322,3323,3324,3325,3333,3351,3367,3369,3370,3371,3372,3389,3390,3404,3476,3493,3517,3527,3546,3551,3580,3659,3689,3690,3703,3737,3766,3784,3800,3801,3809,3814,3826,3827,3828,3851,3869,3871,3878,3880,3889,3905,3914,3918,3920,3945,3971,3986,3995,3998,4000,4001,4002,4003,4004,4005,4006,4045,4111,4125,4126,4129,4224,4242,4279,4321,4343,4443,4444,4445,4446,4449,4550,4567,4662,4848,4899,4900,4998,5000,5001,5002,5003,5004,5009,5030,5033,5050,5051,5054,5060,5061,5080,5087,5100,5101,5102,5120,5190,5200,5214,5221,5222,5225,5226,5269,5280,5298,5357,5405,5414,5431,5432,5440,5500,5510,5544,5550,5555,5560,5566,5631,5633,5666,5678,5679,5718,5730,5800,5801,5802,5810,5811,5815,5822,5825,5850,5859,5862,5877,5900,5901,5902,5903,5904,5906,5907,5910,5911,5915,5922,5925,5950,5952,5959,5960,5961,5962,5963,5987,5988,5989,5998,5999,6000,6001,6002,6003,6004,6005,6006,6007,6009,6025,6059,6100,6101,6106,6112,6123,6129,6156,6346,6389,6502,6510,6543,6547,6565,6566,6567,6580,6646,6666,6667,6668,6669,6689,6692,6699,6779,6788,6789,6792,6839,6881,6901,6969,7000,7001,7002,7004,7007,7019,7025,7070,7100,7103,7106,7200,7201,7402,7435,7443,7496,7512,7625,7627,7676,7741,7777,7778,7800,7911,7920,7921,7937,7938,7999,8000,8001,8002,8007,8008,8009,8010,8011,8021,8022,8031,8042,8045,8080,8081,8082,8083,8084,8085,8086,8087,8088,8089,8090,8093,8099,8100,8180,8181,8192,8193,8194,8200,8222,8254,8290,8291,8292,8300,8333,8383,8400,8402,8443,8500,8600,8649,8651,8652,8654,8701,8800,8873,8888,8899,8994,9000,9001,9002,9003,9009,9010,9011,9040,9050,9071,9080,9081,9090,9091,9099,9100,9101,9102,9103,9110,9111,9200,9207,9220,9290,9415,9418,9485,9500,9502,9503,9535,9575,9593,9594,9595,9618,9666,9876,9877,9878,9898,9900,9917,9943,9944,9968,9998,9999,10000,10001,10002,10003,10004,10009,10010,10012,10024,10025,10082,10180,10215,10243,10566,10616,10617,10621,10626,10628,10629,10778,11110,11111,11967,12000,12174,12265,12345,13456,13722,13782,13783,14000,14238,14441,14442,15000,15002,15003,15004,15660,15742,16000,16001,16012,16016,16018,16080,16113,16992,16993,17877,17988,18040,18101,18988,19101,19283,19315,19350,19780,19801,19842,20000,20005,20031,20221,20222,20828,21571,22939,23502,24444,24800,25734,25735,26214,27000,27352,27353,27355,27356,27715,28201,30000,30718,30951,31038,31337,32768,32769,32770,32771,32772,32773,32774,32775,32776,32777,32778,32779,32780,32781,32782,32783,32784,32785,33354,33899,34571,34572,34573,35500,38292,40193,40911,41511,42510,44176,44442,44443,44501,45100,48080,49152,49153,49154,49155,49156,49157,49158,49159,49160,49161,49163,49165,49167,49175,49176,49400,49999,50000,50001,50002,50003,50006,50300,50389,50500,50636,50800,51103,51493,52673,52822,52848,52869,54045,54328,55055,55056,55555,55600,56737,56738,57294,57797,58080,60020,60443,61532,61900,62078,63331,64623,64680,65000,65129,65389';
   }
   elsif ($ports !~ /^[0-9,-]+$/) {
      $log->fatal("Invalid port range for -port argument: [$ports]");
   }

   my @ports = ();
   for my $c (split(',', $ports)) {
      $c =~ s/-/../g;
      for my $p (eval($c)) {
         push @ports, $p;
      }
   }

   #$log->debug("Expanding target ports: Done (count: ".scalar(@ports).")");

   return \@ports;
}

sub expandFiles {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (!defined($h{files})) {
      $log->fatal("expandFiles: You must provide files attribute");
   }
   my $files = $h{files};

   my @list = <{$files}>;
   if (@list == 0) {
      $log->warning("expandFiles: no file found");
      return;
   }

   return \@list;
}

sub lookupMac {
   my $self = shift;

   my $log = $self->log;

   if (! $self->macLookup) {
      $log->verbose("MAC lookup disabled");
      return;
   }

   print "XXX: TODO\n";

   return;
}

sub lookupMac6 {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (! $self->macLookup) {
      $log->verbose("MAC lookup disabled");
      return;
   }

   if (!defined($h{ipv6})) {
      $log->fatal("lookupMac6: You must provide ipv6 attribute");
   }
   my $ipv6 = $h{ipv6};

   $log->verbose("Trying to find MAC address for target IPv6: [$ipv6]");

   my $cacheArp = $self->cacheArp;

   my $mac;
   if (defined($cacheArp->{$ipv6})) {
      $mac = $cacheArp->{$ipv6};
      $log->verbose("Found MAC address: [$mac] from cache");
   }
   else {
      my $dev = Net::Frame::Device->new(
         target6 => $ipv6,
         dev     => $self->device,
      );
      if (!defined($dev)) {
         $log->fatal("lookupMac6: unable to acquire device for target6 [".
                      $ipv6."]");
         return;
      }

      $mac = $dev->lookupMac6($ipv6, $self->retry, $self->timeout);
      if (!defined($mac)) {
         $log->fatal("lookupMac6: unable to get MAC address for IPv6 [".
                      $ipv6."]");
         return;
      }
      $cacheArp->{$ipv6} = $mac;
      $log->verbose("Found MAC address: [$mac] from lookup");
   }

   return $mac;
}

sub _getHostIpv6Addr {
   my ($host) = @_;

   if (Net::IPv6Addr::is_ipv6($host)) {
      return $host;
   }

   my @res = getaddrinfo($host, 'ssh', Socket6::AF_INET6(), SOCK_STREAM);
   if (@res >= 5) {
      my ($ipv6) = getnameinfo($res[3], NI_NUMERICHOST | NI_NUMERICSERV);
      $ipv6 =~ s/%.*$//;
      return $ipv6;
   }

   return;
}

sub _getHostIpv4Addr {
   my ($host) = @_;

   if ($host =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
      return $host;
   }

   my @addrs = (gethostbyname($host))[4];
   return @addrs ? join('.', CORE::unpack('C4', $addrs[0]))
                 : undef;
}

sub getHostAddr {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (!defined($h{host})) {
      $log->fatal("getHostAddr: You must provide host attribute");
   }
   my $host = $h{host};

   my $ip = $self->ipv6 ? _getHostIpv6Addr($host) : _getHostIpv4Addr($host);
   if (!defined($ip)) {
      $log->warning("getHostAddr: unable to resolve ".
                    ($self->ipv6 ? 'IPv6' : 'IPv4').
                    " address for hostname [$host]");
      return;
   }

   return $ip;
}

sub getAddrReverse {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (!defined($h{addr})) {
      $log->fatal("getAddrReverse: You must provide addr attribute");
   }
   my $addr = $h{addr};

   $log->verbose("Trying reverse lookup for IP [$addr]");

   my $reverse;
   if ($self->ipv6) {
      my $inet = inet_pton(Socket6::AF_INET6(), $addr);
      if (!defined($inet)) {
         $log->warning("getAddrReverse: unable to get reverse on IPv6 ".
                       "[$addr]");
         return;
      }
      $reverse = gethostbyaddr($inet, Socket6::AF_INET6());
   }
   else {
      my $inet = inet_aton($addr);
      if (!defined($inet)) {
         $log->warning("getAddrReverse: unable to get reverse on IPv4 ".
                       "[$addr]");
         return;
      }
      $reverse = gethostbyaddr($inet, AF_INET);
   }

   if ($reverse) {
      $log->verbose("Reverse lookup gave: [$reverse]");
   }
   else {
      $log->verbose("Reverse lookup gave nothing");
   }

   return $reverse;
}

sub ipToInt {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (! defined($h{ip})) {
      $log->fatal("ipToInt: You must provide `ip' attribute");
   }
   my $ip = $h{ip};

   if ($self->ipv6) {
      # XXX: Should use inet_pton for IPv6 support
      $log->warning("IPv6 to Int not supported, doing nothing");
      return $ip;
   }

   my $int = $ip;
   # Is this not yet in Int format?
   if ($ip !~ /^\d+$/) {
      $int = unpack('N', inet_aton($ip));
      if (! defined($int)) {
         $log->error("Unable to IP to Int address: [$ip]: $!");
         return;
      }
   }

   return $int;
}

sub intToIp {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (! defined($h{int})) {
      $log->fatal("intToIp: You must provide `int' attribute");
   }
   my $int = $h{int};

   if ($self->ipv6) {
      # XXX: Should use inet_ntop for IPv6 support
      $log->warning("Int to IPv6 not supported, doing nothing");
      return $int;
   }

   my $ip = $int;
   # Is this in Int format?
   if ($int =~ /^\d+$/) {
      $ip = inet_ntoa(pack('N', $int));
      if (! defined($ip)) {
         $log->error("Unable to Int to IP address: [$int]: $!");
         return;
      }
   }

   return $ip;
}

sub getDumpOnline {
   my $self = shift;
   my %h = @_;

   if (defined($h{filter})) {
      $self->log->verbose("getDumpOnline: Using filter [$h{filter}]")
   }

   my $oDump = Net::Frame::Dump::Online2->new(
      dev           => $self->device,
      timeoutOnNext => $self->timeout,
      %h,
   );

   return $oDump;
}

sub getDumpOffline {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (!defined($h{file})) {
      $log->fatal("getDumpOffline: You must provide file attribute");
   }

   if (!-f $h{file}) {
      $log->warning("getDumpOffline: File [$h{file}] not found");
      return;
   }

   if (defined($h{filter})) {
      $log->verbose("getDumpOffline: Using filter [$h{filter}]")
   }

   my $oDump = Net::Frame::Dump::Offline->new(%h);

   return $oDump;
}

sub getDumpWriter {
   my $self = shift;
   my %h = @_;

   my $oDump = Net::Frame::Dump::Writer->new(%h);

   return $oDump;
}

sub getWriteL2 {
   my $self = shift;

   my $oWrite = Net::Write::Layer2->new(dev => $self->device);

   return $oWrite;
}

sub getWriteL3 {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (!defined($h{dst})) {
      $log->fatal("getWriteL3: You must provide dst attribute");
   }

   my $oWrite = Net::Write::Layer3->new(%h);

   return $oWrite;
}

sub getWrite {
   my $self = shift;
   my %h = @_;

   return $self->ipv6 ? $self->getWriteL2(%h)
                      : $self->getWriteL3(%h);

   return;
}

sub tcpConnect {
   my $self = shift;
   my %h = @_;

   my $log = $self->log;

   if (!defined($h{ip})) {
      $log->fatal("tcpConnect: You must provide ip attribute");
   }
   if (!defined($h{port})) {
      $log->fatal("tcpConnect: You must provide port attribute");
   }

   my $mod = $self->ipv6 ? 'IO::Socket::INET6' : 'IO::Socket::INET';
   my $socket = $mod->new(
      PeerHost => $h{ip},
      PeerPort => $h{port},
      Proto    => 'tcp',
      Timeout  => $self->timeout,
   );
   if (!defined($socket)) {
      $log->warning("tcpConnect: [$h{ip}]:$h{port}: $!");
      return;
   }

   $socket->blocking(0);
   $socket->autoflush(1);

   return $socket;
}

1;

__END__

=head1 NAME

Net::SinFP3::Global - global configuration and useful methods for all objects

=head1 SYNOPSIS

   use Net::SinFP3::Global;

   my $global = Net::SinFP3::Global->new(
      log => $log,
   );

=head1 DESCRIPTION

This is nearly the first object to create when you want to use B<Net::SinFP3> framework. This object is given to every other objects (manually or automatically) and serves as parameter bridging between all of them.

This object also gives access to useful methods that plugins may use.

=head1 ATTRIBUTES

=over 4

=item B<log> (B<Net::SinFP3::Log>)

Will contain a B<Net::SinFP3::Log> object.

=item B<job> ($scalar)

This is the current job ID in the context of running process.

=item B<next> (B<Net::SinFP3::Next>)

This is the current B<Net::SinFP3::Next> in the context of running process.

=item B<input> (B<Net::SinFP3::Input>)

This is the current B<Net::SinFP3::Input> in the context of running process.

=item B<db> (B<Net::SinFP3::DB>)

This is the current B<Net::SinFP3::DB> in the context of running process.

=item B<mode> (B<Net::SinFP3::Mode>)

This is the current B<Net::SinFP3::Mode> in the context of running process.

=item B<search> (B<Net::SinFP3::Search>)

This is the current B<Net::SinFP3::Search> in the context of running process.

=item B<output> (B<Net::SinFP3::Output>)

This is the current B<Net::SinFP3::Output> in the context of running process.

=item B<target> ($scalar)

The target is either an IPv4 address, an IPv6 address or a hostname. Device information will be gathered by using this value (if provided).

=item B<ipv6> ($scalar)

Use IPv6 mode globally or not (default to not).

=item B<jobs> ($scalar)

The maximum number of jobs to do in parallel (default to 10).

=item B<dnsReverse> ($scalar)

Do reverse DNS lookups or not (default to not).

=item B<worker> ($scalar)

Specify which worker model you want to use. This is either 'fork' or 'thread' currently (default to 'fork').

=item B<device> ($scalar)

Network device to use (default to auto-discovered).

=item B<retry> ($scalar)

The number of retry to perform on actions requiring such thing (default to 3).

=item B<timeout> ($scalar)

The number of seconds before timing out on actions requiring such thing (default to 3).

=item B<ip> ($scalar)

My IPv4 address (default to auto-discovered).

=item B<ip6> ($scalar)

My IPv6 address (default to auto-discovered).

=item B<mac> ($scalar)

My MAC address (default to auto-discovered).

=item B<subnet> ($scalar)

My subnetwork address (default to auto-discovered).

=item B<gatewayIp> ($scalar)

My gateway IPv4 address (default to auto-discovered).

=item B<gatewayIp6> ($scalar)

My gateway IPv6 address (default to auto-discovered).

=item B<gatewayMac> ($scalar)

My gateway MAC address (default to auto-discovered).

=item B<result> ([ B<Net::SinFP3::Result>, ... ])

This attribute will be set by the currently running B<Net::SinFP3::Search> plugin after it has been B<run>.

=back

=head1 METHODS

All these methods print a warning and return undef on failure.

=over 4

=item B<new> (%hash)

Object contructor. You must give it the following attributes: B<log>. All device related thingies will be automatically found. If you don't want this behaviour, you can manually specify attributes within this object constructor.

=item B<expandSubnet> (subnet => $scalar)

Takes a subnet string in CIDR format (192.168.0/24) and returns an arrayref of IPv4 addresses.

=item B<expandPorts> (ports => $scalar)

Takes a ports string and returns an arrayref of unique ports. The format is using ',' and '-' characters. Examples: '1-65535' or '80,443' or '1-1024,8000'.  You can also specify either one of top10, top100, top1000 or all ports to respectively scan top 10, 100, 1000 or all ports on the target.

=item B<expandFiles> (files => $scalar)

Takes a string that will feed a B<glob> function in order to return an arrayref of files.

=item B<lookupMac> (ip => $scalar)

Will return the MAC address of the target IPv4 host, or the MAC address of the IPv4 gateway.

=item B<lookupMac6> (ipv6 => $scalar)

Will return the MAC address of the target IPv6 host, or the MAC address of the IPv6 gateway.

=item B<getHostAddr> (host => $scalar)

Tries to resolve the IP address of the target host. It will use B<ipv6> attribute to resolve in IPv6 or IPv4 mode.

=item B<intToIp> (ip => $scalar)

Converts an IP address in presentation notation to numerical notation.

=item B<ipToInt> (int => $scalar)

Converts an IP address in numerical notation to presentation notation.

=item B<getAddrReverse> (addr => $scalar)

Tries to do a reverse lookup of the target host. It will use B<ipv6> attribute to resolve in IPv6 or IPv4 mode.

=item B<getDumpOnline> (%hash)

Will return a B<Net::Frame::Dump::Online2> object. See that module to know which attributes you can provide in the hash.

=item B<getDumpOffline> (file => $scalar, %hash)

Will return a B<Net::Frame::Dump::Offline> object. See that module to know which attributes you can provide in the hash. You must at list provide the file attribute.

=item B<getDumpWriter> (%hash)

Will return a B<Net::Frame::Dump::Writer> object. See that module to know which attributes you can provide in the hash.

=item B<getWriteL2> ()

Will return a B<Net::Write::Layer2> object. It will use the B<device> attribute to know which layer 2 link to use.

=item B<getWriteL3> (dst => $scalar)

Will return a B<Net::Write::Layer3> object. It will use dst attribute to know which interface to use.

=item B<getWrite> (%hash)

Will return a B<Net::Write::Layer3> or B<Net::Write::Layer2> object depending on the value of B<ipv6> attribute.

=item B<tcpConnect> (ip => $scalar, port => $scalar)

Will try to connect to the remote host.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
