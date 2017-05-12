# $Id: 06-packet-unique-push.t 1561 2017-04-19 13:08:13Z willem $

use strict;

BEGIN {
	use Test::More tests => 45;

	use_ok('Net::DNS');
}


# Matching of RR name is not case sensitive
my $domain = 'example.com';
my $method = 'unique_push';
my $packet = Net::DNS::Packet->new($domain);

my $rr_1 = Net::DNS::RR->new('bla.foo 100 IN TXT "text" ;lower case');
my $rr_2 = Net::DNS::RR->new('bla.Foo 100 IN Txt "text" ;mixed case');
my $rr_3 = Net::DNS::RR->new('bla.foo 100 IN TXT "mixed CASE"');
my $rr_4 = Net::DNS::RR->new('bla.foo 100 IN TXT "MIXED case"');

$packet->unique_push( "answer", $rr_1 );
$packet->unique_push( "answer", $rr_2 );
is( $packet->header->ancount, 1, "unique_push  case sensitivity test 1" );

$packet->unique_push( "answer", $rr_3 );
$packet->unique_push( "answer", $rr_4 );
is( $packet->header->ancount, 3, "unique_push  case sensitivity test 2" );


my %sections = (
	answer	   => 'ancount',
	authority  => 'nscount',
	additional => 'arcount',
	);

my @tests = (
	[	1,
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.1'),
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.1'),
		],
	[	2,
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.1'),
		Net::DNS::RR->new('bar.example.com 60 IN A 192.0.2.1'),
		],
	[	1,
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.1'),
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.1'),
		Net::DNS::RR->new('foo.example.com 90 IN A 192.0.2.1'),
		],
	[	3,
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.1'),
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.2'),
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.3'),
		],
	[	3,
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.1'),
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.2'),
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.3'),
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.1'),
		],
	[	3,
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.1'),
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.2'),
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.1'),
		Net::DNS::RR->new('foo.example.com 60 IN A 192.0.2.4'),
		Net::DNS::RR->new('foo.example.com 60 HS A 192.0.2.4'),
		],
	[	3,
		Net::DNS::RR->new('foo.example.com IN A'),
		Net::DNS::RR->new('foo.example.com ANY A'),
		Net::DNS::RR->new('foo.example.com NONE A'),
		],
	);


foreach my $test (@tests) {
	my ( $expect, @rrs ) = @$test;

	while ( my ( $section, $count_meth ) = each %sections ) {

		my $packet = new Net::DNS::Update($domain);

		$packet->$method( $section => @rrs );

		my $count = $packet->header->$count_meth();
		is( $count, $expect, "$method  $section	=> RR, RR, ..." );

	}

	#
	# Now do it again, pushing each RR individually.
	#
	while ( my ( $section, $count_meth ) = each %sections ) {

		my $packet = new Net::DNS::Update($domain);

		foreach my $rr (@rrs) {
			$packet->$method( $section => $rr );
		}

		my $count = $packet->header->$count_meth();
		is( $count, $expect, "$method  $section	=> RR" );
	}
}

