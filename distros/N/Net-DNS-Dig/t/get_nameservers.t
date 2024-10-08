
# Before ake install' is performed this script should be runnable with
# ake test'. After ake install' it should work as erl test.pl'

#	get_nameservers.t
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {	$| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use NetAddr::IP::InetBase qw(
	inet_aton
	inet_ntoa
	ipv6_aton
	ipv6_ntoa
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

my %fakename = (
	fakename	=> ipv6_aton('DEAD::beef'),
	'8765::'		=> ipv6_aton('8765::'),
);

{
  undef local $^W;
  $Net::DNS::Dig::{ndd_gethostbyname} = sub {
	undef local $^W;
	inet_aton($_[0]);
  };

  $Net::DNS::Dig::{ndd_gethostbyname2} = sub {
	return $fakename{$_[0]} if exists $fakename{$_[0]};
	return undef;
  };
}

*getnameservers = \&Net::DNS::Dig::_get_nameservers;

## test 2	with PeerAddrs	as a scalar
my $obj = {};
my $exp = q|4	= {
	'PeerAddr'	=> ['1.2.3.4',],
	'_SS'	=> {
		'1.2.3.4'	=> '',
	},
};
|;
$obj->{PeerAddr} = '1.2.3.4';
getnameservers($obj);
my $got = Dumper($obj);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 3	with unknown PeerAddr
$obj = {};
$exp = q|3	= {
	'PeerAddr'	=> ['unknown',],
	'_SS'	=> {
	},
};
|;
$obj->{PeerAddr} = 'unknown';
getnameservers($obj);
$got = Dumper($obj);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 4	array context
$obj = {};
$exp = q|9	= {
	'PeerAddr'	=> ['unknown','fakename','5.6.7.8','8765::',],
	'_SS'	=> {
		'5.6.7.8'	=> '',
		'8765::'	=> '�e              ',
		'fakename'	=> 'ޭ            ��',
	},
};
|;
$obj->{PeerAddr} = ['unknown','fakename','5.6.7.8','8765::'];
getnameservers($obj);
$got = Dumper($obj);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 5	check number and value of host names
$exp = '5.6.7.8,8765::,fakename';
$got = join(',',sort keys %{$obj->{_SS}});
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 6 - 8	check host IP values
my @exp = ('5.6.7.8','8765::','dead::beef');
my $i = 0;
foreach (sort keys %{$obj->{_SS}}) {
  my $v = length($obj->{_SS}->{$_}) == 4
	? inet_ntoa($obj->{_SS}->{$_})
	: ipv6_ntoa($obj->{_SS}->{$_});
  print "got: $v\nexp: $exp[$i]\nnot "
	unless $v = $exp[$i];
  $i++;
  &ok;
}

## test 9	check use of default
Net::DNS::Dig::_set_NS(inet_aton('127.3.4.5'),ipv6_aton('BeEf::DeAd'));
$obj = {};
$exp = q|6	= {
	'PeerAddr'	=> ['127.3.4.5','beef::dead',],
	'_SS'	=> {
		'127.3.4.5'	=> '',
		'beef::dead'	=> '��            ޭ',
	},
};
|;
getnameservers($obj);
$got = Dumper($obj);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

## test 10 - 11	check rv's
foreach(sort keys %{$obj->{_SS}}) {
  $exp = $_;
  $got = length($obj->{_SS}->{$_}) == 4
	? inet_ntoa($obj->{_SS}->{$_})
	: ipv6_ntoa($obj->{_SS}->{$_});
  print "got: $got, exp: $exp\nnot "
	unless $got eq $exp;
  &ok;
}
