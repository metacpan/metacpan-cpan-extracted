use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Amazon::Utils',
    AUTHOR           => q{Gonzalo Barco <gbarco uy at gmail com, no spaces>},
    VERSION_FROM     => 'lib/Net/Amazon/Utils.pm',
    ABSTRACT_FROM    => 'lib/Net/Amazon/Utils.pm',
    LICENSE          => 'gpl, artistic',
    PL_FILES         => {},
    MIN_PERL_VERSION => v5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
				'Carp' => 0,
				'LWP::UserAgent' => 0,
				'LWP::Protocol::https' => 0,
				'HTTP::Message' => 0,
				'XML::Simple' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
		test	=> { TESTS => 't/*.t' },
    clean => { FILES => 'Net-Amazon-Utils-*' },
);
