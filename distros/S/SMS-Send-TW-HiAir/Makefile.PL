use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SMS::Send::TW::HiAir',
    VERSION_FROM      => 'lib/SMS/Send/TW/HiAir.pm', # finds $VERSION
    PREREQ_PM         => {
            'SMS::Send'			=> 0,
	    'WWW::Mechanize'		=> 1.18,
	    'Crypt::SSLeay'		=> 0.51,
    },
    ($] >= 5.006001 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SMS/Send/TW/HiAir.pm', # retrieve abstract from module
       AUTHOR         => 'Tsung-Han Yeh <snowfly@yuntech.edu.tw>') : ()),
);
