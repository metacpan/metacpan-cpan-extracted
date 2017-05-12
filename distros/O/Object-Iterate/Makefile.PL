use ExtUtils::MakeMaker 6.48;

require 5.006;

eval "use Test::Manifest 1.21";

WriteMakefile
	(
	'NAME'          => 'Object::Iterate',
	'ABSTRACT'      => 'iterators for objects that know the next element',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',
	'VERSION_FROM'  => 'lib/Object/Iterate.pm',
	'LICENSE'       => 'perl',

	'PREREQ_PM' => {
		'Test::Data'       => '0',
		'Test::More'       => '0',
		},

	'META_MERGE' => {
        'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git@github.com:briandfoy/Object-Iterate.git',
				web  => 'https://github.com/briandfoy/Object-Iterate',
				},
			},
		},

	clean => { FILES => 'Object-Iterate-*' },
	);
