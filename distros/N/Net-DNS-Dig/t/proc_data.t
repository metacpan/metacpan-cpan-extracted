# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#	proc_data.t
#
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	put1char
	inet_ntoa
);
use Net::DNS::ToolKit::RR;
#use Net::DNS::ToolKit::Debug qw(
#	print_buf
#);
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

*proc_ques = \&Net::DNS::Dig::_proc_ques;
*proc_data = \&Net::DNS::Dig::_proc_data;

#
# ; <<>> dig.pl 1.10 <<>> -t soa -d bizsystems.net
# ;;
# ;; Got answer.
# ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 11370
# ;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 2
#
# ;; QUESTION SECTION:
# ;bizsystems.net.		IN	SOA
#
# ;; ANSWER SECTION:
# bizsystems.net.	10800	IN	SOA	ns2.bizsystems.net. sysadm.bizsystems.com. 2011021804 43200 3600 259200 10800 
#
# ;; AUTHORITY SECTION:
# bizsystems.net.	10800	IN	NS	ns2.bizsystems.net. 
# bizsystems.net.	10800	IN	NS	ns3.bizsystems.net. 
#
# ;; ADDITIONAL SECTION:
# ns2.bizsystems.net.	10800	IN	A	75.101.7.146 
# ns3.bizsystems.net.	10800	IN	A	173.13.169.225 
#
# ;; Query time: 48 ms
# ;; SERVER: 192.168.1.171#53(192.168.1.171)
# ;; WHEN: Sat Oct  1 22:23:23 2011
# ;; MSG SIZE rcvd: 157 -- XFR size: 6 records
#
my $ques = q
| 0	:  0010_1100  0x2C   44  ,  
  1	:  0110_1010  0x6A  106  j  
  2	:  0000_0001  0x01    1    
  3	:  0000_0000  0x00    0    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0000  0x00    0    
  8	:  0000_0000  0x00    0    
  9	:  0000_0000  0x00    0    
  10	:  0000_0000  0x00    0    
  11	:  0000_0000  0x00    0    
  12	:  0000_1010  0x0A   10    
  13	:  0110_0010  0x62   98  b  
  14	:  0110_1001  0x69  105  i  
  15	:  0111_1010  0x7A  122  z  
  16	:  0111_0011  0x73  115  s  
  17	:  0111_1001  0x79  121  y  
  18	:  0111_0011  0x73  115  s  
  19	:  0111_0100  0x74  116  t  
  20	:  0110_0101  0x65  101  e  
  21	:  0110_1101  0x6D  109  m  
  22	:  0111_0011  0x73  115  s  
  23	:  0000_0011  0x03    3    
  24	:  0110_1110  0x6E  110  n  
  25	:  0110_0101  0x65  101  e  
  26	:  0111_0100  0x74  116  t  
  27	:  0000_0000  0x00    0    
  28	:  0000_0000  0x00    0    
  29	:  0000_0110  0x06    6    
  30	:  0000_0000  0x00    0    
  31	:  0000_0001  0x01    1    |;

my $ansr = q
| 0	:  0010_1100  0x2C   44  ,  
  1	:  0110_1010  0x6A  106  j  
  2	:  1000_0101  0x85  133    
  3	:  1000_0000  0x80  128    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0001  0x01    1    
  8	:  0000_0000  0x00    0    
  9	:  0000_0010  0x02    2    
  10	:  0000_0000  0x00    0    
  11	:  0000_0010  0x02    2    
  12	:  0000_1010  0x0A   10    
  13	:  0110_0010  0x62   98  b  
  14	:  0110_1001  0x69  105  i  
  15	:  0111_1010  0x7A  122  z  
  16	:  0111_0011  0x73  115  s  
  17	:  0111_1001  0x79  121  y  
  18	:  0111_0011  0x73  115  s  
  19	:  0111_0100  0x74  116  t  
  20	:  0110_0101  0x65  101  e  
  21	:  0110_1101  0x6D  109  m  
  22	:  0111_0011  0x73  115  s  
  23	:  0000_0011  0x03    3    
  24	:  0110_1110  0x6E  110  n  
  25	:  0110_0101  0x65  101  e  
  26	:  0111_0100  0x74  116  t  
  27	:  0000_0000  0x00    0    
  28	:  0000_0000  0x00    0    
  29	:  0000_0110  0x06    6    
  30	:  0000_0000  0x00    0    
  31	:  0000_0001  0x01    1    
  32	:  1100_0000  0xC0  192    
  33	:  0000_1100  0x0C   12    
  34	:  0000_0000  0x00    0    
  35	:  0000_0110  0x06    6    
  36	:  0000_0000  0x00    0    
  37	:  0000_0001  0x01    1    
  38	:  0000_0000  0x00    0    
  39	:  0000_0000  0x00    0    
  40	:  0010_1010  0x2A   42  *  
  41	:  0011_0000  0x30   48  0  
  42	:  0000_0000  0x00    0    
  43	:  0011_0001  0x31   49  1  
  44	:  0000_0011  0x03    3    
  45	:  0110_1110  0x6E  110  n  
  46	:  0111_0011  0x73  115  s  
  47	:  0011_0010  0x32   50  2  
  48	:  1100_0000  0xC0  192    
  49	:  0000_1100  0x0C   12    
  50	:  0000_0110  0x06    6    
  51	:  0111_0011  0x73  115  s  
  52	:  0111_1001  0x79  121  y  
  53	:  0111_0011  0x73  115  s  
  54	:  0110_0001  0x61   97  a  
  55	:  0110_0100  0x64  100  d  
  56	:  0110_1101  0x6D  109  m  
  57	:  0000_1010  0x0A   10    
  58	:  0110_0010  0x62   98  b  
  59	:  0110_1001  0x69  105  i  
  60	:  0111_1010  0x7A  122  z  
  61	:  0111_0011  0x73  115  s  
  62	:  0111_1001  0x79  121  y  
  63	:  0111_0011  0x73  115  s  
  64	:  0111_0100  0x74  116  t  
  65	:  0110_0101  0x65  101  e  
  66	:  0110_1101  0x6D  109  m  
  67	:  0111_0011  0x73  115  s  
  68	:  0000_0011  0x03    3    
  69	:  0110_0011  0x63   99  c  
  70	:  0110_1111  0x6F  111  o  
  71	:  0110_1101  0x6D  109  m  
  72	:  0000_0000  0x00    0    
  73	:  0111_0111  0x77  119  w  
  74	:  1101_1101  0xDD  221    
  75	:  1100_0001  0xC1  193    
  76	:  1110_1100  0xEC  236    
  77	:  0000_0000  0x00    0    
  78	:  0000_0000  0x00    0    
  79	:  1010_1000  0xA8  168    
  80	:  1100_0000  0xC0  192    
  81	:  0000_0000  0x00    0    
  82	:  0000_0000  0x00    0    
  83	:  0000_1110  0x0E   14    
  84	:  0001_0000  0x10   16    
  85	:  0000_0000  0x00    0    
  86	:  0000_0011  0x03    3    
  87	:  1111_0100  0xF4  244    
  88	:  1000_0000  0x80  128    
  89	:  0000_0000  0x00    0    
  90	:  0000_0000  0x00    0    
  91	:  0010_1010  0x2A   42  *  
  92	:  0011_0000  0x30   48  0  
  93	:  1100_0000  0xC0  192    
  94	:  0000_1100  0x0C   12    
  95	:  0000_0000  0x00    0    
  96	:  0000_0010  0x02    2    
  97	:  0000_0000  0x00    0    
  98	:  0000_0001  0x01    1    
  99	:  0000_0000  0x00    0    
  100	:  0000_0000  0x00    0    
  101	:  0010_1010  0x2A   42  *  
  102	:  0011_0000  0x30   48  0  
  103	:  0000_0000  0x00    0    
  104	:  0000_0010  0x02    2    
  105	:  1100_0000  0xC0  192    
  106	:  0010_1100  0x2C   44  ,  
  107	:  1100_0000  0xC0  192    
  108	:  0000_1100  0x0C   12    
  109	:  0000_0000  0x00    0    
  110	:  0000_0010  0x02    2    
  111	:  0000_0000  0x00    0    
  112	:  0000_0001  0x01    1    
  113	:  0000_0000  0x00    0    
  114	:  0000_0000  0x00    0    
  115	:  0010_1010  0x2A   42  *  
  116	:  0011_0000  0x30   48  0  
  117	:  0000_0000  0x00    0    
  118	:  0000_0110  0x06    6    
  119	:  0000_0011  0x03    3    
  120	:  0110_1110  0x6E  110  n  
  121	:  0111_0011  0x73  115  s  
  122	:  0011_0011  0x33   51  3  
  123	:  1100_0000  0xC0  192    
  124	:  0000_1100  0x0C   12    
  125	:  1100_0000  0xC0  192    
  126	:  0010_1100  0x2C   44  ,  
  127	:  0000_0000  0x00    0    
  128	:  0000_0001  0x01    1    
  129	:  0000_0000  0x00    0    
  130	:  0000_0001  0x01    1    
  131	:  0000_0000  0x00    0    
  132	:  0000_0000  0x00    0    
  133	:  0010_1010  0x2A   42  *  
  134	:  0011_0000  0x30   48  0  
  135	:  0000_0000  0x00    0    
  136	:  0000_0100  0x04    4    
  137	:  0100_1011  0x4B   75  K  
  138	:  0110_0101  0x65  101  e  
  139	:  0000_0111  0x07    7    
  140	:  1001_0010  0x92  146    
  141	:  1100_0000  0xC0  192    
  142	:  0111_0111  0x77  119  w  
  143	:  0000_0000  0x00    0    
  144	:  0000_0001  0x01    1    
  145	:  0000_0000  0x00    0    
  146	:  0000_0001  0x01    1    
  147	:  0000_0000  0x00    0    
  148	:  0000_0000  0x00    0    
  149	:  0010_1010  0x2A   42  *  
  150	:  0011_0000  0x30   48  0  
  151	:  0000_0000  0x00    0    
  152	:  0000_0100  0x04    4    
  153	:  1010_1101  0xAD  173    
  154	:  0000_1101  0x0D   13    
  155	:  1010_1001  0xA9  169    
  156	:  1110_0001  0xE1  225    |;

# input:	data pointer
# returns:	pointer to query buffer
#
sub makebuf {
  my $dp = shift;
  my @data = split("\n",$$dp);
  my $off = 0;
  my $buffer = '';
  foreach (@data) {
    $_ =~ /0x.{2}\s+(\d+)/;
    $off = put1char(\$buffer,$off,$1);
  }
  return \$buffer;
}
my $qbp = makebuf(\$ques);
my $abp = makebuf(\$ansr);

my($get,$put,$parse) = new Net::DNS::ToolKit::RR;

my $datastart = proc_ques($get,&HFIXEDSZ,$abp);

my $soacount = 0;

## test 2	get answer
my($qdcount,$ancount,$nscount,$arcount) = (1,1,2,2);
my($off,@rdata) = proc_data($get,$datastart,$abp,'ANSWER',$ancount,\$soacount);
my $got = join(' ',$off,@rdata);
my $exp = '93 ns2.bizsystems.net sysadm.bizsystems.com 2011021804 43200 3600 259200 10800';
print "data decode failure\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 3	check increment of SOA count for type = SOA
print "SOA count did not increment\nnot "
	unless $soacount == 1;
&ok;

## test 4	get authority
($off,@rdata) = proc_data($get,$off,$abp,'AUTHORITY',$nscount,\$soacount);
$got = join(' ',$off,@rdata);
$exp = '125 ns2.bizsystems.net ns3.bizsystems.net';
print "data decode failure\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 5	check that SOA count did not increment
print "SOA count should not increment\nnot "
	unless $soacount == 1;
&ok;

## test 6	get glue records
($off,@rdata) = proc_data($get,$off,$abp,'ADDITIONAL',$arcount,\$soacount);
foreach(@rdata) {
  $_ = inet_ntoa($_);
}
$got = join(' ',$off,@rdata);
$exp = '157 75.101.7.146 173.13.169.225';
print "data decode failure\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 7	check that SOA count did not increment
print "SOA count should not increment\nnot "
	unless $soacount == 1;
&ok;

my $obj = {};

## test 8	get answer
($off,@rdata) = proc_data($get,$datastart,$abp,'ANSWER',$ancount,\$soacount,$obj);
$got = join(' ',$off,@rdata);
$exp = '93 ns2.bizsystems.net sysadm.bizsystems.com 2011021804 43200 3600 259200 10800';
print "data decode failure\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 9	check increment of SOA count for type = SOA
print "SOA count did not increment\nnot "
	unless $soacount == 2;
&ok;

## test 10	check object contents
$exp = q|15	= {
	'ANSWER'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'bizsystems.net',
		'RDATA'	=> ['ns2.bizsystems.net','sysadm.bizsystems.com',2011021804,43200,3600,259200,10800,],
		'RDLEN'	=> 49,
		'TTL'	=> 10800,
		'TYPE'	=> 6,
	},
],
};
|;
$got = Dumper($obj);
print "object build failed\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 11	get authority
($off,@rdata) = proc_data($get,$off,$abp,'AUTHORITY',$nscount,\$soacount,$obj);
$got = join(' ',$off,@rdata);
$exp = '125 ns2.bizsystems.net ns3.bizsystems.net';
print "data decode failure\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 12	check that SOA count did not increment
print "SOA count should not increment\nnot "
	unless $soacount == 2;
&ok;

## test 13	check object with authority
$exp = q|32	= {
	'ANSWER'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'bizsystems.net',
		'RDATA'	=> ['ns2.bizsystems.net','sysadm.bizsystems.com',2011021804,43200,3600,259200,10800,],
		'RDLEN'	=> 49,
		'TTL'	=> 10800,
		'TYPE'	=> 6,
	},
],
	'AUTHORITY'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'bizsystems.net',
		'RDATA'	=> ['ns2.bizsystems.net',],
		'RDLEN'	=> 2,
		'TTL'	=> 10800,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'bizsystems.net',
		'RDATA'	=> ['ns3.bizsystems.net',],
		'RDLEN'	=> 6,
		'TTL'	=> 10800,
		'TYPE'	=> 2,
	},
],
};
|;
$got = Dumper($obj);
print "object build failed\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 14	get glue records
($off,@rdata) = proc_data($get,$off,$abp,'ADDITIONAL',$arcount,\$soacount,$obj);
foreach(@rdata) {
  $_ = inet_ntoa($_);
}
$got = join(' ',$off,@rdata);
$exp = '157 75.101.7.146 173.13.169.225';
print "data decode failure\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 15	check that SOA count did not increment
print "SOA count should not increment\nnot "
	unless $soacount == 2;
&ok;

## test 16	check object with glue
$exp = q|49	= {
	'ADDITIONAL'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'ns2.bizsystems.net',
		'RDATA'	=> ['KeТ',],
		'RDLEN'	=> 4,
		'TTL'	=> 10800,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'ns3.bizsystems.net',
		'RDATA'	=> ['нйс',],
		'RDLEN'	=> 4,
		'TTL'	=> 10800,
		'TYPE'	=> 1,
	},
],
	'ANSWER'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'bizsystems.net',
		'RDATA'	=> ['ns2.bizsystems.net','sysadm.bizsystems.com',2011021804,43200,3600,259200,10800,],
		'RDLEN'	=> 49,
		'TTL'	=> 10800,
		'TYPE'	=> 6,
	},
],
	'AUTHORITY'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'bizsystems.net',
		'RDATA'	=> ['ns2.bizsystems.net',],
		'RDLEN'	=> 2,
		'TTL'	=> 10800,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'bizsystems.net',
		'RDATA'	=> ['ns3.bizsystems.net',],
		'RDLEN'	=> 6,
		'TTL'	=> 10800,
		'TYPE'	=> 2,
	},
],
};
|;
$got = Dumper($obj);
print "object build failed\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;
