use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Term::TtyRec',
    'VERSION_FROM' => 'lib/Term/TtyRec.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.18,
	Time::HiRes => 1.20,
    },
    'EXE_FILES' => [ 'bin/pttyplay' ],
);
