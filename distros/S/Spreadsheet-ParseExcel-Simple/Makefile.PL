use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Spreadsheet::ParseExcel::Simple',
	AUTHOR        => 'Tony Bowden <kasei@tmtm.com>',
	VERSION_FROM  => 'lib/Spreadsheet/ParseExcel/Simple.pm',
	ABSTRACT_FROM => 'lib/Spreadsheet/ParseExcel/Simple.pm',
	PREREQ_PM     => {
		'Spreadsheet::ParseExcel' => 0.18,
		'Test::More'              => 0.01,
	},
);
