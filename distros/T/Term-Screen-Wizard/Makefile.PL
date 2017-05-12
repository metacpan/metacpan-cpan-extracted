use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Term::Screen::Wizard',
    'VERSION_FROM' => 'Wizard.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm'
    'DEFINE'	=> '',	   # e.g., '-DHAVE_SOMETHING'
    'INC'	=> '',	   # e.g., '-I/usr/include/other'
    'PREREQ_PM' => { Term::Screen => 0, Term::Screen::ReadLine => 0.33 },
);


