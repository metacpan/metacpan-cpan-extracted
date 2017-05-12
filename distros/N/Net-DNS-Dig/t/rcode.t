# Before make install' is performed this script should be runnable with
# make test'. After make install' it should work as perl test.pl'

#	rcode.t
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {	$| = 1; print "1..35\n";}
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	getflags
	putflags
);
use Net::DNS::ToolKit::Utilities qw(
	id
	question
);
use Net::DNS::Dig;

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


require './recurse2txt';

*proc_head = \&Net::DNS::Dig::_proc_head;

## test 2	build a real question

id(12343);	# seed query buffer ID

my $qbuf = question('foo.com',T_A);

my $obj = {};

my @stuff = proc_head(\$qbuf,$obj);

# the query buffer prototype produces a response like this

my $exp = q|16	= {
	'HEADER'	=> {
		'AA'	=> 0,
		'AD'	=> 0,
		'ANCOUNT'	=> 0,
		'ARCOUNT'	=> 0,
		'CD'	=> 0,
		'ID'	=> 12345,
		'MBZ'	=> 0,
		'NSCOUNT'	=> 0,
		'OPCODE'	=> 0,
		'QDCOUNT'	=> 1,
		'QR'	=> 0,
		'RA'	=> 0,
		'RCODE'	=> 0,
		'RD'	=> 1,
		'TC'	=> 0,
	},
};
|;

my $got = Dumper($obj);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

my %rcode = (
        NOERROR         => 0,
        FORMERR         => 1,
        SERVFAIL        => 2,
        NXDOMAIN        => 3,
        NOTIMP          => 4,
        REFUSED         => 5,
        YXDOMAIN        => 6,
        YXRRSET         => 7,
        NXRRSET         => 8,
        NOTAUTH         => 9,
        NOTZONE         => 10,
);

my %revrcode = reverse %rcode;

## test 3 - 	check numeric response

foreach(sort { $a <=> $b } keys %revrcode) {
  my $flags = getflags(\$qbuf);
  $flags &= RCODE_MASK;
  $flags |= $_;			# rcode is the least significant 4 bits so "numeric" or works
  putflags(\$qbuf,$flags);

  $dig = bless {}, 'Net::DNS::Dig';
  my ($newoff,$rcode,$qdcount,$ancount,$nscount,$arcount) = proc_head(\$qbuf,$dig);

# rcode should match
  print "proc_head rcode mismatch, got: $rcode, exp: $_\nnot "
	if $rcode != $_;
  &ok;

  my $rv = $dig->rcode();
#print "\t$rv\n";
  print "numeric rcode mismatch, got: $rv, exp: $_\nnot "
	if $rv != $_;
  &ok;

  $rv = $dig->rcode(1);
#print "\t$rv\n";
  print "text rcode mismatch, got: $rv, exp: ", $revrcode{$_}, "\nnot "
	unless $rv eq $revrcode{$_};
  &ok;
}
