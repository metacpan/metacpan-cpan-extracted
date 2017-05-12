use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'MooseX::Contract',
	AUTHOR        => 'Brian Phillips <bphillips@cpan.org>',
	VERSION_FROM  => 'lib/MooseX/Contract.pm',
	ABSTRACT_FROM => 'lib/MooseX/Contract.pm',
	( $ExtUtils::MakeMaker::VERSION >= 6.3002
		? ( 'LICENSE' => 'perl' )
		: () ),
	PL_FILES  => {},
	PREREQ_PM => {
		'Test::More'  => 0,
		'Moose'       => '0.64',
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'MooseX-Contract-*' },
);
