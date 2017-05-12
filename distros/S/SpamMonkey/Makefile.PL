use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SpamMonkey',
    VERSION_FROM      => 'lib/SpamMonkey.pm', # finds $VERSION
    PREREQ_PM         => {
        URI::Find => 0,
        File::Path::Expand => 0,
        UNIVERSAL::require => 0,
    }, # e.g., Module::Name => 1.1
);
