# $Id: Makefile.PL,v 1.1 2004/12/23 12:02:30 jminieri Exp $
use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SDEE',
    VERSION_FROM      => 'lib/Net/SDEE.pm', # finds $VERSION
    PREREQ_PM         => {'MIME::Base64' => '0',
				'LWP::UserAgent' => '0',
				'Crypt::SSLeay' => '0',
				'XML::Simple' => '0'
			},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SDEE.pm', # retrieve abstract from module
       AUTHOR         => 'Joe Minieri <jminieri@mindspring.com>') : ()),
);
