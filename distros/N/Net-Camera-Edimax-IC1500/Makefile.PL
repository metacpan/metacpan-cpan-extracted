use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Camera::Edimax::IC1500',
    VERSION_FROM      => 'lib/Net/Camera/Edimax/IC1500.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Camera/Edimax/IC1500.pm', # retrieve abstract from module
       AUTHOR         => 'Andy Smith <andy.smith@netprojects.org.uk>') : ()),
);
