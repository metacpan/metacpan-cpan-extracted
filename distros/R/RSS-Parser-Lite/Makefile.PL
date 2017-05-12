use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'XML::RSS::Parser::Lite',
	VERSION_FROM	=> 'lib/XML/RSS/Parser/Lite.pm',
	PREREQ_PM	=> {
		'XML::Parser::Lite' => 0,
	}
);
