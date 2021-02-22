use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'PHP::Functions::Password',
	'AUTHOR'	=> 'Craig Manley',
	'ABSTRACT'	=> 'This module provides ported PHP password functions.',
	'VERSION_FROM' => 'lib/PHP/Functions/Password.pm',
	'BUILD_REQUIRES' => {
		'ExtUtils::MakeMaker'	=> 6.48,
		'Test::More'			=> 0,
	},
	'PREREQ_PM' =>	{
		'Crypt::Argon2'				=> 0.004,
		'Crypt::Eksblowfish'		=> 0,
		'Crypt::OpenSSL::Random'	=> 0,
		'MIME::Base64'				=> 0,
		'version'					=> 0.77,
	},
	'MIN_PERL_VERSION'	=> 5.010000,
	'LICENSE' => 'perl_5',
	'dist' => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
	'META_MERGE' => {
		'meta-spec' => { 'version' => 2 },
		'resources' => {
			'repository' => {
				'type' => 'git',
				'url'  => 'https://github.com/cmanley/p5-PHP-Functions-Password.git',
				'web'  => 'https://github.com/cmanley/p5-PHP-Functions-Password/',
			},
			'bugtracker' => {'web' => 'https://github.com/cmanley/p5-PHP-Functions-Password/issues'},
			#homepage   => 'https://craigmanley.com/',
		},
	},
);
