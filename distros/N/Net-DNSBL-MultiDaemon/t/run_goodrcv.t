# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..47\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNSBL::MultiDaemon qw(
	:debug
	run
);
use Net::DNSBL::Utilities qw(
	write_stats
	statinit
	cntinit
        open_udpNB
	DO
);
use Socket;
use POSIX qw(EWOULDBLOCK);
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	newhead
	gethead
	get1char
);
use Net::DNS::ToolKit::RR;
use Net::DNS::ToolKit::Debug qw(
	print_head
	print_buf
);

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

umask 027;
foreach my $dir (qw(tmp)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;       # remove files of this name as well
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

my $dir = './tmp';
mkdir $dir,0755;

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
 
sub chk_exp {
  my($bp,$exp) = @_;
  my $todo = '';
  my @expect = expect($$exp);
  foreach(0..length($$bp) -1) {
    $char = get1char($bp,$_);
    next if $char == $expect[$_];
    print "buffer mismatch $_, got: $char, exp: $expect[$_]\nnot ";
    $todo = 'fix test for marginal dn_comp resolver implementations';
    last;
  }
  &ok($todo);
}

my $config = './local/test.conf';
my $sfile = $dir .'/stats.tst';

my $FATans = Net::DNSBL::MultiDaemon::fatreturn();

sub fixfat {
  ${$_[0]} =~ s|  11	:  0000_0011  0x03    3    |  11	:  0000_0001  0x01    1    |
	unless $FATans;
}

## test 2-3	suck in and check config file for domain1.com domain2.net

my $DNSBLS = DO($config);
print "could not open configuration file $config\nnot "
	unless $DNSBLS;
&ok;

print "missing configuration file variables domain1.com, domain2.net\nnot "
	unless exists $DNSBLS->{'domain1.com'} && exists $DNSBLS->{'domain2.net'};
&ok;

## test 4	init STATS
my %STATS;
cntinit($DNSBLS,\%STATS);
print "got: $_, exp: 5, bad key count\nnot "
        unless ($_ = keys %STATS) == 5;
&ok;

my $statime = statinit($sfile,\%STATS);	# set stat init time

## test 5	open a listening socket
my $L = open_udpNB;
print "could not open local unbound socket\nnot "
	unless $L;
&ok;

## test 6	bind a listner for testing
my $port;
foreach(10000..10100) {		# find a port to bind to
  if (bind($L,sockaddr_in($_,INADDR_ANY))) {
    $port = $_;
    last;
  }
}
print "could not bind a port for remote\nnot "
	unless $port;
&ok;

my $L_sin = sockaddr_in($port,inet_aton('127.0.0.1'));

## test 7	open a sending socket

my $R = open_udpNB;
print "could not open unbound send socket\nnot "
	unless $R;
&ok;

## test 8	open a socket for test
my $T1 = open_udpNB;
print "could not open local unbound socket\nnot "
	unless $T1;
&ok;

## test 9	bind a listner for testing
my $t1port;
foreach(($port +1)..($port +100)) {		# find a port to bind to
  if (bind($T1,sockaddr_in($_,INADDR_ANY))) {
    $t1port = $_;
    last;
  }
}
print "could not bind a port for testing\nnot "
	unless $t1port;
&ok;

## test 10	open a test socket for sending
my $T2 = open_udpNB;
print "could not open local unbound socket\nnot "
	unless $T2;
&ok;

my($get,$put,$parse) = new Net::DNS::ToolKit::RR;
my $msg;

my $blackz = 'blackzone.tst';
# udp timeout will default to 30
my $run = 5;
my $runval;

# set the target for remote interrogations
*Net::DNSBL::MultiDaemon::R_Sin = \scalar sockaddr_in($t1port,inet_aton('127.0.0.1'));

## test 11-14	do a good zone lookup, send request
uniqueID(12344);
my $off = newhead(\$msg,
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg,$off,'1.2.3.4.'.$blackz,T_A,C_IN);

# send T2 message
sub sendT2 {
  my ($msg) = @_;
  my $err = eval {
	local $SIG{ALRM} = sub {die "blocked sendT2, timeout"};
	my $rv;
	alarm 2;
	if (($rv = send($T2,$msg,0,$L_sin)) && $rv >= &HFIXEDSZ) {
	  alarm 0;
	  undef;
	} else {
	  die "sent $rv bytes";
	}
  };
  ## t11
}

sendT2($msg);
print $@, "\nnot "
	if $@;
&ok;

my $now = &next_sec();
# 'run' and hopefully send a response
sub do_run {
  my $Dconditions = shift;
  eval {
	local $SIG{ALRM} = sub {die "blocked do_run, timeout"};
	alarm 10;
	$runval = run($blackz,$L,$R,$DNSBLS,\%STATS,\$run,$sfile,$statime,$Dconditions);
	alarm 0;
  };
}

## t12
do_run($D_SHRTHD | $D_QRESP | $D_CLRRUN);
print $@, "\nnot "
	if $@;
&ok;

$now = &next_sec();

sub recvT1 {
  my $mp = shift;
  my $recvfrom;
  eval {	# response should come to local
	local $SIG{ALRM} = sub {die "blocked recvT1, timeout"};
	my $rv;
	alarm 5;
	$recvfrom = recv($T1,$$mp,512,0);
	die "no message received"
		unless $recvfrom;
	alarm 0;
  };
  return $recvfrom;
}

## t13
recvT1(\$msg);
print $@, "\nnot "
	if $@;
&ok;

## t14 starts here
  ($off,my($id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount))
	= gethead(\$msg);

my $expectxt = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  0000_0001  0x01    1    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0001  0x01    1    
  13    :  0011_0001  0x31   49  1  
  14    :  0000_0001  0x01    1    
  15    :  0011_0010  0x32   50  2  
  16    :  0000_0001  0x01    1    
  17    :  0011_0011  0x33   51  3  
  18    :  0000_0001  0x01    1    
  19    :  0011_0100  0x34   52  4  
  20    :  0000_0111  0x07    7    
  21    :  0110_0100  0x64  100  d  
  22    :  0110_1111  0x6F  111  o  
  23    :  0110_1101  0x6D  109  m  
  24    :  0110_0001  0x61   97  a  
  25    :  0110_1001  0x69  105  i  
  26    :  0110_1110  0x6E  110  n  
  27    :  0011_0001  0x31   49  1  
  28    :  0000_0011  0x03    3    
  29    :  0110_0011  0x63   99  c  
  30    :  0110_1111  0x6F  111  o  
  31    :  0110_1101  0x6D  109  m  
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0001  0x01    1    
  35    :  0000_0000  0x00    0    
  36    :  0000_0001  0x01    1    
|;

#print_buf(\$msg);
chk_exp(\$msg,\$expectxt);

#### everything on the receive side of 'run' is not checked

#### test for the exception conditions on the receive side.
#### this involves leaving the daemon running and sending a series of messages that will fail
#### the assumption is that the setup (above) will always pass since it passed the first time.
####

sub setup {
  uniqueID(12344);		# preset remote id to match id
  my ($mp) = @_;
  my $off = newhead($mp,
        12345,
        BITS_QUERY,
        1,0,0,0);
  $put->Question($mp,$off,'1.2.3.4.'.$blackz,T_A,C_IN);
  sendT2($$mp);
  print $@, "\nnot "
	if $@;
  &ok;
}

sub kidstuf1 {
  my($mp) = @_;
  close $R;
  close $L;
  close $T2;
  local $SIG{ALRM} = sub {die 'child timeout'};

  my $bogus;

  my $recvfrom;
  alarm 5;
  while(! $recvfrom) {
    &next_sec();
    $recvfrom = recvT1(\$bogus);	# just assume the message is correct
  }
  alarm 0;

  alarm 5;
  send($T1,$$mp,0,$recvfrom);
  alarm 0;

  close $T1;
  exit;
}

### triplet for short response
## test 15
setup(\$msg);
my $kid = fork;
unless ($kid) {
  $off = newhead(\$msg,
	12345,
	BITS_QUERY | QR,
	1,0,1,0);	# message about right
  chop $msg;		# shorten message by one
  kidstuf1(\$msg);
}

## test 16	check no timeout
do_run($D_NOTME | $D_SHRTHD);
print $@, "\nnot "
	if $@;
&ok;

## test 17	check error found
print "got: $runval, exp: 'short header'\nnot "
	unless $runval eq 'short header';
&ok;

waitpid($kid,0);

### triplet for wrong message ID
## test 18
setup(\$msg);
$kid = fork;

unless ($kid) {
  $off = newhead(\$msg,
	11111,		# bogus ID
	BITS_QUERY | QR,
	1,1,0,0);	# message about right
  kidstuf1(\$msg);
}

## test 19	check no timeout
do_run($D_NOTME | $D_SHRTHD);
print $@, "\nnot "
	if $@;
&ok;

## test 20	check error found
print "got: $runval, exp: 'not me 1'\nnot "
	unless $runval eq 'not me 1';
&ok;

waitpid($kid,0);

### 3 triplet's for not my question, all combinations
foreach(['9.2.3.4.domain1.com',T_A,C_IN],
	['1.2.3.4.domain1.com',T_ANY,C_IN],
	['1.2.3.4.domain1.com',T_A,C_HS],
	) {
## test 21 (24, 27)
  setup(\$msg);
  $kid = fork;

  unless ($kid) {
    $off = newhead(\$msg,
	12345,
	BITS_QUERY | QR,
	1,1,0,0);	# message about right
    $put->Question(\$msg,$off,@{$_});
    kidstuf1(\$msg);
  }

## test 22 (25, 28)	check no timeout
  do_run($D_NOTME | $D_SHRTHD);
  print $@, "\nnot "
	if $@;
  &ok;

## test 23 (26, 29)	check error found
  print "got: $runval, exp: 'not me 2'\nnot "
	unless $runval eq 'not me 2';
  &ok;

  waitpid($kid,0);
}

## test 30	send a response question, get a good answer
setup(\$msg);
$kid = fork;

unless ($kid) {
  $off = newhead(\$msg,
	12345,
	BITS_QUERY | QR,
	1,1,1,1);
  ($off,my @dnptrs) = $put->Question(\$msg,$off,'1.2.3.4.domain1.com',T_A,C_IN);
  ($off,@dnptrs) = $put->A(\$msg,$off,\@dnptrs,'1.2.3.4.domain1.com',T_A,C_IN,54321,inet_aton('127.0.0.2'));
  ($off,@dnptrs) = $put->NS(\$msg,$off,\@dnptrs,'domain1.com',T_NS,C_IN,43210,'ns.domain1.com');
  $put->A(\$msg,$off,\@dnptrs,'ns.domain1.com',T_A,C_IN,32109,inet_aton('5.4.3.2'));
  kidstuf1(\$msg);
}

## test 31	run and produce answer
do_run($D_NOTME | $D_SHRTHD | $D_ANSTOP);
print $@, "\nnot "
	if $@;
&ok;

undef $msg;
&next_sec();
eval {
	local $SIG{ALRM} = sub {'answer timed out'};
	alarm 2;
	recv($T2,$msg,512,0) or die "no answer received";
	alarm 0;
};

## test 32	check for errors
print $@, "\nnot "
	if $@;
&ok;

waitpid($kid,0);

## test 33	check expected answer
$expectxt = q|
  0	:  0011_0000  0x30   48  0  
  1	:  0011_1001  0x39   57  9  
  2	:  1000_0000  0x80  128    
  3	:  0000_0000  0x00    0    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0001  0x01    1    
  8	:  0000_0000  0x00    0    
  9	:  0000_0001  0x01    1    
  10	:  0000_0000  0x00    0    
  11	:  0000_0011  0x03    3    
  12	:  0000_0001  0x01    1    
  13	:  0011_0001  0x31   49  1  
  14	:  0000_0001  0x01    1    
  15	:  0011_0010  0x32   50  2  
  16	:  0000_0001  0x01    1    
  17	:  0011_0011  0x33   51  3  
  18	:  0000_0001  0x01    1    
  19	:  0011_0100  0x34   52  4  
  20	:  0000_1001  0x09    9    
  21	:  0110_0010  0x62   98  b  
  22	:  0110_1100  0x6C  108  l  
  23	:  0110_0001  0x61   97  a  
  24	:  0110_0011  0x63   99  c  
  25	:  0110_1011  0x6B  107  k  
  26	:  0111_1010  0x7A  122  z  
  27	:  0110_1111  0x6F  111  o  
  28	:  0110_1110  0x6E  110  n  
  29	:  0110_0101  0x65  101  e  
  30	:  0000_0011  0x03    3    
  31	:  0111_0100  0x74  116  t  
  32	:  0111_0011  0x73  115  s  
  33	:  0111_0100  0x74  116  t  
  34	:  0000_0000  0x00    0    
  35	:  0000_0000  0x00    0    
  36	:  0000_0001  0x01    1    
  37	:  0000_0000  0x00    0    
  38	:  0000_0001  0x01    1    
  39	:  1100_0000  0xC0  192    
  40	:  0000_1100  0x0C   12    
  41	:  0000_0000  0x00    0    
  42	:  0000_0001  0x01    1    
  43	:  0000_0000  0x00    0    
  44	:  0000_0001  0x01    1    
  45	:  0000_0000  0x00    0    
  46	:  0000_0000  0x00    0    
  47	:  1101_0100  0xD4  212    
  48	:  0011_0001  0x31   49  1  
  49	:  0000_0000  0x00    0    
  50	:  0000_0100  0x04    4    
  51	:  0111_1111  0x7F  127    
  52	:  0000_0000  0x00    0    
  53	:  0000_0000  0x00    0    
  54	:  0000_0010  0x02    2    
  55	:  1100_0000  0xC0  192    
  56	:  0001_0100  0x14   20    
  57	:  0000_0000  0x00    0    
  58	:  0000_0010  0x02    2    
  59	:  0000_0000  0x00    0    
  60	:  0000_0001  0x01    1    
  61	:  0000_0000  0x00    0    
  62	:  0000_0001  0x01    1    
  63	:  0101_0001  0x51   81  Q  
  64	:  1000_0000  0x80  128    
  65	:  0000_0000  0x00    0    
  66	:  0000_0010  0x02    2    
  67	:  1100_0000  0xC0  192    
  68	:  0001_0100  0x14   20    
  69	:  1100_0000  0xC0  192    
  70	:  0001_0100  0x14   20    
  71	:  0000_0000  0x00    0    
  72	:  0000_0001  0x01    1    
  73	:  0000_0000  0x00    0    
  74	:  0000_0001  0x01    1    
  75	:  0000_0000  0x00    0    
  76	:  0000_0001  0x01    1    
  77	:  0101_0001  0x51   81  Q  
  78	:  1000_0000  0x80  128    
  79	:  0000_0000  0x00    0    
  80	:  0000_0100  0x04    4    
  81	:  0111_1111  0x7F  127    
  82	:  0000_0000  0x00    0    
  83	:  0000_0000  0x00    0    
  84	:  0000_0001  0x01    1    
  85	:  0000_0111  0x07    7    
  86	:  0110_0100  0x64  100  d  
  87	:  0110_1111  0x6F  111  o  
  88	:  0110_1101  0x6D  109  m  
  89	:  0110_0001  0x61   97  a  
  90	:  0110_1001  0x69  105  i  
  91	:  0110_1110  0x6E  110  n  
  92	:  0011_0001  0x31   49  1  
  93	:  0000_0011  0x03    3    
  94	:  0110_0011  0x63   99  c  
  95	:  0110_1111  0x6F  111  o  
  96	:  0110_1101  0x6D  109  m  
  97	:  0000_0000  0x00    0    
  98	:  0000_0000  0x00    0    
  99	:  0000_0010  0x02    2    
  100	:  0000_0000  0x00    0    
  101	:  0000_0001  0x01    1    
  102	:  0000_0000  0x00    0    
  103	:  0000_0000  0x00    0    
  104	:  1010_1000  0xA8  168    
  105	:  1100_1010  0xCA  202    
  106	:  0000_0000  0x00    0    
  107	:  0000_0101  0x05    5    
  108	:  0000_0010  0x02    2    
  109	:  0110_1110  0x6E  110  n  
  110	:  0111_0011  0x73  115  s  
  111	:  1100_0000  0xC0  192    
  112	:  0101_0101  0x55   85  U  
  113	:  1100_0000  0xC0  192    
  114	:  0110_1100  0x6C  108  l  
  115	:  0000_0000  0x00    0    
  116	:  0000_0001  0x01    1    
  117	:  0000_0000  0x00    0    
  118	:  0000_0001  0x01    1    
  119	:  0000_0000  0x00    0    
  120	:  0000_0000  0x00    0    
  121	:  0111_1101  0x7D  125  }  
  122	:  0110_1101  0x6D  109  m  
  123	:  0000_0000  0x00    0    
  124	:  0000_0100  0x04    4    
  125	:  0000_0101  0x05    5    
  126	:  0000_0100  0x04    4    
  127	:  0000_0011  0x03    3    
  128	:  0000_0010  0x02    2    
|;

#print_buf(\$msg);
fixfat(\$expectxt);
chk_exp(\$msg,\$expectxt);

## test 34	send another response question, get a good answer
setup(\$msg);
$kid = fork;

unless ($kid) {
  $off = newhead(\$msg,
	12345,
	BITS_QUERY | QR,
	1,1,1,1);
  ($off,my @dnptrs) = $put->Question(\$msg,$off,'1.2.3.4.domain1.com',T_A,C_IN);
  ($off,@dnptrs) = $put->A(\$msg,$off,\@dnptrs,'1.2.3.4.domain1.com',T_A,C_IN,98765,inet_aton('127.0.0.4'));
  ($off,@dnptrs) = $put->NS(\$msg,$off,\@dnptrs,'domain1.com',T_NS,C_IN,87654,'ns.domain1.com');
  $put->A(\$msg,$off,\@dnptrs,'ns.domain1.com',T_A,C_IN,76543,inet_aton('99.100.101.102'));
  kidstuf1(\$msg);
}

## test 35	run and produce answer
do_run($D_NOTME | $D_SHRTHD | $D_ANSTOP);
print $@, "\nnot "
	if $@;
&ok;

undef $msg;
&next_sec();
eval {
	local $SIG{ALRM} = sub {'answer timed out'};
	alarm 2;
	recv($T2,$msg,512,0) or die "no answer received";
	alarm 0;
};

## test 36	check for errors
print $@, "\nnot "
	if $@;
&ok;

waitpid($kid,0);

## test 37	check expected answer
$expectxt = q|
  0	:  0011_0000  0x30   48  0  
  1	:  0011_1001  0x39   57  9  
  2	:  1000_0000  0x80  128    
  3	:  0000_0000  0x00    0    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0001  0x01    1    
  8	:  0000_0000  0x00    0    
  9	:  0000_0001  0x01    1    
  10	:  0000_0000  0x00    0    
  11	:  0000_0011  0x03    3    
  12	:  0000_0001  0x01    1    
  13	:  0011_0001  0x31   49  1  
  14	:  0000_0001  0x01    1    
  15	:  0011_0010  0x32   50  2  
  16	:  0000_0001  0x01    1    
  17	:  0011_0011  0x33   51  3  
  18	:  0000_0001  0x01    1    
  19	:  0011_0100  0x34   52  4  
  20	:  0000_1001  0x09    9    
  21	:  0110_0010  0x62   98  b  
  22	:  0110_1100  0x6C  108  l  
  23	:  0110_0001  0x61   97  a  
  24	:  0110_0011  0x63   99  c  
  25	:  0110_1011  0x6B  107  k  
  26	:  0111_1010  0x7A  122  z  
  27	:  0110_1111  0x6F  111  o  
  28	:  0110_1110  0x6E  110  n  
  29	:  0110_0101  0x65  101  e  
  30	:  0000_0011  0x03    3    
  31	:  0111_0100  0x74  116  t  
  32	:  0111_0011  0x73  115  s  
  33	:  0111_0100  0x74  116  t  
  34	:  0000_0000  0x00    0    
  35	:  0000_0000  0x00    0    
  36	:  0000_0001  0x01    1    
  37	:  0000_0000  0x00    0    
  38	:  0000_0001  0x01    1    
  39	:  1100_0000  0xC0  192    
  40	:  0000_1100  0x0C   12    
  41	:  0000_0000  0x00    0    
  42	:  0000_0001  0x01    1    
  43	:  0000_0000  0x00    0    
  44	:  0000_0001  0x01    1    
  45	:  0000_0000  0x00    0    
  46	:  0000_0001  0x01    1    
  47	:  1000_0001  0x81  129    
  48	:  1100_1101  0xCD  205    
  49	:  0000_0000  0x00    0    
  50	:  0000_0100  0x04    4    
  51	:  0111_1111  0x7F  127    
  52	:  0000_0000  0x00    0    
  53	:  0000_0000  0x00    0    
  54	:  0000_0010  0x02    2    
  55	:  1100_0000  0xC0  192    
  56	:  0001_0100  0x14   20    
  57	:  0000_0000  0x00    0    
  58	:  0000_0010  0x02    2    
  59	:  0000_0000  0x00    0    
  60	:  0000_0001  0x01    1    
  61	:  0000_0000  0x00    0    
  62	:  0000_0001  0x01    1    
  63	:  0101_0001  0x51   81  Q  
  64	:  1000_0000  0x80  128    
  65	:  0000_0000  0x00    0    
  66	:  0000_0010  0x02    2    
  67	:  1100_0000  0xC0  192    
  68	:  0001_0100  0x14   20    
  69	:  1100_0000  0xC0  192    
  70	:  0001_0100  0x14   20    
  71	:  0000_0000  0x00    0    
  72	:  0000_0001  0x01    1    
  73	:  0000_0000  0x00    0    
  74	:  0000_0001  0x01    1    
  75	:  0000_0000  0x00    0    
  76	:  0000_0001  0x01    1    
  77	:  0101_0001  0x51   81  Q  
  78	:  1000_0000  0x80  128    
  79	:  0000_0000  0x00    0    
  80	:  0000_0100  0x04    4    
  81	:  0111_1111  0x7F  127    
  82	:  0000_0000  0x00    0    
  83	:  0000_0000  0x00    0    
  84	:  0000_0001  0x01    1    
  85	:  0000_0111  0x07    7    
  86	:  0110_0100  0x64  100  d  
  87	:  0110_1111  0x6F  111  o  
  88	:  0110_1101  0x6D  109  m  
  89	:  0110_0001  0x61   97  a  
  90	:  0110_1001  0x69  105  i  
  91	:  0110_1110  0x6E  110  n  
  92	:  0011_0001  0x31   49  1  
  93	:  0000_0011  0x03    3    
  94	:  0110_0011  0x63   99  c  
  95	:  0110_1111  0x6F  111  o  
  96	:  0110_1101  0x6D  109  m  
  97	:  0000_0000  0x00    0    
  98	:  0000_0000  0x00    0    
  99	:  0000_0010  0x02    2    
  100	:  0000_0000  0x00    0    
  101	:  0000_0001  0x01    1    
  102	:  0000_0000  0x00    0    
  103	:  0000_0001  0x01    1    
  104	:  0101_0110  0x56   86  V  
  105	:  0110_0110  0x66  102  f  
  106	:  0000_0000  0x00    0    
  107	:  0000_0101  0x05    5    
  108	:  0000_0010  0x02    2    
  109	:  0110_1110  0x6E  110  n  
  110	:  0111_0011  0x73  115  s  
  111	:  1100_0000  0xC0  192    
  112	:  0101_0101  0x55   85  U  
  113	:  1100_0000  0xC0  192    
  114	:  0110_1100  0x6C  108  l  
  115	:  0000_0000  0x00    0    
  116	:  0000_0001  0x01    1    
  117	:  0000_0000  0x00    0    
  118	:  0000_0001  0x01    1    
  119	:  0000_0000  0x00    0    
  120	:  0000_0001  0x01    1    
  121	:  0010_1010  0x2A   42  *  
  122	:  1111_1111  0xFF  255    
  123	:  0000_0000  0x00    0    
  124	:  0000_0100  0x04    4    
  125	:  0110_0011  0x63   99  c  
  126	:  0110_0100  0x64  100  d  
  127	:  0110_0101  0x65  101  e  
  128	:  0110_0110  0x66  102  f  
|;

#print_buf(\$msg);
fixfat(\$expectxt);
chk_exp(\$msg,\$expectxt);

## test 38	send not found answer, elicit another question, send good response to second question
setup(\$msg);
$kid = fork;

unless ($kid) {
  close $R;
  close $L;
  close $T2;
  local $SIG{ALRM} = sub {die 'child timeout'};

  $off = newhead(\$msg,
	12345,
	BITS_QUERY | QR,
	1,0,1,0);
  ($off,my @dnptrs) = $put->Question(\$msg,$off,'1.2.3.4.domain1.com',T_A,C_IN);
  $put->SOA(\$msg,$off,\@dnptrs,'domain1.com',T_SOA,C_IN,222223,'testhost','nospam.testhost',11223344,98765,87654,76543,65431);

  my $bogus;

  my $recvfrom;
  alarm 5;
  while(! $recvfrom) {
    &next_sec();
    $recvfrom = recvT1(\$bogus);	# just assume the message is correct
  }
  alarm 0;

  alarm 5;
  send($T1,$msg,0,$recvfrom);
  alarm 0;

  my $kmsg;

  $recvfrom = undef;
  alarm 5;
  while(! $recvfrom) {
    &next_sec();
    $recvfrom = recvT1(\$kmsg);		# should be second domain request
  }
  alarm 0;

  ($off,@_) = gethead(\$kmsg);
  ($off,my($name,$type,$class)) = $get->Question(\$kmsg,$off);

# generate a known response pattern

  $name =~ /(\d+\.\d+\.\d+\.\d+)\.(.+)$/;
  my $rip = $1;
  my $zone = $2;

  $off = newhead(\$msg,
	12345,
	BITS_QUERY | QR,
	1,1,1,1);
  ($off,@dnptrs) = $put->Question(\$msg,$off,$name,$type,$class);
  ($off,@dnptrs) = $put->A(\$msg,$off,\@dnptrs,$name,$type,$class,98765,inet_aton('127.0.0.6'));
  ($off,@dnptrs) = $put->NS(\$msg,$off,\@dnptrs,$zone,T_NS,C_IN,87654,'ns.'.$zone);
  $put->A(\$msg,$off,\@dnptrs,'ns.'.$zone,T_A,C_IN,76543,inet_aton('199.200.201.202'));

  alarm 5;
  send($T1,$msg,0,$recvfrom);
  alarm 0;

  close $T1;
  exit;
}

## test 39	run and produce answer
do_run($D_NOTME | $D_SHRTHD | $D_ANSTOP);
print $@, "\nnot "
	if $@;
&ok;

undef $msg;
&next_sec();
eval {
	local $SIG{ALRM} = sub {'answer timed out'};
	alarm 2;
	recv($T2,$msg,512,0) or die "no answer received";
	alarm 0;
};

## test 40	check for errors
print $@, "\nnot "
	if $@;
&ok;

waitpid($kid,0);

## test 41	check expected answer
$expectxt = q|
  0	:  0011_0000  0x30   48  0  
  1	:  0011_1001  0x39   57  9  
  2	:  1000_0000  0x80  128    
  3	:  0000_0000  0x00    0    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0001  0x01    1    
  8	:  0000_0000  0x00    0    
  9	:  0000_0001  0x01    1    
  10	:  0000_0000  0x00    0    
  11	:  0000_0011  0x03    3    
  12	:  0000_0001  0x01    1    
  13	:  0011_0001  0x31   49  1  
  14	:  0000_0001  0x01    1    
  15	:  0011_0010  0x32   50  2  
  16	:  0000_0001  0x01    1    
  17	:  0011_0011  0x33   51  3  
  18	:  0000_0001  0x01    1    
  19	:  0011_0100  0x34   52  4  
  20	:  0000_1001  0x09    9    
  21	:  0110_0010  0x62   98  b  
  22	:  0110_1100  0x6C  108  l  
  23	:  0110_0001  0x61   97  a  
  24	:  0110_0011  0x63   99  c  
  25	:  0110_1011  0x6B  107  k  
  26	:  0111_1010  0x7A  122  z  
  27	:  0110_1111  0x6F  111  o  
  28	:  0110_1110  0x6E  110  n  
  29	:  0110_0101  0x65  101  e  
  30	:  0000_0011  0x03    3    
  31	:  0111_0100  0x74  116  t  
  32	:  0111_0011  0x73  115  s  
  33	:  0111_0100  0x74  116  t  
  34	:  0000_0000  0x00    0    
  35	:  0000_0000  0x00    0    
  36	:  0000_0001  0x01    1    
  37	:  0000_0000  0x00    0    
  38	:  0000_0001  0x01    1    
  39	:  1100_0000  0xC0  192    
  40	:  0000_1100  0x0C   12    
  41	:  0000_0000  0x00    0    
  42	:  0000_0001  0x01    1    
  43	:  0000_0000  0x00    0    
  44	:  0000_0001  0x01    1    
  45	:  0000_0000  0x00    0    
  46	:  0000_0001  0x01    1    
  47	:  1000_0001  0x81  129    
  48	:  1100_1101  0xCD  205    
  49	:  0000_0000  0x00    0    
  50	:  0000_0100  0x04    4    
  51	:  0111_1111  0x7F  127    
  52	:  0000_0000  0x00    0    
  53	:  0000_0000  0x00    0    
  54	:  0000_0010  0x02    2    
  55	:  1100_0000  0xC0  192    
  56	:  0001_0100  0x14   20    
  57	:  0000_0000  0x00    0    
  58	:  0000_0010  0x02    2    
  59	:  0000_0000  0x00    0    
  60	:  0000_0001  0x01    1    
  61	:  0000_0000  0x00    0    
  62	:  0000_0001  0x01    1    
  63	:  0101_0001  0x51   81  Q  
  64	:  1000_0000  0x80  128    
  65	:  0000_0000  0x00    0    
  66	:  0000_0010  0x02    2    
  67	:  1100_0000  0xC0  192    
  68	:  0001_0100  0x14   20    
  69	:  1100_0000  0xC0  192    
  70	:  0001_0100  0x14   20    
  71	:  0000_0000  0x00    0    
  72	:  0000_0001  0x01    1    
  73	:  0000_0000  0x00    0    
  74	:  0000_0001  0x01    1    
  75	:  0000_0000  0x00    0    
  76	:  0000_0001  0x01    1    
  77	:  0101_0001  0x51   81  Q  
  78	:  1000_0000  0x80  128    
  79	:  0000_0000  0x00    0    
  80	:  0000_0100  0x04    4    
  81	:  0111_1111  0x7F  127    
  82	:  0000_0000  0x00    0    
  83	:  0000_0000  0x00    0    
  84	:  0000_0001  0x01    1    
  85	:  0000_0111  0x07    7    
  86	:  0110_0100  0x64  100  d  
  87	:  0110_1111  0x6F  111  o  
  88	:  0110_1101  0x6D  109  m  
  89	:  0110_0001  0x61   97  a  
  90	:  0110_1001  0x69  105  i  
  91	:  0110_1110  0x6E  110  n  
  92	:  0011_0010  0x32   50  2  
  93	:  0000_0011  0x03    3    
  94	:  0110_1110  0x6E  110  n  
  95	:  0110_0101  0x65  101  e  
  96	:  0111_0100  0x74  116  t  
  97	:  0000_0000  0x00    0    
  98	:  0000_0000  0x00    0    
  99	:  0000_0010  0x02    2    
  100	:  0000_0000  0x00    0    
  101	:  0000_0001  0x01    1    
  102	:  0000_0000  0x00    0    
  103	:  0000_0001  0x01    1    
  104	:  0101_0110  0x56   86  V  
  105	:  0110_0110  0x66  102  f  
  106	:  0000_0000  0x00    0    
  107	:  0000_0101  0x05    5    
  108	:  0000_0010  0x02    2    
  109	:  0110_1110  0x6E  110  n  
  110	:  0111_0011  0x73  115  s  
  111	:  1100_0000  0xC0  192    
  112	:  0101_0101  0x55   85  U  
  113	:  1100_0000  0xC0  192    
  114	:  0110_1100  0x6C  108  l  
  115	:  0000_0000  0x00    0    
  116	:  0000_0001  0x01    1    
  117	:  0000_0000  0x00    0    
  118	:  0000_0001  0x01    1    
  119	:  0000_0000  0x00    0    
  120	:  0000_0001  0x01    1    
  121	:  0010_1010  0x2A   42  *  
  122	:  1111_1111  0xFF  255    
  123	:  0000_0000  0x00    0    
  124	:  0000_0100  0x04    4    
  125	:  1100_0111  0xC7  199    
  126	:  1100_1000  0xC8  200    
  127	:  1100_1001  0xC9  201    
  128	:  1100_1010  0xCA  202    
|;

#print_buf(\$msg);
fixfat(\$expectxt);
chk_exp(\$msg,\$expectxt);

## test 42	response of only not found, produce answer of not found
my $sav = $STATS{'domain2.net'};
delete $STATS{'domain2.net'};		# only one dnsbl now
setup(\$msg);
$kid = fork;

unless ($kid) {
  $off = newhead(\$msg,
	12345,
	BITS_QUERY | QR,
	1,0,1,0);
  ($off,my @dnptrs) = $put->Question(\$msg,$off,'1.2.3.4.domain1.com',T_A,C_IN);
  $put->SOA(\$msg,$off,\@dnptrs,'domain1.com',T_SOA,C_IN,222223,'testhost','nospam.testhost',11223344,98765,87654,76543,65431);
  close $R;
  close $L;
  local $SIG{ALRM} = sub {die 'child timeout'};

  my $bogus;

  my $recvfrom;
  alarm 5;
  while(! $recvfrom) {
    &next_sec();
    $recvfrom = recvT1(\$bogus);	# just assume the message is correct
  }
  alarm 0;

  alarm 5;
  send($T1,$msg,0,$recvfrom);
  alarm 0;

  &next_sec();

  $off = newhead(\$msg,
	12345,
	BITS_QUERY | QR,
	1,0,0,0);
  chop $msg;				# force exit with short response
  
  sendT2($msg);
  close $T2;
  close $T1;
  exit;
}

## test 43	run and produce answer
do_run($D_NOTME | $D_SHRTHD | $D_ANSTOP);
print $@, "\nnot "
	if $@;
&ok;

undef $msg;
&next_sec();
eval {
	local $SIG{ALRM} = sub {'answer timed out'};
	alarm 2;
	recv($T2,$msg,512,0) or die "no answer received";
	alarm 0;
};

## test 44	check for errors
print $@, "\nnot "
	if $@;
&ok;

waitpid($kid,0);

## test 45	check expected answer
$expectxt = q|
  0	:  0011_0000  0x30   48  0  
  1	:  0011_1001  0x39   57  9  
  2	:  1000_0000  0x80  128    
  3	:  0000_0011  0x03    3    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0000  0x00    0    
  8	:  0000_0000  0x00    0    
  9	:  0000_0001  0x01    1    
  10	:  0000_0000  0x00    0    
  11	:  0000_0000  0x00    0    
  12	:  0000_0001  0x01    1    
  13	:  0011_0001  0x31   49  1  
  14	:  0000_0001  0x01    1    
  15	:  0011_0010  0x32   50  2  
  16	:  0000_0001  0x01    1    
  17	:  0011_0011  0x33   51  3  
  18	:  0000_0001  0x01    1    
  19	:  0011_0100  0x34   52  4  
  20	:  0000_1001  0x09    9    
  21	:  0110_0010  0x62   98  b  
  22	:  0110_1100  0x6C  108  l  
  23	:  0110_0001  0x61   97  a  
  24	:  0110_0011  0x63   99  c  
  25	:  0110_1011  0x6B  107  k  
  26	:  0111_1010  0x7A  122  z  
  27	:  0110_1111  0x6F  111  o  
  28	:  0110_1110  0x6E  110  n  
  29	:  0110_0101  0x65  101  e  
  30	:  0000_0011  0x03    3    
  31	:  0111_0100  0x74  116  t  
  32	:  0111_0011  0x73  115  s  
  33	:  0111_0100  0x74  116  t  
  34	:  0000_0000  0x00    0    
  35	:  0000_0000  0x00    0    
  36	:  0000_0001  0x01    1    
  37	:  0000_0000  0x00    0    
  38	:  0000_0001  0x01    1    
  39	:  1100_0000  0xC0  192    
  40	:  0001_0100  0x14   20    
  41	:  0000_0000  0x00    0    
  42	:  0000_0110  0x06    6    
  43	:  0000_0000  0x00    0    
  44	:  0000_0001  0x01    1    
  45	:  0000_0000  0x00    0    
  46	:  0000_0000  0x00    0    
  47	:  0000_0000  0x00    0    
  48	:  0000_0000  0x00    0    
  49	:  0000_0000  0x00    0    
  50	:  0001_1101  0x1D   29    
  51	:  1100_0000  0xC0  192    
  52	:  0001_0100  0x14   20    
  53	:  0000_0100  0x04    4    
  54	:  0111_0010  0x72  114  r  
  55	:  0110_1111  0x6F  111  o  
  56	:  0110_1111  0x6F  111  o  
  57	:  0111_0100  0x74  116  t  
  58	:  1100_0000  0xC0  192    
  59	:  0001_0100  0x14   20    
  60	:  0011_1111  0x3F   63  ?  
  61	:  1010_1000  0xA8  168    
  62	:  0001_0110  0x16   22    
  63	:  1010_0111  0xA7  167    
  64	:  0000_0000  0x00    0    
  65	:  0000_0001  0x01    1    
  66	:  0101_0001  0x51   81  Q  
  67	:  1000_0000  0x80  128    
  68	:  0000_0000  0x00    0    
  69	:  0000_0000  0x00    0    
  70	:  1010_1000  0xA8  168    
  71	:  1100_0000  0xC0  192    
  72	:  0000_0000  0x00    0    
  73	:  0000_0010  0x02    2    
  74	:  1010_0011  0xA3  163    
  75	:  0000_0000  0x00    0    
  76	:  0000_0000  0x00    0    
  77	:  0000_0000  0x00    0    
  78	:  0000_1110  0x0E   14    
  79	:  0001_0000  0x10   16    
|;

substr($msg,60,4,pack("N",0x3FA816A7));	# set SOA serial (time) to sequence in expected string above
#print_buf(\$msg);
chk_exp(\$msg,\$expectxt);

close $L;
close $R;
close $T1;
close $T2;

## test 46	check statistics collection
print "domain1.com - got: ",$STATS{'domain1.com'},", exp: 2\nnot "
	unless $STATS{'domain1.com'} == 2;
&ok;

## test 47
print "domain2.net = got: $sav, exp: 1\nnot "
	unless $sav == 1;
&ok;
