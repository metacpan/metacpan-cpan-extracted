use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SMS::Send::TW::ShareSMS',
    VERSION_FROM      => 'lib/SMS/Send/TW/ShareSMS.pm', # finds $VERSION
    PREREQ_PM         => {
            'SMS::Send'			=> 0.03,    	
	    'LWP::UserAgent'		=> 2.0,
    	}, # e.g., Module::Name => 1.1
    ($] >= 5.006001 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SMS/Send/TW/ShareSMS.pm', # retrieve abstract from module
       AUTHOR         => 'Tsung-Han Yeh <snowfly@yuntech.edu.tw>') : ()),
);
