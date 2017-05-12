# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..39\n"; }
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

## test 2-15 check rcodes
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
  printf("rcode %s\ngot: %d\nexp: %d\nnot ",$_,&$_,$rcodes{$_})
	unless &$_ == $rcodes{$_};
  &ok;
}

## test 16-29
my %revrcodes = reverse %rcodes;

foreach(sort keys %revrcodes) {
  printf("rcode %d\ngot: %s\nexp: %s\nnot ",$_,RcodeTxt->{$_},$revrcodes{$_})
	unless RcodeTxt->{$_} eq $revrcodes{$_};
  &ok;
}

## test 30-34 check opcodes
my %opcodes = (
        QUERY           => 0,
        IQUERY          => 1,
        STATUS          => 2,
        NS_NOTIFY_OP    => 4,
        NS_UPDATE_OP    => 5,
);

foreach(sort {
	$opcodes{$a} <=> $opcodes{$b}
	} keys %opcodes) {
  printf("opcode %s\ngot: %d\nexp: %d\nnot ",$_,&$_,$opcodes{$_})
	unless &$_ == $opcodes{$_};
  &ok;
}

## test 35-39
my %revopcodes = reverse %opcodes;

foreach(sort keys %revopcodes) {
  printf("opcode %d\ngot: %s\nexp: %s\nnot ",$_,OpcodeTxt->{$_},$revopcodes{$_})
	unless OpcodeTxt->{$_} eq $revopcodes{$_};
  &ok;
}
