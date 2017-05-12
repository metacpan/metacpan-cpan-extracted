use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SMS::Send::TW::emome',
    VERSION_FROM      => 'lib/SMS/Send/TW/emome.pm', # finds $VERSION
    PREREQ_PM         => {            
	    'SMS::Send'                 => 0.03,
	    'WWW::Mechanize'		=> 1.20,
	    'Text::Iconv'		=> 1.50,
	    'Crypt::SSLeay'		=> 0.57,
        }, # e.g., Module::Name => 1.1    
    ($] >= 5.006001 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SMS/Send/TW/emome.pm', # retrieve abstract from module
       AUTHOR         => 'Tsung-Han Yeh <snowfly@yuntech.edu.tw>') : ()),
);
