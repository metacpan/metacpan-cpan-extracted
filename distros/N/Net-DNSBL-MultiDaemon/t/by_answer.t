# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNSBL::MultiDaemon;

*by_average	= \&Net::DNSBL::MultiDaemon::by_average;
*set_nownext	= \&Net::DNSBL::MultiDaemon::set_nownext;

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
my $now = 1000;
my $next = $now;

my($interval,$AVGs,$CNTs) = set_nownext($now,$next);

%{$AVGs} = qw(
	a.5	5
	b.6	6
	c.7	7
);

my $STATs = {qw(
	a.5	7
	b.6	6
	c.7	5
)};

sub do_sort() {
 return sort {by_average($STATs,$a,$b)} keys %$STATs;
}

my @exp = qw(c.7 b.6 a.5);
my @ans = do_sort;
print "got: @ans\nexp: @exp\nnot "
	unless "@ans" eq "@exp";
&ok;

delete $AVGs->{'b.6'};
@exp = qw(c.7 a.5 b.6);
@ans = do_sort;
print "got: @ans\nexp: @exp\nnot "
	unless "@ans" eq "@exp";
&ok;

delete $AVGs->{'c.7'};
@exp = qw(a.5 b.6 c.7);
@ans = do_sort;
print "got: @ans\nexp: @exp\nnot "
	unless "@ans" eq "@exp";
&ok;

delete $AVGs->{'a.5'};
@exp = qw(a.5 b.6 c.7);
@ans = do_sort;
print "got: @ans\nexp: @exp\nnot "
	unless "@ans" eq "@exp";
&ok;
