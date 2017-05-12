use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SMS::Send::TW::Socket2Air',
    VERSION_FROM      => 'lib/SMS/Send/TW/Socket2Air.pm', # finds $VERSION
    PREREQ_PM         => {
	'SMS::Send'                 => 0,
	'LWP::UserAgent'            => 5.834,
	'Text::Iconv'               => 1.7,
	'Switch'                    => 2.14,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SMS/Send/TW/Socket2Air.pm', # retrieve abstract from module
       AUTHOR         => 'Jui-Nan Lin <jnlin@csie.nctu.edu.tw>') : ()),
);
