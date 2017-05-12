use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'STUN::RFC_5389',
	AUTHOR => 'Detlef Pilzecker deti@cpan.org',
	VERSION_FROM => 'lib/STUN/RFC_5389.pm',
	PREREQ_PM => {
		'Socket' => 0,
	},
	LICENSE => 'perl',
);
