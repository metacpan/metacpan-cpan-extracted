use 5.007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POOF',
    VERSION_FROM      => 'lib/POOF.pm', # finds $VERSION
    PREREQ_PM         =>
    {
        Attribute::Handlers => 0,
        Scalar::Util => 0,
        B::Deparse => 0,
        Carp => 0,
        Digest::MD5 => 0,
        Class::ISA => 0,
        Test::More => 0,
        Tie::IxHash => 0,
    },
    (
        $] >= 5.007
            ? ( ABSTRACT_FROM  => 'lib/POOF.pm', # retrieve abstract from module
                AUTHOR         => 'Benny Millares <bmillares@cpan.org>' )
            : ( )
    ),
);

