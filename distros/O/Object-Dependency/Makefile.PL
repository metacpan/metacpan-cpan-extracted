
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION_FROM' => 'lib/Object/Dependency.pm',
	'NAME' => 'Object-Dependency',
	($] >= 5.005
		?
			(
				ABSTRACT	=> 'dependency graph',
				AUTHOR		=> 'David Muir Sharnoff <cpan@dave.sharnoff.org>',
				META_MERGE	=> {
					resources	=> {
						repository => 'https://github.com/muir/Object-Dependency',
					},
				},
			)
		: ()
	),
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'PREREQ_PM'	=> {
		'Scalar::Util'			=> 0,
		'Hash::Util'			=> 0,
		'Hash::Util'			=> 0,
		'List::MoreUtils'		=> 0,
	},
);

