use 5.018004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RogueCurses',
    VERSION_FROM      => 'lib/RogueCurses.pm', # finds $VERSION
    PREREQ_PM         => { Curses => 1.37 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RogueCurses.pm', # retrieve abstract from module
       AUTHOR         => 'koboldwiz <koboldwiz@yahoo.com>') : ()),
);
