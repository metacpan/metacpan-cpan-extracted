use ExtUtils::MakeMaker;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'SourceCode::LineCounter::Perl',
	'ABSTRACT'     => 'Classify and count lines in a Perl file',
	'VERSION_FROM' => 'lib/SourceCode/LineCounter/Perl.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'   => '0.94',
		'Test::Output' => '0',
		},

	clean  => { FILES    => q|SourceCode-LineCounter-Perl-*| },
	);
