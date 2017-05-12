# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "could not load Net::Connection::Sniffer\nnot ok 1\n" unless $loaded;}

use Net::Connection::Sniffer qw(:timer);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

require './recurse2txt';

sub ok {
  print "ok $test\n";
  ++$test;
}

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

sub gotexp {
  my($got,$exp) = @_;
  if ($exp =~ /\D/) {
    print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
  } else {  
    print "got: $got, exp: $exp\nnot "
        unless $got == $exp;
  }
  &ok;
}

my $now = next_sec();
set_globals();
$now -= 15;

my($stats,$dns) = _ptrs();	# get array pointers
$dns->{a} = {
	TO	=>	$now +1,
	IP	=>	'is a',
};
$dns->{b} = {
	TO	=>	$now,
	IP	=>	'is b',
};
my $ary = Dumper($dns);

$dns->{c} = {
	TO	=>	$now -1,
	IP	=>	'is c',
};

## test 2	check dns expiration
dns_expire($now);
gotexp(Dumper($dns),$ary);

