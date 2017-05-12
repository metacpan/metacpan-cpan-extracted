use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME								=> 'Net::Amazon::Glacier',
    AUTHOR							=> q{Tim Nordenfur <tim@gurka.se>},
    VERSION_FROM				=> 'lib/Net/Amazon/Glacier.pm',
    ABSTRACT_FROM				=> 'lib/Net/Amazon/Glacier.pm',
		LICENSE							=> 'gpl, artistic',
    PL_FILES						=> {},
    MIN_PERL_VERSION		=> v5.10.0,
    CONFIGURE_REQUIRES	=> {
        'ExtUtils::MakeMaker'	=> 6.3002,
    },
    BUILD_REQUIRES => {
        'Test::More'					=> 0,
    },
    PL_FILES						=> {},
    PREREQ_PM => {
			'Net::Amazon::Signature::V4' => 0,
			'Net::Amazon::TreeHash' => 0,
			'Digest::SHA' => 0,
			'File::Slurp' => 9999.19,
			'JSON' => 2.61,
			'POSIX' => 0,
			'Carp' => 0,
			'HTTP::Request' => 0,
			'LWP::UserAgent' => 0,
			'LWP::Protocol::https' => 0,
    },
    dist								=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Amazon-Glacier-*' },
);
