#!/usr/bin/perl
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME             => 'Test::Class::WithStrictPlan',
	VERSION_FROM     => 'lib/Test/Class/WithStrictPlan.pm',
	ABSTRACT_FROM    => 'lib/Test/Class/WithStrictPlan.pm',
	AUTHOR           => 'Pali <pali@cpan.org>',
	LICENSE          => 'perl_5',
	MIN_PERL_VERSION => '5.6.0',

	PREREQ_PM => {
		'parent'                 => '0',
		'strict'                 => '0',
		'warnings'               => '0',
		'Attribute::Handlers'    => '0',
		'Test::Class'            => '0.37',
	},
	TEST_REQUIRES => {
		'Test::More'             => '0',
	},
	eval { ExtUtils::MakeMaker->VERSION('6.68') } ? (
	META_MERGE => {
		'meta-spec' => {
			version => 2,
		},
		'resources' => {
			bugtracker => {
				web  => 'https://github.com/pali/Test-Class-WithStrictPlan/issues',
			},
			repository => {
				url  => 'git://github.com/pali/Test-Class-WithStrictPlan.git',
				web  => 'https://github.com/pali/Test-Class-WithStrictPlan',
				type => 'git',
			},
		},
	},
	) : (),
);
