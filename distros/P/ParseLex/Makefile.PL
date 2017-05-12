use ExtUtils::MakeMaker;	# See the Camel, page 409-
require 5.000;

WriteMakefile(
	      'NAME'			=> 'Parse::Lex',
	      'DISTNAME'        => "ParseLex",
	      'VERSION_FROM'	=> 'lib/Parse/ALex.pm',
		  'PREREQ_PM' 		=> { 'Test::More' 		=> 0.96,	# needs done_testing()
								 'Parse::Template'	=> 3.04,
								 'File::Find'		=> 0,
								 'File::Slurp'		=> 0,
								 'Symbol'			=> 0,
								 'integer'			=> 0,
							},
	      'clean'			=> {'FILES' => ['err', 'testlog']},
	      'dist'            => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);

