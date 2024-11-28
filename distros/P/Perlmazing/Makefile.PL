use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %dependencies = (
    'Carp'                  => 0,
    'CLDR::Number'          => 0.19,
    'Crypt::Rijndael'       => 0,
    'Cwd'                   => 0,
    'Data::Dump'            => 0,
    'Data::Structure::Util' => 0,
    'Devel::Caller'         => 2.06,
    'Digest::MD5'           => 0,
    'Encode'                => 0,
    'ExtUtils::MakeMaker'   => 0,
    'File::Copy::Recursive' => 0,
    'File::Path'            => 2.08,
    'IPC::Cmd'              => 0,
    'List::Util'            => 0,
    'Math::Round'           => 0,
    'Scalar::Util'          => 0,
    'Submodules'            => 1.0015,
    'Taint::Util'           => 0.08,
    'Time::Precise'         => '1.0012',
    'URI::Escape'           => 0,
    'version'               => 0,
    'Win32::Symlinks'       => '0.12',
);

my %params = (
	NAME             => 'Perlmazing',
    AUTHOR           => q{Francisco Zarabozo <zarabozo@cpan.org>},
    VERSION_FROM     => 'lib/Perlmazing.pm',
    ABSTRACT_FROM    => 'lib/Perlmazing.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        %dependencies,
    },
    BUILD_REQUIRES => {
        %dependencies,
    },
    TEST_REQUIRES => {
        %dependencies,
    },
    PREREQ_PM => {
        %dependencies,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Perlmazing-*' },
);

delete $params{TEST_REQUIRES} unless ExtUtils::MakeMaker->VERSION >= 6.64;

WriteMakefile(%params);
