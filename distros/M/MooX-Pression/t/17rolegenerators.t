use strict;
use warnings;
use Test::More;

package MyApp {
	use MooX::Pression;
	class Doggo {
		with Generators::Species('dog', 'Canis familiaris'), GoodBoi?;
	}
	role Generators::Species (Str $common, Str $binomial) {
		constant common_name = $common;
		constant binomial    = $binomial;
	}
}

my $lassie = MyApp->new_doggo(name => 'Lassie');

ok(
	$lassie->does('MyApp::Generators::Species::__GEN000001__'),
	'$lassie->does("MyApp::Generators::Species::__GEN000001__")'
);

ok(
	$lassie->binomial eq "Canis familiaris",
	'$lassie->binomial eq "Canis familiaris"',
);

ok(
	$lassie->does('MyApp::GoodBoi'),
	'$lassie->does("MyApp::GoodBoi")'
);

done_testing;