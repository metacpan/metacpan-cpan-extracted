use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SNMPMonitor',
    VERSION_FROM      => 'lib/SNMPMonitor.pm', # finds $VERSION

    PREREQ_PM         => {
                            common::sense       => 0,
                            NetSNMP::OID        => 0,
                            NetSNMP::agent      => 0,
                            NetSNMP::ASN        => 0,
                            Module::Pluggable   => 0,
                            parent              => 0,
    }, 

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SNMPMonitor.pm', # retrieve abstract from module
       AUTHOR         => 'root <root@localdomain>') : ()),
);

