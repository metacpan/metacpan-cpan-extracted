use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'TRD::Watch::DB',
    VERSION_FROM      => 'lib/TRD/Watch/DB.pm', # finds $VERSION
    PREREQ_PM         => {
        'DBI'               => 0,
        'threads'           => 1.7,
        'Time::HiRes'       => 0,
        'TRD::DebugLog'     => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/TRD/Watch/DB.pm', # retrieve abstract from module
       AUTHOR            => 'Takuya Ichikawa <ichi@cpan.org>') : ()),
);
