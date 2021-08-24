use 5.010;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MooseX::Traits::SetScalarByRef',
    VERSION_FROM      => 'lib/MooseX/Traits/SetScalarByRef.pm', # finds $VERSION
    ABSTRACT_FROM  => 'lib/MooseX/Traits/SetScalarByRef.pm', # retrieve abstract from module
    PREREQ_PM         => {
        # e.g., Module::Name => 1.1
        'Moose'         => 2.0604,
        'Moose::Util::TypeConstraints'  => 2.0604,
        'ExtUtils::MakeMaker'           => 6.64,
        'Test::More'    => 0.98,
        'Scalar::Util'  => 1.27,
    },
    TEST_REQUIRES => {
        # optional, as only useful for DEV
        # Test::Pod => 1.0,
        # Test::Pod::Coverage => 1.08,
    },
    AUTHOR         => 'Alexander Becker <asb@cpan.org>',
    LICENSE        => 'perl_5',
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/asb-capfan/MooseX-Traits-SetScalarByRef',
        },
    },
    MIN_PERL_VERSION => 5.010,
);
