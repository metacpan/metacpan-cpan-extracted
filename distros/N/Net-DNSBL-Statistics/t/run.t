# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 21;

BEGIN { $| = 1; use_ok(Net::DNSBL::Statistics, qw(run)); }

#use diagnostics;
use Socket;
use Net::DNSBL::Utilities qw(
	open_udpNB
);
use Net::DNS::ToolKit qw(
        newhead
        gethead
        get1char
);
use Net::DNS::ToolKit::Utilities qw(
	id
	revIP
);
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit::RR;
use Net::DNS::ToolKit::Debug qw(
        print_head
        print_buf
);

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

require './recurse2txt';

select STDERR;
$| = 1;
select STDOUT;
$| = 1;

#sub ok {
#  my $comment = $_[0] || '';
#  print "ok $test $comment\n";
#  ++$test;
#}

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

sub gotexp {
  my($got,$exp,$txt) = @_;
  $txt = '' unless $txt;
  my $fail;
  if ($exp =~ /\D/) {
    $fail = 1 unless ($got eq $exp);
  } else {  
    $fail = 1 unless ($got == $exp);
  }
  SKIP: {
	skip "got: $got, exp: $exp",1 if $fail;
	pass($txt);
  };
}

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
 
#sub chk_exp {
#  my($bp,$exp) = @_;
#  my $todo = '';
#  my @expect = expect($$exp);
#  foreach(0..length($$bp) -1) {
#    $char = get1char($bp,$_);
#    next if $char == $expect[$_];
#    print "buffer mismatch $_, got: $char, exp: $expect[$_]\n ";
#    $todo = '# TODO: fix test for marginal dn_comp resolver implementations';
#    last;
#  }
#  SKIP: {
#	skip $todo,1 if $todo;
#	pass;
#  };
#}

my $dir = './tmp';
mkdir $dir,0755;  
my $ipfile = $dir .'/ips.tmp';

my $conf = {
	FILES	=> $ipfile,
	IGNORE	=> [qw(
		1.1.1.2
		1.1.1.3
	)],
	GENERIC	=> {
		ignore	=> ['dsl-only','static'],
		regexp	=> [
			'\d+[a-zA-Z_\-\.]\d+[a-zA-Z_\-\.]\d+[a-zA-Z_\-\.]\d+|\d{12}',
			'\d+\.\d+\.broadband',
		],
		timeout	=> 2,
	},
	'in-addr.arpa'	=> {
		timeout	=> 2,
	},
	'dead.dnsbl'	=> {
		timeout => 2,
	},
	'live1.dnsbl'	=> {
		accept	=> {
			'127.0.0.2'	=> 'proxy',
			'127.0.0.3'	=> 'relay',
		},
		timeout	=> 2,
	},
	'live2.dnsbl'	=> {
		accept	=> {
			'127.0.0.4'	=> 'spammer',
			'127.0.0.5'	=> 'dynamic',
		},
		timeout => 2,
	},
};

my $response = {
	'1.1.1.1'	=> {
		'in-addr.arpa'	=> {
			code	=> NOERROR,
			resp	=> '1.1.1.1.dsl-only',
		},
		'live1.dnsbl'	=> {
			code	=> NXDOMAIN,
		},
		'live2.dnsbl'	=> {
			code	=> SERVFAIL,
		},
	},
	'1.1.1.2'	=> {			# this should never be used
		'in-addr.arpa'	=> {
			code	=> NXDOMAIN,
		},
		'live2.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> '127.0.0.3',
		},
		'live2.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> '127.0.0.5',
		},
	},
	'1.1.1.3'	=> {			# this should never be used
		'in-addr.arpa'	=> {
			code	=> NXDOMAIN,
		},
		'live2.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> '127.0.0.2',
		},
		'live2.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> '127.0.0.4',
		},
	},
	'1.1.1.4'	=> {
		'in-addr.arpa'	=> {
			code	=> SERVFAIL,
		},
		'live1.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> ['127.0.0.1','127.0.0.2'],
		},
		'live2.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> ['1.2.3.4','5.6.7.8'],
		},
	},
	'1.1.1.5'	=> {
		# no in-addr.arpa, let it timeout
		'live1.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> ['2.3.4.5','3.4.5.6'],
		},
		# no live2, timeout instead
	},
	'1.1.1.6'	=> {
		'in-addr.arpa'	=> {
			code	=> NOERROR,
			resp	=> '123456789012.mydomain.com',
		},
		'live1.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> '127.0.0.3',
		},
		'live2.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> '127.0.0.5',
		},
	},
	'1.1.1.7'	=> {
		'in-addr.arpa'	=> {
			code	=> NOERROR,
			resp	=> ['1.1.1.7.mydomain.com','1.1.1.7.static.stuff.com'],
		},
		'live1.dnsbl'	=> {
			code	=> NXDOMAIN,
		},
		'live2.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> ['1.1.1.7','127.0.0.4'],
		},
	},
	'1.1.1.8'	=> {
		'in-addr.arpa'	=> {
			code	=> NOERROR,
			resp	=> ['123.56.broadband.net'],
		},	
		'live1.dnsbl'	=> {
			code	=> NOERROR,
			resp	=> '127.0.0.2',
		},
		'live2.dnsbl'	=> {
			code	=> SERVFAIL,
		},
	},
	'1.1.1.9'	=> {
		'in-addr.arpa'	=> {
			code	=> NOERROR,
			resp	=> ['123.45.broadband.net','random.name.com'],
		},
		'live2.dnsbl'	=> {
			code	=> NXDOMAIN,
		},
	},
	'1.1.1.0'	=> {
		'in-addr.arpa'	=> {
			code	=> NXDOMAIN,
		},
	},
};

open(T,'>'. $ipfile) or die "could not open temporary file for testing\n";
foreach(sort keys %$response) {
  print T $_,"\n";
}
close T;

## test 2	open listening port
my $L = open_udpNB();
ok($L,'open local unbound socket');

## test 3	bind a listner for testing
my $port;   
foreach(10000..10100) {         # find a port to bind to
  if (bind($L,sockaddr_in($_,INADDR_LOOPBACK))) {
    $port = $_;
    last;
  }
}
ok($port,'bind a port for remote');

my $L_sin = sockaddr_in($port,INADDR_LOOPBACK);

## test 4	open sending socket
my $R = open_udpNB();
ok($R,'open unbound send socket');

my $Alarm = 150;
my $kid = fork;
unless ($kid) {	# parent see's kid

  close $R;

  $Alarm *= 5;
  eval {
	my $run = 1;
	local $SIG{ALRM} = sub {die "child died"};
	local $SIG{TERM} = sub { $run = 0 };

	my($get,$put,$parse) = new Net::DNS::ToolKit::RR;
	my($msg,$recvfrom);

	my $fileno = fileno($L);
	my($rin,$rout,$win,$wout,@sndQ);
	my $vin = '';
	vec($vin,$fileno,1) = 1;

	alarm $Alarm;

	while ($run) {
	  $rin = $vin;
	  if (@sndQ) {
	    $win = $vin;
	  } else {
	    $win = '';
	  }
	  my $nfound = select($rout=$rin,$wout=$win,undef,0.2);
	  next unless $nfound > 0;
	  if (vec($wout,$fileno,1) && @sndQ) {
	    $msg = shift @sndQ;
	    $recvfrom = shift @sndQ;
	    send($L,$msg,0,$recvfrom);
	  }
	  next unless vec($rout,$fileno,1);
	  undef $msg;
	  $recvfrom = recv($L,$msg,512,0);
#print STDERR "RECEIVE\n";
#print_buf(\$msg);
#print STDERR "\n";
# we'll assume that a lot of checking is not necessary for the received message
	  my($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,$qdcount,$ancount,$nscount,$arcount) = gethead(\$msg);
	  ($off,my($name,$type,$class)) = $get->Question(\$msg,$off);
	  $name =~ /(\d+\.\d+\.\d+\.\d+)\.(.+)$/;
	  my $zone = $2;
	  my $ip = revIP($1);
	  next unless exists $response->{"$ip"};
	  next unless exists $response->{"$ip"}->{"$zone"};
	  my(@dnptrs,@answers);
	  if($response->{"$ip"}->{"$zone"}->{code} == NOERROR) {
	    next unless exists $response->{"$ip"}->{"$zone"}->{resp} &&
		$response->{"$ip"}->{"$zone"}->{resp};
	    if (ref $response->{"$ip"}->{"$zone"}->{resp}) {
	      @answers = @{$response->{"$ip"}->{"$zone"}->{resp}};
	    } else {
	      @answers = ($response->{"$ip"}->{"$zone"}->{resp});
	    }
	    $ancount = @answers;
	    $off = newhead(\$msg,
		$id,
		BITS_QUERY | QR,
		$qdcount,$ancount,0,0);
	    ($off,@dnptrs) = $put->Question(\$msg,$off,$name,$type,$class);
	    foreach my $ans (@answers) {
	      if ($type == T_A) {
		($off,@dnptrs)=$put->A(\$msg,$off,\@dnptrs,$name,$type,$class,98765,inet_aton($ans));
	      } else { # type must be PTR
		($off,@dnptrs)=$put->PTR(\$msg,$off,\@dnptrs,$name,$type,$class,98765,$ans);
	      }
	    }
	  } else {	# is an error response
	    $off = newhead(\$msg,
		$id,
		BITS_QUERY | QR | $response->{"$ip"}->{"$zone"}->{code},
		1,0,0,0);
	    ($off) = $put->Question(\$msg,$off,$name,$type,$class);
	  }
#print STDERR "SEND\n";
#print_head(\$msg);
#print STDERR "\n";
#print_buf(\$msg);
#print STDERR "\n";
	  push @sndQ, $msg, $recvfrom;
	}
	alarm 0;
  };
  exit;
} # end kid

# parent
close $L;
id(1);		# seed ID's

## test 5	dnsbls array
my @rv;
next_sec();
eval {
	local $SIG{ALRM} = sub {die "timeout"};
	alarm $Alarm;
	@rv = run($conf,$R,$L_sin,20);
	alarm 0;
};
ok(!$@,$@ || 'dnsbls array');

my %dnsbls = @rv;

## test 6	check total IP count
my $exp = 8;
my $total = $dnsbls{TOTAL}->{C};
SKIP: {
	skip "got: $total, exp: $exp",1 unless $total == $exp;
	pass('total IP count');
};

## test 7	check array values
$exp = q|17	= {
	'GENERIC'	=> {
		'C'	=> 2,
	},
	'TOTAL'	=> {
		'C'	=> 8,
	},
	'UNION'	=> {
		'C'	=> 6,
	},
	'dead.dnsbl'	=> {
		'C'	=> 0,
		'TO'	=> 7,
	},
	'in-addr.arpa'	=> {
		'C'	=> 3,
	},
	'live1.dnsbl'	=> {
		'C'	=> 3,
		'TO'	=> 1,
	},
	'live2.dnsbl'	=> {
		'C'	=> 2,
		'TO'	=> 0,
	},
};
|;
gotexp(Dumper(\%dnsbls),$exp,'array values');

## test 8	check send counts
next_sec();

eval {
	local $SIG{ALRM} = sub {die "timeout"};
	alarm $Alarm;
	@rv = run($conf,$R,$L_sin,5);
	alarm 0;
};
ok(!$@,$@ || 'send counts');

## test 9	check count values
my %qc = @rv;
$exp = q|4	= {
	'generic'	=> 0,
	'in-addr'	=> 8,
	'regular'	=> 23,
	'retry-r'	=> 11,
};
|;
gotexp(Dumper(\%qc),$exp,'count values');

## test 10	check union counts
next_sec();

eval {
	local $SIG{ALRM} = sub {die "timeout"};
	alarm $Alarm;
	@rv = run($conf,$R,$L_sin,4);
	alarm 0;
};
ok(!$@,$@ || 'union counts');

sub ufix {
  my $union = shift;
  @_ = keys %$union;
  my $min = $union->{$_[0]};		# pick one
  foreach(@_) {
    $min = $union->{"$_"}
	if $union->{"$_"} < $min;
  }
  foreach(@_) {
    $union->{"$_"} -= $min;
  }
}

## test 11	check count values
my %union = @rv;
ufix(\%union);
$exp = q|6	= {
	'0.1.1.1'	=> 0,
	'4.1.1.1'	=> 0,
	'5.1.1.1'	=> 6,
	'6.1.1.1'	=> 4,
	'7.1.1.1'	=> 4,
	'8.1.1.1'	=> 6,
};
|;
gotexp(Dumper(\%union),$exp,'count values');

#################################
### repeat without 'in-addr.arpa'
#################################

delete $conf->{'in-addr.arpa'};

## test 12	dnsbls array
next_sec();
eval {
	local $SIG{ALRM} = sub {die "timeout"};
	alarm $Alarm;
	@rv = run($conf,$R,$L_sin,20);
	alarm 0;
};
ok(!$@,$@ || 'dnsbls array');

%dnsbls = @rv;
$total = $dnsbls{TOTAL}->{C};
## test 13	check total IP count
$exp = 8;
SKIP: {
	skip "got: $total, exp: $exp",1 unless ($total == $exp);
	pass('total IP count');
};

## test 14	check array values
$exp = q|15	= {
	'GENERIC'	=> {
		'C'	=> 2,
	},
	'TOTAL'	=> {
		'C'	=> 8,
	},
	'UNION'	=> {
		'C'	=> 4,
	},
	'dead.dnsbl'	=> {
		'C'	=> 0,
		'TO'	=> 8,
	},
	'live1.dnsbl'	=> {
		'C'	=> 3,
		'TO'	=> 1,
	},
	'live2.dnsbl'	=> {
		'C'	=> 2,
		'TO'	=> 0,
	},
};
|;
gotexp(Dumper(\%dnsbls),$exp,'array values');

## test 15	check send counts
next_sec();

eval {
	local $SIG{ALRM} = sub {die "timeout"};
	alarm $Alarm;
	@rv = run($conf,$R,$L_sin,5);
	alarm 0;
};
ok(!$@,$@ || 'send counts');

## test 16	check count values
%qc = @rv;
$exp = q|4	= {
	'generic'	=> 1,
	'in-addr'	=> 8,
	'regular'	=> 24,
	'retry-r'	=> 12,
};
|;
gotexp(Dumper(\%qc),$exp,'count values');

## test 17	check union counts
next_sec();

eval {
	local $SIG{ALRM} = sub {die "timeout"};
	alarm $Alarm;
	@rv = run($conf,$R,$L_sin,4);
	alarm 0;
};
ok(!$@,$@ || 'union counts');

## test 18	check count values
%union = @rv;
ufix(\%union);
$exp = q|4	= {
	'4.1.1.1'	=> 0,
	'6.1.1.1'	=> 4,
	'7.1.1.1'	=> 4,
	'8.1.1.1'	=> 4,
};
|;
gotexp(Dumper(\%union),$exp,'count values');

############ re-run without debug
## test 19	dnsbls array
next_sec();
eval {
	local $SIG{ALRM} = sub {die "timeout"};
	alarm $Alarm;
	@rv = run($conf,$R,$L_sin);
	alarm 0;
};
ok(!$@,$@ || 'dnsbls array');

%dnsbls = @rv;
$total = $dnsbls{TOTAL};
## test 20	check total IP count
$exp = 8;
SKIP: {
	skip "got: $total, exp: $exp",1 unless ($total == $exp);
	pass('total IP count');
};

## test 21	check array values
$exp = q|6	= {
	'GENERIC'	=> 2,
	'TOTAL'	=> 8,
	'UNION'	=> 4,
	'dead.dnsbl'	=> 0,
	'live1.dnsbl'	=> 3,
	'live2.dnsbl'	=> 2,
};
|;
gotexp(Dumper(\%dnsbls),$exp,'array values');

close $R;
kill 15, $kid;
