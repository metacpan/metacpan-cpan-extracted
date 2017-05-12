BEGIN { require 5.008003 }
	# 5.8.2 doesn't like *foo{THING} for q/quote-like/

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sub::Delete',
    AUTHOR              => 'Father Chrysostomos <sprout [hat] cpan . org>',
    VERSION_FROM        => 'lib/Sub/Delete.pm',
    ABSTRACT_FROM       => 'lib/Sub/Delete.pm',
    PL_FILES            => {},
    PREREQ_PM => {
         constant                         => 0,
         Exporter                         => 5.57,
         strict                           => 0,
# for testing:
	warnings   => 0,
    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'Sub-Delete-*' },
);
