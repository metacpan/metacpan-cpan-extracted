# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
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
%dnsbls = run($conf,undef,undef,2);
print "missing DNSBL's\nnot "
	unless keys %$conf;
&ok;

## test 3	check vals picked up
my $got = \%dnsbls;
my $exp = {
        'GENERIC'       => {
                'C'     => 0,
        },
        'bogons.cymru.com'      => {
                'C'     => 0,
                'TO'    => 0,
        },
        'cbl.abuseat.org'       => {
                'C'     => 0,
                'TO'    => 0,
        },
        'dnsbl.njabl.org'       => {
                'C'     => 0,
                'TO'    => 0,
        },
        'dnsbl.sorbs.net'       => {
                'C'     => 0,
                'TO'    => 0,
        },
        'dynablock.njabl.org'   => {
                'C'     => 0,
                'TO'    => 0,
        },
        'in-addr.arpa'  => {
                'C'     => 0,
        },
        'list.dsbl.org' => {
                'C'     => 0,
                'TO'    => 0,
        },
        'zen.spamhaus.org'      => {
                'C'     => 0,
                'TO'    => 0,
        },
};

gotexp(Dumper($got),Dumper($exp));
