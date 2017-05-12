use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Module::Pluggable::Ordered',
    VERSION_FROM      => 'Ordered.pm', # finds $VERSION
    PREREQ_PM         => {
        Module::Pluggable => 1.9,
        UNIVERSAL::require => 0
    }, # e.g., Module::Name => 1.1
);
