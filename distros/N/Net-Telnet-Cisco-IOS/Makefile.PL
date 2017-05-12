use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Telnet::Cisco::IOS',
    VERSION_FROM      => 'lib/Net/Telnet/Cisco/IOS.pm', # finds $VERSION
    PREREQ_PM         => { Net::Telnet::Cisco => 1.10 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Telnet/Cisco/IOS.pm', # retrieve abstract from module
       AUTHOR         => 'Aaron Conaway <kraken@cpan.org>') : ()),
);
