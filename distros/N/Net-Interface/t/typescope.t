# Before `make install' is performed this script should be runnable with
# make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 247;
#use diagnostics;

# test 1
BEGIN { use_ok( 'Net::Interface', qw(
	:iftype
	:scope
	type
	scope
	inet_pton
	full_inet_ntop
	inet_ntop
    ))
}
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

my @ipv6 = (

'0000:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00080000,	'global-scope',	'unspecified ',
'0000:0000:0000:0000:0000:0000:0000:0001',	0x01,	0x00000011,	'loopback',	'unicast loopback ',
'0000:0000:0000:0000:0000:0000:0000:0100',	0x10,	0x00000081,	'lx-compat-v4',	'unicast compat-v4 ',
'0000:0000:0000:0000:0000:0000:0001:0001',	0x10,	0x00000081,	'lx-compat-v4',	'unicast compat-v4 ',
'0000:0000:0000:0000:0000:0000:0100:0001',	0x10,	0x00000081,	'lx-compat-v4',	'unicast compat-v4 ',
'0000:0000:0000:0000:0000:0001:0000:0000',	0x0e,	0x00002000,	'global-scope',	'reserved ',
'3FFE:831F:0000:0000:0000:0000:0000:0000',	0x0e,	0x00060001,	'global-scope',	'unicast 6bone global-unicast ',
'FC00:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00004001,	'global-scope',	'unicast uniq-lcl-unicast ',
'FE00:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00002000,	'global-scope',	'reserved ',
'2000:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00440001,	'global-scope',	'unicast global-unicast productive ',
'3000:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00440001,	'global-scope',	'unicast global-unicast productive ',
'3FFE:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00060001,	'global-scope',	'unicast 6bone global-unicast ',
'2001:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x01040001,	'global-scope',	'unicast global-unicast teredo ',
'2001:0001:0000:0000:0000:0000:0000:0000',	0x0e,	0x00440001,	'global-scope',	'unicast global-unicast productive ',
'2001:0000:0001:0000:0000:0000:0000:0000',	0x0e,	0x01040001,	'global-scope',	'unicast global-unicast teredo ',
'2001:0DB8:0000:0000:0000:0000:0000:0000',	0x0e,	0x08040001,	'global-scope',	'unicast global-unicast non-routeable-doc ',
'2002:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00850001,	'global-scope',	'unicast 6to4 global-unicast 6to4-ms ',
'2002:ABCD:EF01:0000:0000:0000:ABCD:EF01',	0x0e,	0x00850001,	'global-scope',	'unicast 6to4 global-unicast 6to4-ms ',
'20FF:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00440001,	'global-scope',	'unicast global-unicast productive ',
'0000:0000:0000:0000:0000:0001:FF00:0000',	0x0e,	0x00002000,	'global-scope',	'reserved ',
'0000:0000:0000:0000:0000:0001:FFF0:0000',	0x0e,	0x00002000,	'global-scope',	'reserved ',
'FF02:0000:0000:0000:0000:0001:FF00:0000',	0x02,	0x00100022,	'link-local',	'multicast link-local solicited-node ',
'FF02:0000:0000:0000:0000:0001:FFF0:0000',	0x02,	0x00100022,	'link-local',	'multicast link-local solicited-node ',
'FF02:0001:0000:0000:0000:0000:0000:0000',	0x02,	0x00000022,	'link-local',	'multicast link-local ',
'FF02:0000:0001:0000:0000:0000:0000:0000',	0x02,	0x00000022,	'link-local',	'multicast link-local ',
'FF02:0000:0000:0001:0000:0000:0000:0000',	0x02,	0x00000022,	'link-local',	'multicast link-local ',
'FF01:0000:0000:0000:0000:0000:0000:0000',	0x01,	0x00000012,	'loopback',	'multicast loopback ',
'FF05:0000:0000:0000:0000:0000:0000:0000',	0x05,	0x00000042,	'site-local',	'multicast site-local ',
'FE80:0000:0000:0000:0000:FEFE:0000:0000',	0x02,	0x00000021,	'link-local',	'unicast link-local ',
'E000:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00002000,	'global-scope',	'reserved ',
'C000:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00000001,	'global-scope',	'unicast ',
'A000:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00000001,	'global-scope',	'unicast ',
'8000:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00000001,	'global-scope',	'unicast ',
'6000:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00000001,	'global-scope',	'unicast ',
'4000:0000:0000:0000:0000:0000:0000:0000',	0x0e,	0x00000001,	'global-scope',	'unicast ',
'FEF0:0000:0000:0000:0000:0000:0000:0000',	0x05,	0x00000041,	'site-local',	'unicast site-local ',
'FEE0:0000:0000:0000:0000:0000:0000:0000',	0x05,	0x00000041,	'site-local',	'unicast site-local ',
'FEC0:0000:0000:0000:0000:0000:0000:0000',	0x05,	0x00000041,	'site-local',	'unicast site-local ',
'FE80:0000:0000:0000:0000:0000:0000:0000',	0x02,	0x00000021,	'link-local',	'unicast link-local ',
'FEC0:0000:0000:0000:0000:0000:0000:0000',	0x05,	0x00000041,	'site-local',	'unicast site-local ',
'0000:0000:0000:0000:0000:FFFF:0000:0000',	0x0e,	0x00001000,	'global-scope',	'mapped ',

);

my @bmsk = qw(
  IPV6_ADDR_ANY
  IPV6_ADDR_UNICAST
  IPV6_ADDR_MULTICAST
  IPV6_ADDR_ANYCAST
  IPV6_ADDR_LOOPBACK
  IPV6_ADDR_LINKLOCAL
  IPV6_ADDR_SITELOCAL
  IPV6_ADDR_COMPATv4
  IPV6_ADDR_MAPPED
  IPV6_ADDR_RESERVED
  IPV6_ADDR_ULUA
  IPV6_ADDR_6TO4
  IPV6_ADDR_6BONE
  IPV6_ADDR_AGU
  IPV6_ADDR_UNSPECIFIED
  IPV6_ADDR_SOLICITED_NODE
  IPV6_ADDR_ISATAP
  IPV6_ADDR_PRODUCTIVE
  IPV6_ADDR_6TO4_MICROSOFT
  IPV6_ADDR_TEREDO
  IPV6_ADDR_ORCHID
  IPV6_ADDR_NON_ROUTE_DOC
);

my @seql = qw(
  RFC2373_GLOBAL
  RFC2373_ORGLOCAL
  RFC2373_SITELOCAL
  RFC2373_LINKLOCAL
  RFC2373_NODELOCAL
  LINUX_COMPATv4
);

sub scopetxt {
  my $scope = shift;
  local *seql;
  my $rv = '';
  foreach (@seql) {
    *seql = $_;
    my $rfcscp = 0 + &seql;
    next unless $scope eq $rfcscp;
    return &seql;
  }
  die "missing scope $scope";
}

sub typetxt {
  my $type = shift;
  local *bmsk;
  my $rv = '';
  foreach (@bmsk) {
    *bmsk = $_;
    my $mask = 0 + &bmsk;
    next unless $type & $mask;
    $rv .= &bmsk .' ';
  }
  return $rv;
}

sub develop_test {
  for (my $i=0;$i<@ipv6;$i+=5) {
    my $naddr = inet_pton($ipv6[$i]);
#    print "$addr\n";
    print "'",full_inet_ntop($naddr),"',"; 
    my $type = type($naddr);
    my $scope = scope($naddr);
    printf("\t0x%02x,\t0x%08x,\t'",$scope,$type);
    $scope = scopetxt($scope);
    print $scope,"',\t'";
    $type = typetxt($type);
    print $type," ";
    print "',\n";
  }
}
#develop_test();

my $bo = Net::Interface->_bo();
foreach(my $i=0;$i<@ipv6;$i+=5) {
  my $naddr = inet_pton($ipv6[$i]);
  my $addr = inet_ntop($naddr);
  my $type = type($naddr);
  ok($type == $ipv6[$i+2],sprintf("%s\tfunction type got: 0x%0x exp: 0x%0x",$addr,$type,$ipv6[$i+2]));
  $type = $bo->type($naddr);
  ok($type == $ipv6[$i+2],sprintf("%s\tmethod type got: 0x%0x exp: 0x%0x",$addr,$type,$ipv6[$i+2]));
  $type = typetxt($type);
  ok($type eq $ipv6[$i+4],sprintf("%s\ttext type got: %s exp: %s",$addr,$type,$ipv6[$i+4]));
  my $scope = scope($naddr);
  ok($scope == $ipv6[$i+1],sprintf("%s\tfunction scope got: 0x%08x exp: 0x%08x",$addr,$scope,$ipv6[$i+1]));
  $scope = $bo->scope($naddr);
  ok($scope == $ipv6[$i+1],sprintf("%s\tmethod scope got: 0x%08x exp: 0x%08x",$addr,$scope,$ipv6[$i+1]));
  $scope = scopetxt($scope);
  ok($scope eq $ipv6[$i+3],sprintf("%s\ttext scope got: %s exp: %s",$addr,$scope,$ipv6[$i+3]));
}
