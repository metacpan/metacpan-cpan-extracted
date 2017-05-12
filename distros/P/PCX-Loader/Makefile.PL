use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PCX::Loader',
    VERSION_FROM      => 'lib/PCX/Loader.pm', # finds $VERSION
    ABSTRACT_FROM     => 'lib/PCX/Loader.pm', # retrieve abstract from module
    PREREQ_PM         => {},
    TEST_REQUIRES => {
        # modules only required for testing
        'Test::More' => '0.98',
    },
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/asb-capfan/PCX-Loader',
        },
    },
    MIN_PERL_VERSION => 5.008008,
);
