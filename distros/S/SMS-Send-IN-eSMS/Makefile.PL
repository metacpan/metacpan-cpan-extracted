use 5.014002;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME              => 'SMS::Send::IN::eSMS',
              VERSION_FROM      => 'lib/SMS/Send/IN/eSMS.pm', # finds $VERSION
              PREREQ_PM         => { 'SMS::Send'       => '0.05', # '1.06',
                                     'IO::Socket::SSL' => '1.76',
                                     'LWP::UserAgent'  => '6.04',
                                     'File::Spec'      => '3.33',
                                     'Test::More'      => '0.98',
				     'Test::Exception' => '0.31',
                                }, 
              ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
               (ABSTRACT_FROM  => 'lib/SMS/Send/IN/eSMS.pm', # retrieve abstract from module
                AUTHOR         => 'Indranil Das Gupta <indradg@l2c2.co.in>') : ()),
	     'LICENSE'  => 'perl_5',
);
