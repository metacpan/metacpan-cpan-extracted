use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Rovio',
    VERSION_FROM      => 'lib/Net/Rovio.pm', # finds $VERSION
    PREREQ_PM         => { 'LWP::Simple' => 0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Rovio.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Greene <ivantis@ivantis.net>') : ()),
);
