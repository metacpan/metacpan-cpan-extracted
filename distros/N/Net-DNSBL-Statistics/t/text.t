# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNSBL::Statistics qw(
	plaintxt
	htmltxt
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

my %dnsbls = (
        'GENERIC'               => 22,
        'TOTAL'                 => 44,
        'UNION'                 => 41,
        'bl.spamcannibal.org'   => 1,
        'bogons.cymru.com'      => 0,
        'cbl.abuseat.org'       => 11,
        'dnsbl.njabl.org'       => 2,
        'dnsbl.sorbs.net'       => 34,
        'dynablock.njabl.org'   => 0,
        'in-addr.arpa'          => 13,
        'list.dsbl.org'         => 9,
        'zen.spamhaus.org'      => 0,
);

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
		url	=> 'www.dsbl.org',
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

## test 2	check plain text
my $exp = q|44 100.0% TOTAL IP's interrogated
41  93.2% UNION of all results
34  77.3% dnsbl.sorbs.net 
22  50.0% GENERIC anonymous mail system, generic PTR
13  29.5% in-addr.arpa missing PTR record = 127.0.0.2
11  25.0% cbl.abuseat.org 
 9  20.5% list.dsbl.org 
 2   4.5% dnsbl.njabl.org njabl comment
 1   2.3% bl.spamcannibal.org 127.0.0.2
 0   0.0% bogons.cymru.com have no counts
 0   0.0% dynablock.njabl.org 
 0   0.0% zen.spamhaus.org 
|;
my $got = plaintxt(\%conf,\%dnsbls);
gotexp($got,$exp);

## test 3	check html txt
$exp = q|<tr class=dnsbl><td align=right>44</td><td align=right>100.0%</td><td align=left>TOTAL</td><td align=left>IP's interrogated</td></tr>
<tr class=dnsbl><td align=right>41</td><td align=right>93.2%</td><td align=left>UNION</td><td align=left>of all results</td></tr>
<tr class=dnsbl><td align=right>34</td><td align=right>77.3%</td><td align=left>dnsbl.sorbs.net</td><td align=left>&nbsp;</td></tr>
<tr class=dnsbl><td align=right>22</td><td align=right>50.0%</td><td align=left>GENERIC</td><td align=left>anonymous mail system, generic PTR</td></tr>
<tr class=dnsbl><td align=right>13</td><td align=right>29.5%</td><td align=left>in-addr.arpa</td><td align=left>missing PTR record = 127.0.0.2</td></tr>
<tr class=dnsbl><td align=right>11</td><td align=right>25.0%</td><td align=left>cbl.abuseat.org</td><td align=left>&nbsp;</td></tr>
<tr class=dnsbl><td align=right>9</td><td align=right>20.5%</td><td align=left><a href="www.dsbl.org">list.dsbl.org</a></td><td align=left>&nbsp;</td></tr>
<tr class=dnsbl><td align=right>2</td><td align=right>4.5%</td><td align=left><a href="http://www.njabl.org/">dnsbl.njabl.org</a></td><td align=left>njabl comment</td></tr>
<tr class=dnsbl><td align=right>1</td><td align=right>2.3%</td><td align=left><a href="cannibal.cgi">bl.spamcannibal.org</a></td><td align=left>127.0.0.2</td></tr>
<tr class=dnsbl><td align=right>0</td><td align=right>0.0%</td><td align=left>bogons.cymru.com</td><td align=left>have no counts</td></tr>
<tr class=dnsbl><td align=right>0</td><td align=right>0.0%</td><td align=left>dynablock.njabl.org</td><td align=left>&nbsp;</td></tr>
<tr class=dnsbl><td align=right>0</td><td align=right>0.0%</td><td align=left>zen.spamhaus.org</td><td align=left>&nbsp;</td></tr>
|;
$got = htmltxt(\%conf,\%dnsbls);
gotexp($got,$exp);
