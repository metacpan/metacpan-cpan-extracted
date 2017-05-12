use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SVN::TXN::Props',
    VERSION_FROM      => 'lib/SVN/TXN/Props.pm', # finds $VERSION
    PREREQ_PM         => {
	SVN::Base	=> 1.4.3,
    	Test::More	=> 0.70,
    	Test::MockClass	=> 1.04,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SVN/TXN/Props.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Leishman <chris@leishman.org>') : ()),
);
