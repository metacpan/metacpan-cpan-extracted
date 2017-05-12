use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SMS::BulkSMS',
    VERSION_FROM      => 'lib/Net/SMS/BulkSMS.pm', # finds $VERSION
    PREREQ_PM         => {
      HTTP::Request::Common => 0,
      Carp                  => 0,
      LWP::UserAgent        => 0,
      MIME::Base64          => 0,
      POSIX                 => 0,
		},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SMS/BulkSMS.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Edwards <peter@dragonstaff.co.uk>') : ()),
);
