# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNSBL::MultiDaemon;

*average	= \&Net::DNSBL::MultiDaemon::average;
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

%$AVGs = qw(
	a.5	1500
	b.6	1800
	c.7	2100
);

my $STATs = {qw(
	a.5	5
	b.6	6
	c.7	7
)};

%$CNTs = %$STATs;

sub do_sort {
  my $h = shift;
  my @rv;
  foreach(sort keys %$h) {
    push @rv, $_, sprintf("%2.2f",$h->{"$_"});
  }
  @rv;
}

## test 2
my @exp = qw(
	a.5 1498.98 b.6 1798.77 c.7 2098.57
);
average($STATs);
my @ans = do_sort($AVGs);
print "got: @ans\nexp: @exp\nnot "
	unless "@ans" eq "@exp";
&ok;

## test 3
set_nownext($now,$next);
%$CNTs = %$STATs;
@exp = qw(
	a.5 1497.97 b.6 1797.56 c.7 2097.16
);
average($STATs);
@ans = do_sort($AVGs);
print "got: @ans\nexp: @exp\nnot "
	unless "@ans" eq "@exp";
&ok;

## test 4
foreach(1..288) {	# a days worth, should approach 1440, 1728, 2016
  set_nownext($now,$next);
  %$CNTs = %$STATs;
  average($STATs); 
}
@exp = qw(
	a.5 1440.41 b.6 1728.49 c.7 2016.57
);
@ans = do_sort($AVGs);
print "got: @ans\nexp: @exp\nnot "
	unless "@ans" eq "@exp";
&ok;

## test 5	should not change at all
%$CNTs = %$STATs;
$AVGs = {qw(
	a.5	1440
	b.6	1728
	c.7	2016
)};
foreach(1..288) {	# a days worth
  set_nownext($now,$next);
  %$CNTs = %$STATs;
  average($STATs); 
}
@exp = qw(
	a.5 1440.00 b.6 1728.00 c.7 2016.00
);
@ans = do_sort($AVGs);
print "got: @ans\nexp: @exp\nnot "
	unless "@ans" eq "@exp";
&ok;
