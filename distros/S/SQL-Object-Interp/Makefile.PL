use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'SQL::Object::Interp',
	VERSION_FROM	=> 'lib/SQL/Object/Interp.pm',
	ABSTRACT => 'Yet another SQL condition builder with SQL::Interp',
	PREREQ_PM		=> {'ExtUtils::MakeMaker' => 6.42, 'Test::More' => 0.94, 'SQL::Object' => 0.01, 'SQL::Interp' => 0},
	($] >= 5.005 ?	## Add these new keywords supported since 5.005
	  (AUTHOR	=> 'Narazaka (http://narazaka.net/)') : ()),
	( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl', ) : () ),
);
