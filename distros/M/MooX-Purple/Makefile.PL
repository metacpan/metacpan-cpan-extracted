use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'MooX::Purple',
	AUTHOR           => q{lnation <thisusedtobeanemail@gmail.com>},
	VERSION_FROM     => 'lib/MooX/Purple.pm',
	ABSTRACT_FROM    => 'lib/MooX/Purple.pm',
	LICENSE          => 'artistic_2',
	PL_FILES         => {},
	MIN_PERL_VERSION => '5.018',
	CONFIGURE_REQUIRES => {
	    'ExtUtils::MakeMaker' => '0',
	},
	BUILD_REQUIRES => {
		'Test::More' => '0',
		'JSON' => '0',
		'Scalar::Util' => '0'
	},
	PREREQ_PM => {
		'Keyword::Declare' => '0.001017',
		'Moo' => '2.003004',
		'MooX::LazierAttributes' => '1.07008',
		'MooX::ValidateSubs' => '1.012005',
		'Data::LnArray' => '0.02',
		'Perl::Tidy' => '20200110'
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'MooX-Purple-*' },
);
