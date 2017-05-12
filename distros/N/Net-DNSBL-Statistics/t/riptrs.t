# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
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

## test 2	DNSBL array
my $conf = do 'local/test.conf';
my($iptr,$rptr) = run($conf,undef,undef,3);
print "missing DNSBL's\nnot "
	unless keys %$conf;
&ok;

## test 3	ignore
my $exp = [qw(dsl-only)];
gotexp(Dumper($iptr),Dumper($exp));

## test 4	regexptr
$exp = [
'\d+[a-zA-Z_\-\.]\d+[a-zA-Z_\-\.]\d+[a-zA-Z_\-\.]\d+|\d{12}',
'\d+\.(?i:sub|subnet|net|Red)\-?\d+[a-zA-Z_\-\.]\d+[a-zA-Z_\-\.]\d+',
'athedsl-\d+',
'i5[93][0-9a-fA-F]+\.versa',
'5ac[a-f0-9]+.+sky',
'bd[a-f0-9]+.virtua\.com',
'\d+\.\d+\.broadband',
'\d{11}\.\d{10}\.acesso',
'c[0-9a-f]{4,}\.virtua',
'(?:(u|s))\d+\.onlinehome',
'd\d+-\d+-\d+\.home\d+\.cgocable',
'CableLink\d+-\d+\.tele',
'(?:(auh|dxb|ner))-as\d+\.alshamil',
'p\d+-ipbf.+\.ne\.jp'
];
gotexp(Dumper($rptr),Dumper($exp));
