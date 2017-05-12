use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Palm::PunchClock',
    'VERSION_FROM'	=> 'lib/Palm/PunchClock.pm',
    'PREREQ_PM'		=> {
	Palm::PDB		=> 1.10,
	Palm::StdAppInfo	=> 1.3,
    },
);
