# $Id: 35-NSEC3-match.t 1561 2017-04-19 13:08:13Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Digest::SHA
		Net::DNS::RR::NSEC3
		);

foreach my $package (@prerequisite) {
	next if eval "use $package; 1;";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 10;


my $algorithm = 1;			## test vectors from RFC5155
my $flags     = 0;
my $iteration = 12;
my $salt      = 'aabbccdd';
my $hnxtname  = 'irrelevant';

my @name = qw(example a.example ai.example ns1.example ns2.example
		w.example *.w.example x.w.example y.w.example x.y.w.example);
my %testcase = (
	'example'	=> '0p9mhaveqvm6t7vbl5lop2u3t2rp3tom',
	'a.example'	=> '35mthgpgcu1qg68fab165klnsnk3dpvl',
	'ai.example'	=> 'gjeqe526plbf1g8mklp59enfd789njgi',
	'ns1.example'	=> '2t7b4g4vsa5smi47k61mv5bv1a22bojr',
	'ns2.example'	=> 'q04jkcevqvmu85r014c7dkba38o0ji5r',
	'w.example'	=> 'k8udemvp1j2f7eg6jebps17vp3n8i58h',
	'*.w.example'	=> 'r53bq7cc2uvmubfu5ocmm6pers9tk9en',
	'x.w.example'	=> 'b4um86eghhds6nea196smvmlo4ors995',
	'y.w.example'	=> 'ji6neoaepv8b5o6k4ev33abha8ht9fgc',
	'x.y.w.example' => '2vptu5timamqttgl4luu9kg21e0aor3s',
	);

foreach my $name (@name) {
	my $hash  = $testcase{$name};
	my @args  = ( $algorithm, $flags, $iteration, $salt, $hnxtname );
	my $nsec3 = new Net::DNS::RR("$hash.example. NSEC3 @args");
	ok( $nsec3->match($name), "nsec3->match($name)" );
}


exit;

__END__


