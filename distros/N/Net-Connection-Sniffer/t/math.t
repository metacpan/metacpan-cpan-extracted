# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "could not load Net::Connection::Sniffer\nnot ok 1\n" unless $loaded;}

use Net::Connection::Sniffer qw(:math);

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

$hp = {};

## test 2	set C
my $exp = 1;
set_uv($hp,'C',$exp);
print 'got: ', ($_ || ''), ", exp: $exp\nnot "
	unless $hp->{C} && ($_ = $hp->{C}) == $exp;
&ok;

## test 3	fetch C
my $rv = fetch_uv($hp,'C') || '';
print "got: $rv, exp: $exp\nnot "
	unless $rv && $rv == $exp;
&ok;

## test 4	increment
$exp = 2;
inc_sv($hp,'C');
print 'got: ', ($_ || ''), ", exp: $exp\nnot "
	unless $hp->{C} && ($_ = $hp->{C}) == $exp;
&ok;

## test 5	set A
$exp = 2**33 +33;
set_nv($hp,'A',$exp);
print 'got: ', ($_ || ''), ", exp: $exp\nnot "
	unless $hp->{A} && ($_ = $hp->{A}) == $exp;
&ok;

## test 6	set B
my $exp2 = 2**15 +15;
set_nv($hp,'B',$exp2);
print 'got: ', ($_ || ''), ", exp: $exp2\nnot "
	unless $hp->{B} && ($_ = $hp->{B}) == $exp2;
&ok;


## test 7	add
add_nv($hp,'B',55);
$exp2 += 55;
print 'got: ', ($_ || ''), ", exp: $exp2\nnot "
	unless $hp->{B} && ($_ = $hp->{B}) == $exp2;
&ok;

## test 8	a = (a+b) *m
my $multiply = 23;
$exp = ($exp + $exp2) * $multiply;
aEQaPLUSbXm($hp,'A','B',$multiply);
print 'got: ', ($_ || ''), ", exp: $exp\nnot "
	unless $hp->{A} && ($_ = $hp->{A}) == $exp;
&ok;

## test 9	check B
print 'got: ', ($_ || ''), ", exp: $exp2\nnot "
	unless $hp->{B} && ($_ = $hp->{B}) == $exp2;
&ok;
