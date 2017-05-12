use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'PITA::Test::Dummy::Perl5::Make',
	AUTHOR        => 'Adam Kennedy <cpan@ali.as>',
	VERSION       => '1.05',
	ABSTRACT      => 'CPAN Test Dummy for PITA Makefile.PL installs',
	PL_FILES      => {},
	PREREQ_PM     => {
		'strict' => 0,
	},
	( $ExtUtils::MakeMaker::VERSION ge '6.30_00' ? (
		LICENSE => 'perl',
	) : () ),
);
