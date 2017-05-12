# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
$| = 1;
END {print "1..1\nnot ok 1\n" unless $test;}

use Net::Interface qw(
	inet_pton
	inet_ntop
);

$test = 1;

sub ok {
  print "ok $test\n";
  ++$test;
}

my @addr =
qw(
	0:0:0:0:0:0:0:0		::
	::			::
	:::			undef
	foo			undef
	::foo			undef
	foo::			undef
	abc::def::9		undef
	abcd1::			undef
	aBcd:0:0:0:0:0:0:0	abcd::
	::abcde			undef
	:a:b:c:d:1:2:3:4	undef
	:a:b:c:d		undef
	a:b:c:d:1:2:3:4:	undef
	a:b:c:d:1:2:3:4::	undef
	::a:b:c:d:1:2:3:4	undef
	0:A:b:c:d:1:2:3		0:a:b:c:d:1:2:3
	::a:b:c:d:1:2:3:	undef
	:a:b:c:d:1:2:3::	undef
	a:b:C:d:1:2:3:0		a:b:c:d:1:2:3:0
);

my $x = @addr;

# notify TEST about number of tests
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print '1..',$x,"\n";

$x /= 2;

for ($x = 0;$x <= $#addr; $x+=2) {
  my $bstr = inet_pton($addr[$x]);
  if ($addr[$x +1] =~ /undef/) {
    print "unexpected return value for $addr[$x]: $_\nnot "
	if ($_ = inet_pton && (inet_ntop($_) || 'not defined'));
  } else {
    my $rv = inet_pton($addr[$x]);
    unless ($rv) {
      print "got undefined value for $addr[$x]\nnot ";
    }
    else {
      $rv = inet_ntop($rv) || 'not defined';
      print "got: $rv, exp: $addr[$x +1]\nnot "
	unless $rv eq uc $addr[$x +1];
    }
  }
  &ok;
}

Net::Interface::import qw(:lower);

for ($x = 0;$x <= $#addr; $x+=2) {
  my $bstr = inet_pton($addr[$x]);
  if ($addr[$x +1] =~ /undef/) {
    print "unexpected return value for $addr[$x]: $_\nnot "
	if ($_ = inet_pton && (inet_ntop($_) || 'not defined'));
  } else {
    my $rv = inet_pton($addr[$x]);
    unless ($rv) {
      print "got undefined value for $addr[$x]\nnot ";
    }
    else {
      $rv = inet_ntop($rv) || 'not defined';
      print "got: $rv, exp: $addr[$x +1]\nnot "
	unless $rv eq $addr[$x +1];
    }
  }
  &ok;
}
