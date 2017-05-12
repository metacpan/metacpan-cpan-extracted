use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Filter::Stomp',
    VERSION_FROM      => 'lib/POE/Filter/Stomp.pm', # finds $VERSION
    PREREQ_PM         => {Net::Stomp => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POE/Filter/Stomp.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin L. Esteb <kesteb@wsipc.org>') : ()),
);
