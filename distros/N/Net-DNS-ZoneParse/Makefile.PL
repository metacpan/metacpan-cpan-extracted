use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Net::DNS::ZoneParse',
	VERSION_FROM      => 'lib/Net/DNS/ZoneParse.pm', # finds $VERSION
	PREREQ_PM         => {
		"Net::DNS" => 0.66,
		"Test::More" => 0,
		"Test::Deep" => 0,
		"Class::Accessor" => 0,
	}, # e.g., Module::Name => 1.1
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(
			LICENSE	 => "perl",
			ABSTRACT_FROM  => 'lib/Net/DNS/ZoneParse.pm', # retrieve abstract from module
			AUTHOR         => 'Benjamin Tietz <benjamin.tietz@micronet24.de>',
			META_MERGE     => {
				no_index => {
					package => ['Net::DNS::RR'],
					namespace => ['Net::DNS::RR'],
				},
			},
		) : ()),
);
