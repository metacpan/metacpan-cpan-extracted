# $Id: 33-NSEC3-hash.t 1679 2018-05-24 12:09:36Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Digest::SHA
		Net::DNS::RR::NSEC3
		Net::DNS::RR::NSEC3PARAM
		);

foreach my $package (@prerequisite) {
	next if eval "use $package; 1;";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 12;


my $nsec3param = new Net::DNS::RR('example NSEC3PARAM 1 0 12 aabbccdd');

my $algorithm = $nsec3param->algorithm;
my $iteration = $nsec3param->iterations;
my $salt      = $nsec3param->salt;


ok( Net::DNS::RR::NSEC3::name2hash( 1, 'example' ), "defaulted arguments" );
ok( Net::DNS::RR::NSEC3::name2hash( 1, 'example', $iteration, $salt ), "explicit arguments" );


my %testcase = (			## test vectors from RFC5155
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


my @name = qw(example a.example ai.example ns1.example ns2.example
		w.example *.w.example x.w.example y.w.example x.y.w.example);

foreach my $name (@name) {
	my $hash = $testcase{$name};
	my @args = ( $algorithm, $name, $iteration, $salt );
	is( Net::DNS::RR::NSEC3::name2hash(@args), $hash, "H($name)" );
}


exit;

__END__


