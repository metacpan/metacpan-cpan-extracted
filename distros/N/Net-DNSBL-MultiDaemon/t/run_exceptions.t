# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..77\n"; }
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

my $off = newhead(\$msg,
        12345,
        BITS_QUERY,
        1,0,0,0);

chop $msg;	# make messages one byte short

## test 8	send message, should not block
my $R_sin = sockaddr_in($port,inet_aton('127.0.0.1'));
my $err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	if (($rv = send($R,$msg,0,$R_sin)) && $rv == &HFIXEDSZ -1) {
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

my $blackz = 'blackzone.tst';
$DNSBL->{'domain1.com'}->{timeout} = 3;
$DNSBL->{'domain2.net'}->{timeout} = 3;	# udp timeout
my $run = 5;
my $runval;
eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	alarm 3;
	$runval = run($blackz,$L,$R,$DNSBL,\%STATS,\$run,$sfile,$statime,$D_SHRTHD | $D_QRESP);
	alarm 0;
};

print $@, "\nnot "
	if $@;
&ok;

## test 10	return value should be 'short header'
print "got $runval, exp: short header\nnot "
	unless $runval eq 'short header';
&ok;

## test 11	send a bogus message with QR turned on
$off = newhead(\$msg,
        12345,
        BITS_QUERY | QR,	# bogus query response
        1,0,0,0);

$err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	if (($rv = send($R,$msg,0,$R_sin)) && $rv == &HFIXEDSZ) {
	  alarm 0;
	  undef;
	} else {
	  die "sent $rv bytes";
	}
};
print $@, "\nnot "
	if $@;
&ok;

## test 12	check for query response returned
eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	alarm 3;
	$runval = run($blackz,$L,$R,$DNSBL,\%STATS,\$run,$sfile,$statime,$D_SHRTHD | $D_QRESP);
	alarm 0;
};

print $@, "\nnot "
	if $@;
&ok;

## test 13	check return value
print "got: $runval, exp: query response\nnot "
	unless $runval eq 'query response';
&ok;

################
## test 14-77	check various stats's, this is 4 tests x 16
### set up a series of bad messages
my @msg;
my @exp_rcode;

newhead(\$msg[0],	# 14-17
        12345,
	BITS_STATUS,	# something besides BITS_QUERY
        1,0,0,0);
$exp_rcode[0] = &NOTIMP;

newhead(\$msg[1],	# 18-21
        12345,
        BITS_QUERY,
        0,0,0,0);	# no question
$exp_rcode[1] = &FORMERR;

newhead(\$msg[2],	# 22-25
        12345,
        BITS_QUERY,
        0,1,0,0);
$exp_rcode[2] = &FORMERR;

newhead(\$msg[3],	# 26-29
        12345,
        BITS_QUERY,
        0,0,1,0);
$exp_rcode[3] = &FORMERR;

newhead(\$msg[4],	# 30-33
        12345,
        BITS_QUERY,
        0,0,0,1);
$exp_rcode[4] = &FORMERR;

$off = newhead(\$msg[5], # 34-37
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[5],$off,'',T_A,C_IN);	# name will fail with null value
$exp_rcode[5] = &FORMERR;

$off = newhead(\$msg[6], # 38-41
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[6],$off,$blackz,T_A,C_HS);	# bad class
$exp_rcode[6] = &REFUSED;

$off = newhead(\$msg[7], # 42-45
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[7],$off,$blackz.'trash',T_A,C_IN);	# not our zone
$exp_rcode[7] = &NXDOMAIN;

### tests begin for THIS IS OUR ZONE
### in the order it appears in the code
### excluding the bl_lookup

$off = newhead(\$msg[8], # 46-49
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[8],$off,'x.'.$blackz,T_A,C_IN);	# not rev ip lookup
$exp_rcode[8] = &NXDOMAIN;

$off = newhead(\$msg[9], # 50-53
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[9],$off,$blackz,T_AXFR,C_IN);	# not allowed type
$exp_rcode[9] = &REFUSED;

$off = newhead(\$msg[10], # 54-57
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[10],$off,'1.2.3.4'.$blackz,T_NS,C_IN);	# type NS, etc...
$exp_rcode[10] = &NXDOMAIN;

$off = newhead(\$msg[11], # 58-61
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[11],$off,$blackz,T_MX,C_IN);
$exp_rcode[11] = &NXDOMAIN;

$off = newhead(\$msg[12], # 62-65
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[12],$off,$blackz,T_SOA,C_IN);
$exp_rcode[12] = &NXDOMAIN;

$off = newhead(\$msg[13], # 66-69
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[13],$off,$blackz,T_CNAME,C_IN);
$exp_rcode[13] = &NXDOMAIN;

$off = newhead(\$msg[14], # 70-73
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[14],$off,$blackz,T_TXT,C_IN);
$exp_rcode[14] = &NXDOMAIN;

$off = newhead(\$msg[15], # 74-77
        12345,
        BITS_QUERY,
        1,0,0,0);
$put->Question(\$msg[15],$off,$blackz,T_IXFR,C_IN);	# unknown type
$exp_rcode[15] = &NOTIMP;

my $now = &next_sec();

my $i;
foreach $i (0..$#msg) {
## t1
# send the message
  $err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	if (($rv = send($R,$msg[$i],0,$R_sin)) && $rv >= &HFIXEDSZ) {
	  alarm 0;
	  undef;
	} else {
	  die "sent $rv bytes";
	}
  };
  print $@, "\nnot "
	if $@;
  &ok;

# decode and hopefully send a response
  $now = &next_sec();
  eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	alarm 3;
	$runval = run($blackz,$L,$R,$DNSBL,\%STATS,\$run,$sfile,$statime,$D_SHRTHD | $D_QRESP | $D_CLRRUN);
	alarm 0;
  };
## t2
  print $@, "\nnot "
	if $@;
  &ok;

  $err = eval {
	local $SIG{ALRM} = sub {die "blocked, timeout"};
	my $rv;
	alarm 2;
	recv($R,$msg,512,0) or
		die "no message received";
	alarm 0;
  };
## t3
  print $@, "\nnot "
	if $@;
  &ok;
  my ($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$msg);
#print_head(\$msg);

## t4
  if ($exp_rcode[$i] == &NOERROR) {		# not found??
    my ($name,$type,$class,$ttl,$rdlength,$mname,$rname,$serial,$refresh,$retry,$expire,$min,$RIP);
    unless ($rcode == &NOERROR) {
      print 'got: ',RcodeTxt->{$rcode},", exp: NOERROR\nnot ";
    }
    elsif ($qr != 1) {
      print "got: QR=$qr, exp: 1\nnot ";
    }
    elsif ($qdcount != 1) {
      print "got: qdcount=$qdcount, exp: 1\nnot ";
    }
    elsif ($ancount) {
      print "got: ancount=$ancount, exp: 0\nnot ";
    }
    elsif ($nscount != 1) {
      print "got: nscount=$nscount, exp: 1\nnot ";
    }
    elsif ($arcount) {
      print "got: arcount=$arcount, exp: 0\nnot ";
    }
    elsif ((($off,$name,$type,$class) = $get->Question(\$msg,$off)) &&
	$name !~ /$blackz$/i && ($RIP = $`)) {	# set RIP as a side effect on normal failure
      print "not my zone, got: $name, exp: $blackz\nnot ";
    }
    elsif (($type == T_A || $type == T_ANY) && $RIP && $RIP =~/d+\.\d+\.\d+\.\d+/) {
      print "unexpected T_A or T_ANY question $&.$blackz\nnot ";
    }
    elsif ( ! ( $type == T_A || $type == T_ANY) &&
	    ! (	$type == T_NS ||
		$type == T_MX ||
		$type == T_SOA ||
		$type == T_CNAME ||
		$type == T_TXT)) {
      print 'unexpected type: ', TypeTxt->{$type}, "\nnot ";
    }
    elsif ((($off,$name,$type,$class,$ttl,$rdlength,
		$mname,$rname,$serial,$refresh,$retry,$expire,$min)
		= $get->SOA(\$msg,$off)) &&
	     $name ne $blackz) {
      print "SOA zonename: $name, exp: $blackz\nnot ";
    }
    elsif ($type != &T_SOA) {
      print "bad SOA response, got: ",TypeTxt->{$type},", exp: T_SOA\nnot ";
    }
    elsif ($class != &C_IN) {
      print "got: ", ClassTxt->{$class},", exp: C_IN\nnot ";
    }
    elsif ($mname ne 'localhost') {
      print "got: $mname, exp: localhost\nnot ";
    }
    elsif ($rname ne 'root.localhost') {
      print "got: $rname, exp: root.localhost\nnot ";
    }
    elsif ($serial != $now) {
      print "got serial: $serial, exp: $now\nnot ";
    }
    elsif ($refresh != 86400) {
      print "got refresh: $refresh, exp: 86400\nnot ";
    }
    elsif ($retry != 86401) {
      print "got retry: $retry, exp: 86401\nnot ";
    }
    elsif ($expire != 86402) {
      print "got expire: $expire, exp: 86402\nnot ";
    }
    elsif ($min != 86403) {
      print "got minimum: $min, exp: 86403\nnot ";
    }
    &ok;
  } else {				# rcode error
    print 'got: ',RcodeTxt->{$rcode},', exp: ', RcodeTxt->{$exp_rcode[$i]},"\nnot "
	unless $rcode == $exp_rcode[$i];
    &ok;
  }
}

close $L;
close $R;
