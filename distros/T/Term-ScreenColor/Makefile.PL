# Makefile.PL for Term::ScreenColor module

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Term::ScreenColor',
	VERSION_FROM	=> 'ScreenColor.pm',
	PREREQ_PM	=> {
		'Term::Cap'    => 0,
		'Term::Screen' => 1.03,
	},
);

