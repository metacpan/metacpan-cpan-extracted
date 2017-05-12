use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Syndic8',
    VERSION_FROM      => 'lib/Net/Syndic8.pm', # finds $VERSION
    PREREQ_PM         => {FreezeThaw}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Syndic8.pm', # retrieve abstract from module
       AUTHOR         => 'Zahatski Aliaksandr, <zagap@users.sourceforge.net>') : ()),
);
