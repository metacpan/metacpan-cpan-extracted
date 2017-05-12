use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Proc::Safetynet',
    VERSION_FROM      => 'lib/Proc/Safetynet.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::Exception'                   => 0.25,
        'JSON::XS'                          => 2.21,
        'POE'                               => 1.0003,
        'Moose'                             => 0.51,
        'File::Spec'                        => 3.12,
        'POE::Filter::JSON::Incr'           => 0.02,
    }, 
    EXE_FILES         => [
        'bin/safetynetd.pl',
        'bin/safetynet-shell.pl',
    ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Proc/Safetynet.pm', # retrieve abstract from module
       AUTHOR         => 'Dexter Tad-y <dexterbt1@yahoo.com>') : ()),
);
