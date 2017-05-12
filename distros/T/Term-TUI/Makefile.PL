
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Term::TUI',
	VERSION	         => '1.23',
	($] >= 5.005
	? (ABSTRACT=>'simple tool for building text-based user interfaces',
	   AUTHOR  =>'Sullivan Beck (sbeck@cpan.org)')
	: ()),
	'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
        PL_FILES  => {},
	PREREQ_PM => {
		'Term::ReadLine'      => '0',
		'Text::ParseWords'    => '0',
		'Test::More'          => '0',
		'Test::Pod'           => '0',
		'Test::Pod::Coverage' => '0',
	},
);
