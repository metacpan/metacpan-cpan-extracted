use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Parse::EBNF',
	'VERSION_FROM'	=> 'lib/Parse/EBNF.pm',
	'PREREQ_PM'	=> {
		Test::Simple => 0,
		Test::More => 0,
	},
);
