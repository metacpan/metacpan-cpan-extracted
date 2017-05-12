use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::APNS::Persistent',
    VERSION_FROM      => 'lib/Net/APNS/Persistent.pm', # finds $VERSION
    MIN_PERL_VERSION  => 5.008,
    PREREQ_PM         => {
        Class::Accessor => 0,
        Net::SSLeay => 0, # what version did ssl_write_all appear?
        Socket => 0,
        Encode => 0,
        JSON::XS => 0, # any min version for utf8?
        Test::More => 0,
        Test::Exception => 0,
        FindBin => 0,
       }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/APNS/Persistent.pm', # retrieve abstract from module
       AUTHOR         => 'Mark Aufflick <mark@aufflick.com>') : ()),
);
