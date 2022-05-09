use 5.024000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Quantum::Superpositions::Lazy',
	MIN_PERL_VERSION => '5.024',
	VERSION_FROM => 'lib/Quantum/Superpositions/Lazy.pm',

	TEST_REQUIRES => {
		'Test::Exception' => 0,
		'Mock::Sub' => 0,
	},

	PREREQ_PM => {
		"namespace::clean" => 0,
		"Moo" => "2.000000",
		"Type::Tiny" => "1.002000",
		"Random::Any" => 0,
		"Sort::Key" => 0,
	},

	META_MERGE => {
		resources => {
			license => 'https://dev.perl.org/licenses',
			homepage => 'https://bbrtj.eu/project/quantum-superpositions-lazy',
			bugtracker => 'https://github.com/bbrtj/perl-quantum-superpositions-lazy/issues',
			repository => 'https://github.com/bbrtj/perl-quantum-superpositions-lazy',
		},
	},

	ABSTRACT_FROM => 'lib/Quantum/Superpositions/Lazy.pm',
	AUTHOR => 'Bartosz Jarzyna <bbrtj.pro@gmail.com>',
	LICENSE => 'perl',
);

