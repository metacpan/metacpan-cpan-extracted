use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Statistics::Multtest',
	VERSION_FROM  => 'lib/Statistics/Multtest.pm',
	PREREQ_PM     => {
		'List::Vectorize' => "1.00",
		'Test::More'   => 0,
		'Carp'         => 0,
	},
	AUTHOR        => 'Zuguang Gu <jokergoo@gmail.com>',
	ABSTRACT      => 'Control false discovery rate in multiple test problem',
	LICENSE       => 'perl',
);
