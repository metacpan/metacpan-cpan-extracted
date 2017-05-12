use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Term::Screen::ReadLine',
    'VERSION_FROM' => 'ReadLine.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm'
    'DEFINE'	=> '',	   # e.g., '-DHAVE_SOMETHING'
    'INC'	=> '',	   # e.g., '-I/usr/include/other'
    'PREREQ_PM' => { Term::Screen => 0 },
);


