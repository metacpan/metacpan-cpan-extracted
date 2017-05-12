# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNSBL::Monitor qw(
	plainresp
	htmlresp
);

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

my %conf = (
	'dnsbl.njabl.org' => {
		comment	=> 'njabl comment',
		url	=> 'http://www.njabl.org/',
	},
	'bogons.cymru.com' => {
		comment	=> 'have no counts',
	},
	'bl.spamcannibal.org' => {
		comment	=> '127.0.0.2',
		url	=> 'cannibal.cgi',
	},
	'list.dsbl.org' => {
		url	=> 'http://www.dsbl.org/',
	},
	'cbl.abuseat.org' => {},
	'dnsbl.sorbs.net' => {},
	'dynablock.njabl.org' => {},
	'in-addr.arpa' => {
		comment => 'missing PTR record = 127.0.0.2',
	},
	'zen.spamhaus.org' => {},
	GENERIC => {
		comment	=> 'anonymous mail system, generic PTR',
	},
);

my %respons = (
	'1.2.3.4' => {
		COMMENT		=> 'group 99',
		'dnsbl.1'	=> '127.0.0.1',
		'dnsbl.3'	=> '127.0.0.3',
		'dnsbl.4'	=> '127.0.0.4',
	},
	'1.2.3.5' => {
		COMMENT		=> 'group 99',
		'list.dsbl.org'	=> '127.0.0.2',
		'dnsbl.4'	=> '127.0.0.4',
	},
	'1.2.3.6' => {
		COMMENT		=> '',
		'dnsbl.5'	=> '127.0.0.5',
		'dnsbl.1'	=> '127.0.0.2',
	},
	'1.2.3.7' => {
		COMMENT		=> '',
		'dnsbl.4'	=> '127.0.0.4',
	},
	'4.5.6.7' => {
		COMMENT		=> 'group 2',
		'dnsbl.1'	=> '127.0.0.1',
	},
	'5.6.7.8' => {
		COMMENT		=> 'group 3',
		'dnsbl.1'	=> '127.0.0.1',
		'dnsbl.3'	=> '127.0.0.3',
		'dnsbl.5'	=> '127.0.0.5',
	},
	'5.6.7.9' => {
		COMMENT		=> 'group 3',
		'dnsbl.1'	=> '127.0.0.1',
		'list.dsbl.org'	=> '127.0.0.2',
		'dnsbl.4'	=> '127.0.0.4',
	},
);


## test 2	check plain text
my $exp = q|

    1.2.3.6		127.0.0.2	dnsbl.1
			127.0.0.5	dnsbl.5
    1.2.3.7		127.0.0.4	dnsbl.4

group 2
    4.5.6.7		127.0.0.1	dnsbl.1

group 3
    5.6.7.8		127.0.0.1	dnsbl.1
			127.0.0.3	dnsbl.3
			127.0.0.5	dnsbl.5
    5.6.7.9		127.0.0.1	dnsbl.1
			127.0.0.4	dnsbl.4
			127.0.0.2	list.dsbl.org

group 99
    1.2.3.4		127.0.0.1	dnsbl.1
			127.0.0.3	dnsbl.3
			127.0.0.4	dnsbl.4
    1.2.3.5		127.0.0.4	dnsbl.4
			127.0.0.2	list.dsbl.org
|;
my $got = plainresp(\%respons);
gotexp($got,$exp);

## test 3	check html txt
$exp = q|
<tr valign=top align=left><td rowspan=3>&nbsp;</td><td rowspan=2>1.2.3.6</td><td>127.0.0.2</td><td>dnsbl.1</td></tr>
<tr valign=top align=left><td>127.0.0.5</td><td>dnsbl.5</td></tr>
<tr valign=top align=left><td rowspan=1>1.2.3.7</td><td>127.0.0.4</td><td>dnsbl.4</td></tr>

<tr valign=top align=left><td rowspan=1>group 2</td><td rowspan=1>4.5.6.7</td><td>127.0.0.1</td><td>dnsbl.1</td></tr>

<tr valign=top align=left><td rowspan=6>group 3</td><td rowspan=3>5.6.7.8</td><td>127.0.0.1</td><td>dnsbl.1</td></tr>
<tr valign=top align=left><td>127.0.0.3</td><td>dnsbl.3</td></tr>
<tr valign=top align=left><td>127.0.0.5</td><td>dnsbl.5</td></tr>
<tr valign=top align=left><td rowspan=3>5.6.7.9</td><td>127.0.0.1</td><td>dnsbl.1</td></tr>
<tr valign=top align=left><td>127.0.0.4</td><td>dnsbl.4</td></tr>
<tr valign=top align=left><td>127.0.0.2</td><td><a href="http://www.dsbl.org/">list.dsbl.org</a></td></tr>

<tr valign=top align=left><td rowspan=5>group 99</td><td rowspan=3>1.2.3.4</td><td>127.0.0.1</td><td>dnsbl.1</td></tr>
<tr valign=top align=left><td>127.0.0.3</td><td>dnsbl.3</td></tr>
<tr valign=top align=left><td>127.0.0.4</td><td>dnsbl.4</td></tr>
<tr valign=top align=left><td rowspan=2>1.2.3.5</td><td>127.0.0.4</td><td>dnsbl.4</td></tr>
<tr valign=top align=left><td>127.0.0.2</td><td><a href="http://www.dsbl.org/">list.dsbl.org</a></td></tr>
|;
$got = htmlresp(\%conf,\%respons);
gotexp($got,$exp);
