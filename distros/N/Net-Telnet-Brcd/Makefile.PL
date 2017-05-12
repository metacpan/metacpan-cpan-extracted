use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Telnet::Brcd',
    VERSION_FROM      => 'lib/Net/Telnet/Brcd.pm', # finds $VERSION
    PREREQ_PM         => {Net::Telnet => 3.0}, # e.g., Module::Name => 1.1
    ($] >= 5.008 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Telnet/Brcd.pm', # retrieve abstract from module
       AUTHOR         => 'Laurent Bendavid <bendavid.laurent@free.fr>') : ()),
);
