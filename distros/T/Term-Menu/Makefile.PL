use 5.000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Term::Menu',
    VERSION_FROM      => 'lib/Term/Menu.pm', # finds $VERSION
    PREREQ_PM         => { },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/Term/Menu.pm', # retrieve abstract from module
       AUTHOR         => 'Sjors Gielen <sjorsgielen@gmail.com>') : ()),
);
