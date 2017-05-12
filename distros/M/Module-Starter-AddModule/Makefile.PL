use ExtUtils::MakeMaker;

require 5.010;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Module::Starter::AddModule',
	'ABSTRACT'     => 'Add a module to a distribution',
	'VERSION_FROM' => 'lib/Module/Starter/AddModule.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Distribution::Guess::BuildSystem' => '0',
		'Module::Starter::Simple'          => '0',
		'Module::Starter::Smart'           => '0',
		'Module::Starter'                  => '0',
		'parent'                           => '0',
		'Test::More'                       => '0.95',
		},

	clean  => { FILES    => q|Module-Starter-AddModule-*| },

	);
