# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..23\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit qw(
	ipv6_aton
	ipv6_n2x
	ipv6_n2d
);

#use Net::DNS::ToolKit::Debug qw(print_buf);

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

my @pass = qw(
	::		0:0:0:0:0:0:0:0		0:0:0:0:0:0:0.0.0.0
	::0.0.0.1	0:0:0:0:0:0:0:1		0:0:0:0:0:0:0.0.0.1
	::4		0:0:0:0:0:0:0:4		0:0:0:0:0:0:0.0.0.4
	1::		1:0:0:0:0:0:0:0		1:0:0:0:0:0:0.0.0.0
	ff::2		FF:0:0:0:0:0:0:2	FF:0:0:0:0:0:0.0.0.2
	ff:fe::1.2.3.4	FF:FE:0:0:0:0:102:304	FF:FE:0:0:0:0:1.2.3.4
);

my @fail = (undef,'',qw(
	:
	:5
	::5.
	::5.6.7.1111
	::3.4.5.256
	::2.3.4.-1
	a:b:c:d
	e:f:1.2.3.4
));

## test 2 - 13
for (my $i=0; $i <= $#pass;$i+=3) {
  my $buffer = ipv6_aton($pass[$i]);
  my $rv = ipv6_n2x($buffer);
  print "got: $rv, exp: $pass[$i+1]\nnot "
	unless $rv eq $pass[$i+1];
  &ok;
  $rv = ipv6_n2d($buffer);
  print "got: $rv, exp: $pass[$i+2]\nnot "
	unless $rv eq $pass[$i+2];
  &ok;
}

## test 14 - 23
foreach(@fail) {
  if (defined (my $rv = ipv6_aton($_))) {
    print "expected undef from bad value $_\n";
    if (length($rv) != 16) {
      print 'bad length ',length($_),"\n";
    } else {
      print 'got: ';
      $rv = ($_ =~ /\./)
	? ipv6_n2d($rv)
	: ipv6_n2x($rv);
      print "$rv\n";
    }
    print 'not ';
  }
  &ok;
}
