use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SMS::PChome',
    DISTNAME          => 'Net-SMS-PChome',
    VERSION_FROM      => 'lib/Net/SMS/PChome.pm', # finds $VERSION
    PREREQ_PM         => {
	    'WWW::Mechanize'	=> 1.18,
	    'Crypt::SSLeay'	=> 0.51,
            'Date::Calc'        => 5.4,
	    'HTML::TagParser'	=> 0.13,
            'Test::Simple'      => 0.44,
    },
    ($] >= 5.006001 ?     ## Add these new keywords supported since 5.006001
      (ABSTRACT_FROM  => 'lib/Net/SMS/PChome.pm', # retrieve abstract from module
       AUTHOR         => 'Tsung-Han Yeh <snowfly@yuntech.edu.tw>') : ()),
);
