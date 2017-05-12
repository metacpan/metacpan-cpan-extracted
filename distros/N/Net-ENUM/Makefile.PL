use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile(
	NAME => 'Net::ENUM',
	VERSION_FROM => 'lib/Net/ENUM.pm',
	PREREQ_PM => {
		'Net::DNS' => 0.56,
	},
);
