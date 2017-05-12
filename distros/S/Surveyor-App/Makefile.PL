use ExtUtils::MakeMaker 6.46;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Surveyor::App',
	'ABSTRACT'     => 'Run benchmarks from a package',
	'VERSION_FROM' => 'lib/Surveyor/App.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More' => '0.94',
		'Benchmark'  => '0',
		},

	'EXE_FILES' => [ qw(scripts/survey) ],

	'META_MERGE' => {
		resources => {
			repository => 'https://github.com/briandfoy/surveyor-app'
			}
		},

	clean  => { FILES    => q|Surveyor-App-*| },
	);
