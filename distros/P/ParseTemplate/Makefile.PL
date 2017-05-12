use ExtUtils::MakeMaker;	# See the Camel, page 409-
require 5.000;

WriteMakefile(
	      $] >= 5.005 ? 
	      (AUTHOR 		=> 'Philippe Verdret <pverdret@dalet.com>',
	       ABSTRACT 	=> 'Processor for templates containing Perl expressions') : (),
	      NAME			=> 'Parse::Template',
	      DISTNAME      => "ParseTemplate",
	      VERSION_FROM	=> 'lib/Parse/Template.pm',
	      clean			=> {
							'FILES' => 'err testlog doc/pod2html-*'
						   },
	      dist			=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
		  PREREQ_PM 	=> {
			'Test::More'	=> 0.96,	# needs done_testing()
			'Symbol'		=> 0,
		  },
);

