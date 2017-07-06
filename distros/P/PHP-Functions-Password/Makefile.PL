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
		'Crypt::Eksblowfish'		=> 0,
		'Crypt::OpenSSL::Random'	=> 0,
		'MIME::Base64'				=> 0,
		'Test::More'				=> 0,
	},
	'MIN_PERL_VERSION'	=> 5.010000,
	'LICENSE' => 'perl_5',
	'dist' => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
