# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}

use Sys::Sig;

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

my %known = qw(
	HUP	1
	int	2
	KiLl	9
	qUiT	3
	TERM	15
);

## test 2 - 6
foreach $sig (sort keys %known) {
  print "got: $_, exp: $known{$sig} for ", uc $sig, "\nnot "
	unless ($_ = eval "Sys::Sig->$sig") == $known{$sig};
  &ok;
}

## test 7	fail

$_ = eval {
	Sys::Sig->BLEEP;
};
print "expected 'die', got: $_ for undefined symbol BLEEP\nnot "
	unless $@ && $@ =~ /not defined SIGNAL 'BLEEP'/;
&ok;

## test 8 - 12
my $Sig = new Sys::Sig;
foreach my $sig (sort keys %known) {
  print "got: $_, exp: $known{$sig} for ", uc $sig, "\nnot "
	unless ($_ = eval "\$Sig->$sig") == $known{$sig};
  &ok;
}

## test 13	fail

$_ = eval {
	$Sig->BLEEP;
};
print "expected 'die', got: $_ for undefined symbol BLEEP\nnot "
	unless $@ && $@ =~ /not defined SIGNAL 'BLEEP'/;
&ok;

## test 14 - 18
foreach my $sig (sort keys %known) {
  print "got: $_, exp: $known{$sig} for ", uc $sig, "\nnot "
	unless ($_ = &{"Sys::Sig::$sig"}) == $known{$sig};
  &ok;
}

## test 19
print "got: $_, exp: $known{TERM} for TERM\nnot "
	unless ($_ = &Sys::Sig::term) == $known{TERM};
&ok;
