# Before `make install' is performed this script should be runnable with
# make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 1;
use strict;
#use diagnostics;

# test 1
BEGIN { use_ok( 'Net::Interface',qw(
	:afs
	:iffs
	:iftype
	inet_ntoa
	inet_ntop
	mac_bin2hex
)); }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

#use Devel::Peek;
#use Data::Dumper;

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

my @ifaces = interfaces Net::Interface();
my $num = @ifaces;
diag("\nSummary: $num interfaces\n\t@ifaces\n");

sub getflags {
  my($flags) = @_;
  no strict;
  my $txt = ($flags & IFF_UP) ? '<up ' : '<down ';
  foreach(sort @{$Net::Interface::EXPORT_TAGS{iffs}}) {
    my $x = eval { &$_(); };
    my $v = 0 + $x;
    next if $v == IFF_UP;
    $txt .= $x .' ' if $flags & $v;
  }
  chop $txt;
  $txt .= '>';
}

sub addr42txt {
  my($txt,$naddr) = @_;
  return '' unless $naddr;
  $txt .= ' '. inet_ntoa($naddr);
}

sub dumpaddrs {
  my($hvp,$i,$fam,$mac) = @_;
  my $key = 0 + $fam;
  if (exists $i->{$key}) {
    diag(sprintf("\t%s %d, addr size %d %s\n",$fam,$i->{$key}->{number},$i->{$key}->{size},$$mac));
    $$mac = '';
    my @address = $hvp->address($key);
    my @netmask = $hvp->netmask($key);
    my @broadcast = $hvp->broadcast($key);
    if ($key == AF_INET()) {
      foreach(0..$#address) {
	diag(sprintf("\t%s %s %s\n",
		addr42txt('addr',scalar $hvp->address($key,$_)),
		addr42txt('netmask',scalar $hvp->netmask($key,$_)),
		addr42txt('broadcast',scalar $hvp->broadcast($key,$_))
	));
      }
    } else {
      foreach(0..$#address) {
	diag(sprintf("\t%s/%d <%s>\n",
		inet_ntop($address[$_]),
		$hvp->mask2cidr($netmask[$_]),
		typetxt($hvp->type($address[$_])) ."\b"
	));
      }
    }
  }
}

foreach my $hvp (@ifaces) {
  my $i = $hvp->info();
  unless (defined $i->{flags} && $i->{flags} & IFF_UP()) {
    diag(sprintf("%s\t<DOWN>\n",$i->{name}));
    next;
  }
##  Dump($i);
  my $flags = getflags($i->{flags});
  my $mac = (defined $i->{mac}) ? "\tMAC: ". mac_bin2hex($i->{mac}) : '';
  my $mtu = $i->{mtu} ? 'MTU:'. $i->{mtu} : '';
  my $metric = (defined $i->{metric}) ? 'Metric:'. $i->{metric} : '';
  my $af_inet6 = eval {AF_INET6} || 0;
  diag(sprintf("%s id %d\tflags:0x%02x%s %s %s\n",$i->{name},$i->{index},$i->{flags},$flags,$mtu,$metric));
  dumpaddrs($hvp,$i,AF_INET,\$mac);
  dumpaddrs($hvp,$i,$af_inet6,\$mac);

#  print Dumper($i),"\n";
}

