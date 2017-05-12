# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}

use Sys::Sig qw(TERM HUP KILL);

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

## test 2	check bare word

my $val = TERM;
print "got: $val, exp: $known{TERM} for sub 'TERM'\nnot "
	unless $val == $known{TERM};
&ok;

## test 3 - 5	check imported subs
foreach my $sig(qw(TERM HUP KiLl)) {
  local *s = uc $sig;
  print "got: $_, exp:$known{$sig} for sub '$sig'\nnot "
	unless ($_ = &{*s}) == $known{$sig};
  &ok;
}

## test 6	check not imported item
$val = eval {
	&QUIT;
};
print "got: $val, expected 'die' for not imported symbol 'QUIT'\nnot "
	unless $@ && $@ =~ /QUIT/;
&ok;

## test 7 - 11		check them all
import Sys::Sig qw(:all);
foreach my $sig (sort keys %known) {
  local *s = uc $sig;
  print "got: $_, exp: $known{$sig} for ", uc $sig, "\nnot "
        unless ($_ = &{*s}) == $known{$sig};
  &ok;
}
