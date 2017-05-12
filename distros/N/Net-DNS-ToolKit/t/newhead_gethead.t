# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..31\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::Codes qw(:constants :header);
use Net::DNS::ToolKit qw(
	newhead
	gethead
	get16
	get1char
	parse_char
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

## test 2	create basic header

my $buffer	= '';
my $id		= 1234;

my %flags = (
	0x8000	=> {	#    id, qd,an,ns,ar
		input	=> [1234,8000,22,33,44],
		expect	=> {
			ID      => 1234,
			QR      => 1,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NOERROR',
			QDCOUNT => 8000,
			ANCOUNT => 22,
			NSCOUNT => 33,
			ARCOUNT => 44,
		},
	},
# 0x4000 purposefully missing

	0x2000	=> {
		input	=> [3456,99,111,2000,222],
		expect	=> {
			ID      => 3456,
			QR      => 0,
			OPCODE  => 'NS_NOTIFY_OP',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NOERROR',
			QDCOUNT => 99,
			ANCOUNT => 111,
			NSCOUNT => 2000,
			ARCOUNT => 222,
		},
	},
	0x1000	=> {
		input	=> [7890,333,444,555,1000],
		expect	=> {
			ID      => 7890,
			QR      => 0,
			OPCODE  => 'STATUS',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NOERROR',
			QDCOUNT => 333,
			ANCOUNT => 444,
			NSCOUNT => 555,
			ARCOUNT => 1000,
		},
	},
	0x0800	=> {
		input	=> [10234,800,666,777,888],
		expect	=> {
			ID      => 10234,
			QR      => 0,
			OPCODE  => 'IQUERY',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NOERROR',
			QDCOUNT => 800,
			ANCOUNT => 666,
			NSCOUNT => 777,
			ARCOUNT => 888,
		},
	},
	0x0400	=> {
		input	=> [56789,999,400,1111,2222],
		expect	=> {
			ID      => 56789,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 1,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NOERROR',
			QDCOUNT => 999,
			ANCOUNT => 400,
			NSCOUNT => 1111,
			ARCOUNT => 2222,
		},
	},
	0x0200	=> {
		input	=> [65432,3333,4444,200,5555],
		expect	=> {
			ID      => 65432,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 1,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NOERROR',
			QDCOUNT => 3333,
			ANCOUNT => 4444,
			NSCOUNT => 200,
			ARCOUNT => 5555,
		},
	},
	0x0100	=> {
		input	=> [54321,6666,7777,8888,100],
		expect	=> {
			ID      => 54321,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 0,
			RD      => 1,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NOERROR',
			QDCOUNT => 6666,
			ANCOUNT => 7777,
			NSCOUNT => 8888,
			ARCOUNT => 100,
		},
	},
	0x0080	=> {
		input	=> [43210,80,9999,11111,22222],
		expect	=> {
			ID      => 43210,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 1,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NOERROR',
			QDCOUNT => 80,
			ANCOUNT => 9999,
			NSCOUNT => 11111,
			ARCOUNT => 22222,
		},
	},
	0x0040	=> {
		input	=> [32109,33333,40,44444,55555],
		expect	=> {
			ID      => 32109,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 1,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NOERROR',
			QDCOUNT => 33333,
			ANCOUNT => 40,
			NSCOUNT => 44444,
			ARCOUNT => 55555,
		},
	},
	0x0020	=> {
		input	=> [21098,8765,7654,20,6543],
		expect	=> {
			ID      => 21098,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 1,
			CD      => 0,
			RCODE   => 'NOERROR',
			QDCOUNT => 8765,
			ANCOUNT => 7654,
			NSCOUNT => 20,
			ARCOUNT => 6543,
		},
	},
	0x0010	=> {
		input	=> [10987,5432,4321,3210,10],
		expect	=> {
			ID      => 10987,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 1,
			RCODE   => 'NOERROR',
			QDCOUNT => 5432,
			ANCOUNT => 4321,
			NSCOUNT => 3210,
			ARCOUNT => 10,
		},
	},
	0x0008	=> {
		input	=> [12121,8,2109,1098,9988],
		expect	=> {
			ID      => 12121,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NXRRSET',
			QDCOUNT => 8,
			ANCOUNT => 2109,
			NSCOUNT => 1098,
			ARCOUNT => 9988,
		},
	},
	0x0004	=> {
		input	=> [23232,7766,4,5544,3322],
		expect	=> {
			ID      => 23232,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'NOTIMP',
			QDCOUNT => 7766,
			ANCOUNT => 4,
			NSCOUNT => 5544,
			ARCOUNT => 3322,
		},
	},
	0x0002	=> {
		input	=> [34343,1100,20202,2,30303],
		expect	=> {
			ID      => 34343,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'SERVFAIL',
			QDCOUNT => 1100,
			ANCOUNT => 20202,
			NSCOUNT => 2,
			ARCOUNT => 30303,
		},
	},
	0x0001	=> {
		input	=> [45454,40404,50505,60606,1],
		expect	=> {
			ID      => 45454,
			QR      => 0,
			OPCODE  => 'QUERY',
			AA      => 0,
			TC      => 0,
			RD      => 0,
			RA      => 0,
			Z       => 0,
			AD      => 0,
			CD      => 0,
			RCODE   => 'FORMERR',
			QDCOUNT => 40404,
			ANCOUNT => 50505,
			NSCOUNT => 60606,
			ARCOUNT => 1,
		},
	},
);

#	 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
#	+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
#	|QR|   Opcode  |AA|TC|RD|RA| Z|AD|CD|   Rcode   |
#	+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
#	  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15

foreach my $flags (sort { $b <=> $a } keys %flags) {
  my $buffer = '';
  my($id,$qdcount,$ancount,$nscount,$arcount) = @{$flags{$flags}->{input}};
  print "bad offset $_\nnot "
    unless ($_ = newhead(\$buffer,$id,$flags,$qdcount,$ancount,$nscount,$arcount));
  &ok;
  
  my($offset,$ID,$QR,$OPCODE,$AA,$TC,$RD,$RA,$Z,$AD,$CD,$RCODE,
	$QDCOUNT,$ANCOUNT,$NSCOUNT,$ARCOUNT) = gethead(\$buffer);
  print 
"ID	=> $ID
QR	=> $QR
OPCODE	=> ",OpcodeTxt->{$OPCODE},"
AA	=> $AA
TC	=> $TC
RD	=> $RD
RA	=> $RA
Z	=> $Z
AD	=> $AD
CD	=> $CD
RCODE	=> ",RcodeTxt->{$RCODE},"
QDCOUNT	=> $QDCOUNT
ANCOUNT	=> $ANCOUNT
NSCOUNT	=> $NSCOUNT
ARCOUNT	=> $ARCOUNT
not " unless 
	$ID		== $id &&
	$flags{$flags}->{expect}->{QR}	   == $QR &&
	$flags{$flags}->{expect}->{OPCODE} eq OpcodeTxt->{$OPCODE} &&
	$flags{$flags}->{expect}->{AA}	   == $AA &&
	$flags{$flags}->{expect}->{TC}	   == $TC &&
	$flags{$flags}->{expect}->{RD}	   == $RD &&
	$flags{$flags}->{expect}->{RA}	   == $RA &&
	$flags{$flags}->{expect}->{Z}	   == $Z &&
	$flags{$flags}->{expect}->{AD}	   == $AD &&
	$flags{$flags}->{expect}->{CD}	   == $CD &&
	$flags{$flags}->{expect}->{RCODE}  eq RcodeTxt->{$RCODE} &&
	$QDCOUNT	== $qdcount &&
	$ANCOUNT	== $ancount &&
	$NSCOUNT	== $nscount &&
	$ARCOUNT	== $arcount;
  &ok;
}


#foreach (0..HFIXEDSZ -1) {
#  my $off = $_;
#  my $char = get1char(\$buffer,$off);
#  @x = parse_char($char);
#  print "$_\t:  ";
#  foreach(@x) {
#    print "$_  ";
#  }
#  print "\n";
#}
