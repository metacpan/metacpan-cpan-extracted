# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#	proc_body.t
#
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
	$| = 1; print "1..16\n"; 
	*CORE::GLOBAL::localtime = \&localtime;
}
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::Dig;
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	put1char
	get1char
	inet_aton
);
use Net::DNS::ToolKit::RR;
#use Net::DNS::ToolKit::Debug qw(
#	print_head
#	print_buf
#);

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

$Net::DNS::Dig::VERSION = sprintf("%d.%02d",0,1);       # always test as version 0.01

Net::DNS::Dig::_set_NS(inet_aton('12.34.56.78'),inet_aton('23.45.67.89'));

package MyTest;

require './recurse2txt';

package main;

sub expect {
  my $x = shift;
  my @exp;
  foreach(split(/\n/,$x)) {
    if ($_ =~ /0x\w+\s+(\d+) /) {
      push @exp,$1;
    }
  }
  return @exp;
}

sub print_ptrs {
  foreach(@_) {
    print "$_ ";
  }
  print "\n";
}

sub chk_exp {
  my($bp,$exp) = @_;
  my @expect = expect($$exp);
  foreach(0..length($$bp) -1) {
    $char = get1char($bp,$_);
    next if $char == $expect[$_];
    print "buffer mismatch $_, got: $char, exp: $expect[$_]\nnot ";
    last;
  }
  &ok;
}

my $ques = q
| 0	:  0011_1000  0x38   56  8  
  1	:  1010_0010  0xA2  162    
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
  12	:  0000_0110  0x06    6    
  13	:  0110_0111  0x67  103  g  
  14	:  0110_1111  0x6F  111  o  
  15	:  0110_1111  0x6F  111  o  
  16	:  0110_0111  0x67  103  g  
  17	:  0110_1100  0x6C  108  l  
  18	:  0110_0101  0x65  101  e  
  19	:  0000_0011  0x03    3    
  20	:  0110_0011  0x63   99  c  
  21	:  0110_1111  0x6F  111  o  
  22	:  0110_1101  0x6D  109  m  
  23	:  0000_0000  0x00    0    
  24	:  0000_0000  0x00    0    
  25	:  0000_0001  0x01    1    
  26	:  0000_0000  0x00    0    
  27	:  0000_0001  0x01    1    |;

my $ans = q
| 0	:  0011_1000  0x38   56  8  
  1	:  1010_0010  0xA2  162    
  2	:  1000_0001  0x81  129    
  3	:  1000_0000  0x80  128    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0101  0x05    5    
  8	:  0000_0000  0x00    0    
  9	:  0000_0100  0x04    4    
  10	:  0000_0000  0x00    0    
  11	:  0000_0100  0x04    4    
  12	:  0000_0110  0x06    6    
  13	:  0110_0111  0x67  103  g  
  14	:  0110_1111  0x6F  111  o  
  15	:  0110_1111  0x6F  111  o  
  16	:  0110_0111  0x67  103  g  
  17	:  0110_1100  0x6C  108  l  
  18	:  0110_0101  0x65  101  e  
  19	:  0000_0011  0x03    3    
  20	:  0110_0011  0x63   99  c  
  21	:  0110_1111  0x6F  111  o  
  22	:  0110_1101  0x6D  109  m  
  23	:  0000_0000  0x00    0    
  24	:  0000_0000  0x00    0    
  25	:  0000_0001  0x01    1    
  26	:  0000_0000  0x00    0    
  27	:  0000_0001  0x01    1    
  28	:  1100_0000  0xC0  192    
  29	:  0000_1100  0x0C   12    
  30	:  0000_0000  0x00    0    
  31	:  0000_0001  0x01    1    
  32	:  0000_0000  0x00    0    
  33	:  0000_0001  0x01    1    
  34	:  0000_0000  0x00    0    
  35	:  0000_0000  0x00    0    
  36	:  0000_0001  0x01    1    
  37	:  0001_0101  0x15   21    
  38	:  0000_0000  0x00    0    
  39	:  0000_0100  0x04    4    
  40	:  0100_1010  0x4A   74  J  
  41	:  0111_1101  0x7D  125  }  
  42	:  1110_0000  0xE0  224    
  43	:  1001_0001  0x91  145    
  44	:  1100_0000  0xC0  192    
  45	:  0000_1100  0x0C   12    
  46	:  0000_0000  0x00    0    
  47	:  0000_0001  0x01    1    
  48	:  0000_0000  0x00    0    
  49	:  0000_0001  0x01    1    
  50	:  0000_0000  0x00    0    
  51	:  0000_0000  0x00    0    
  52	:  0000_0001  0x01    1    
  53	:  0001_0101  0x15   21    
  54	:  0000_0000  0x00    0    
  55	:  0000_0100  0x04    4    
  56	:  0100_1010  0x4A   74  J  
  57	:  0111_1101  0x7D  125  }  
  58	:  1110_0000  0xE0  224    
  59	:  1001_0010  0x92  146    
  60	:  1100_0000  0xC0  192    
  61	:  0000_1100  0x0C   12    
  62	:  0000_0000  0x00    0    
  63	:  0000_0001  0x01    1    
  64	:  0000_0000  0x00    0    
  65	:  0000_0001  0x01    1    
  66	:  0000_0000  0x00    0    
  67	:  0000_0000  0x00    0    
  68	:  0000_0001  0x01    1    
  69	:  0001_0101  0x15   21    
  70	:  0000_0000  0x00    0    
  71	:  0000_0100  0x04    4    
  72	:  0100_1010  0x4A   74  J  
  73	:  0111_1101  0x7D  125  }  
  74	:  1110_0000  0xE0  224    
  75	:  1001_0011  0x93  147    
  76	:  1100_0000  0xC0  192    
  77	:  0000_1100  0x0C   12    
  78	:  0000_0000  0x00    0    
  79	:  0000_0001  0x01    1    
  80	:  0000_0000  0x00    0    
  81	:  0000_0001  0x01    1    
  82	:  0000_0000  0x00    0    
  83	:  0000_0000  0x00    0    
  84	:  0000_0001  0x01    1    
  85	:  0001_0101  0x15   21    
  86	:  0000_0000  0x00    0    
  87	:  0000_0100  0x04    4    
  88	:  0100_1010  0x4A   74  J  
  89	:  0111_1101  0x7D  125  }  
  90	:  1110_0000  0xE0  224    
  91	:  1001_0100  0x94  148    
  92	:  1100_0000  0xC0  192    
  93	:  0000_1100  0x0C   12    
  94	:  0000_0000  0x00    0    
  95	:  0000_0001  0x01    1    
  96	:  0000_0000  0x00    0    
  97	:  0000_0001  0x01    1    
  98	:  0000_0000  0x00    0    
  99	:  0000_0000  0x00    0    
  100	:  0000_0001  0x01    1    
  101	:  0001_0101  0x15   21    
  102	:  0000_0000  0x00    0    
  103	:  0000_0100  0x04    4    
  104	:  0100_1010  0x4A   74  J  
  105	:  0111_1101  0x7D  125  }  
  106	:  1110_0000  0xE0  224    
  107	:  1001_0000  0x90  144    
  108	:  1100_0000  0xC0  192    
  109	:  0000_1100  0x0C   12    
  110	:  0000_0000  0x00    0    
  111	:  0000_0010  0x02    2    
  112	:  0000_0000  0x00    0    
  113	:  0000_0001  0x01    1    
  114	:  0000_0000  0x00    0    
  115	:  0000_0000  0x00    0    
  116	:  1100_1111  0xCF  207    
  117	:  1001_1011  0x9B  155    
  118	:  0000_0000  0x00    0    
  119	:  0000_0110  0x06    6    
  120	:  0000_0011  0x03    3    
  121	:  0110_1110  0x6E  110  n  
  122	:  0111_0011  0x73  115  s  
  123	:  0011_0010  0x32   50  2  
  124	:  1100_0000  0xC0  192    
  125	:  0000_1100  0x0C   12    
  126	:  1100_0000  0xC0  192    
  127	:  0000_1100  0x0C   12    
  128	:  0000_0000  0x00    0    
  129	:  0000_0010  0x02    2    
  130	:  0000_0000  0x00    0    
  131	:  0000_0001  0x01    1    
  132	:  0000_0000  0x00    0    
  133	:  0000_0000  0x00    0    
  134	:  1100_1111  0xCF  207    
  135	:  1001_1011  0x9B  155    
  136	:  0000_0000  0x00    0    
  137	:  0000_0110  0x06    6    
  138	:  0000_0011  0x03    3    
  139	:  0110_1110  0x6E  110  n  
  140	:  0111_0011  0x73  115  s  
  141	:  0011_0001  0x31   49  1  
  142	:  1100_0000  0xC0  192    
  143	:  0000_1100  0x0C   12    
  144	:  1100_0000  0xC0  192    
  145	:  0000_1100  0x0C   12    
  146	:  0000_0000  0x00    0    
  147	:  0000_0010  0x02    2    
  148	:  0000_0000  0x00    0    
  149	:  0000_0001  0x01    1    
  150	:  0000_0000  0x00    0    
  151	:  0000_0000  0x00    0    
  152	:  1100_1111  0xCF  207    
  153	:  1001_1011  0x9B  155    
  154	:  0000_0000  0x00    0    
  155	:  0000_0110  0x06    6    
  156	:  0000_0011  0x03    3    
  157	:  0110_1110  0x6E  110  n  
  158	:  0111_0011  0x73  115  s  
  159	:  0011_0100  0x34   52  4  
  160	:  1100_0000  0xC0  192    
  161	:  0000_1100  0x0C   12    
  162	:  1100_0000  0xC0  192    
  163	:  0000_1100  0x0C   12    
  164	:  0000_0000  0x00    0    
  165	:  0000_0010  0x02    2    
  166	:  0000_0000  0x00    0    
  167	:  0000_0001  0x01    1    
  168	:  0000_0000  0x00    0    
  169	:  0000_0000  0x00    0    
  170	:  1100_1111  0xCF  207    
  171	:  1001_1011  0x9B  155    
  172	:  0000_0000  0x00    0    
  173	:  0000_0110  0x06    6    
  174	:  0000_0011  0x03    3    
  175	:  0110_1110  0x6E  110  n  
  176	:  0111_0011  0x73  115  s  
  177	:  0011_0011  0x33   51  3  
  178	:  1100_0000  0xC0  192    
  179	:  0000_1100  0x0C   12    
  180	:  1100_0000  0xC0  192    
  181	:  1000_1010  0x8A  138    
  182	:  0000_0000  0x00    0    
  183	:  0000_0001  0x01    1    
  184	:  0000_0000  0x00    0    
  185	:  0000_0001  0x01    1    
  186	:  0000_0000  0x00    0    
  187	:  0000_0011  0x03    3    
  188	:  0111_0010  0x72  114  r  
  189	:  1001_1100  0x9C  156    
  190	:  0000_0000  0x00    0    
  191	:  0000_0100  0x04    4    
  192	:  1101_1000  0xD8  216    
  193	:  1110_1111  0xEF  239    
  194	:  0010_0000  0x20   32     
  195	:  0000_1010  0x0A   10    
  196	:  1100_0000  0xC0  192    
  197	:  0111_1000  0x78  120  x  
  198	:  0000_0000  0x00    0    
  199	:  0000_0001  0x01    1    
  200	:  0000_0000  0x00    0    
  201	:  0000_0001  0x01    1    
  202	:  0000_0000  0x00    0    
  203	:  0000_0011  0x03    3    
  204	:  0111_0010  0x72  114  r  
  205	:  1001_1100  0x9C  156    
  206	:  0000_0000  0x00    0    
  207	:  0000_0100  0x04    4    
  208	:  1101_1000  0xD8  216    
  209	:  1110_1111  0xEF  239    
  210	:  0010_0010  0x22   34  "  
  211	:  0000_1010  0x0A   10    
  212	:  1100_0000  0xC0  192    
  213	:  1010_1110  0xAE  174    
  214	:  0000_0000  0x00    0    
  215	:  0000_0001  0x01    1    
  216	:  0000_0000  0x00    0    
  217	:  0000_0001  0x01    1    
  218	:  0000_0000  0x00    0    
  219	:  0000_0011  0x03    3    
  220	:  0111_0010  0x72  114  r  
  221	:  1001_1100  0x9C  156    
  222	:  0000_0000  0x00    0    
  223	:  0000_0100  0x04    4    
  224	:  1101_1000  0xD8  216    
  225	:  1110_1111  0xEF  239    
  226	:  0010_0100  0x24   36  $  
  227	:  0000_1010  0x0A   10    
  228	:  1100_0000  0xC0  192    
  229	:  1001_1100  0x9C  156    
  230	:  0000_0000  0x00    0    
  231	:  0000_0001  0x01    1    
  232	:  0000_0000  0x00    0    
  233	:  0000_0001  0x01    1    
  234	:  0000_0000  0x00    0    
  235	:  0000_0011  0x03    3    
  236	:  0111_0010  0x72  114  r  
  237	:  1001_1100  0x9C  156    
  238	:  0000_0000  0x00    0    
  239	:  0000_0100  0x04    4    
  240	:  1101_1000  0xD8  216    
  241	:  1110_1111  0xEF  239    
  242	:  0010_0110  0x26   38  &  
  243	:  0000_1010  0x0A   10    |;

# ; <<>> dig.pl 1.10 <<>> -d google.com
# ;;
# ;; Got answer.
# ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14498
# ;; flags: qr rd ra; QUERY: 1, ANSWER: 5, AUTHORITY: 4, ADDITIONAL: 4
# 
# ;; QUESTION SECTION:
# ;google.com.		IN	A
# 
# ;; ANSWER SECTION:
# google.com.	277	IN	A	74.125.224.145 
# google.com.	277	IN	A	74.125.224.146 
# google.com.	277	IN	A	74.125.224.147 
# google.com.	277	IN	A	74.125.224.148 
# google.com.	277	IN	A	74.125.224.144 
# 
# ;; AUTHORITY SECTION:
# google.com.	53147	IN	NS	ns2.google.com. 
# google.com.	53147	IN	NS	ns1.google.com. 
# google.com.	53147	IN	NS	ns4.google.com. 
# google.com.	53147	IN	NS	ns3.google.com. 
# 
# ;; ADDITIONAL SECTION:
# ns1.google.com.	225948	IN	A	216.239.32.10 
# ns2.google.com.	225948	IN	A	216.239.34.10 
# ns3.google.com.	225948	IN	A	216.239.36.10 
# ns4.google.com.	225948	IN	A	216.239.38.10 
# 
# ;; Query time: 51 ms
# ;; SERVER: 192.168.1.171# 53(192.168.1.171)
# ;; WHEN: Sun Oct  2 19:47:50 2011
# ;; MSG SIZE rcvd: 244 -- XFR size: 14 records
# 

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

{
	undef local $^W;
	*Net::DNS::Dig::ndd_gethostbyaddr = \&mygethostbyaddr;
}

# dummy localtime
sub localtime {
  return 'Mon Oct  3 13:41:57 2011';
}

# dummy mygethostbyaddr
sub mygethostbyaddr {
  return 'my.test.domain.com';
}

my $ap = makebuf(\$ans);
my $qp = makebuf(\$ques);

my $soacount = 0;
my($get,$put,$parse) = new Net::DNS::ToolKit::RR;

## test 2	check server failure
my $dig = new Net::DNS::Dig;
my $rp = $dig->_proc_body($ap,$qp,$get,$put,\$soacount);
#print_head($rp);
#print "\n";
#print_head($qp);
chk_exp($rp,\$ans);

## test 3	check object contents
my $exp = q|141	= {
	'ADDITIONAL'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'ns1.google.com',
		'RDATA'	=> ['Шп 
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 225948,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'ns2.google.com',
		'RDATA'	=> ['Шп"
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 225948,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'ns3.google.com',
		'RDATA'	=> ['Шп$
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 225948,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'ns4.google.com',
		'RDATA'	=> ['Шп&
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 225948,
		'TYPE'	=> 1,
	},
],
	'ANSWER'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'google.com',
		'RDATA'	=> ['J}а‘',],
		'RDLEN'	=> 4,
		'TTL'	=> 277,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'google.com',
		'RDATA'	=> ['J}а’',],
		'RDLEN'	=> 4,
		'TTL'	=> 277,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'google.com',
		'RDATA'	=> ['J}а“',],
		'RDLEN'	=> 4,
		'TTL'	=> 277,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'google.com',
		'RDATA'	=> ['J}а”',],
		'RDLEN'	=> 4,
		'TTL'	=> 277,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'google.com',
		'RDATA'	=> ['J}ађ',],
		'RDLEN'	=> 4,
		'TTL'	=> 277,
		'TYPE'	=> 1,
	},
],
	'AUTHORITY'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'google.com',
		'RDATA'	=> ['ns2.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 53147,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'google.com',
		'RDATA'	=> ['ns1.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 53147,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'google.com',
		'RDATA'	=> ['ns4.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 53147,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'google.com',
		'RDATA'	=> ['ns3.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 53147,
		'TYPE'	=> 2,
	},
],
	'BYTES'	=> 244,
	'Class'	=> 'IN',
	'HEADER'	=> {
		'AA'	=> 0,
		'AD'	=> 0,
		'ANCOUNT'	=> 5,
		'ARCOUNT'	=> 4,
		'CD'	=> 0,
		'ID'	=> 14498,
		'MBZ'	=> 0,
		'NSCOUNT'	=> 4,
		'OPCODE'	=> 0,
		'QDCOUNT'	=> 1,
		'QR'	=> 1,
		'RA'	=> 1,
		'RCODE'	=> 0,
		'RD'	=> 1,
		'TC'	=> 0,
	},
	'NRECS'	=> 14,
	'PeerAddr'	=> ['12.34.56.78','23.45.67.89',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'QUESTION'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'google.com',
		'TYPE'	=> 1,
	},
],
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'23.45.67.89'	=> '-CY',
	},
};
|;

#print MyTest::Dumper($dig);
my $got = MyTest::Dumper($dig);
print "proc_body failed\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 4	check that soacount is untouched
print "soacount incremented, got $soacount, exp 0\nnot "
	if $soacount;
&ok;

## test 5	build text object
$dig->{ELAPSED} = 56;
$dig->{SERVER} = '5.6.7.8';
$dig->{PeerAddr} = ['3.4.5.6','5.6.7.8'];
@{$dig->{_SS}}{'3.4.5.6','5.6.7.8'} = (inet_aton('3.4.5.6'),inet_aton('5.6.7.8'));
my $tobj = $dig->to_text();
$exp = q|146	= {
	'ADDITIONAL'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns1.google.com.',
		'RDATA'	=> ['216.239.32.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 225948,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns2.google.com.',
		'RDATA'	=> ['216.239.34.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 225948,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns3.google.com.',
		'RDATA'	=> ['216.239.36.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 225948,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns4.google.com.',
		'RDATA'	=> ['216.239.38.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 225948,
		'TYPE'	=> 'A',
	},
],
	'ANSWER'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'google.com.',
		'RDATA'	=> ['74.125.224.145',],
		'RDLEN'	=> 4,
		'TTL'	=> 277,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'google.com.',
		'RDATA'	=> ['74.125.224.146',],
		'RDLEN'	=> 4,
		'TTL'	=> 277,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'google.com.',
		'RDATA'	=> ['74.125.224.147',],
		'RDLEN'	=> 4,
		'TTL'	=> 277,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'google.com.',
		'RDATA'	=> ['74.125.224.148',],
		'RDLEN'	=> 4,
		'TTL'	=> 277,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'google.com.',
		'RDATA'	=> ['74.125.224.144',],
		'RDLEN'	=> 4,
		'TTL'	=> 277,
		'TYPE'	=> 'A',
	},
],
	'AUTHORITY'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'google.com.',
		'RDATA'	=> ['ns2.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 53147,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'google.com.',
		'RDATA'	=> ['ns1.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 53147,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'google.com.',
		'RDATA'	=> ['ns4.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 53147,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'google.com.',
		'RDATA'	=> ['ns3.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 53147,
		'TYPE'	=> 'NS',
	},
],
	'BYTES'	=> 244,
	'Class'	=> 'IN',
	'ELAPSED'	=> 56,
	'HEADER'	=> {
		'AA'	=> 0,
		'AD'	=> 0,
		'ANCOUNT'	=> 5,
		'ARCOUNT'	=> 4,
		'CD'	=> 0,
		'ID'	=> 14498,
		'MBZ'	=> 0,
		'NSCOUNT'	=> 4,
		'OPCODE'	=> 'QUERY',
		'QDCOUNT'	=> 1,
		'QR'	=> 1,
		'RA'	=> 1,
		'RCODE'	=> 'NOERROR',
		'RD'	=> 1,
		'TC'	=> 0,
	},
	'NRECS'	=> 14,
	'PeerAddr'	=> ['3.4.5.6','5.6.7.8',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'QUESTION'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'google.com.',
		'TYPE'	=> 'A',
	},
],
	'Recursion'	=> 256,
	'SERVER'	=> '5.6.7.8',
	'TEXT'	=> '
; <<>> Net::DNS::Dig 0.01 <<>> -t a google.com.
;;
;; Got answer.
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14498
;; flags: qr rd ra; QUERY: 1, ANSWER: 5, AUTHORITY: 4, ADDITIONAL: 4

;; QUESTION SECTION:
;google.com.		IN	A

;; ANSWER SECTION:
google.com.	277	IN	A	 74.125.224.145
google.com.	277	IN	A	 74.125.224.146
google.com.	277	IN	A	 74.125.224.147
google.com.	277	IN	A	 74.125.224.148
google.com.	277	IN	A	 74.125.224.144

;; AUTHORITY SECTION:
google.com.	53147	IN	NS	 ns2.google.com.
google.com.	53147	IN	NS	 ns1.google.com.
google.com.	53147	IN	NS	 ns4.google.com.
google.com.	53147	IN	NS	 ns3.google.com.

;; ADDITIONAL SECTION:
ns1.google.com.	225948	IN	A	 216.239.32.10
ns2.google.com.	225948	IN	A	 216.239.34.10
ns3.google.com.	225948	IN	A	 216.239.36.10
ns4.google.com.	225948	IN	A	 216.239.38.10

;; Query time: 56 ms
;; SERVER: 5.6.7.8# 53(5.6.7.8)
;; WHEN: Mon Oct  3 13:41:57 2011
;; MSG SIZE rcvd: 244 -- XFR size: 14 records
',
	'Timeout'	=> 15,
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'23.45.67.89'	=> '-CY',
		'3.4.5.6'	=> '',
		'5.6.7.8'	=> '',
	},
};
|;

$got = MyTest::Dumper($tobj);
print "to_text conversion failed\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 6	check that soacount did not increment
print "unexpected soacount increment\nnot "
	if $soacount;
&ok;

my $ques2 = q
| 0	:  0100_0110  0x46   70  F  
  1	:  0111_0001  0x71  113  q  
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
  12	:  0000_0101  0x05    5    
  13	:  0110_0111  0x67  103  g  
  14	:  0110_1101  0x6D  109  m  
  15	:  0110_0001  0x61   97  a  
  16	:  0110_1001  0x69  105  i  
  17	:  0110_1100  0x6C  108  l  
  18	:  0000_0011  0x03    3    
  19	:  0110_0011  0x63   99  c  
  20	:  0110_1111  0x6F  111  o  
  21	:  0110_1101  0x6D  109  m  
  22	:  0000_0000  0x00    0    
  23	:  0000_0000  0x00    0    
  24	:  0000_1111  0x0F   15    
  25	:  0000_0000  0x00    0    
  26	:  0000_0001  0x01    1    |;

my $ans2 = q
| 0	:  0100_0110  0x46   70  F  
  1	:  0111_0001  0x71  113  q  
  2	:  1000_0001  0x81  129    
  3	:  1000_0000  0x80  128    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0101  0x05    5    
  8	:  0000_0000  0x00    0    
  9	:  0000_0100  0x04    4    
  10	:  0000_0000  0x00    0    
  11	:  0000_0100  0x04    4    
  12	:  0000_0101  0x05    5    
  13	:  0110_0111  0x67  103  g  
  14	:  0110_1101  0x6D  109  m  
  15	:  0110_0001  0x61   97  a  
  16	:  0110_1001  0x69  105  i  
  17	:  0110_1100  0x6C  108  l  
  18	:  0000_0011  0x03    3    
  19	:  0110_0011  0x63   99  c  
  20	:  0110_1111  0x6F  111  o  
  21	:  0110_1101  0x6D  109  m  
  22	:  0000_0000  0x00    0    
  23	:  0000_0000  0x00    0    
  24	:  0000_1111  0x0F   15    
  25	:  0000_0000  0x00    0    
  26	:  0000_0001  0x01    1    
  27	:  1100_0000  0xC0  192    
  28	:  0000_1100  0x0C   12    
  29	:  0000_0000  0x00    0    
  30	:  0000_1111  0x0F   15    
  31	:  0000_0000  0x00    0    
  32	:  0000_0001  0x01    1    
  33	:  0000_0000  0x00    0    
  34	:  0000_0000  0x00    0    
  35	:  0000_1101  0x0D   13    
  36	:  1111_0101  0xF5  245    
  37	:  0000_0000  0x00    0    
  38	:  0010_0000  0x20   32     
  39	:  0000_0000  0x00    0    
  40	:  0001_0100  0x14   20    
  41	:  0000_0100  0x04    4    
  42	:  0110_0001  0x61   97  a  
  43	:  0110_1100  0x6C  108  l  
  44	:  0111_0100  0x74  116  t  
  45	:  0011_0010  0x32   50  2  
  46	:  0000_1101  0x0D   13    
  47	:  0110_0111  0x67  103  g  
  48	:  0110_1101  0x6D  109  m  
  49	:  0110_0001  0x61   97  a  
  50	:  0110_1001  0x69  105  i  
  51	:  0110_1100  0x6C  108  l  
  52	:  0010_1101  0x2D   45  -  
  53	:  0111_0011  0x73  115  s  
  54	:  0110_1101  0x6D  109  m  
  55	:  0111_0100  0x74  116  t  
  56	:  0111_0000  0x70  112  p  
  57	:  0010_1101  0x2D   45  -  
  58	:  0110_1001  0x69  105  i  
  59	:  0110_1110  0x6E  110  n  
  60	:  0000_0001  0x01    1    
  61	:  0110_1100  0x6C  108  l  
  62	:  0000_0110  0x06    6    
  63	:  0110_0111  0x67  103  g  
  64	:  0110_1111  0x6F  111  o  
  65	:  0110_1111  0x6F  111  o  
  66	:  0110_0111  0x67  103  g  
  67	:  0110_1100  0x6C  108  l  
  68	:  0110_0101  0x65  101  e  
  69	:  1100_0000  0xC0  192    
  70	:  0001_0010  0x12   18    
  71	:  1100_0000  0xC0  192    
  72	:  0000_1100  0x0C   12    
  73	:  0000_0000  0x00    0    
  74	:  0000_1111  0x0F   15    
  75	:  0000_0000  0x00    0    
  76	:  0000_0001  0x01    1    
  77	:  0000_0000  0x00    0    
  78	:  0000_0000  0x00    0    
  79	:  0000_1101  0x0D   13    
  80	:  1111_0101  0xF5  245    
  81	:  0000_0000  0x00    0    
  82	:  0000_1001  0x09    9    
  83	:  0000_0000  0x00    0    
  84	:  0001_1110  0x1E   30    
  85	:  0000_0100  0x04    4    
  86	:  0110_0001  0x61   97  a  
  87	:  0110_1100  0x6C  108  l  
  88	:  0111_0100  0x74  116  t  
  89	:  0011_0011  0x33   51  3  
  90	:  1100_0000  0xC0  192    
  91	:  0010_1110  0x2E   46  .  
  92	:  1100_0000  0xC0  192    
  93	:  0000_1100  0x0C   12    
  94	:  0000_0000  0x00    0    
  95	:  0000_1111  0x0F   15    
  96	:  0000_0000  0x00    0    
  97	:  0000_0001  0x01    1    
  98	:  0000_0000  0x00    0    
  99	:  0000_0000  0x00    0    
  100	:  0000_1101  0x0D   13    
  101	:  1111_0101  0xF5  245    
  102	:  0000_0000  0x00    0    
  103	:  0000_1001  0x09    9    
  104	:  0000_0000  0x00    0    
  105	:  0010_1000  0x28   40  (  
  106	:  0000_0100  0x04    4    
  107	:  0110_0001  0x61   97  a  
  108	:  0110_1100  0x6C  108  l  
  109	:  0111_0100  0x74  116  t  
  110	:  0011_0100  0x34   52  4  
  111	:  1100_0000  0xC0  192    
  112	:  0010_1110  0x2E   46  .  
  113	:  1100_0000  0xC0  192    
  114	:  0000_1100  0x0C   12    
  115	:  0000_0000  0x00    0    
  116	:  0000_1111  0x0F   15    
  117	:  0000_0000  0x00    0    
  118	:  0000_0001  0x01    1    
  119	:  0000_0000  0x00    0    
  120	:  0000_0000  0x00    0    
  121	:  0000_1101  0x0D   13    
  122	:  1111_0101  0xF5  245    
  123	:  0000_0000  0x00    0    
  124	:  0000_0100  0x04    4    
  125	:  0000_0000  0x00    0    
  126	:  0000_0101  0x05    5    
  127	:  1100_0000  0xC0  192    
  128	:  0010_1110  0x2E   46  .  
  129	:  1100_0000  0xC0  192    
  130	:  0000_1100  0x0C   12    
  131	:  0000_0000  0x00    0    
  132	:  0000_1111  0x0F   15    
  133	:  0000_0000  0x00    0    
  134	:  0000_0001  0x01    1    
  135	:  0000_0000  0x00    0    
  136	:  0000_0000  0x00    0    
  137	:  0000_1101  0x0D   13    
  138	:  1111_0101  0xF5  245    
  139	:  0000_0000  0x00    0    
  140	:  0000_1001  0x09    9    
  141	:  0000_0000  0x00    0    
  142	:  0000_1010  0x0A   10    
  143	:  0000_0100  0x04    4    
  144	:  0110_0001  0x61   97  a  
  145	:  0110_1100  0x6C  108  l  
  146	:  0111_0100  0x74  116  t  
  147	:  0011_0001  0x31   49  1  
  148	:  1100_0000  0xC0  192    
  149	:  0010_1110  0x2E   46  .  
  150	:  1100_0000  0xC0  192    
  151	:  0000_1100  0x0C   12    
  152	:  0000_0000  0x00    0    
  153	:  0000_0010  0x02    2    
  154	:  0000_0000  0x00    0    
  155	:  0000_0001  0x01    1    
  156	:  0000_0000  0x00    0    
  157	:  0000_0010  0x02    2    
  158	:  0111_0111  0x77  119  w  
  159	:  0001_0110  0x16   22    
  160	:  0000_0000  0x00    0    
  161	:  0000_0110  0x06    6    
  162	:  0000_0011  0x03    3    
  163	:  0110_1110  0x6E  110  n  
  164	:  0111_0011  0x73  115  s  
  165	:  0011_0001  0x31   49  1  
  166	:  1100_0000  0xC0  192    
  167	:  0011_1110  0x3E   62  >  
  168	:  1100_0000  0xC0  192    
  169	:  0000_1100  0x0C   12    
  170	:  0000_0000  0x00    0    
  171	:  0000_0010  0x02    2    
  172	:  0000_0000  0x00    0    
  173	:  0000_0001  0x01    1    
  174	:  0000_0000  0x00    0    
  175	:  0000_0010  0x02    2    
  176	:  0111_0111  0x77  119  w  
  177	:  0001_0110  0x16   22    
  178	:  0000_0000  0x00    0    
  179	:  0000_0110  0x06    6    
  180	:  0000_0011  0x03    3    
  181	:  0110_1110  0x6E  110  n  
  182	:  0111_0011  0x73  115  s  
  183	:  0011_0010  0x32   50  2  
  184	:  1100_0000  0xC0  192    
  185	:  0011_1110  0x3E   62  >  
  186	:  1100_0000  0xC0  192    
  187	:  0000_1100  0x0C   12    
  188	:  0000_0000  0x00    0    
  189	:  0000_0010  0x02    2    
  190	:  0000_0000  0x00    0    
  191	:  0000_0001  0x01    1    
  192	:  0000_0000  0x00    0    
  193	:  0000_0010  0x02    2    
  194	:  0111_0111  0x77  119  w  
  195	:  0001_0110  0x16   22    
  196	:  0000_0000  0x00    0    
  197	:  0000_0110  0x06    6    
  198	:  0000_0011  0x03    3    
  199	:  0110_1110  0x6E  110  n  
  200	:  0111_0011  0x73  115  s  
  201	:  0011_0100  0x34   52  4  
  202	:  1100_0000  0xC0  192    
  203	:  0011_1110  0x3E   62  >  
  204	:  1100_0000  0xC0  192    
  205	:  0000_1100  0x0C   12    
  206	:  0000_0000  0x00    0    
  207	:  0000_0010  0x02    2    
  208	:  0000_0000  0x00    0    
  209	:  0000_0001  0x01    1    
  210	:  0000_0000  0x00    0    
  211	:  0000_0010  0x02    2    
  212	:  0111_0111  0x77  119  w  
  213	:  0001_0110  0x16   22    
  214	:  0000_0000  0x00    0    
  215	:  0000_0110  0x06    6    
  216	:  0000_0011  0x03    3    
  217	:  0110_1110  0x6E  110  n  
  218	:  0111_0011  0x73  115  s  
  219	:  0011_0011  0x33   51  3  
  220	:  1100_0000  0xC0  192    
  221	:  0011_1110  0x3E   62  >  
  222	:  1100_0000  0xC0  192    
  223	:  1010_0010  0xA2  162    
  224	:  0000_0000  0x00    0    
  225	:  0000_0001  0x01    1    
  226	:  0000_0000  0x00    0    
  227	:  0000_0001  0x01    1    
  228	:  0000_0000  0x00    0    
  229	:  0000_0010  0x02    2    
  230	:  0111_0101  0x75  117  u  
  231	:  0000_0010  0x02    2    
  232	:  0000_0000  0x00    0    
  233	:  0000_0100  0x04    4    
  234	:  1101_1000  0xD8  216    
  235	:  1110_1111  0xEF  239    
  236	:  0010_0000  0x20   32     
  237	:  0000_1010  0x0A   10    
  238	:  1100_0000  0xC0  192    
  239	:  1011_0100  0xB4  180    
  240	:  0000_0000  0x00    0    
  241	:  0000_0001  0x01    1    
  242	:  0000_0000  0x00    0    
  243	:  0000_0001  0x01    1    
  244	:  0000_0000  0x00    0    
  245	:  0000_0010  0x02    2    
  246	:  0111_0101  0x75  117  u  
  247	:  0000_0010  0x02    2    
  248	:  0000_0000  0x00    0    
  249	:  0000_0100  0x04    4    
  250	:  1101_1000  0xD8  216    
  251	:  1110_1111  0xEF  239    
  252	:  0010_0010  0x22   34  "  
  253	:  0000_1010  0x0A   10    
  254	:  1100_0000  0xC0  192    
  255	:  1101_1000  0xD8  216    
  256	:  0000_0000  0x00    0    
  257	:  0000_0001  0x01    1    
  258	:  0000_0000  0x00    0    
  259	:  0000_0001  0x01    1    
  260	:  0000_0000  0x00    0    
  261	:  0000_0010  0x02    2    
  262	:  0111_0101  0x75  117  u  
  263	:  0000_0010  0x02    2    
  264	:  0000_0000  0x00    0    
  265	:  0000_0100  0x04    4    
  266	:  1101_1000  0xD8  216    
  267	:  1110_1111  0xEF  239    
  268	:  0010_0100  0x24   36  $  
  269	:  0000_1010  0x0A   10    
  270	:  1100_0000  0xC0  192    
  271	:  1100_0110  0xC6  198    
  272	:  0000_0000  0x00    0    
  273	:  0000_0001  0x01    1    
  274	:  0000_0000  0x00    0    
  275	:  0000_0001  0x01    1    
  276	:  0000_0000  0x00    0    
  277	:  0000_0010  0x02    2    
  278	:  0111_0101  0x75  117  u  
  279	:  0000_0010  0x02    2    
  280	:  0000_0000  0x00    0    
  281	:  0000_0100  0x04    4    
  282	:  1101_1000  0xD8  216    
  283	:  1110_1111  0xEF  239    
  284	:  0010_0110  0x26   38  &  
  285	:  0000_1010  0x0A   10    |;

# ; <<>> dig.pl 1.10 <<>> -d -t mx gmail.com
# ;;
# ;; Got answer.
# ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18033
# ;; flags: qr rd ra; QUERY: 1, ANSWER: 5, AUTHORITY: 4, ADDITIONAL: 4
# 
# ;; QUESTION SECTION:
# ;gmail.com.		IN	MX
# 
# ;; ANSWER SECTION:
# gmail.com.	3573	IN	MX	20 alt2.gmail-smtp-in.l.google.com. 
# gmail.com.	3573	IN	MX	30 alt3.gmail-smtp-in.l.google.com. 
# gmail.com.	3573	IN	MX	40 alt4.gmail-smtp-in.l.google.com. 
# gmail.com.	3573	IN	MX	5 gmail-smtp-in.l.google.com. 
# gmail.com.	3573	IN	MX	10 alt1.gmail-smtp-in.l.google.com. 
# 
# ;; AUTHORITY SECTION:
# gmail.com.	161558	IN	NS	ns1.google.com. 
# gmail.com.	161558	IN	NS	ns2.google.com. 
# gmail.com.	161558	IN	NS	ns4.google.com. 
# gmail.com.	161558	IN	NS	ns3.google.com. 
# 
# ;; ADDITIONAL SECTION:
# ns1.google.com.	161026	IN	A	216.239.32.10 
# ns2.google.com.	161026	IN	A	216.239.34.10 
# ns3.google.com.	161026	IN	A	216.239.36.10 
# ns4.google.com.	161026	IN	A	216.239.38.10 
# 
# ;; Query time: 68 ms
# ;; SERVER: 192.168.1.171# 53(192.168.1.171)
# ;; WHEN: Mon Oct  3 13:49:52 2011
# ;; MSG SIZE rcvd: 286 -- XFR size: 14 records
# 

$ap = makebuf(\$ans2);
$qp = makebuf(\$ques2);

## test 7	check server failure
$dig = new Net::DNS::Dig( PeerAddr => ['3.4.5.6', '5.6.7.8']);
$rp = $dig->_proc_body($ap,$qp,$get,$put,\$soacount);
#print_head($rp);
#print "\n";
#print_head($qp);
chk_exp($rp,\$ans2);

## test 8	check object contents
$exp = q|146	= {
	'ADDITIONAL'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'ns1.google.com',
		'RDATA'	=> ['Шп 
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 161026,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'ns2.google.com',
		'RDATA'	=> ['Шп"
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 161026,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'ns3.google.com',
		'RDATA'	=> ['Шп$
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 161026,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'ns4.google.com',
		'RDATA'	=> ['Шп&
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 161026,
		'TYPE'	=> 1,
	},
],
	'ANSWER'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> [20,'alt2.gmail-smtp-in.l.google.com',],
		'RDLEN'	=> 32,
		'TTL'	=> 3573,
		'TYPE'	=> 15,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> [30,'alt3.gmail-smtp-in.l.google.com',],
		'RDLEN'	=> 9,
		'TTL'	=> 3573,
		'TYPE'	=> 15,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> [40,'alt4.gmail-smtp-in.l.google.com',],
		'RDLEN'	=> 9,
		'TTL'	=> 3573,
		'TYPE'	=> 15,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> [5,'gmail-smtp-in.l.google.com',],
		'RDLEN'	=> 4,
		'TTL'	=> 3573,
		'TYPE'	=> 15,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> [10,'alt1.gmail-smtp-in.l.google.com',],
		'RDLEN'	=> 9,
		'TTL'	=> 3573,
		'TYPE'	=> 15,
	},
],
	'AUTHORITY'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> ['ns1.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 161558,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> ['ns2.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 161558,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> ['ns4.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 161558,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> ['ns3.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 161558,
		'TYPE'	=> 2,
	},
],
	'BYTES'	=> 286,
	'Class'	=> 'IN',
	'HEADER'	=> {
		'AA'	=> 0,
		'AD'	=> 0,
		'ANCOUNT'	=> 5,
		'ARCOUNT'	=> 4,
		'CD'	=> 0,
		'ID'	=> 18033,
		'MBZ'	=> 0,
		'NSCOUNT'	=> 4,
		'OPCODE'	=> 0,
		'QDCOUNT'	=> 1,
		'QR'	=> 1,
		'RA'	=> 1,
		'RCODE'	=> 0,
		'RD'	=> 1,
		'TC'	=> 0,
	},
	'NRECS'	=> 14,
	'PeerAddr'	=> ['3.4.5.6','5.6.7.8',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'QUESTION'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'TYPE'	=> 15,
	},
],
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'_SS'	=> {
		'3.4.5.6'	=> '',
		'5.6.7.8'	=> '',
	},
};
|;

#print MyTest::Dumper($dig);
$got = MyTest::Dumper($dig);
print "proc_body failed\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 9	check that soacount is untouched
print "soacount incremented, got $soacount, exp 0\nnot "
	unless $soacount == 0;
&ok;

## test 10	build text object
$dig->{ELAPSED} = 56;
$dig->{SERVER} = '1.2.3.4';
$dig->{PeerAddr} = ['1.2.3.4'];
$dig->{_SS} = { '1.2.3.4', inet_aton('1.2.3.4') };
$tobj = $dig->to_text();
$exp = q|147	= {
	'ADDITIONAL'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns1.google.com.',
		'RDATA'	=> ['216.239.32.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 161026,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns2.google.com.',
		'RDATA'	=> ['216.239.34.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 161026,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns3.google.com.',
		'RDATA'	=> ['216.239.36.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 161026,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns4.google.com.',
		'RDATA'	=> ['216.239.38.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 161026,
		'TYPE'	=> 'A',
	},
],
	'ANSWER'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> [20,'alt2.gmail-smtp-in.l.google.com.',],
		'RDLEN'	=> 32,
		'TTL'	=> 3573,
		'TYPE'	=> 'MX',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> [30,'alt3.gmail-smtp-in.l.google.com.',],
		'RDLEN'	=> 9,
		'TTL'	=> 3573,
		'TYPE'	=> 'MX',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> [40,'alt4.gmail-smtp-in.l.google.com.',],
		'RDLEN'	=> 9,
		'TTL'	=> 3573,
		'TYPE'	=> 'MX',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> [5,'gmail-smtp-in.l.google.com.',],
		'RDLEN'	=> 4,
		'TTL'	=> 3573,
		'TYPE'	=> 'MX',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> [10,'alt1.gmail-smtp-in.l.google.com.',],
		'RDLEN'	=> 9,
		'TTL'	=> 3573,
		'TYPE'	=> 'MX',
	},
],
	'AUTHORITY'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> ['ns1.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 161558,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> ['ns2.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 161558,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> ['ns4.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 161558,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> ['ns3.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 161558,
		'TYPE'	=> 'NS',
	},
],
	'BYTES'	=> 286,
	'Class'	=> 'IN',
	'ELAPSED'	=> 56,
	'HEADER'	=> {
		'AA'	=> 0,
		'AD'	=> 0,
		'ANCOUNT'	=> 5,
		'ARCOUNT'	=> 4,
		'CD'	=> 0,
		'ID'	=> 18033,
		'MBZ'	=> 0,
		'NSCOUNT'	=> 4,
		'OPCODE'	=> 'QUERY',
		'QDCOUNT'	=> 1,
		'QR'	=> 1,
		'RA'	=> 1,
		'RCODE'	=> 'NOERROR',
		'RD'	=> 1,
		'TC'	=> 0,
	},
	'NRECS'	=> 14,
	'PeerAddr'	=> ['1.2.3.4',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'QUESTION'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'TYPE'	=> 'MX',
	},
],
	'Recursion'	=> 256,
	'SERVER'	=> '1.2.3.4',
	'TEXT'	=> '
; <<>> Net::DNS::Dig 0.01 <<>> -t mx gmail.com.
;;
;; Got answer.
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18033
;; flags: qr rd ra; QUERY: 1, ANSWER: 5, AUTHORITY: 4, ADDITIONAL: 4

;; QUESTION SECTION:
;gmail.com.		IN	MX

;; ANSWER SECTION:
gmail.com.	3573	IN	MX	 20 alt2.gmail-smtp-in.l.google.com.
gmail.com.	3573	IN	MX	 30 alt3.gmail-smtp-in.l.google.com.
gmail.com.	3573	IN	MX	 40 alt4.gmail-smtp-in.l.google.com.
gmail.com.	3573	IN	MX	 5 gmail-smtp-in.l.google.com.
gmail.com.	3573	IN	MX	 10 alt1.gmail-smtp-in.l.google.com.

;; AUTHORITY SECTION:
gmail.com.	161558	IN	NS	 ns1.google.com.
gmail.com.	161558	IN	NS	 ns2.google.com.
gmail.com.	161558	IN	NS	 ns4.google.com.
gmail.com.	161558	IN	NS	 ns3.google.com.

;; ADDITIONAL SECTION:
ns1.google.com.	161026	IN	A	 216.239.32.10
ns2.google.com.	161026	IN	A	 216.239.34.10
ns3.google.com.	161026	IN	A	 216.239.36.10
ns4.google.com.	161026	IN	A	 216.239.38.10

;; Query time: 56 ms
;; SERVER: 1.2.3.4# 53(1.2.3.4)
;; WHEN: Mon Oct  3 13:41:57 2011
;; MSG SIZE rcvd: 286 -- XFR size: 14 records
',
	'Timeout'	=> 15,
	'_SS'	=> {
		'1.2.3.4'	=> '',
	},
};
|;
$got = MyTest::Dumper($tobj);
print "to_text conversion failed\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 11	check that soacount did not increment
print "unexpected soacount increment\nnot "
	if $soacount;
&ok;

my $ques3 = q
| 0	:  0100_1011  0x4B   75  K  
  1	:  1010_0010  0xA2  162    
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
  12	:  0000_0101  0x05    5    
  13	:  0110_0111  0x67  103  g  
  14	:  0110_1101  0x6D  109  m  
  15	:  0110_0001  0x61   97  a  
  16	:  0110_1001  0x69  105  i  
  17	:  0110_1100  0x6C  108  l  
  18	:  0000_0011  0x03    3    
  19	:  0110_0011  0x63   99  c  
  20	:  0110_1111  0x6F  111  o  
  21	:  0110_1101  0x6D  109  m  
  22	:  0000_0000  0x00    0    
  23	:  0000_0000  0x00    0    
  24	:  0000_1111  0x0F   15    
  25	:  0000_0000  0x00    0    
  26	:  0000_0001  0x01    1    |;

my $ans3 = q
| 0	:  0100_1011  0x4B   75  K  
  1	:  1010_0010  0xA2  162    
  2	:  1000_0001  0x81  129    
  3	:  1000_0000  0x80  128    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0101  0x05    5    
  8	:  0000_0000  0x00    0    
  9	:  0000_0100  0x04    4    
  10	:  0000_0000  0x00    0    
  11	:  0000_0100  0x04    4    
  12	:  0000_0101  0x05    5    
  13	:  0110_0111  0x67  103  g  
  14	:  0110_1101  0x6D  109  m  
  15	:  0110_0001  0x61   97  a  
  16	:  0110_1001  0x69  105  i  
  17	:  0110_1100  0x6C  108  l  
  18	:  0000_0011  0x03    3    
  19	:  0110_0011  0x63   99  c  
  20	:  0110_1111  0x6F  111  o  
  21	:  0110_1101  0x6D  109  m  
  22	:  0000_0000  0x00    0    
  23	:  0000_0000  0x00    0    
  24	:  0000_1111  0x0F   15    
  25	:  0000_0000  0x00    0    
  26	:  0000_0001  0x01    1    
  27	:  1100_0000  0xC0  192    
  28	:  0000_1100  0x0C   12    
  29	:  0000_0000  0x00    0    
  30	:  0000_1111  0x0F   15    
  31	:  0000_0000  0x00    0    
  32	:  0000_0001  0x01    1    
  33	:  0000_0000  0x00    0    
  34	:  0000_0000  0x00    0    
  35	:  0000_0101  0x05    5    
  36	:  1101_1000  0xD8  216    
  37	:  0000_0000  0x00    0    
  38	:  0001_1011  0x1B   27    
  39	:  0000_0000  0x00    0    
  40	:  0000_0101  0x05    5    
  41	:  0000_1101  0x0D   13    
  42	:  0110_0111  0x67  103  g  
  43	:  0110_1101  0x6D  109  m  
  44	:  0110_0001  0x61   97  a  
  45	:  0110_1001  0x69  105  i  
  46	:  0110_1100  0x6C  108  l  
  47	:  0010_1101  0x2D   45  -  
  48	:  0111_0011  0x73  115  s  
  49	:  0110_1101  0x6D  109  m  
  50	:  0111_0100  0x74  116  t  
  51	:  0111_0000  0x70  112  p  
  52	:  0010_1101  0x2D   45  -  
  53	:  0110_1001  0x69  105  i  
  54	:  0110_1110  0x6E  110  n  
  55	:  0000_0001  0x01    1    
  56	:  0110_1100  0x6C  108  l  
  57	:  0000_0110  0x06    6    
  58	:  0110_0111  0x67  103  g  
  59	:  0110_1111  0x6F  111  o  
  60	:  0110_1111  0x6F  111  o  
  61	:  0110_0111  0x67  103  g  
  62	:  0110_1100  0x6C  108  l  
  63	:  0110_0101  0x65  101  e  
  64	:  1100_0000  0xC0  192    
  65	:  0001_0010  0x12   18    
  66	:  1100_0000  0xC0  192    
  67	:  0000_1100  0x0C   12    
  68	:  0000_0000  0x00    0    
  69	:  0000_1111  0x0F   15    
  70	:  0000_0000  0x00    0    
  71	:  0000_0001  0x01    1    
  72	:  0000_0000  0x00    0    
  73	:  0000_0000  0x00    0    
  74	:  0000_0101  0x05    5    
  75	:  1101_1000  0xD8  216    
  76	:  0000_0000  0x00    0    
  77	:  0000_1001  0x09    9    
  78	:  0000_0000  0x00    0    
  79	:  0000_1010  0x0A   10    
  80	:  0000_0100  0x04    4    
  81	:  0110_0001  0x61   97  a  
  82	:  0110_1100  0x6C  108  l  
  83	:  0111_0100  0x74  116  t  
  84	:  0011_0001  0x31   49  1  
  85	:  1100_0000  0xC0  192    
  86	:  0010_1001  0x29   41  )  
  87	:  1100_0000  0xC0  192    
  88	:  0000_1100  0x0C   12    
  89	:  0000_0000  0x00    0    
  90	:  0000_1111  0x0F   15    
  91	:  0000_0000  0x00    0    
  92	:  0000_0001  0x01    1    
  93	:  0000_0000  0x00    0    
  94	:  0000_0000  0x00    0    
  95	:  0000_0101  0x05    5    
  96	:  1101_1000  0xD8  216    
  97	:  0000_0000  0x00    0    
  98	:  0000_1001  0x09    9    
  99	:  0000_0000  0x00    0    
  100	:  0001_0100  0x14   20    
  101	:  0000_0100  0x04    4    
  102	:  0110_0001  0x61   97  a  
  103	:  0110_1100  0x6C  108  l  
  104	:  0111_0100  0x74  116  t  
  105	:  0011_0010  0x32   50  2  
  106	:  1100_0000  0xC0  192    
  107	:  0010_1001  0x29   41  )  
  108	:  1100_0000  0xC0  192    
  109	:  0000_1100  0x0C   12    
  110	:  0000_0000  0x00    0    
  111	:  0000_1111  0x0F   15    
  112	:  0000_0000  0x00    0    
  113	:  0000_0001  0x01    1    
  114	:  0000_0000  0x00    0    
  115	:  0000_0000  0x00    0    
  116	:  0000_0101  0x05    5    
  117	:  1101_1000  0xD8  216    
  118	:  0000_0000  0x00    0    
  119	:  0000_1001  0x09    9    
  120	:  0000_0000  0x00    0    
  121	:  0001_1110  0x1E   30    
  122	:  0000_0100  0x04    4    
  123	:  0110_0001  0x61   97  a  
  124	:  0110_1100  0x6C  108  l  
  125	:  0111_0100  0x74  116  t  
  126	:  0011_0011  0x33   51  3  
  127	:  1100_0000  0xC0  192    
  128	:  0010_1001  0x29   41  )  
  129	:  1100_0000  0xC0  192    
  130	:  0000_1100  0x0C   12    
  131	:  0000_0000  0x00    0    
  132	:  0000_1111  0x0F   15    
  133	:  0000_0000  0x00    0    
  134	:  0000_0001  0x01    1    
  135	:  0000_0000  0x00    0    
  136	:  0000_0000  0x00    0    
  137	:  0000_0101  0x05    5    
  138	:  1101_1000  0xD8  216    
  139	:  0000_0000  0x00    0    
  140	:  0000_1001  0x09    9    
  141	:  0000_0000  0x00    0    
  142	:  0010_1000  0x28   40  (  
  143	:  0000_0100  0x04    4    
  144	:  0110_0001  0x61   97  a  
  145	:  0110_1100  0x6C  108  l  
  146	:  0111_0100  0x74  116  t  
  147	:  0011_0100  0x34   52  4  
  148	:  1100_0000  0xC0  192    
  149	:  0010_1001  0x29   41  )  
  150	:  1100_0000  0xC0  192    
  151	:  0000_1100  0x0C   12    
  152	:  0000_0000  0x00    0    
  153	:  0000_0010  0x02    2    
  154	:  0000_0000  0x00    0    
  155	:  0000_0001  0x01    1    
  156	:  0000_0000  0x00    0    
  157	:  0000_0010  0x02    2    
  158	:  0001_0000  0x10   16    
  159	:  0001_1011  0x1B   27    
  160	:  0000_0000  0x00    0    
  161	:  0000_0110  0x06    6    
  162	:  0000_0011  0x03    3    
  163	:  0110_1110  0x6E  110  n  
  164	:  0111_0011  0x73  115  s  
  165	:  0011_0010  0x32   50  2  
  166	:  1100_0000  0xC0  192    
  167	:  0011_1001  0x39   57  9  
  168	:  1100_0000  0xC0  192    
  169	:  0000_1100  0x0C   12    
  170	:  0000_0000  0x00    0    
  171	:  0000_0010  0x02    2    
  172	:  0000_0000  0x00    0    
  173	:  0000_0001  0x01    1    
  174	:  0000_0000  0x00    0    
  175	:  0000_0010  0x02    2    
  176	:  0001_0000  0x10   16    
  177	:  0001_1011  0x1B   27    
  178	:  0000_0000  0x00    0    
  179	:  0000_0110  0x06    6    
  180	:  0000_0011  0x03    3    
  181	:  0110_1110  0x6E  110  n  
  182	:  0111_0011  0x73  115  s  
  183	:  0011_0001  0x31   49  1  
  184	:  1100_0000  0xC0  192    
  185	:  0011_1001  0x39   57  9  
  186	:  1100_0000  0xC0  192    
  187	:  0000_1100  0x0C   12    
  188	:  0000_0000  0x00    0    
  189	:  0000_0010  0x02    2    
  190	:  0000_0000  0x00    0    
  191	:  0000_0001  0x01    1    
  192	:  0000_0000  0x00    0    
  193	:  0000_0010  0x02    2    
  194	:  0001_0000  0x10   16    
  195	:  0001_1011  0x1B   27    
  196	:  0000_0000  0x00    0    
  197	:  0000_0110  0x06    6    
  198	:  0000_0011  0x03    3    
  199	:  0110_1110  0x6E  110  n  
  200	:  0111_0011  0x73  115  s  
  201	:  0011_0011  0x33   51  3  
  202	:  1100_0000  0xC0  192    
  203	:  0011_1001  0x39   57  9  
  204	:  1100_0000  0xC0  192    
  205	:  0000_1100  0x0C   12    
  206	:  0000_0000  0x00    0    
  207	:  0000_0010  0x02    2    
  208	:  0000_0000  0x00    0    
  209	:  0000_0001  0x01    1    
  210	:  0000_0000  0x00    0    
  211	:  0000_0010  0x02    2    
  212	:  0001_0000  0x10   16    
  213	:  0001_1011  0x1B   27    
  214	:  0000_0000  0x00    0    
  215	:  0000_0110  0x06    6    
  216	:  0000_0011  0x03    3    
  217	:  0110_1110  0x6E  110  n  
  218	:  0111_0011  0x73  115  s  
  219	:  0011_0100  0x34   52  4  
  220	:  1100_0000  0xC0  192    
  221	:  0011_1001  0x39   57  9  
  222	:  1100_0000  0xC0  192    
  223	:  1011_0100  0xB4  180    
  224	:  0000_0000  0x00    0    
  225	:  0000_0001  0x01    1    
  226	:  0000_0000  0x00    0    
  227	:  0000_0001  0x01    1    
  228	:  0000_0000  0x00    0    
  229	:  0000_0010  0x02    2    
  230	:  0000_1110  0x0E   14    
  231	:  0000_0111  0x07    7    
  232	:  0000_0000  0x00    0    
  233	:  0000_0100  0x04    4    
  234	:  1101_1000  0xD8  216    
  235	:  1110_1111  0xEF  239    
  236	:  0010_0000  0x20   32     
  237	:  0000_1010  0x0A   10    
  238	:  1100_0000  0xC0  192    
  239	:  1010_0010  0xA2  162    
  240	:  0000_0000  0x00    0    
  241	:  0000_0001  0x01    1    
  242	:  0000_0000  0x00    0    
  243	:  0000_0001  0x01    1    
  244	:  0000_0000  0x00    0    
  245	:  0000_0010  0x02    2    
  246	:  0000_1110  0x0E   14    
  247	:  0000_0111  0x07    7    
  248	:  0000_0000  0x00    0    
  249	:  0000_0100  0x04    4    
  250	:  1101_1000  0xD8  216    
  251	:  1110_1111  0xEF  239    
  252	:  0010_0010  0x22   34  "  
  253	:  0000_1010  0x0A   10    
  254	:  1100_0000  0xC0  192    
  255	:  1100_0110  0xC6  198    
  256	:  0000_0000  0x00    0    
  257	:  0000_0001  0x01    1    
  258	:  0000_0000  0x00    0    
  259	:  0000_0001  0x01    1    
  260	:  0000_0000  0x00    0    
  261	:  0000_0010  0x02    2    
  262	:  0000_1110  0x0E   14    
  263	:  0000_0111  0x07    7    
  264	:  0000_0000  0x00    0    
  265	:  0000_0100  0x04    4    
  266	:  1101_1000  0xD8  216    
  267	:  1110_1111  0xEF  239    
  268	:  0010_0100  0x24   36  $  
  269	:  0000_1010  0x0A   10    
  270	:  1100_0000  0xC0  192    
  271	:  1101_1000  0xD8  216    
  272	:  0000_0000  0x00    0    
  273	:  0000_0001  0x01    1    
  274	:  0000_0000  0x00    0    
  275	:  0000_0001  0x01    1    
  276	:  0000_0000  0x00    0    
  277	:  0000_0010  0x02    2    
  278	:  0000_1110  0x0E   14    
  279	:  0000_0111  0x07    7    
  280	:  0000_0000  0x00    0    
  281	:  0000_0100  0x04    4    
  282	:  1101_1000  0xD8  216    
  283	:  1110_1111  0xEF  239    
  284	:  0010_0110  0x26   38  &  
  285	:  0000_1010  0x0A   10    |;

# ; <<>> dig.pl 1.10 <<>> -d -t mx gmail.com
# ;;
# ;; Got answer.
# ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 19362
# ;; flags: qr rd ra; QUERY: 1, ANSWER: 5, AUTHORITY: 4, ADDITIONAL: 4
# 
# ;; QUESTION SECTION:
# ;gmail.com.		IN	MX
# 
# ;; ANSWER SECTION:
# gmail.com.	1496	IN	MX	5 gmail-smtp-in.l.google.com. 
# gmail.com.	1496	IN	MX	10 alt1.gmail-smtp-in.l.google.com. 
# gmail.com.	1496	IN	MX	20 alt2.gmail-smtp-in.l.google.com. 
# gmail.com.	1496	IN	MX	30 alt3.gmail-smtp-in.l.google.com. 
# gmail.com.	1496	IN	MX	40 alt4.gmail-smtp-in.l.google.com. 
# 
# ;; AUTHORITY SECTION:
# gmail.com.	135195	IN	NS	ns2.google.com. 
# gmail.com.	135195	IN	NS	ns1.google.com. 
# gmail.com.	135195	IN	NS	ns3.google.com. 
# gmail.com.	135195	IN	NS	ns4.google.com. 
# 
# ;; ADDITIONAL SECTION:
# ns1.google.com.	134663	IN	A	216.239.32.10 
# ns2.google.com.	134663	IN	A	216.239.34.10 
# ns3.google.com.	134663	IN	A	216.239.36.10 
# ns4.google.com.	134663	IN	A	216.239.38.10 
# 
# ;; Query time: 59 ms
# ;; SERVER: 192.168.1.171# 53(192.168.1.171)
# ;; WHEN: Mon Oct  3 21:09:15 2011
# ;; MSG SIZE rcvd: 286 -- XFR size: 14 records
# 


$ap = makebuf(\$ans3);
$qp = makebuf(\$ques3);

## test 12	check server failure
$dig = new Net::DNS::Dig( PeerAddr => ['3.4.5.6','5.6.7.8'] );
$dig->{_SS} = {
	'3.4.5.6'	=> inet_aton('3.4.5.6'),
	'5.6.7.8'	=> inet_aton('5.6.7.8')
};
$dig->{SERVER} = '5.6.7.8';
$rp = $dig->_proc_body($ap,$qp,$get,$put,\$soacount);
#print_head($rp);
#print "\n";
#print_head($qp);
chk_exp($rp,\$ans3);

## test 13	check object contents
$exp = q|147	= {
	'ADDITIONAL'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'ns1.google.com',
		'RDATA'	=> ['Шп 
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 134663,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'ns2.google.com',
		'RDATA'	=> ['Шп"
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 134663,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'ns3.google.com',
		'RDATA'	=> ['Шп$
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 134663,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'ns4.google.com',
		'RDATA'	=> ['Шп&
	',],
		'RDLEN'	=> 4,
		'TTL'	=> 134663,
		'TYPE'	=> 1,
	},
],
	'ANSWER'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> [5,'gmail-smtp-in.l.google.com',],
		'RDLEN'	=> 27,
		'TTL'	=> 1496,
		'TYPE'	=> 15,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> [10,'alt1.gmail-smtp-in.l.google.com',],
		'RDLEN'	=> 9,
		'TTL'	=> 1496,
		'TYPE'	=> 15,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> [20,'alt2.gmail-smtp-in.l.google.com',],
		'RDLEN'	=> 9,
		'TTL'	=> 1496,
		'TYPE'	=> 15,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> [30,'alt3.gmail-smtp-in.l.google.com',],
		'RDLEN'	=> 9,
		'TTL'	=> 1496,
		'TYPE'	=> 15,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> [40,'alt4.gmail-smtp-in.l.google.com',],
		'RDLEN'	=> 9,
		'TTL'	=> 1496,
		'TYPE'	=> 15,
	},
],
	'AUTHORITY'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> ['ns2.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 135195,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> ['ns1.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 135195,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> ['ns3.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 135195,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'RDATA'	=> ['ns4.google.com',],
		'RDLEN'	=> 6,
		'TTL'	=> 135195,
		'TYPE'	=> 2,
	},
],
	'BYTES'	=> 286,
	'Class'	=> 'IN',
	'HEADER'	=> {
		'AA'	=> 0,
		'AD'	=> 0,
		'ANCOUNT'	=> 5,
		'ARCOUNT'	=> 4,
		'CD'	=> 0,
		'ID'	=> 19362,
		'MBZ'	=> 0,
		'NSCOUNT'	=> 4,
		'OPCODE'	=> 0,
		'QDCOUNT'	=> 1,
		'QR'	=> 1,
		'RA'	=> 1,
		'RCODE'	=> 0,
		'RD'	=> 1,
		'TC'	=> 0,
	},
	'NRECS'	=> 14,
	'PeerAddr'	=> ['3.4.5.6','5.6.7.8',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'QUESTION'	=> [{
		'CLASS'	=> 1,
		'NAME'	=> 'gmail.com',
		'TYPE'	=> 15,
	},
],
	'Recursion'	=> 256,
	'SERVER'	=> '5.6.7.8',
	'Timeout'	=> 15,
	'_SS'	=> {
		'3.4.5.6'	=> '',
		'5.6.7.8'	=> '',
	},
};
|;

#print MyTest::Dumper($dig);
$got = MyTest::Dumper($dig);
print "proc_body failed\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 14	check that soacount is untouched
print "soacount incremented, got $soacount, exp 0\nnot "
	unless $soacount == 0;
&ok;

## test 15	build text object
$dig->{ELAPSED} = 56;
$dig->{SERVER} = 'my.test.domain.com';
$dig->{PeerAddr} = ['1.2.3.4'];
$dig->{_SS} = { 'my.test.domain.com' => inet_aton('1.2.3.4') };
$tobj = $dig->to_text();
$exp = q|147	= {
	'ADDITIONAL'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns1.google.com.',
		'RDATA'	=> ['216.239.32.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 134663,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns2.google.com.',
		'RDATA'	=> ['216.239.34.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 134663,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns3.google.com.',
		'RDATA'	=> ['216.239.36.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 134663,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'ns4.google.com.',
		'RDATA'	=> ['216.239.38.10',],
		'RDLEN'	=> 4,
		'TTL'	=> 134663,
		'TYPE'	=> 'A',
	},
],
	'ANSWER'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> [5,'gmail-smtp-in.l.google.com.',],
		'RDLEN'	=> 27,
		'TTL'	=> 1496,
		'TYPE'	=> 'MX',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> [10,'alt1.gmail-smtp-in.l.google.com.',],
		'RDLEN'	=> 9,
		'TTL'	=> 1496,
		'TYPE'	=> 'MX',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> [20,'alt2.gmail-smtp-in.l.google.com.',],
		'RDLEN'	=> 9,
		'TTL'	=> 1496,
		'TYPE'	=> 'MX',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> [30,'alt3.gmail-smtp-in.l.google.com.',],
		'RDLEN'	=> 9,
		'TTL'	=> 1496,
		'TYPE'	=> 'MX',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> [40,'alt4.gmail-smtp-in.l.google.com.',],
		'RDLEN'	=> 9,
		'TTL'	=> 1496,
		'TYPE'	=> 'MX',
	},
],
	'AUTHORITY'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> ['ns2.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 135195,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> ['ns1.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 135195,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> ['ns3.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 135195,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'RDATA'	=> ['ns4.google.com.',],
		'RDLEN'	=> 6,
		'TTL'	=> 135195,
		'TYPE'	=> 'NS',
	},
],
	'BYTES'	=> 286,
	'Class'	=> 'IN',
	'ELAPSED'	=> 56,
	'HEADER'	=> {
		'AA'	=> 0,
		'AD'	=> 0,
		'ANCOUNT'	=> 5,
		'ARCOUNT'	=> 4,
		'CD'	=> 0,
		'ID'	=> 19362,
		'MBZ'	=> 0,
		'NSCOUNT'	=> 4,
		'OPCODE'	=> 'QUERY',
		'QDCOUNT'	=> 1,
		'QR'	=> 1,
		'RA'	=> 1,
		'RCODE'	=> 'NOERROR',
		'RD'	=> 1,
		'TC'	=> 0,
	},
	'NRECS'	=> 14,
	'PeerAddr'	=> ['1.2.3.4',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'QUESTION'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'gmail.com.',
		'TYPE'	=> 'MX',
	},
],
	'Recursion'	=> 256,
	'SERVER'	=> 'my.test.domain.com',
	'TEXT'	=> '
; <<>> Net::DNS::Dig 0.01 <<>> -t mx gmail.com.
;;
;; Got answer.
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 19362
;; flags: qr rd ra; QUERY: 1, ANSWER: 5, AUTHORITY: 4, ADDITIONAL: 4

;; QUESTION SECTION:
;gmail.com.		IN	MX

;; ANSWER SECTION:
gmail.com.	1496	IN	MX	 5 gmail-smtp-in.l.google.com.
gmail.com.	1496	IN	MX	 10 alt1.gmail-smtp-in.l.google.com.
gmail.com.	1496	IN	MX	 20 alt2.gmail-smtp-in.l.google.com.
gmail.com.	1496	IN	MX	 30 alt3.gmail-smtp-in.l.google.com.
gmail.com.	1496	IN	MX	 40 alt4.gmail-smtp-in.l.google.com.

;; AUTHORITY SECTION:
gmail.com.	135195	IN	NS	 ns2.google.com.
gmail.com.	135195	IN	NS	 ns1.google.com.
gmail.com.	135195	IN	NS	 ns3.google.com.
gmail.com.	135195	IN	NS	 ns4.google.com.

;; ADDITIONAL SECTION:
ns1.google.com.	134663	IN	A	 216.239.32.10
ns2.google.com.	134663	IN	A	 216.239.34.10
ns3.google.com.	134663	IN	A	 216.239.36.10
ns4.google.com.	134663	IN	A	 216.239.38.10

;; Query time: 56 ms
;; SERVER: 1.2.3.4# 53(my.test.domain.com)
;; WHEN: Mon Oct  3 13:41:57 2011
;; MSG SIZE rcvd: 286 -- XFR size: 14 records
',
	'Timeout'	=> 15,
	'_SS'	=> {
		'my.test.domain.com'	=> '',
	},
};
|;
$got = MyTest::Dumper($tobj);
print "to_text conversion failed\ngot: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 16	check that soacount did not increment
print "unexpected soacount increment\nnot "
	if $soacount;
&ok;
