# $Id: Makefile.PL,v 1.4 2004/07/04 17:04:17 comdog Exp $
use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.14";

WriteMakefile(
	'NAME'	       => 'Pod::SpeakIt::MacSpeech',
	'ABSTRACT'     => 'This is what the module does',
	'VERSION_FROM' => 'lib/MacSpeech.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'  => '0',
		'Mac::Carbon' => '0.77',
		'Mac::Speech' => '0',
		'Mac::Files'  => '0',
		},

	'EXE_FILES'    => [ 'bin/pod2speech' ],
	
	'PM'           => {
		'lib/MacSpeech.pm'         => '$(INST_LIBDIR)/MacSpeech.pm',
		},

	'MAN3PODS'     => {
		'lib/MacSpeech.pm' => '$(INST_MAN3DIR)/Pod::SpeakIt::MacSpeech.3',
		},

	clean  => { FILES    => q|Pod-SpeakIt-MacSpeech-*| },

	);
