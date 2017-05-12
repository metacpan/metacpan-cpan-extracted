# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Codes qw(:all );
use Net::DNS::ToolKit qw(
	sec2time
);

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

my %in = (
        59      => '59s',
        60      => '1m',
        61      => '1m1s',
        3599    => '59m59s',
        3600    => '1h',
        3601    => '1h1s',
        3660    => '1h1m',
        3661    => '1h1m1s',
        86399   => '23h59m59s',
        86400   => '1d',
        86401   => '1d1s',
        86460   => '1d1m',
        86461   => '1d1m1s',
        89999   => '1d59m59s',
        90000   => '1d1h',
        90060   => '1d1h1m',
        90061   => '1d1h1m1s',
        604799  => '6d23h59m59s',
        604800  => '1w',
        604801  => '1w1s',
        604860  => '1w1m',
        604861  => '1w1m1s',
        608399  => '1w59m59s',
        608400  => '1w1h',
        608459  => '1w1h59s',
        608460  => '1w1h1m',
        608461  => '1w1h1m1s',
        691199  => '1w23h59m59s',
        691200  => '1w1d',
        691259  => '1w1d59s',
        691300  => '1w1d1m40s',
        691301  => '1w1d1m41s',
        694799  => '1w1d59m59s',
        694800  => '1w1d1h',
        694801  => '1w1d1h1s',
        694859  => '1w1d1h59s',
        694860  => '1w1d1h1m',
        694861  => '1w1d1h1m1s',
);

foreach(sort {$a <=> $b} keys %in) {
  my $out = sec2time($_);
#  print "\t$_\t=> '$out',\n";
  next if $out eq $in{$_};
  print "got: $out, exp: $in{$_}\nnot ";
  last;
}
&ok;
