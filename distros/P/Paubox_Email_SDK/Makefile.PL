use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Paubox_Email_SDK',
    VERSION_FROM      => 'lib/Paubox_Email_SDK.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'JSON' => 4.02,
        'Config::General' => 2.63,
        'REST::Client' => 273,        
        'TryCatch' => 1.003002,        
    }, 
    ABSTRACT_FROM     => 'lib/Paubox_Email_SDK.pm',
    AUTHOR            => 'Paubox Inc.',    
);
