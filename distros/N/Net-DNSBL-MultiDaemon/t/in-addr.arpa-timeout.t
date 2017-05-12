# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

#################################################################
#################################################################
# NOTE: this test sequence is almost identical to t/run_timer.t	#
# except that the timeout is for the 'in-addr.arpa' lookup	#
# which should return an A record of 127.0.0.3			#
#################################################################
#################################################################

BEGIN { $| = 1; print "1..20\n"; }
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

## test 2-3	suck in and check config file for domain1.com domain2.net

my $DNSBL = DO($config);
print "could not open configuration file $config\nnot "
	unless $DNSBL;
&ok;

print "missing configuration file variables domain1.com, domain2.net\nnot "
	unless exists $DNSBL->{'domain1.com'} && exists $DNSBL->{'domain2.net'};
&ok;

$DNSBL->{'in-addr.arpa'}->{timeout} = 1;

## test 4	init STATS
my %STATS;
cntinit($DNSBL,\%STATS);
print "got: $_, exp: 6, bad key count\nnot "
        unless ($_ = keys %STATS) == 6;
&ok;

$STATS{'domain1.com'} = 3;
$STATS{'domain2.net'} = 2;

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
$DNSBL->{'domain1.com'}->{timeout} = 1;	# short alarm timeout for dnsbl interrogation
$DNSBL->{'domain2.net'}->{timeout} = 1;	# udp timeout
my $run = 5;
my $runval;

# set the target for remote interrogations
*Net::DNSBL::MultiDaemon::R_Sin = \scalar sockaddr_in($t1port,inet_aton('127.0.0.1'));

## test 11-14	do a good zone lookup, send request

uniqueID(1233);	# preset ID generator

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
	if (send($T2,$msg,0,$L_sin)) {
	  alarm 0;
	  undef;
	} else {
	  die "nothing sent\n";
	}
  };
  ## t11
}

## test 11
sendT2($msg);
print $@, "\nnot "
	if $@;
&ok;

# 'run' and let it time out
sub do_run {
  my $Dconditions = shift;
  eval {
	local $SIG{ALRM} = sub {die "blocked do_run, timeout"};
	alarm 10;
	$runval = run($blackz,$L,$R,$DNSBL,\%STATS,\$run,$sfile,$statime,$Dconditions);
	alarm 0;
  };
}

my $kid = fork;
unless ($kid) {
  close $T1;
  close $T2;
  do_run($D_SHRTHD);
  close $R;
  close $L;
#  print $@ if $@;
  exit;
}

sub recvT1 {
  my $mp = shift;
  my $recvfrom;
  eval {
	local $SIG{ALRM} = sub {die "blocked recvT1, timeout"};
	alarm 5;
	while (!$recvfrom) {
	  &next_sec();
	  $recvfrom = recv($T1,$$mp,512,0);
	}
	alarm 0;
  };
  return $recvfrom;
}

## test 12
my $recvfrom = recvT1(\$msg);
print $@, "\nnot "
	if $@;
&ok;

## test 13	check first question
($off,my($id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount))
	= gethead(\$msg);

my $expectxt = q|
  0	:  0000_0100  0x04    4    
  1	:  1101_0010  0xD2  210    
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
  12	:  0000_0001  0x01    1    
  13	:  0011_0001  0x31   49  1  
  14	:  0000_0001  0x01    1    
  15	:  0011_0010  0x32   50  2  
  16	:  0000_0001  0x01    1    
  17	:  0011_0011  0x33   51  3  
  18	:  0000_0001  0x01    1    
  19	:  0011_0100  0x34   52  4  
  20	:  0000_0111  0x07    7    
  21	:  0110_0100  0x64  100  d  
  22	:  0110_1111  0x6F  111  o  
  23	:  0110_1101  0x6D  109  m  
  24	:  0110_0001  0x61   97  a  
  25	:  0110_1001  0x69  105  i  
  26	:  0110_1110  0x6E  110  n  
  27	:  0011_0001  0x31   49  1  
  28	:  0000_0011  0x03    3    
  29	:  0110_0011  0x63   99  c  
  30	:  0110_1111  0x6F  111  o  
  31	:  0110_1101  0x6D  109  m  
  32	:  0000_0000  0x00    0    
  33	:  0000_0000  0x00    0    
  34	:  0000_0001  0x01    1    
  35	:  0000_0000  0x00    0    
  36	:  0000_0001  0x01    1    
|;

#print_buf(\$msg);
chk_exp(\$msg,\$expectxt);

## test 14
$recvfrom = recvT1(\$msg);
print $@, "\nnot "
	if $@;
&ok;

## test 15	check second question
($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$msg);

$expectxt = q|
  0	:  0000_0100  0x04    4    
  1	:  1101_0010  0xD2  210    
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
  12	:  0000_0001  0x01    1    
  13	:  0011_0001  0x31   49  1  
  14	:  0000_0001  0x01    1    
  15	:  0011_0010  0x32   50  2  
  16	:  0000_0001  0x01    1    
  17	:  0011_0011  0x33   51  3  
  18	:  0000_0001  0x01    1    
  19	:  0011_0100  0x34   52  4  
  20	:  0000_0111  0x07    7    
  21	:  0110_0100  0x64  100  d  
  22	:  0110_1111  0x6F  111  o  
  23	:  0110_1101  0x6D  109  m  
  24	:  0110_0001  0x61   97  a  
  25	:  0110_1001  0x69  105  i  
  26	:  0110_1110  0x6E  110  n  
  27	:  0011_0010  0x32   50  2  
  28	:  0000_0011  0x03    3    
  29	:  0110_1110  0x6E  110  n  
  30	:  0110_0101  0x65  101  e  
  31	:  0111_0100  0x74  116  t  
  32	:  0000_0000  0x00    0    
  33	:  0000_0000  0x00    0    
  34	:  0000_0001  0x01    1    
  35	:  0000_0000  0x00    0    
  36	:  0000_0001  0x01    1    
|;

#print_buf(\$msg);
chk_exp(\$msg,\$expectxt);

## test 16
$recvfrom = recvT1(\$msg);
print $@, "\nnot "
	if $@;
&ok;

## test 17	check third question
($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$msg);

$expectxt = q|
  0	:  0000_0100  0x04    4    
  1	:  1101_0010  0xD2  210    
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
  12	:  0000_0001  0x01    1    
  13	:  0011_0001  0x31   49  1  
  14	:  0000_0001  0x01    1    
  15	:  0011_0010  0x32   50  2  
  16	:  0000_0001  0x01    1    
  17	:  0011_0011  0x33   51  3  
  18	:  0000_0001  0x01    1    
  19	:  0011_0100  0x34   52  4  
  20	:  0000_0111  0x07    7    
  21	:  0110_1001  0x69  105  i  
  22	:  0110_1110  0x6E  110  n  
  23	:  0010_1101  0x2D   45  -  
  24	:  0110_0001  0x61   97  a  
  25	:  0110_0100  0x64  100  d  
  26	:  0110_0100  0x64  100  d  
  27	:  0111_0010  0x72  114  r  
  28	:  0000_0100  0x04    4    
  29	:  0110_0001  0x61   97  a  
  30	:  0111_0010  0x72  114  r  
  31	:  0111_0000  0x70  112  p  
  32	:  0110_0001  0x61   97  a  
  33	:  0000_0000  0x00    0    
  34	:  0000_0000  0x00    0    
  35	:  0000_1100  0x0C   12    
  36	:  0000_0000  0x00    0    
  37	:  0000_0001  0x01    1    
|;

#print_buf(\$msg);
chk_exp(\$msg,\$expectxt);

## test 18	checkfor SOA record returned for not found
eval {
	local $SIG{ALRM} = sub {die "blocked recvT1, timeout"};
	alarm 5;
	while (!recv($T2,$msg,512,0)) {
	  &next_sec();
	}
	alarm 0;
};
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
  11	:  0000_0001  0x01    1    
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
  47	:  0000_1110  0x0E   14    
  48	:  0001_0000  0x10   16    
  49	:  0000_0000  0x00    0    
  50	:  0000_0100  0x04    4    
  51	:  0111_1111  0x7F  127    
  52	:  0000_0000  0x00    0    
  53	:  0000_0000  0x00    0    
  54	:  0000_0100  0x04    4    
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
|;
#print_head(\$msg);
#print_buf(\$msg);
chk_exp(\$msg,\$expectxt);

## test 19;
newhead(\$msg,
	12345,
	BITS_QUERY,
	1,0,0,0);
chop $msg;
sendT2($msg);			# send short message to terminate kid
print $@, "\nnot "
	if $@;
&ok;

waitpid($kid,0);

## test 20
&ok;				# marker so we know we're done debugging

close $L;
close $R;
close $T1;
close $T2;
