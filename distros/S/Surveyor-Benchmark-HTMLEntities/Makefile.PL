use ExtUtils::MakeMaker;

require 5.010;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Surveyor::Benchmark::HTMLEntities',
	'ABSTRACT'     => 'Benchmark HTML entity escaping',
	'VERSION_FROM' => 'lib/Surveyor/Benchmark/HTMLEntities.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'      => '0',
		'HTML::Escape'    => '0',
		'HTML::Entities'  => '0',
		'Mojo::UserAgent' => '0',
		'Surveyor::App'   => '0',
		},

	clean  => { FILES    => q|Surveyor-Benchmark-HTMLEntities-*| },

	);
