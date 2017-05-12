use lib "./t";
use ExtUtils::TBone;

BEGIN {
	use lib '..';
	
	use Net::IP qw(:PROC);

	if (eval (require Math::BigInt))
	{
		$math_bigint = 1;
	};
};

my $numtests = 8031;

# Create checker:
my $T = typical ExtUtils::TBone;
#my $T = new ExUtils::TBone "log.txt";

$numtests++ if $math_bigint;

$T->begin($numtests);
#------------------------------------------------------------------------------



$ip = new Net::IP('195.114.80/24',4);

$T->ok (defined($ip),$Net::IP::Error);
$T->ok_eq ($ip->binip(),'11000011011100100101000000000000',$ip->error());
$T->ok_eq ($ip->ip(),'195.114.80.0',$ip->error());
$T->ok_eq ($ip->print(),'195.114.80/24',$ip->error());
$T->ok_eq ($ip->hexip(),'0xc3725000',$ip->error());
$T->ok_eq ($ip->hexmask(),'0xffffff00',$ip->error());
$T->ok_eqnum ($ip->prefixlen(),24,$ip->error());
$T->ok_eqnum ($ip->version(),4,$ip->error());
$T->ok_eqnum ($ip->size(),256,$ip->error());
$T->ok_eq ($ip->binmask(),'11111111111111111111111100000000',$ip->error());
$T->ok_eq ($ip->mask(),'255.255.255.0',$ip->error());
$T->ok_eqnum ($ip->intip(),3279048704,$ip->error()) if $math_bigint;
$T->ok_eq ($ip->iptype(),'PUBLIC',$ip->error());
$T->ok_eq ($ip->reverse_ip(),'80.114.195.in-addr.arpa.',$ip->error());
$T->ok_eq ($ip->last_bin(),'11000011011100100101000011111111',$ip->error());
$T->ok_eq ($ip->last_ip(),'195.114.80.255',$ip->error());

$ip->set('202.31.4/24');
$T->ok_eq ($ip->ip(),'202.31.4.0',$ip->error());

$ip->set('234.245.252.253/2');
$T->ok_eq ($ip->error(),'Invalid prefix 11101010111101011111110011111101/2',$ip->error());
$T->ok_eqnum ($ip->errno(),171,$ip->error());

$ip->set('62.33.41.9');
$ip2 = new Net::IP('0.1.0.5');
$T->ok_eq ($ip->binadd($ip2)->ip(),'62.34.41.14',$ip->error());

$ip->set('133.45.0/24');
$ip2 = new Net::IP('133.45.1/24');
$T->ok_eqnum ($ip->aggregate($ip2)->prefixlen(),23,$ip->error());

$ip2 = new Net::IP('133.44.255.255');
$T->ok_eqnum ($ip->bincomp('gt',$ip2),1,$ip->error());

$ip = new Net::IP('133.44.255.255-133.45.0.42');
$T->ok_eq (($ip->find_prefixes())[3],'133.45.0.40/31',$ip->error());

$ip = new Net::IP('192.168.2.254-192.168.2.255');
my @prefixes = $ip->find_prefixes();
$T->ok_eqnum (scalar(@prefixes), 1);
$T->ok_eq ($prefixes[0],'192.168.2.254/31',$ip->error());

$ip->set('201.33.128.0/22');
$ip2->set('201.33.129.0/24');

$T->ok_eqnum ($ip->overlaps($ip2),$IP_B_IN_A_OVERLAP,$ip->error());

$ip->set('192.168.0.3/32');
$T->ok_eqnum ($ip->size,1,$ip->error());

# test if hexip changes when ip is set (bug 80164 RT)
$ip = new Net::IP('195.114.80/24',4);
$hex1 = $ip->hexip;
$ip->set('192.168.0.3/32');
$hex2 = $ip->hexip;
$T->ok($hex1 ne $hex2, "Hex IP should not match (hexip1:$hex1  hexip2:$hex2");

# regression test bug 32232 RT
$ip->set('61-217-102-8.hinet-ip.hinet.net');
$T->ok_eq ($ip->error(),'Not a valid IPv4 address 217-102-8.hinet-ip.hinet.net',$ip->error());
$T->ok_eqnum ($ip->errno(),102,$ip->error());


#------------------------------------------------------------------------------
# test for network types

sub rbin { return int(2*rand); }
sub ip2bin { return unpack('B32', pack('C4C4C4C4', split(/\./, shift))); }
sub bin2ip { return join('.', unpack('C4C4C4C4', pack('B32', shift))); }
sub v4_first {
    my $network = shift;
    while (length $network < 32) {
     $network .= '0'; 
    }
    return bin2ip($network);
}
sub v4_last {
    my $network = shift;
    while (length $network < 32) {
     $network .= '1'; 
    }
    return bin2ip($network);
}
sub v4_rand {
    my $network = shift;
    while (length $network < 32) {
     $network .= rbin(); 
    }
    return bin2ip($network);
}
sub v4_okeq {
   my $ip = Net::IP->new(shift);
   $T->msg('IPv4: '.$ip->print );
   $T->ok_eq ($ip->iptype(), shift, $ip->error());
   return;
}
sub v4_nettest {
  my $ip = shift;
  my $prefix = shift;
  my $iptype = shift;
  my $numoftests = shift;
  my $network      = substr( ip2bin($ip), 0, $prefix);
  
  die "ERROR! At least 3 tests must be run." if $numoftests < 3;

  v4_okeq( v4_first( $network ), $iptype );
  v4_okeq( v4_last(  $network ), $iptype );
  $numoftests -= 2;
    
  while ($numoftests--) {
     v4_okeq( v4_rand( $network ), $iptype ); 
  }    
 
  # done
  return;
}


# Address Block       Present Use                Reference
# ------------------------------------------------------------------
# 0.0.0.0/8           "This" Network             RFC 1122, Section 3.2.1.3     PRIVATE
# 10.0.0.0/8          Private-Use Networks       RFC 1918                      PRIVATE
# 100.64.0.0/10       CGN Shared Address Space   RFC 6598                      SHARED
# 127.0.0.0/8         Loopback                   RFC 1122, Section 3.2.1.3     LOOPBACK
# 169.254.0.0/16      Link Local                 RFC 3927                      LINK-LOCAL
# 172.16.0.0/12       Private-Use Networks       RFC 1918                      PRIVATE
# 192.0.0.0/24        IETF Protocol Assignments  RFC 5736                      RESERVED
# 192.0.2.0/24        TEST-NET-1                 RFC 5737                      TEST-NET
# 192.88.99.0/24      6to4 Relay Anycast         RFC 3068                      6TO4-RELAY
# 192.168.0.0/16      Private-Use Networks       RFC 1918                      PRIVATE
# 198.18.0.0/15       Network Interconnect               
#                     Device Benchmark Testing   RFC 2544                      RESERVED
# 198.51.100.0/24     TEST-NET-2                 RFC 5737                      TEST-NET
# 203.0.113.0/24      TEST-NET-3                 RFC 5737                      TEST-NET
# 224.0.0.0/4         Multicast                  RFC 3171                      MULTICAST
# 240.0.0.0/4         Reserved for Future Use    RFC 1112, Section 4           RESERVED
# 255.255.255.255/32  Limited Broadcast          RFC 919, Section 7            BROADCAST
#                                                RFC 922, Section 7


v4_nettest( '0.0.0.0',           8, 'PRIVATE',    100); #  1
v4_nettest( '10.0.0.0',          8, 'PRIVATE',    100); #  2
v4_nettest( '100.64.0.0',       10, 'SHARED',     100); #  3
v4_nettest( '127.0.0.0',         8, 'LOOPBACK',   100); #  4
v4_nettest( '169.254.0.0',      16, 'LINK-LOCAL', 100); #  5
v4_nettest( '172.16.0.0',       12, 'PRIVATE',    100); #  6
v4_nettest( '192.0.0.0',        24, 'RESERVED',   100); #  7
v4_nettest( '192.0.2.0',        24, 'TEST-NET',   100); #  8
v4_nettest( '192.88.99.0',      24, '6TO4-RELAY', 100); #  9   
v4_nettest( '192.168.0.0',      16, 'PRIVATE',    100); # 10
v4_nettest( '198.18.0.0',       15, 'RESERVED',   100); # 11
v4_nettest( '198.51.100.0',     24, 'TEST-NET',   100); # 12
v4_nettest( '203.0.113.0',      24, 'TEST-NET',   100); # 13
v4_nettest( '224.0.0.0',         4, 'MULTICAST',  100); # 14
# the 240/4 net can not be tested directly because the last ip in the block 255.255.255.255/32 has another type
v4_nettest( '240.0.0.0',         5, 'RESERVED',   100); # 15
v4_nettest( '248.0.0.0',         6, 'RESERVED',   100); # 16
v4_nettest( '252.0.0.0',         7, 'RESERVED',   100); # 17
v4_nettest( '254.0.0.0',         8, 'RESERVED',   100); # 18
v4_nettest( '255.0.0.0',         9, 'RESERVED',   100); # 19
v4_nettest( '255.128.0.0',      10, 'RESERVED',   100); # 20
v4_nettest( '255.192.0.0',      11, 'RESERVED',   100); # 21
v4_nettest( '255.224.0.0',      12, 'RESERVED',   100); # 22
v4_nettest( '255.240.0.0',      13, 'RESERVED',   100); # 23
v4_nettest( '255.248.0.0',      14, 'RESERVED',   100); # 24
v4_nettest( '255.252.0.0',      15, 'RESERVED',   100); # 25
v4_nettest( '255.254.0.0',      16, 'RESERVED',   100); # 26
v4_nettest( '255.255.0.0',      17, 'RESERVED',   100); # 27
v4_nettest( '255.255.128.0',    18, 'RESERVED',   100); # 28
v4_nettest( '255.255.192.0',    19, 'RESERVED',   100); # 29
v4_nettest( '255.255.224.0',    20, 'RESERVED',   100); # 30
v4_nettest( '255.255.240.0',    21, 'RESERVED',   100); # 31
v4_nettest( '255.255.248.0',    22, 'RESERVED',   100); # 32
v4_nettest( '255.255.252.0',    23, 'RESERVED',   100); # 33
v4_nettest( '255.255.254.0',    24, 'RESERVED',   100); # 34
v4_nettest( '255.255.255.0',    25, 'RESERVED',   100); # 35
v4_nettest( '255.255.255.128',  26, 'RESERVED',   100); # 36
v4_nettest( '255.255.255.192',  27, 'RESERVED',   100); # 37
v4_nettest( '255.255.255.224',  28, 'RESERVED',   100); # 38
v4_nettest( '255.255.255.240',  29, 'RESERVED',   100); # 39
v4_nettest( '255.255.255.248',  30, 'RESERVED',   100); # 40
v4_nettest( '255.255.255.252',  31, 'RESERVED',   100); # 41
v4_okeq(  '255.255.255.254', 'RESERVED');           
v4_okeq(  '255.255.255.255', 'BROADCAST');

# check boundary networks to be public
v4_nettest( '1.0.0.0',       8, 'PUBLIC', 100); # 42
v4_nettest( '8.0.0.0',       8, 'PUBLIC', 100); # 43
v4_nettest( '9.0.0.0',       8, 'PUBLIC', 100); # 44
v4_nettest( '11.0.0.0',      8, 'PUBLIC', 100); # 45
v4_nettest( '100.63.0.0',   10, 'PUBLIC', 100); # 46
v4_nettest( '100.128.0.0',  10, 'PUBLIC', 100); # 47
v4_nettest( '100.192.0.0',  10, 'PUBLIC', 100); # 48
v4_nettest( '126.0.0.0',     8, 'PUBLIC', 100); # 49
v4_nettest( '128.0.0.0',     8, 'PUBLIC', 100); # 50
v4_nettest( '169.253.0.0',  16, 'PUBLIC', 100); # 51
v4_nettest( '169.255.0.0',  16, 'PUBLIC', 100); # 52
v4_nettest( '172.15.0.0',   12, 'PUBLIC', 100); # 53
v4_nettest( '172.32.0.0',   12, 'PUBLIC', 100); # 54 
v4_nettest( '172.48.0.0',   12, 'PUBLIC', 100); # 55

v4_nettest( '191.255.255.0',24, 'PUBLIC', 100); # 56
v4_nettest( '192.0.1.0',    24, 'PUBLIC', 100); # 57

v4_nettest( '192.0.1.0',    24, 'PUBLIC', 100); # 58
v4_nettest( '192.0.3.0',    24, 'PUBLIC', 100); # 59

v4_nettest( '192.88.96.0',  24, 'PUBLIC', 100); # 60
v4_nettest( '192.88.97.0',  24, 'PUBLIC', 100); # 61
v4_nettest( '192.88.98.0',  24, 'PUBLIC', 100); # 62
v4_nettest( '192.88.100.0', 24, 'PUBLIC', 100); # 63
v4_nettest( '192.88.103.0', 24, 'PUBLIC', 100); # 64

v4_nettest( '192.160.0.0',  16, 'PUBLIC', 100); # 65
v4_nettest( '192.187.0.0',  16, 'PUBLIC', 100); # 66
v4_nettest( '192.175.0.0',  16, 'PUBLIC', 100); # 67
v4_nettest( '192.176.0.0',  16, 'PUBLIC', 100); # 68

v4_nettest( '198.16.0.0',   15, 'PUBLIC', 100); # 69
v4_nettest( '198.17.0.0',   15, 'PUBLIC', 100); # 70
v4_nettest( '198.20.0.0',   15, 'PUBLIC', 100); # 71
v4_nettest( '198.22.0.0',   15, 'PUBLIC', 100); # 72

v4_nettest( '198.48.100.0', 24, 'PUBLIC', 100); # 73
v4_nettest( '198.49.100.0', 24, 'PUBLIC', 100); # 74
v4_nettest( '198.50.100.0', 24, 'PUBLIC', 100); # 75
v4_nettest( '198.52.100.0', 24, 'PUBLIC', 100); # 76
v4_nettest( '198.55.100.0', 24, 'PUBLIC', 100); # 77

v4_nettest( '203.0.112.0',  24, 'PUBLIC', 100); # 78
v4_nettest( '203.0.114.0',  24, 'PUBLIC', 100); # 79
v4_nettest( '203.0.115.0',  24, 'PUBLIC', 100); # 80


#------------------------------------------------------------------------------
$T->end;
1;
