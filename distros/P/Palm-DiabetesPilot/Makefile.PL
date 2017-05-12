use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'              => 'Palm::DiabetesPilot',
	'VERSION_FROM'      => 'DiabetesPilot.pm',
	'DISTNAME'          => 'Palm-DiabetesPilot',
	'INSTALLDIRS'       => 'site',
	'AUTHOR' => 'Christophe Beauregard <cpb@cpan.org>',
	'ABSTRACT' => 'Module for processing Diabetes Pilot databases',
	'PREREQ_PM' => {
		'Palm::PDB' => '1',
		'Test::More' => 0.46,
	},
	'EXE_FILES' => [ 'diabetes-report' ],
);
