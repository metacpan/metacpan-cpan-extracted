BEGIN { require 5.01 } # // and (?1)
use ExtUtils::MakeMaker;

my %prq = (
	 Compress'Zlib                => 0,
#	 Encode                       => 2.1,  # LEAVE_SRC
#	 Exporter                     => 0,
	 Hash'Util'FieldHash          => 0,
	 warnings                     => 0,
# for testing only:
	'lib'                         => 0,
	'File::Copy'                  => 0,
);


WriteMakefile(
    NAME           => 'PDF::Tiny',
    AUTHOR         => 'Father Chrysostomos <sprout at, um, cpan . org>',
    VERSION_FROM   => 'lib/PDF/Tiny.pm',
    ABSTRACT_FROM  => 'lib/PDF/Tiny.pod',
    LICENSE        => 'perl',
    PL_FILES       => {},
    PREREQ_PM      => \%prq,
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                        TAR => 'COPYFILE_DISABLE=1 tar' },
    clean          => { FILES => 'PDF-Tiny-*' },
);
