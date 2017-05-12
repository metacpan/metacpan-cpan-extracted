use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'         => 'Spreadsheet::WriteExcel::Simple',
	'VERSION_FROM' => 'Simple.pm',                         # finds $VERSION
	'PREREQ_PM'    => {
		'Spreadsheet::WriteExcel' => 0.31,
		'IO::Scalar'              => 1.126,
		'Test::More'              => 0.04,
	},
	(
		$] >= 5.005
		?    ## Add these new keywords supported since 5.005
			(
			ABSTRACT_FROM => 'Simple.pm',    # retrieve abstract from module
			AUTHOR => 'Tony Bowden <kasei@tmtm.com>'
			)
		: ()
	),
);
