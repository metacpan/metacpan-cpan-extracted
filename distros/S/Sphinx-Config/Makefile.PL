use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sphinx::Config',
    AUTHOR              => 'Jon Schutz <jon@jschutz.net>',
    VERSION_FROM        => 'lib/Sphinx/Config.pm',
    ABSTRACT_FROM       => 'lib/Sphinx/Config.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Carp' => 0,
	'FindBin' => 0,
	'Storable' => 0,
	'List::MoreUtils' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sphinx-Config-*' },
);
