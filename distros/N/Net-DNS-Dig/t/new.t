# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit qw(
	inet_aton
);
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

# name server setting is tested elsewhere
Net::DNS::Dig::_set_NS(inet_aton('12.34.56.78'),inet_aton('97.65.43.21'));

# test 2
my $dig = new Net::DNS::Dig;
my $exp = q|11	= {
	'Class'	=> 'IN',
	'PeerAddr'	=> ['12.34.56.78','97.65.43.21',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'97.65.43.21'	=> 'aA+',
	},
};
|;
my $got = Dumper($dig);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 3
my $d2 = $dig->new();
$d2->{XXX} = 'xxx';
$exp = q|12	= {
	'Class'	=> 'IN',
	'PeerAddr'	=> ['12.34.56.78','97.65.43.21',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'XXX'	=> 'xxx',
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'97.65.43.21'	=> 'aA+',
	},
};
|;
$got = Dumper($d2);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 4
$dig = $d2->new( array	=> 'context' );
$exp = q|12	= {
	'Class'	=> 'IN',
	'PeerAddr'	=> ['12.34.56.78','97.65.43.21',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'97.65.43.21'	=> 'aA+',
	},
	'array'	=> 'context',
};
|;
$got = Dumper($dig);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 5
my %ddd = ( scalar	=> 'context' );
$dig = $d2->new(\%ddd);
$exp = q|12	= {
	'Class'	=> 'IN',
	'PeerAddr'	=> ['12.34.56.78','97.65.43.21',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'97.65.43.21'	=> 'aA+',
	},
	'scalar'	=> 'context',
};
|;
$got = Dumper($dig);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 6
$dig = $d2->new( 
	PeerAddr => [qw( 4.3.2.1  8.7.6.5 )]
);
$exp = q|11	= {
	'Class'	=> 'IN',
	'PeerAddr'	=> ['4.3.2.1','8.7.6.5',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'_SS'	=> {
		'4.3.2.1'	=> '',
		'8.7.6.5'	=> '',
	},
};
|;
$got = Dumper($dig);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 7
$dig = $d2->new( PeerPort => 1234 );
$exp = q|11	= {
	'Class'	=> 'IN',
	'PeerAddr'	=> ['12.34.56.78','97.65.43.21',],
	'PeerPort'	=> 1234,
	'Proto'	=> 'UDP',
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'97.65.43.21'	=> 'aA+',
	},
};
|;
$got = Dumper($dig);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 8
$dig = $d2->new( Timeout => 4567 );
$exp = q|11	= {
	'Class'	=> 'IN',
	'PeerAddr'	=> ['12.34.56.78','97.65.43.21',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'Recursion'	=> 256,
	'Timeout'	=> 4567,
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'97.65.43.21'	=> 'aA+',
	},
};
|;
$got = Dumper($dig);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 9
$dig = $d2->new( Class => 'in' );
$exp = q|11	= {
	'Class'	=> 'IN',
	'PeerAddr'	=> ['12.34.56.78','97.65.43.21',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'97.65.43.21'	=> 'aA+',
	},
};
|;
$got = Dumper($dig);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 10
$dig = eval {
	$d2->new( Class => 'chaos' );
};
print "failed to detect invalid Class 'chaos'\nnot "
	unless $@ && $@ =~ /CHAOS/;
&ok;

# test 11
$dig = $d2->new( Proto => 'tcp' );
$exp = q|11	= {
	'Class'	=> 'IN',
	'PeerAddr'	=> ['12.34.56.78','97.65.43.21',],
	'PeerPort'	=> 53,
	'Proto'	=> 'TCP',
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'97.65.43.21'	=> 'aA+',
	},
};
|;
$got = Dumper($dig);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 12
$dig = $d2->new( Proto => 'udp' );
$exp = q|11	= {
	'Class'	=> 'IN',
	'PeerAddr'	=> ['12.34.56.78','97.65.43.21',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'Recursion'	=> 256,
	'Timeout'	=> 15,
	'_SS'	=> {
		'12.34.56.78'	=> '"8N',
		'97.65.43.21'	=> 'aA+',
	},
};
|;
$got = Dumper($dig);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 13
$dig = eval {
	$d2->new( Proto => 'xyz' );
};
print "failed to detect invalid Proto 'xyz'\nnot "
	unless $@ && $@ =~ /XYZ/;
&ok;
