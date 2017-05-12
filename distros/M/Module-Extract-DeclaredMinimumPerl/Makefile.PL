use ExtUtils::MakeMaker;

require 5.010;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Module::Extract::DeclaredMinimumPerl',
	'ABSTRACT'     => 'Extract the version of Perl a module declares',
	'VERSION_FROM' => 'lib/Module/Extract/DeclaredMinimumPerl.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => {
		'feature'              => '0',
		'PPI'                  => '0',
		'Test::More'           => '0',
		'Test::Output'         => '0',
		'version'              => '0',
		},

	(
	$ExtUtils::MakeMaker::VERSION ge '6.48' ? 
		(
		MIN_PERL_VERSION => 5.006,

		META_MERGE       => {
			resources => {
				repository => 'git://github.com/briandfoy/module-extract-declaredminimumperl.git',
				},
			keywords => [ qw( ppi parsing static-analysis modules ) ],
			no_index => {
				dir       => [ qw(corpus) ],
				directory => [ qw(corpus) ],
				},
			},
	 	) 
	 	: 
	 	()
	 ),

	clean  => { FILES    => q|Module-Extract-DeclaredMinimumPerl-*| },

	);
