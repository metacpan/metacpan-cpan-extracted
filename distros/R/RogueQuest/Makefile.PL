use 5.018004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RogueQuest',
    VERSION_FROM      => 'lib/RogueQuest.pm', # finds $VERSION
    PREREQ_PM         => { SDL => 2.0, RogueCurses => 0.0.6 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RogueQuest.pm', # retrieve abstract from module
       AUTHOR         => 'koboldwiz <koboldwiz@yahoo.com>') : ()),
);
