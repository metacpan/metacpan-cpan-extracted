use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SMS::Send::NexmoUnicode',
    VERSION_FROM      => 'lib/SMS/Send/NexmoUnicode.pm', # finds $VERSION
    PREREQ_PM         => {
    	    'Nexmo::SMS'		=> 0.04,
            'SMS::Send'			=> 0,
    },
    ($] >= 5.006001 ?     ## Add these new keywords supported since 5.006001
      (ABSTRACT_FROM  => 'lib/SMS/Send/NexmoUnicode.pm', # retrieve abstract from module
       AUTHOR         => 'Jui-Nan Lin <jnlin@csie.nctu.edu.tw>') : ()),
);

