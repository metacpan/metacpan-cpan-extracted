use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SolarWinds::REST',
    VERSION_FROM      => 'lib/Net/SolarWinds/REST.pm', # finds $VERSION
    PREREQ_PM         => {
    qw(
     IO::Socket::SSL 1.968
     LWP::UserAgent  6.04
     MIME::Base64    3.13
     URI::Encode     0.09
     JSON            2.53
     IO::Scalar      2.11
     Net::SSLeay     1.58
    )

    
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SolarWinds/REST.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Shipper <AKALINUX@CPAN.ORG>') : ()),
);
