use ExtUtils::MakeMaker;

WriteMakefile(
	AUTHOR        => 'Ka-Wai Mak',
	NAME          => 'PBS::Client',
	VERSION_FROM  => 'lib/PBS/Client.pm',
	ABSTRACT_FROM => "lib/PBS/Client.pm",
	PREREQ_PM     => {
        Data::Dumper => 2.121,
        File::Temp   => 0.14,
        Symbol       => 1.06,
        IPC::Open3   => 1.02,
    },
	EXE_FILES     => [ 'bin/run' ],
	dist          => {
		SUFFIX   => '.gz',
		COMPRESS => 'gzip -f',
	},

    ($ExtUtils::MakeMaker::VERSION > 6.48)? (LICENSE => "perl"): (),
);
