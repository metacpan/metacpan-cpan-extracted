use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Term::Animation',
    'VERSION_FROM'	=> 'lib/Term/Animation.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Curses' => 1.06}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Term/Animation.pm', # retrieve abstract from module
       AUTHOR     => 'Kirk Baucom <kbaucom@schizoid.com>') : ()),
);
