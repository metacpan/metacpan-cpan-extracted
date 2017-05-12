# Before `make install' is performed this script should be runnable with
# make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More qw(no_plan);
#use diagnostics;

# test 1
BEGIN { use_ok( 'Net::Interface',qw(:afs :pfs :ifs :scope :iftype _NI_AF_TEST)); }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}

require_ok( 'Net::Interface::NetSymbols');

foreach(qw(PF_UNSPEC PF_INET AF_UNSPEC AF_INET _NI_AF_TEST IFHWADDRLEN IF_NAMESIZE IFNAMSIZ)) {
  my $x = eval {
	&$_;
  };
  my $s = (defined $x) ? 0 + $x : undef;
  if ($_ =~ /^_NI/) {	# must fail
    unless ($@ && $@ =~ /architecture/) {
      fail($_ . " = $s exists???, got: $s");
    } else {
      $@ =~ /(.+architecture)/;
      pass('expected that '. $1);
    }
  } else {		# must pass
    if ($@) {
      fail($@);
    } else {
      pass($_ ." = $s found, $x");
    }
  }
}

my $rv = Net::Interface::NetSymbols->NI_ENDVAL();
ok($rv, "netsymbols max value +1 = $rv");

my %unique = %{Net::Interface::NetSymbols->NI_UNIQUE()};

foreach(sort {$a <=> $b} keys %unique) {
  my $symbol = $unique{$_};
  my $x = eval {
	&$symbol;
  };
  if ($@) {
    fail($@);
  } else {
    my $s = 0 + $x;
    if ($x == $_) {
      pass("found $symbol\t=> $s $x");
    } else {
    fail("$symbol = $s, should be $_");
    }
  }
}

foreach(qw(
	IFF_UP
	AF_INET
        RFC2373_GLOBAL
        RFC2373_ORGLOCAL
        RFC2373_SITELOCAL
        RFC2373_LINKLOCAL
        RFC2373_NODELOCAL
        IPV6_ADDR_ANY
        IPV6_ADDR_UNICAST
        IPV6_ADDR_MULTICAST
        IPV6_ADDR_ANYCAST
        IPV6_ADDR_LOOPBACK
        IPV6_ADDR_LINKLOCAL
        IPV6_ADDR_SITELOCAL
        IPV6_ADDR_COMPATv4
        IPV6_ADDR_SCOPE_MASK
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
)) {

  my $x = eval {
	&$_;
  };

  if ($@) {
    fail($@);
  } else {
    pass($_ . sprintf("\t=> 0x%0x = %s",$x,$x));
  }
}
