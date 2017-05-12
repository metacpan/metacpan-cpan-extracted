# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNSBL::Statistics qw(run);

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

## test 2	test missing FILES key
my $conf = {};
my @ips = run($conf,undef,undef,1);
print "unexpected IP returned\nnot "
	if @ips;
&ok;

## test 3	no file present
$conf->{FILES} = 'not_there';
@ips = run($conf,undef,undef,1);
print "unexpected IP returned\nnot "
	if @ips;
&ok;

## test 4	single file present
$conf->{FILES} = 'local/allips.txt';  
@ips = run($conf,undef,undef,1);
print "missing IP list\nnot "
	unless @ips;
&ok;

## test 5	check number of IP's
my @loaded = sort @ips;
open(F,'local/snglips.txt') or die "could not open 'local/snglips.txt'\n";
my $ips;
{
	undef local $/;
	$ips = (<F>);
}	
close F;
@ips = split("\n",$ips);
print "bad item count ",scalar @ips, " not equal ",scalar @loaded, " \nnot "
	if @ips != @loaded;
&ok;

## test 6	compare IP values
gotexp(Dumper(\@ips),Dumper(\@loaded));

## test 7	multiple files present
$conf = {
	FILES	=> [qw(
		local/allips.txt
		local/n3allips.txt
	)],
};
@ips = run($conf,undef,undef,1);
print "missing IP list\nnot "
	unless @ips;
&ok;

## test 8	check number of IP's
@loaded = sort @ips;
open(F,'local/iplist.txt') or die "could not open 'local/iplist'\n";
{
	undef local $/;
	$ips = (<F>);
}	
close F;
@ips = split("\n",$ips);
print "bad item count ",scalar @ips, " not equal ",scalar @loaded, " \nnot "
	if @ips != @loaded;
&ok;

## test 9	compare IP values
gotexp(Dumper(\@ips),Dumper(\@loaded));
