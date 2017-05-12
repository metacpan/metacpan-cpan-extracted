use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'String::KeyboardDistanceXS',
    'VERSION_FROM'	=> 'KeyboardDistanceXS.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> ['-lm'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
    'C'     => [ qw( keyboardDistance.c ) ],
    'OBJECT' => "keyboardDistance.o KeyboardDistanceXS.o"
);
