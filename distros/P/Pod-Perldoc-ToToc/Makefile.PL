use ExtUtils::MakeMaker 6.46;

require 5.008;

eval "use Test::Manifest 1.21";

# Stupid Mac extended attribute files
unlink glob ( map { "$_/._*" } ( '', qw(t lib examples) ) );

WriteMakefile(
	'NAME'          => 'Pod::Perldoc::ToToc',
	'VERSION_FROM'  => 'lib/Pod/Perldoc/ToToc.pm',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',
	'ABSTRACT'      => 'Turn one or more Pod files into a table of contents',

	'PREREQ_PM'    => {
		'ExtUtils::MakeMaker' => '6.46',
		'Test::More'          => '0.95',
		'Pod::Perldoc'        => '0',
		'Pod::Simple'         => '0',
		'parent'              => '0',
		},

	'META_MERGE' => {
		resources => {
			repository => 'https://github.com/briandfoy/pod-perldoc-totoc',
			},
		},

	clean  => { FILES    => q|Pod-Perldoc-ToToc-*| },
	);
