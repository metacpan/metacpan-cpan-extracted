use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::IP::RangeCompare',
    VERSION_FROM      => 'lib/Net/IP/RangeCompare.pm', # finds $VERSION
    PREREQ_PM         => {
     Data::Range::Compare=>1.030
     ,Data::IPV4::Range::Parse=>.05
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/IP/RangeCompare.pod', # retrieve abstract from module
       AUTHOR         => 'Michael Shipper') : ()),
);
