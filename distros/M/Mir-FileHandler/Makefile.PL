use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mir::FileHandler',
    AUTHOR           => q{Marco Masetti <grubert65@gmail.com>},
    VERSION_FROM     => 'lib/Mir/FileHandler.pm',
    ABSTRACT_FROM    => 'lib/Mir/FileHandler.pm',
    LICENSE          => 'BSD',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'DirHandle'         => 0,
        'File::Find'        => 0,
        'File::Basename'    => 0,
        'Log::Log4perl'     => 0,
        'Moose'             => 0,
        'Cache::Cache'      => 0,
        'Digest::MD5'       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mir-FileHandler-*' },
);
