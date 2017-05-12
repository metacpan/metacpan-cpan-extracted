use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'PITA::Test::Dummy::Perl5::Deps',
	AUTHOR        => 'Adam Kennedy <adamk@cpan.org>',
	VERSION       => '1.03',
	ABSTRACT      => 'CPAN Test Dummy for PITA Makefile.PL installs',
	PL_FILES      => {},
	PREREQ_PM     => {
		'PITA::Test::Dummy::Perl5::Make'  => '1.02',
		'PITA::Test::Dummy::Perl5::Build' => '1.01',
		'PITA::Test::Dummy::Perl5::MI'    => '0.64',
	},
	( $ExtUtils::MakeMaker::VERSION ge '6.30_00' ? (
		LICENSE => 'perl',
	) : () ),
);
