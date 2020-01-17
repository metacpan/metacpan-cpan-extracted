use strict;
use warnings;
use Test::More;

use MooX::Press (
	prefix => 'MyApp',
	class  => [
		'Animal' => {
			has => ['$name'],
		},
		'Doggo' => {
			extends => [ 'Species' => ['dog', 'Canis familiaris'] ],
		},
	],
	class_generator => [
		'Species' => sub {
			my ($gen, $common, $binomial) = @_;
			return {
				extends  => ['Animal'],
				constant => {
					common_name => $common,
					binomial    => $binomial,
				},
			};
		},
	],
);

use Types::Standard -types;
use MyApp::Types -types;

my $Human = MyApp->generate_species('human', 'Homo sapiens');

ok(
	ClassName->check($Human) && $Human->can('new'),
	'$Human appears to be a class',
);

ok(
	$Human->binomial eq "Homo sapiens",
	'$Human->binomial eq "Homo sapiens"'
);

ok(
	SpeciesClass->check($Human),
	'$Human passes SpeciesClass',
);

ok(
	!SpeciesInstance->check($Human),
	'$Human fails SpeciesInstance',
);

my $alice = $Human->new(name => 'Alice');

ok(
	$alice->isa($Human),
	'$alice isa $Human',
);

ok(
	$alice->binomial eq "Homo sapiens",
	'$alice->binomial eq "Homo sapiens"'
);

ok(
	$alice->isa('MyApp::Animal'),
	'$alice isa Animal',
);

ok(
	!$alice->isa('MyApp::Species'),
	'NOT $alice isa Species',
);

ok(
	!SpeciesClass->check($alice),
	'$alice fails SpeciesClass',
);

ok(
	SpeciesInstance->check($alice),
	'$alice passes SpeciesInstance',
);

my $lassie = MyApp->new_doggo(name => 'Lassie');

ok(
	SpeciesClass->check('MyApp::Doggo'),
	'MyApp::Doggo passes SpeciesClass',
);

ok(
	SpeciesInstance->check($lassie),
	'$lassie passes SpeciesInstance',
);

done_testing;