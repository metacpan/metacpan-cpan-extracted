use ExtUtils::MakeMaker;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Module::Extract::Namespaces',
	'ABSTRACT'     => 'extract the package declarations from a module',
	'VERSION_FROM' => 'lib/Module/Extract/Namespaces.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More' => '0',
		'PPI'        => '0',
		},

	'META_MERGE'   => {
		no_index => {
			directory => [ qw(inc t corpus examples) ],
			},
		},

	clean  => { FILES    => q|Module-Extract-Namespaces-*| },

	);
