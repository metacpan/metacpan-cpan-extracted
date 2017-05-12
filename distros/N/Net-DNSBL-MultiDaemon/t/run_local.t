# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
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

## test 4	init STATS
my %STATS;
cntinit($DNSBL,\%STATS);
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
print "could not bind a port for testing\nnot "
	unless $port;
&ok;

## test 7	open a sending socket that is only used by test on this end
my $R = open_udpNB;
print "could not open unbound send socket\nnot "
	unless $R;
&ok;

my($get,$put,$parse) = new Net::DNS::ToolKit::RR;
my $msg;

my $blackz = 'blackzone.tst';
my $off = newhead(\$msg,
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg,$off,'7.7.1.2.'.$blackz,T_A,C_IN);	# should return 'notfound'

## test 8	send message, should not block
my $R_sin = sockaddr_in($port,inet_aton('127.0.0.1'));
my $err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	if ($rv = send($R,$msg,0,$R_sin)) {
	  alarm 0;
	  undef;
	} else {
	  die "sent $rv bytes";
	}
};
print $@, "\nnot "
	if $@;
&ok;

## test 9	read message back in 'run'
$DNSBL->{IGNORE} = ['2.1.7.7'];
$DNSBL->{'domain1.com'}->{timeout} = 3;
$DNSBL->{'domain2.net'}->{timeout} = 3;	# udp timeout
my $run = 5;
my $runval;
eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	alarm 3;
	$runval = run($blackz,$L,$R,$DNSBL,\%STATS,\$run,$sfile,$statime,$D_CLRRUN);
	alarm 0;
};

print $@, "\nnot "
	if $@;
&ok;

$msg = undef;
$err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	recv($R,$msg,512,0) or
		die "no message received";
	alarm 0;
};
## test 10
print $@, "\nnot "
	if $@;
&ok;

## test 11	check expected answer
my $expectxt = q|
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
  13	:  0011_0111  0x37   55  7  
  14	:  0000_0001  0x01    1    
  15	:  0011_0111  0x37   55  7  
  16	:  0000_0001  0x01    1    
  17	:  0011_0001  0x31   49  1  
  18	:  0000_0001  0x01    1    
  19	:  0011_0010  0x32   50  2  
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
  61	:  1100_0110  0xC6  198    
  62	:  0101_1111  0x5F   95  _  
  63	:  1010_1000  0xA8  168    
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

substr($msg,60,4,pack("N",0x3FC65FA8));	# set SOA serial (time) to sequence in expected string above
#print_head(\$msg);
#print_buf(\$msg);
chk_exp(\$msg,\$expectxt);

##################################################################

# test 12	check BLOCK
$off = newhead(\$msg,
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg,$off,'8.7.1.2.'.$blackz,T_A,C_IN);	# should return 'notfound'

#	send message, should not block
$R_sin = sockaddr_in($port,inet_aton('127.0.0.1'));
$err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	if ($rv = send($R,$msg,0,$R_sin)) {
	  alarm 0;
	  undef;
	} else {
	  die "sent $rv bytes";
	}
};
print $@, "\nnot "
	if $@;
&ok;

## test 13	read message back in 'run'
$DNSBL->{BLOCK} = ['2.1.7.8'];

eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	alarm 3;
	$runval = run($blackz,$L,$R,$DNSBL,\%STATS,\$run,$sfile,$statime,$D_CLRRUN);
	alarm 0;
};

print $@, "\nnot "
	if $@;
&ok;

$msg = undef;
$err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	recv($R,$msg,512,0) or
		die "no message received";
	alarm 0;
};
## test 14
print $@, "\nnot "
	if $@;
&ok;

## test 15	check expected answer
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
  13	:  0011_1000  0x38   56  8  
  14	:  0000_0001  0x01    1    
  15	:  0011_0111  0x37   55  7  
  16	:  0000_0001  0x01    1    
  17	:  0011_0001  0x31   49  1  
  18	:  0000_0001  0x01    1    
  19	:  0011_0010  0x32   50  2  
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
  54	:  0000_0101  0x05    5    
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

##################################################################

# test 16	check BLOCK BY COUNTRY
$off = newhead(\$msg,
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg,$off,'1.0.0.6.'.$blackz,T_A,C_IN);	# should return 'notfound'

#	send message, should not block
$R_sin = sockaddr_in($port,inet_aton('127.0.0.1'));
$err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	if ($rv = send($R,$msg,0,$R_sin)) {
	  alarm 0;
	  undef;
	} else {
	  die "sent $rv bytes";
	}
};
print $@, "\nnot "
	if $@;
&ok;

## test 17	read message back in 'run'

eval { require Geo::IP::PurePerl };

if ($@) {
  print "ok $test # Skipped, \tGeo::IP::PurePerl is not installed, BBC service unavailable\n";
  ++$test;
  print "ok $test # Skipped, \tGeo::IP::PurePerl is not installed, BBC service unavailable\n";
  ++$test;
  print "ok $test # Skipped, \tGeo::IP::PurePerl is not installed, BBC service unavailable\n";
  ++$test;
} else {
  $DNSBL->{BBC} = ['US'];

  eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	alarm 3;
	$runval = run($blackz,$L,$R,$DNSBL,\%STATS,\$run,$sfile,$statime,$D_CLRRUN);
	alarm 0;
  };

  print $@, "\nnot "
	if $@;
  &ok;

  $msg = undef;
  $err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	recv($R,$msg,512,0) or
		die "no message received";
	alarm 0;
  };
  ## test 18
  print $@, "\nnot "
	if $@;
  &ok;

## test 19	check expected answer
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
  15	:  0011_0000  0x30   48  0  
  16	:  0000_0001  0x01    1    
  17	:  0011_0000  0x30   48  0  
  18	:  0000_0001  0x01    1    
  19	:  0011_0110  0x36   54  6  
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
  54	:  0000_0110  0x06    6    
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

  close $L;
  close $R;
};
