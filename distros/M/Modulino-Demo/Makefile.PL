use ExtUtils::MakeMaker;

require 5.014;

WriteMakefile(
	'NAME'	       => 'Modulino::Demo',
	'ABSTRACT'     => 'A demonstration of various modulino ideas',
	'VERSION_FROM' => 'lib/Modulino/Demo.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'          => '0',
		'Test::Pod'           => '0',
		'Test::Pod::Coverage' => '0',
		},

	'META_MERGE' => {
		resources => {
			repository => 'https://github.com/briandfoy/modulino-demo',
			},
		no_index => {
			dir       => [ qw(t) ],
			directory => [ qw(t) ],
			},
		},

	clean  => { FILES    => q|Modulino-Demo-*| },
	);
