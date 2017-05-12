use ExtUtils::MakeMaker;
WriteMakefile(
	NAME              => 'Sub::Lvalue',
	VERSION_FROM      => 'lib/Sub/Lvalue.pm',
	ABSTRACT_FROM     => 'lib/Sub/Lvalue.pm',
	PREREQ_PM         => { 'Sub::Name' => 0 },
	LICENSE           => 'perl',
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
);
