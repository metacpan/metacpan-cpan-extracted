
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::CSTA',
    VERSION_FROM      => 'lib/Net/CSTA.pm', # finds $VERSION
    PREREQ_PM         => {'Convert::ASN1'=>'0.21',XML::Simple=>0,MIME::Base64=>0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/CSTA.pm', # retrieve abstract from module
       AUTHOR         => 'Leif Johansson <leifj@it.su.se>') : ()),
);
