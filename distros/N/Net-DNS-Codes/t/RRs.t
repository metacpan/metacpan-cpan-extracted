# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..145\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Codes qw(:RRs);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2-6 check class codes
my %classes = (
        C_IN            => 1,  
        C_CHAOS         => 3,
        C_HS            => 4,
        C_NONE          => 254,
        C_ANY           => 255,
);

foreach(sort {
	$classes{$a} <=> $classes{$b}
	} keys %classes) {
  printf("class %s\ngot: %d\nexp: %d\nnot ",$_,&$_,$classes{$_})
	unless &$_ == $classes{$_};
  &ok;
}

## test 7-11
my %revclasses = reverse %classes;

foreach(sort keys %revclasses) {
  printf("class %d\ngot: %s\nexp: %s\nnot ",$_,ClassTxt->{$_},$revclasses{$_})
	unless ClassTxt->{$_} eq $revclasses{$_};
  &ok;
}
#print "start $test\n";
## test 12 - 78
my %types = (
  T_A           => 1,   # rfc1035.txt
  T_NS          => 2,   # rfc1035.txt
  T_MD          => 3,   # rfc1035.txt
  T_MF          => 4,   # rfc1035.txt
  T_CNAME       => 5,   # rfc1035.txt
  T_SOA         => 6,   # rfc1035.txt
  T_MB          => 7,   # rfc1035.txt
  T_MG          => 8,   # rfc1035.txt
  T_MR          => 9,   # rfc1035.txt
  T_NULL        => 10,  # rfc1035.txt
  T_WKS         => 11,  # rfc1035.txt
  T_PTR         => 12,  # rfc1035.txt
  T_HINFO       => 13,  # rfc1035.txt
  T_MINFO       => 14,  # rfc1035.txt
  T_MX          => 15,  # rfc1035.txt
  T_TXT         => 16,  # rfc1035.txt
  T_RP          => 17,  # rfc1183.txt
  T_AFSDB       => 18,  # rfc1183.txt
  T_X25         => 19,  # rfc1183.txt
  T_ISDN        => 20,  # rfc1183.txt
  T_RT          => 21,  # rfc1183.txt
  T_NSAP        => 22,  # rfc1706.txt
  T_NSAP_PTR    => 23,  # rfc1348.txt
  T_SIG         => 24,  # rfc2535.txt
  T_KEY         => 25,  # rfc2535.txt
  T_PX          => 26,  # rfc2163.txt
  T_GPOS        => 27,  # rfc1712.txt
  T_AAAA        => 28,  # rfc1886.txt
  T_LOC         => 29,  # rfc1876.txt
  T_NXT         => 30,  # rfc2535.txt
  T_EID         => 31,  # draft-ietf-nimrod-dns-02.txt
  T_NIMLOC      => 32,  # draft-ietf-nimrod-dns-02.txt
  T_SRV         => 33,  # rfc2052.txt
  T_ATMA        => 34,  # af-saa-0069.000.txt
  T_NAPTR       => 35,  # rfc2168.txt
  T_KX          => 36,  # rfc2230.txt
  T_CERT        => 37,  # rfc2538.txt
  T_A6          => 38,  # rfc2874.txt
  T_DNAME       => 39,  # rfc2672.txt
  T_SINK        => 40,  # draft-ietf-dnsind-kitchen-sink-01.txt
  T_OPT         => 41,  # rfc2671.txt
  T_APL         => 42,  # rfc3123.txt
  T_DS          => 43,  # draft-ietf-dnsext-delegation-signer-15.txt
  T_SSHFP       => 44,  # rfc4255.txt
  T_IPSECKEY    => 45,  # rfc4025.txt
  T_RRSIG       => 46,  # rfc4034.txt
  T_NSEC        => 47,  # rfc4034.txt
  T_DNSKEY      => 48,  # rfc4034.txt
  T_DHCID       => 49,  # rfc4701.txt
  T_NSEC3       => 50,  # rfc5155.txt
  T_NSEC3PARAM  => 51,  # rfc5155.txt
        # unassigned 52 - 54
  T_HIP         => 55,  # rfc5205.txt
  T_NINFO       => 56,  # unknown
  T_RKEY        => 57,  # draft-reid-dnsext-rkey-00.txt
  T_ALINK       => 58,  # draft-ietf-dnsop-dnssec-trust-history-02.txt
  T_CDS         => 59,  # draft-barwood-dnsop-ds-publish-02.txt
        # unassigned 60 - 98
  T_UINFO       => 100, # reserved
  T_UID         => 101, # reserved
  T_GID         => 102, # reserved
  T_UNSPEC      => 103, # reserved
        # unassigned 104 - 248
  T_TKEY        => 249, # rfc2930.txt
  T_TSIG        => 250, # rfc2931.txt
  T_IXFR        => 251, # rfc1995.txt
  T_AXFR        => 252, # rfc1886.txt
  T_MAILB       => 253, # rfc1886.txt
  T_MAILA       => 254, # rfc1886.txt
  T_ANY         => 255, # rfc1886.txt
);
foreach(sort {
	$types{$a} <=> $types{$b}
	} keys %types) {
  printf("type %s\ngot: %d\nexp: %d\nnot ",$_,&$_,$types{$_})
	unless &$_ == $types{$_};
  &ok;
}
#print "end $test\n";
## test 79 - 145
my %revtypes = reverse %types;

foreach(sort keys %revtypes) {
  printf("type %d\ngot: %s\nexp: %s\nnot ",$_,TypeTxt->{$_},$revtypes{$_})
	unless TypeTxt->{$_} eq $revtypes{$_};
  &ok;
}
