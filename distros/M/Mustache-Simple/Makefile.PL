use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mustache::Simple',
    AUTHOR	      => q{Cliff Stanford <cpan@may.be>},
    VERSION_FROM      => 'lib/Mustache/Simple.pm',
    ABSTRACT_FROM     => 'lib/Mustache/Simple.pm',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10.1,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'YAML::XS'    => 0,
        'Data::Dumper' => 0,
    },
    PREREQ_PM         => {
	'File::Spec' => 0,
        'Scalar::Util' => 0,
	'YAML::XS'   => 0,
	'experimental' => 0.008,
        Carp        => 0,
        version     => 0,
    },
);
