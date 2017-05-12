use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Template::Plugin::PerlTidy',
	VERSION_FROM  => 'lib/Template/Plugin/PerlTidy.pm',
	PREREQ_PM     => { 
			  'Template'	=> 2.00,
			  'Perl::Tidy'	=> 0,
			  'IO::Scalar'	=> 0,
			  'IO::ScalarArray'	=> 0,
			 },
	ABSTRACT_FROM => 'lib/Template/Plugin/PerlTidy.pm',
	AUTHOR        => 'Briac Pilpré <briac@cpan.org>',
);

