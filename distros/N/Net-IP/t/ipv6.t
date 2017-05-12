use lib "./t";
use ExtUtils::TBone;
use Net::IP qw(:PROC);

BEGIN {
	if (eval (require Math::BigInt))
	{
		$math_bigint = 1;
	};
};
my $numtests = 28;

# Create checker:
my $T = typical ExtUtils::TBone;

$numtests++ if $math_bigint;

$numtests += 28 * 1000 + 8; # IPv6 network type tests 

$T->begin($numtests);
#------------------------------------------------------------------------------

$ip = new Net::IP('dead:beef:0::/48',6);

$T->ok (defined($ip),$Net::IP::ERROR);
$T->ok_eq ($ip->binip(),'11011110101011011011111011101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',$ip->error());
$T->ok_eq ($ip->ip(),'dead:beef:0000:0000:0000:0000:0000:0000',$ip->error());
$T->ok_eq ($ip->short(),'dead:beef::',$ip->error());
$T->ok_eq ($ip->hexip(),'0xdeadbeef000000000000000000000000',$ip->error());
$T->ok_eq ($ip->hexmask(),'0xffffffffffff00000000000000000000',$ip->error());
$T->ok_eqnum ($ip->prefixlen(),48,$ip->error());
$T->ok_eqnum ($ip->version(),6,$ip->error());
$T->ok_eq ($ip->mask(),'ffff:ffff:ffff:0000:0000:0000:0000:0000',$ip->error());

if ($math_bigint)
{
	my $n = new Math::BigInt ('295990755014133383690938178081940045824');

	$T->ok_eqnum ($ip->intip(),$n,$ip->error());
}

$T->ok_eq ($ip->iptype(),'RESERVED',$ip->error());
$T->ok_eq ($ip->reverse_ip(),'0.0.0.0.f.e.e.b.d.a.e.d.ip6.arpa.',$ip->error());
$T->ok_eq ($ip->last_ip(),'dead:beef:0000:ffff:ffff:ffff:ffff:ffff',$ip->error());

$ip->set('202.31.4/24',4);
$T->ok_eq ($ip->ip(),'202.31.4.0',$ip->error());

$ip->set(':1/128');
$T->ok_eq ($ip->error(),'Invalid address :1 (starts with :)',$ip->error());
$T->ok_eqnum ($ip->errno(),109,$ip->error());


$ip->set('ff00:0:f000::');
$ip2 = new Net::IP('0:0:1000::');
$T->ok_eq ($ip->binadd($ip2)->short(),'ff00:1::',$ip->error());

$ip->set('::e000:0/112');
$ip2->set('::e001:0/112');
$T->ok_eqnum ($ip->aggregate($ip2)->prefixlen(),111,$ip->error());

$ip2->set('::dfff:ffff');
$T->ok_eqnum ($ip->bincomp('gt',$ip2),1,$ip->error());

$ip->set('::e000:0 - ::e002:42');

$T->ok_eq (($ip->find_prefixes())[2],'0000:0000:0000:0000:0000:0000:e002:0040/127',$ip->error());

$ip->set('ffff::/16');
$ip2->set('8000::/16');

$T->ok_eqnum ($ip->overlaps($ip2),$IP_NO_OVERLAP,$ip->error());

# regression test bug 74898 RT
$T->ok_eq( ip_compress_address ("2221:0:0:f800::1", 6), '2221:0:0:f800::1');

# regression test bug 73232 RT
$T->ok( !ip_is_ipv6('1:2:3:4:5:6:7'), 'Invalid IPv6 1:2:3:4:5:6:7');
$T->ok( ip_is_ipv6('::1'), 'Valid ip ::1');
$T->ok( ip_is_ipv6('2001::'), 'Valid ip 2001::');
$T->ok( !ip_is_ipv6("1:2") , 'Invalid ip 1:2'); # bug 73105 RT

# regression test bug 73104 RT
$T->ok( !defined ip_expand_address("1::2::3",6), 'Expand invalid 1::2::3');
$T->ok_eq(Error(), 'Too many :: in ip');
$T->ok_eqnum(Errno(), 102);

# regression test bug 71042 RT
$T->ok_eq( ip_reverse("2001:4f8:3:36:0:0:0:235", 128, 6), '5.3.2.0.0.0.0.0.0.0.0.0.0.0.0.0.6.3.0.0.3.0.0.0.8.f.4.0.1.0.0.2.ip6.arpa.'); 
$T->ok_eq( ip_reverse("2001:4f8:3:36::235", 128, 6), '5.3.2.0.0.0.0.0.0.0.0.0.0.0.0.0.6.3.0.0.3.0.0.0.8.f.4.0.1.0.0.2.ip6.arpa.'); 

#------------------------------------------------------------------------------
# test for network types
sub v6_expand {
    my ($ip) = @_;

    # Keep track of ::
    $ip =~ s/::/:!:/;

    # IP as an array
    my @ip = split /:/, $ip;


    # prepare result string
    $ip = '';
    
    # go through all octets
    foreach (@ip) {

        # insert octet divider
        $ip .= ':' if length($ip);
        
        # replace ! with 0 octets
        if ($_ eq '!') {
            my $num_of_zero_octets = 9 - scalar(@ip);
            $ip .= ('0000:' x ($num_of_zero_octets - 1)) . '0000';
            next; 
        }
        
        # Add missing trailing 0s
        $ip .= ('0' x (4 - length($_))) . $_;
    }

    return lc($ip);
}
sub rbin { return int(2*rand); }
sub ip2bin { my $ip = v6_expand(shift);  $ip =~ s/://g;  return unpack('B128', pack('H32', $ip)); }
sub bin2ip { return join(':', unpack('H4H4H4H4H4H4H4H4', pack('B128', shift))); }
sub v6_first {
    my $network = shift;
    while (length $network < 128) {
     $network .= '0'; 
    }
    return bin2ip($network);
}
sub v6_last {
    my $network = shift;
    while (length $network < 128) {
     $network .= '1'; 
    }
    return bin2ip($network);
}
sub v6_rand {
    my $network = shift;
    while (length $network < 128) {
     $network .= rbin(); 
    }
    return bin2ip($network);
}
sub v6_okeq {
   my $ip = Net::IP->new(shift);
   $T->msg('IPv6: '.$ip->print );
   $T->ok_eq ($ip->iptype(), shift, $ip->error());
   return;
}
sub v6_nettest {
  my $ip = shift;
  my $prefix = shift;
  my $iptype = shift;
  my $numoftests = shift;
  my $network      = substr( ip2bin($ip), 0, $prefix);
  
  die "ERROR! At least 3 tests must be run." if $numoftests < 3;

  v6_okeq( v6_first( $network ), $iptype );
  v6_okeq( v6_last(  $network ), $iptype );
  $numoftests -= 2;
    
  while ($numoftests--) {
     v6_okeq( v6_rand( $network ), $iptype ); 
  }    
 
  # done
  return;
}

# this net is not complete of type RESERVED, test only parts
#v6_nettest('::',             8, 'RESERVED',             1000);
v6_nettest('::',           128, 'UNSPECIFIED',              3);
v6_nettest('::1',          128, 'LOOPBACK',                 3);
v6_nettest('::FFFF:0:0',    96, 'IPV4MAP',              1000);
v6_nettest('80::',           9, 'RESERVED',             1000);

# this net is not complete of type RESERVED, test oly parts
#v6_nettest('0100::',         8, 'RESERVED',             1000);
v6_nettest('0100::',        64, 'DISCARD',              1000);
v6_nettest('0180::',         9, 'RESERVED',             1000);

v6_nettest('0200::',         7, 'RESERVED',             1000);
v6_nettest('0400::',         6, 'RESERVED',             1000);
v6_nettest('0800::',         5, 'RESERVED',             1000);
v6_nettest('1000::',         4, 'RESERVED',             1000);

# this net is not complete of type GLOBAL-UNICAST, test only parts
#v6_nettest('2000::',         3, 'GLOBAL-UNICAST',       1000);
v6_nettest('2001::',        32, 'TEREDO',               1000);
v6_nettest('2001:2::',      48, 'BMWG',                 1000);
v6_nettest('2001:DB8::',    32, 'DOCUMENTATION',        1000);
v6_nettest('2001:10::',     28, 'ORCHID',               1000);
v6_nettest('2002::',        16, '6TO4',                 1000);
v6_nettest('3000::',         4, 'GLOBAL-UNICAST',       1000);

v6_nettest('4000::',         3, 'RESERVED',             1000);
v6_nettest('6000::',         3, 'RESERVED',             1000);
v6_nettest('8000::',         3, 'RESERVED',             1000);
v6_nettest('A000::',         3, 'RESERVED',             1000);
v6_nettest('C000::',         3, 'RESERVED',             1000);
v6_nettest('E000::',         4, 'RESERVED',             1000);
v6_nettest('F000::',         5, 'RESERVED',             1000);
v6_nettest('F800::',         6, 'RESERVED',             1000);
v6_nettest('FA00::',         7, 'RESERVED',             1000);
v6_nettest('FC00::',         8, 'UNIQUE-LOCAL-UNICAST', 1000);
v6_nettest('FE00::',         9, 'RESERVED',             1000);
v6_nettest('FE80::',        10, 'LINK-LOCAL-UNICAST',   1000);
v6_nettest('FEC0::',        10, 'RESERVED',             1000);
v6_nettest('FF00::',         8, 'MULTICAST',            1000);

$T->end;
1;
