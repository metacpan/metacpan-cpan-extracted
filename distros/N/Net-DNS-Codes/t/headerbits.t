# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..47\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::DNS::Codes qw(:header);

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

## test 2-9 check header codes
my %headcodes = (
  QR            => 1 << 15, # 0b1000_0000_0000_0000,
  AA            => 1 << 10, #       0b100_0000_0000,
  TC            => 1 << 9,  #        0b10_0000_0000,
  RD            => 1 << 8,  #         0b1_0000_0000,
  RA            => 1 << 7,  #           0b1000_0000,
  MBZ		=> 1 << 6,  #            0b100_0000,
  Z		=> 1 << 6,  #            0b100_0000,
  AD            => 1 << 5,  #             0b10_0000,
  CD            => 1 << 4,  #              0b1_0000,
);

foreach(sort {
	$headcodes{$a} <=> $headcodes{$b}
	} keys %headcodes) {
  my $code = eval($_);
  printf("bitfield %s\ngot: %b\nexp: %b\nnot ", $_,$code,$headcodes{$_})
	unless $code = $headcodes{$_};
  &ok;
}

## test 10-20 check opcodes
my %opcodes = (
        QUERY           => 0, 
        IQUERY          => 1,  
        STATUS          => 2,
        NS_NOTIFY_OP    => 4, 
        NS_UPDATE_OP    => 5,
  BITS_QUERY        =>    0,
  BITS_IQUERY       => 1 << 11, #    0b1000_0000_0000
  BITS_STATUS       => 2 << 11, #  0b1_0000_0000_0000
  BITS_NS_NOTIFY_OP => 4 << 11, # 0b10_0000_0000_0000
  BITS_NS_UPDATE_OP => 5 << 11, # 0b10_1000_0000_0000
);

foreach(sort {
	$opcodes{$a} <=> $opcodes{$b}
	} keys %opcodes) {
  printf("opcode bitfield %s\ngot: %b\nexp: %b\nnot ",$_,&$_,$opcodes{$_})
	unless &$_ == $opcodes{$_};
  &ok;
}

## test 21-34 check response codes
my %rcodes = (
        NOERROR         => 0,
        FORMERR         => 1,
        SERVFAIL        => 2,
        NXDOMAIN        => 3, 
        NOTIMP          => 4,  
        REFUSED         => 5,
        YXDOMAIN        => 6, 
        YXRRSET         => 7,
        NXRRSET         => 8,
        NOTAUTH         => 9,
        NOTZONE         => 10,
        BADSIG          => 16,
        BADKEY          => 17,
        BADTIME         => 18,
);

foreach(sort {
	$rcodes{$a} <=> $rcodes{$b}
	} keys %rcodes) {
  printf("response code bitfield %s\ngot: %b\nexp: %b\nnot ",$_,&$_,$rcodes{$_})
	unless &$_ == $rcodes{$_};
  &ok;
}

## test 35-47 check reverse bit codes
@_ = (
  QR            => 1 << 15, # 0b1000_0000_0000_0000,
  AA            => 1 << 10, #       0b100_0000_0000,
  TC            => 1 << 9,  #        0b10_0000_0000,
  RD            => 1 << 8,  #         0b1_0000_0000,
  RA            => 1 << 7,  #           0b1000_0000,
  MBZ		=> 1 << 6,  #            0b100_0000,
  AD            => 1 << 5,  #             0b10_0000,
  CD            => 1 << 4,  #              0b1_0000,
  QUERY         =>    0,
  IQUERY        => 1 << 11, #    0b1000_0000_0000
  STATUS        => 2 << 11, #  0b1_0000_0000_0000
  NS_NOTIFY_OP  => 4 << 11, # 0b10_0000_0000_0000
  NS_UPDATE_OP  => 5 << 11, # 0b10_1000_0000_0000
);

my %revheadcodes = reverse @_;

foreach(sort keys %revheadcodes) {
  printf("opcode %d\ngot: %s\nexp: %s\nnot
",$_,RBitsTxt->{$_},$revheadcodes{$_})
        unless RBitsTxt->{$_} eq $revheadcodes{$_};
  &ok;
}
