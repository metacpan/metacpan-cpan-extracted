use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'Mojolicious::Plugin::CBOR',
	VERSION_FROM	=> 'lib/Mojolicious/Plugin/CBOR.pm',
	ABSTRACT_FROM	=> 'lib/Mojolicious/Plugin/CBOR.pm',
	LICENSE			=> 'perl',
	AUTHOR			=> 'Konstantin Cherednichenko <dshadow@cpan.org>',
	PREREQ_PM => {
		'Mojolicious'			=> '5.31',
		'CBOR::XS'				=> '1.25',
	},
	BUILD_REQUIRES	=> {
		'ExtUtils::MakeMaker'	=> '6.46',
		'File::FindLib'			=> 0,
	},
	META_MERGE => {
		resources => {
			repository => 'http://github.com/dshadow/mojolicious-plugin-cbor',
		},
	},
	dist => {
		COMPRESS	=> 'gzip -9f',
		SUFFIX		=> 'gz'
	},
	test			=> { TESTS => 't/*.t' }
);
