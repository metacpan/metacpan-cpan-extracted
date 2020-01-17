use strict;
use warnings;
use Test::More;

use MooX::Press (
	prefix => 'MyApp',
	class  => [
		'Doggo' => {
			with => [ 'Species' => ['dog', 'Canis familiaris'] ],
		},
	],
	role_generator => [
		'Species' => sub {
			my ($gen, $common, $binomial) = @_;
			return {
				constant => {
					common_name => $common,
					binomial    => $binomial,
				},
			};
		},
	],
);

my $lassie = MyApp->new_doggo(name => 'Lassie');

ok(
	$lassie->does('MyApp::Species::__GEN000001__'),
	'$lassie->does("MyApp::Species::__GEN000001__")'
);

ok(
	$lassie->binomial eq "Canis familiaris",
	'$lassie->binomial eq "Canis familiaris"',
);

done_testing;