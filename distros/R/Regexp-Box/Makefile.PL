use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Regexp::Box',
    VERSION_FROM      => 'lib/Regexp/Box.pm', # finds $VERSION
    PREREQ_PM         => {
      Regexp::Common => 1,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Regexp/Box.pm', # retrieve abstract from module
       AUTHOR         => 'Murat Ünalan <muenalan@cpan.org>') : ()),
);
