use 5.010;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MooseX::Traits::SetScalarByRef',
    VERSION_FROM      => 'lib/MooseX/Traits/SetScalarByRef.pm', # finds $VERSION
    PREREQ_PM         => {
        # e.g., Module::Name => 1.1
        'Moose'         => 2.0604,
        'Moose::Util::TypeConstraints'  => 2.0604,
        'ExtUtils::MakeMaker'           => 6.6302,
        'Test::More'    => 0.98,
        'Scalar::Util'  => 1.27,
        # optional, as only useful for DEV
        # Test::Pod => 1.0,
        # Test::Pod::Coverage => 1.08,
    },
    ABSTRACT_FROM  => 'lib/MooseX/Traits/SetScalarByRef.pm', # retrieve abstract from module
    AUTHOR         => 'Alex Becker <c a p f a n at g m x write_Adot-here d e>',
    LICENSE        => 'perl_5',
    MIN_PERL_VERSION => 5.010,
);
