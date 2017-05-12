use 5.006001;
use ExtUtils::MakeMaker;
use ExtUtils::Liblist;

BEGIN {
	if ($^O eq 'MSWin32') {		# Should check other OS as well?
		print("OS unsupported\n");
		exit(0);
	}
}

WriteMakefile(
    NAME                => 'Net::NIS::Netgroup',
    AUTHOR              => 'Bastian Friedrich <bastian.friedrich@collax.com>',
    VERSION_FROM        => 'lib/Net/NIS/Netgroup.pm',
    ABSTRACT_FROM       => 'lib/Net/NIS/Netgroup.pm',
    PREREQ_PM           => {
        'Exporter'      => 0,
        'Test::More'    => 0,
        'Test::Builder' => 0,
    },

    NEEDS_LINKING       => 1,
    INC                 => '-I.',

    EXE_FILES           => [],
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Net-NIS-Netgroup-*.tar.*' },
);
