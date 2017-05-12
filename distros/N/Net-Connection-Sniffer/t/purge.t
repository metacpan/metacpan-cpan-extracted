# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
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

my %subref;
foreach(sort keys %Net::Connection::Sniffer::) {
  my $subref = \&{"Net::Connection::Sniffer::$_"};
  $Net::Connection::Sniffer::{$_} =~ /[^:]+$/;
  $subref{$subref} = $&;
}

my($stats,$dns) = _ptrs();	# get array pointers
my $oneday = 86400;
my $now = next_sec();
set_globals();

@{$stats}{qw(a b c d e f g h)} = (
	{ E	=> $now - $oneday -1},	# a
	{ E	=> $now - $oneday -1},	# b
	{ E	=> $now - $oneday},	# c
	{ E	=> $now - $oneday},	# d
	{ E	=> $now - $oneday +1},	# e
	{ E	=> $now - $oneday +1},	# f
	{ E	=> $now - $oneday +10},	# g
	{ E	=> $now - $oneday +10},	# h
);
## test 2	check that init path is taken
my $rv = _purge($now);
print "expected reference to be returned\nnot "
	unless ref $rv;
&ok;

## test 3	check that rv is 'dopurge';
my $exp = 'dopurge';
print "got: $subref{$rv}, exp: $exp\nnot "
	unless $subref{$rv} eq $exp;
&ok;

## test 4	check delete of one element
$exp = {};
%{$exp} = %{$stats};
delete $exp->{a};
_purge($now);
gotexp(Dumper($stats),Dumper($exp));

## test 5	delete another element
delete $exp->{b};
_purge($now);
gotexp(Dumper($stats),Dumper($exp));

## test 6	don't delete
_purge($now);
gotexp(Dumper($stats),Dumper($exp));

## test 7	delete
$now += 1;
delete $exp->{d};
_purge($now);
gotexp(Dumper($stats),Dumper($exp));

## test 8	don't delete element
_purge($now);
gotexp(Dumper($stats),Dumper($exp));

## test 9	delete
$now += 1;
delete $exp->{f};
_purge($now);
gotexp(Dumper($stats),Dumper($exp));

## test 10	don't delete
_purge($now);
gotexp(Dumper($stats),Dumper($exp));

## test 11	don't delete
$rv = _purge($now);	# should return a reference
gotexp(Dumper($stats),Dumper($exp));

## test 12	check that rv is reference
print "expected reference to be returned\nnot "
	unless ref $rv;
&ok;

## test 13	check that rv returns 'setpurge'
$exp = 'setpurge';
print "got: $subref{$rv}, exp: $exp\nnot "
	unless $subref{$rv} eq $exp;
&ok;

## test 14	check for no action
print "got: $rv, exp: 'undef'\nnot "
	if defined ($rv = _purge($now));
&ok;

## test 15	check that init path is taken
$rv = _purge($now + $oneday);
print "expected reference to be returned\nnot "
	unless ref $rv;
&ok;

## test 16	check that rv is 'dopurge';
$exp = 'dopurge';
print "got: $subref{$rv}, exp: $exp\nnot "
	unless $subref{$rv} eq $exp;
&ok;
