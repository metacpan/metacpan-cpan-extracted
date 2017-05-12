use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Amazon::AWSSign',
    VERSION_FROM      => 'lib/Net/Amazon/AWSSign.pm', # finds $VERSION
    PREREQ_PM         => {'MIME::Base64' => 0,
			  'Digest::SHA' => 0,
			  'URI::Escape' => 0,
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Amazon/AWSSign.pm', # retrieve abstract from module
       AUTHOR         => 'Naton Aiman-Smith <naton@>') : ()),
);
