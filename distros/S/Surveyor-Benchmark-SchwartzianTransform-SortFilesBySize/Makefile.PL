use ExtUtils::MakeMaker;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Surveyor::Benchmark::SchwartzianTransform::SortFilesBySize',
	'ABSTRACT'     => 'Compare the low-tech and Schwartzian Transform sorts',
	'VERSION_FROM' => 'lib/Surveyor/Benchmark/SchwartzianTransform/SortFilesBySize.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More' => '0.94',
		},

	META_MERGE => {
		resources => {
			repository => 'https://github.com/briandfoy/surveyor-benchmark-schwartziantransform-sortfilesbysize'
			}
		},

	clean  => { FILES    => q|Surveyor-Benchmark-SchwartzianTransform-SortFilesBySize-*| },
	);
